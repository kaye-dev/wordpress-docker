import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as s3 from 'aws-cdk-lib/aws-s3';
import { Construct } from 'constructs';

export interface AlbStackProps extends cdk.StackProps {
  projectName: string;
  environment: string;
  vpc: ec2.Vpc;
  ecsService: ecs.FargateService;
  ecsSecurityGroup: ec2.SecurityGroup;
}

/**
 * Application Load Balancerスタック
 * - HTTPS対応（オプション）
 * - アクセスログ記録
 * - ヘルスチェック
 */
export class AlbStack extends cdk.Stack {
  public readonly loadBalancer: elbv2.ApplicationLoadBalancer;
  public readonly listener: elbv2.ApplicationListener;
  public readonly securityGroup: ec2.SecurityGroup;

  constructor(scope: Construct, id: string, props: AlbStackProps) {
    super(scope, id, props);

    // ALB用セキュリティグループ
    this.securityGroup = new ec2.SecurityGroup(this, 'AlbSecurityGroup', {
      vpc: props.vpc,
      securityGroupName: `${props.projectName}-${props.environment}-alb-sg`,
      description: 'Security group for Application Load Balancer',
      allowAllOutbound: true,
    });

    // インターネットからHTTP/HTTPSアクセスを許可
    this.securityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(80),
      'Allow HTTP traffic from anywhere'
    );

    this.securityGroup.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(443),
      'Allow HTTPS traffic from anywhere'
    );

    // ECSコンテナへのアクセスを許可
    props.ecsSecurityGroup.addIngressRule(
      this.securityGroup,
      ec2.Port.tcp(80),
      'Allow traffic from ALB'
    );

    // アクセスログ用S3バケット
    const accessLogsBucket = new s3.Bucket(this, 'AccessLogsBucket', {
      bucketName: `${props.projectName}-${props.environment}-alb-logs-${cdk.Stack.of(this).account}`,
      removalPolicy: props.environment === 'production'
        ? cdk.RemovalPolicy.RETAIN
        : cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: props.environment !== 'production',
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      lifecycleRules: [
        {
          enabled: true,
          expiration: cdk.Duration.days(90), // 90日後に削除
          transitions: [
            {
              storageClass: s3.StorageClass.INTELLIGENT_TIERING,
              transitionAfter: cdk.Duration.days(30),
            },
          ],
        },
      ],
    });

    // Application Load Balancerの作成
    this.loadBalancer = new elbv2.ApplicationLoadBalancer(this, 'LoadBalancer', {
      loadBalancerName: `${props.projectName}-${props.environment}-alb`,
      vpc: props.vpc,
      internetFacing: true,
      securityGroup: this.securityGroup,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PUBLIC,
      },
      deletionProtection: props.environment === 'production',
      http2Enabled: true,
      idleTimeout: cdk.Duration.seconds(60),
    });

    // アクセスログの有効化
    this.loadBalancer.logAccessLogs(accessLogsBucket);

    // HTTPリスナー（HTTPSへリダイレクト or 直接アクセス）
    this.listener = this.loadBalancer.addListener('HttpListener', {
      port: 80,
      protocol: elbv2.ApplicationProtocol.HTTP,
      open: true,
    });

    // ターゲットグループの作成
    const targetGroup = this.listener.addTargets('EcsTarget', {
      targetGroupName: `${props.projectName}-${props.environment}-tg`,
      port: 80,
      protocol: elbv2.ApplicationProtocol.HTTP,
      targets: [props.ecsService],
      deregistrationDelay: cdk.Duration.seconds(30),

      // ヘルスチェック設定
      healthCheck: {
        enabled: true,
        path: '/',
        protocol: elbv2.Protocol.HTTP,
        port: '80',
        healthyThresholdCount: 2,
        unhealthyThresholdCount: 3,
        timeout: cdk.Duration.seconds(5),
        interval: cdk.Duration.seconds(30),
        healthyHttpCodes: '200-399',
      },

      // スティッキーセッション（WordPress管理画面用）
      stickinessCookieDuration: cdk.Duration.days(1),
      stickinessCookieName: 'WORDPRESS_LB_COOKIE',

      // ターゲット属性
      targetType: elbv2.TargetType.IP,
    });

    // タグの追加
    cdk.Tags.of(this.loadBalancer).add('Name', `${props.projectName}-${props.environment}-alb`);
    cdk.Tags.of(this.loadBalancer).add('Environment', props.environment);
    cdk.Tags.of(this.loadBalancer).add('Project', props.projectName);

    // 出力
    new cdk.CfnOutput(this, 'LoadBalancerDNS', {
      value: this.loadBalancer.loadBalancerDnsName,
      description: 'Load Balancer DNS name',
      exportName: `${props.projectName}-${props.environment}-alb-dns`,
    });

    new cdk.CfnOutput(this, 'LoadBalancerArn', {
      value: this.loadBalancer.loadBalancerArn,
      description: 'Load Balancer ARN',
      exportName: `${props.projectName}-${props.environment}-alb-arn`,
    });

    new cdk.CfnOutput(this, 'LoadBalancerUrl', {
      value: `http://${this.loadBalancer.loadBalancerDnsName}`,
      description: 'Load Balancer URL',
    });
  }
}
