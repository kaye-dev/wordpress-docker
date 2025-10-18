import * as cdk from 'aws-cdk-lib';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as origins from 'aws-cdk-lib/aws-cloudfront-origins';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as wafv2 from 'aws-cdk-lib/aws-wafv2';
import { Construct } from 'constructs';

export interface CloudFrontStackProps extends cdk.StackProps {
  projectName: string;
  environment: string;
  loadBalancer: elbv2.ApplicationLoadBalancer;
  webAclArn?: string;
}

/**
 * CloudFrontスタック
 * - グローバルCDN配信
 * - キャッシング最適化
 * - WAF統合（オプション）
 */
export class CloudFrontStack extends cdk.Stack {
  public readonly distribution: cloudfront.Distribution;

  constructor(scope: Construct, id: string, props: CloudFrontStackProps) {
    super(scope, id, props);

    // CloudFrontログ用S3バケット
    const logBucket = new s3.Bucket(this, 'CloudFrontLogsBucket', {
      bucketName: `${props.projectName}-${props.environment}-cf-logs-${cdk.Stack.of(this).account}`,
      removalPolicy: props.environment === 'production'
        ? cdk.RemovalPolicy.RETAIN
        : cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: props.environment !== 'production',
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      lifecycleRules: [
        {
          enabled: true,
          expiration: cdk.Duration.days(90),
        },
      ],
    });

    // キャッシュポリシー（WordPress最適化）
    const cachePolicy = new cloudfront.CachePolicy(this, 'WordPressCachePolicy', {
      cachePolicyName: `${props.projectName}-${props.environment}-cache-policy`,
      comment: 'Cache policy optimized for WordPress',
      defaultTtl: cdk.Duration.hours(24),
      minTtl: cdk.Duration.seconds(1),
      maxTtl: cdk.Duration.days(365),
      enableAcceptEncodingGzip: true,
      enableAcceptEncodingBrotli: true,
      headerBehavior: cloudfront.CacheHeaderBehavior.allowList(
        'Host',
        'CloudFront-Forwarded-Proto'
      ),
      cookieBehavior: cloudfront.CacheCookieBehavior.allowList(
        'wordpress_*',
        'wp-*',
        'comment_*'
      ),
      queryStringBehavior: cloudfront.CacheQueryStringBehavior.all(),
    });

    // オリジンリクエストポリシー
    const originRequestPolicy = new cloudfront.OriginRequestPolicy(this, 'OriginRequestPolicy', {
      originRequestPolicyName: `${props.projectName}-${props.environment}-origin-policy`,
      comment: 'Origin request policy for WordPress',
      headerBehavior: cloudfront.OriginRequestHeaderBehavior.allowList(
        'Host',
        'User-Agent',
        'Referer',
        'CloudFront-Forwarded-Proto'
      ),
      cookieBehavior: cloudfront.OriginRequestCookieBehavior.all(),
      queryStringBehavior: cloudfront.OriginRequestQueryStringBehavior.all(),
    });

    // レスポンスヘッダーポリシー（セキュリティヘッダー）
    const responseHeadersPolicy = new cloudfront.ResponseHeadersPolicy(this, 'SecurityHeadersPolicy', {
      responseHeadersPolicyName: `${props.projectName}-${props.environment}-security-headers`,
      comment: 'Security headers for WordPress',
      securityHeadersBehavior: {
        contentTypeOptions: { override: true },
        frameOptions: {
          frameOption: cloudfront.HeadersFrameOption.SAMEORIGIN,
          override: true,
        },
        referrerPolicy: {
          referrerPolicy: cloudfront.HeadersReferrerPolicy.STRICT_ORIGIN_WHEN_CROSS_ORIGIN,
          override: true,
        },
        strictTransportSecurity: {
          accessControlMaxAge: cdk.Duration.seconds(31536000),
          includeSubdomains: true,
          override: true,
        },
        xssProtection: {
          protection: true,
          modeBlock: true,
          override: true,
        },
      },
    });

    // CloudFront Distributionの作成
    this.distribution = new cloudfront.Distribution(this, 'Distribution', {
      comment: `${props.projectName} ${props.environment} WordPress Distribution`,
      enabled: true,
      httpVersion: cloudfront.HttpVersion.HTTP2_AND_3,
      priceClass: cloudfront.PriceClass.PRICE_CLASS_ALL,
      enableLogging: true,
      logBucket,
      logFilePrefix: 'cloudfront/',
      webAclId: props.webAclArn,

      // デフォルトビヘイビア
      defaultBehavior: {
        origin: new origins.LoadBalancerV2Origin(props.loadBalancer, {
          protocolPolicy: cloudfront.OriginProtocolPolicy.HTTP_ONLY,
          httpPort: 80,
          originShieldEnabled: false,
          connectionAttempts: 3,
          connectionTimeout: cdk.Duration.seconds(10),
          customHeaders: {
            'X-Custom-Header': props.projectName,
          },
        }),
        viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
        allowedMethods: cloudfront.AllowedMethods.ALLOW_ALL,
        cachedMethods: cloudfront.CachedMethods.CACHE_GET_HEAD_OPTIONS,
        cachePolicy,
        originRequestPolicy,
        responseHeadersPolicy,
        compress: true,
      },

      // 追加のビヘイビア（管理画面はキャッシュしない）
      additionalBehaviors: {
        '/wp-admin/*': {
          origin: new origins.LoadBalancerV2Origin(props.loadBalancer, {
            protocolPolicy: cloudfront.OriginProtocolPolicy.HTTP_ONLY,
            httpPort: 80,
          }),
          viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
          allowedMethods: cloudfront.AllowedMethods.ALLOW_ALL,
          cachePolicy: cloudfront.CachePolicy.CACHING_DISABLED,
          originRequestPolicy: cloudfront.OriginRequestPolicy.ALL_VIEWER,
          compress: false,
        },
        '/wp-login.php': {
          origin: new origins.LoadBalancerV2Origin(props.loadBalancer, {
            protocolPolicy: cloudfront.OriginProtocolPolicy.HTTP_ONLY,
            httpPort: 80,
          }),
          viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
          allowedMethods: cloudfront.AllowedMethods.ALLOW_ALL,
          cachePolicy: cloudfront.CachePolicy.CACHING_DISABLED,
          originRequestPolicy: cloudfront.OriginRequestPolicy.ALL_VIEWER,
          compress: false,
        },
        'wp-content/uploads/*': {
          origin: new origins.LoadBalancerV2Origin(props.loadBalancer, {
            protocolPolicy: cloudfront.OriginProtocolPolicy.HTTP_ONLY,
            httpPort: 80,
          }),
          viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
          allowedMethods: cloudfront.AllowedMethods.ALLOW_GET_HEAD_OPTIONS,
          cachedMethods: cloudfront.CachedMethods.CACHE_GET_HEAD_OPTIONS,
          cachePolicy: new cloudfront.CachePolicy(this, 'MediaCachePolicy', {
            cachePolicyName: `${props.projectName}-${props.environment}-media-cache`,
            defaultTtl: cdk.Duration.days(30),
            minTtl: cdk.Duration.days(1),
            maxTtl: cdk.Duration.days(365),
            enableAcceptEncodingGzip: true,
            enableAcceptEncodingBrotli: true,
          }),
          compress: true,
        },
      },

      // エラーページ
      errorResponses: [
        {
          httpStatus: 403,
          ttl: cdk.Duration.minutes(5),
        },
        {
          httpStatus: 404,
          ttl: cdk.Duration.minutes(5),
        },
        {
          httpStatus: 500,
          ttl: cdk.Duration.seconds(10),
        },
        {
          httpStatus: 503,
          ttl: cdk.Duration.seconds(10),
        },
      ],
    });

    // タグの追加
    cdk.Tags.of(this.distribution).add('Name', `${props.projectName}-${props.environment}-cf`);
    cdk.Tags.of(this.distribution).add('Environment', props.environment);
    cdk.Tags.of(this.distribution).add('Project', props.projectName);

    // 出力
    new cdk.CfnOutput(this, 'DistributionId', {
      value: this.distribution.distributionId,
      description: 'CloudFront Distribution ID',
      exportName: `${props.projectName}-${props.environment}-cf-id`,
    });

    new cdk.CfnOutput(this, 'DistributionDomainName', {
      value: this.distribution.distributionDomainName,
      description: 'CloudFront Distribution Domain Name',
      exportName: `${props.projectName}-${props.environment}-cf-domain`,
    });

    new cdk.CfnOutput(this, 'WordPressUrl', {
      value: `https://${this.distribution.distributionDomainName}`,
      description: 'WordPress URL (via CloudFront)',
    });
  }
}
