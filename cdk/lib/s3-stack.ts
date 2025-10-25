import * as cdk from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import { Construct } from 'constructs';

export interface S3StackProps extends cdk.StackProps {
  projectName: string;
  environment: string;
}

export class S3Stack extends cdk.Stack {
  public readonly uploadsBucket: s3.Bucket;

  constructor(scope: Construct, id: string, props: S3StackProps) {
    super(scope, id, props);

    const { projectName, environment } = props;

    // WordPress ファイルアップロード用 S3 バケット
    this.uploadsBucket = new s3.Bucket(this, 'WordPressUploadsBucket', {
      bucketName: `${projectName}-${environment}-uploads`,
      // バージョニングを有効化（誤削除対策）
      versioned: true,
      // パブリックアクセスをブロック（CloudFront経由でのみアクセス可能にする）
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      // 暗号化を有効化
      encryption: s3.BucketEncryption.S3_MANAGED,
      // CORS設定（WordPress管理画面からのアップロード用）
      cors: [
        {
          allowedMethods: [
            s3.HttpMethods.GET,
            s3.HttpMethods.POST,
            s3.HttpMethods.PUT,
            s3.HttpMethods.DELETE,
            s3.HttpMethods.HEAD,
          ],
          allowedOrigins: ['*'], // 本番環境では特定のドメインに制限すべき
          allowedHeaders: ['*'],
          maxAge: 3000,
        },
      ],
      // ライフサイクルルール（古いバージョンを自動削除）
      lifecycleRules: [
        {
          id: 'DeleteOldVersions',
          enabled: true,
          noncurrentVersionExpiration: cdk.Duration.days(30),
        },
      ],
      // スタック削除時の動作（本番環境では RETAIN を推奨）
      removalPolicy:
        environment === 'production'
          ? cdk.RemovalPolicy.RETAIN
          : cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: environment !== 'production',
    });

    // CloudFormation Outputs
    new cdk.CfnOutput(this, 'UploadsBucketName', {
      value: this.uploadsBucket.bucketName,
      description: 'WordPress uploads S3 bucket name',
      exportName: `${projectName}-${environment}-UploadsBucketName`,
    });

    new cdk.CfnOutput(this, 'UploadsBucketArn', {
      value: this.uploadsBucket.bucketArn,
      description: 'WordPress uploads S3 bucket ARN',
      exportName: `${projectName}-${environment}-UploadsBucketArn`,
    });

    // タグの追加
    cdk.Tags.of(this).add('Component', 'Storage');
    cdk.Tags.of(this).add('Service', 'S3');
  }
}
