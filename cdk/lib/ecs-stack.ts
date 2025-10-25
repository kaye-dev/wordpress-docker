import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as s3 from 'aws-cdk-lib/aws-s3';
import { Construct } from 'constructs';

export interface EcsStackProps extends cdk.StackProps {
  projectName: string;
  environment: string;
  vpc: ec2.Vpc;
  databaseSecret: secretsmanager.Secret;
  databaseEndpoint: string;
  databaseName: string;
  databaseSecurityGroup: ec2.SecurityGroup;
  uploadsBucket?: s3.Bucket;
  targetGroup?: elbv2.ApplicationTargetGroup;
  taskCpu?: number;
  taskMemory?: number;
  desiredCount?: number;
  minCapacity?: number;
  maxCapacity?: number;
}

/**
 * ECS Fargateスタック
 * - WordPress コンテナを実行
 * - Auto Scaling対応
 * - ALB統合
 */
export class EcsStack extends cdk.Stack {
  public readonly cluster: ecs.Cluster;
  public readonly service: ecs.FargateService;
  public readonly securityGroup: ec2.SecurityGroup;
  public readonly repository: ecr.Repository;

  constructor(scope: Construct, id: string, props: EcsStackProps) {
    super(scope, id, props);

    // ECRリポジトリの作成
    this.repository = new ecr.Repository(this, 'Repository', {
      repositoryName: `${props.projectName}-${props.environment}`,
      imageScanOnPush: true, // プッシュ時に脆弱性スキャン
      removalPolicy: props.environment === 'production'
        ? cdk.RemovalPolicy.RETAIN
        : cdk.RemovalPolicy.DESTROY,
      lifecycleRules: [
        {
          description: 'Keep last 10 images',
          maxImageCount: 10,
        },
      ],
    });

    // ECSクラスターの作成
    this.cluster = new ecs.Cluster(this, 'Cluster', {
      clusterName: `${props.projectName}-${props.environment}-cluster`,
      vpc: props.vpc,
      containerInsights: true, // Container Insightsを有効化
    });

    // ECSタスク実行ロール
    const executionRole = new iam.Role(this, 'TaskExecutionRole', {
      assumedBy: new iam.ServicePrincipal('ecs-tasks.amazonaws.com'),
      managedPolicies: [
        iam.ManagedPolicy.fromAwsManagedPolicyName('service-role/AmazonECSTaskExecutionRolePolicy'),
      ],
    });

    // Secrets Managerへのアクセス権限を追加
    props.databaseSecret.grantRead(executionRole);

    // ECSタスクロール（コンテナ内から使用）
    const taskRole = new iam.Role(this, 'TaskRole', {
      assumedBy: new iam.ServicePrincipal('ecs-tasks.amazonaws.com'),
    });

    // S3バケットへのアクセス権限を付与
    if (props.uploadsBucket) {
      props.uploadsBucket.grantReadWrite(taskRole);
    }

    // CloudWatch Logsロググループ
    const logGroup = new logs.LogGroup(this, 'LogGroup', {
      logGroupName: `/ecs/${props.projectName}-${props.environment}`,
      retention: logs.RetentionDays.ONE_MONTH,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // タスク定義
    const taskDefinition = new ecs.FargateTaskDefinition(this, 'TaskDefinition', {
      family: `${props.projectName}-${props.environment}`,
      cpu: props.taskCpu || 512,
      memoryLimitMiB: props.taskMemory || 1024,
      executionRole,
      taskRole,
    });

    // WordPressコンテナの追加
    const container = taskDefinition.addContainer('wordpress', {
      containerName: 'wordpress',
      image: ecs.ContainerImage.fromEcrRepository(this.repository, 'latest'),
      logging: ecs.LogDrivers.awsLogs({
        streamPrefix: 'wordpress',
        logGroup,
      }),
      environment: {
        WORDPRESS_DB_HOST: props.databaseEndpoint,
        WORDPRESS_DB_NAME: props.databaseName,
        ...(props.uploadsBucket && {
          S3_UPLOADS_BUCKET: props.uploadsBucket.bucketName,
          S3_UPLOADS_REGION: cdk.Stack.of(this).region,
        }),
      },
      secrets: {
        WORDPRESS_DB_USER: ecs.Secret.fromSecretsManager(props.databaseSecret, 'username'),
        WORDPRESS_DB_PASSWORD: ecs.Secret.fromSecretsManager(props.databaseSecret, 'password'),
      },
      healthCheck: {
        command: ['CMD-SHELL', 'curl -f http://localhost/ || exit 1'],
        interval: cdk.Duration.seconds(30),
        timeout: cdk.Duration.seconds(5),
        retries: 3,
        startPeriod: cdk.Duration.seconds(60),
      },
    });

    // ポートマッピング
    container.addPortMappings({
      containerPort: 80,
      protocol: ecs.Protocol.TCP,
    });

    // ECS用セキュリティグループ
    this.securityGroup = new ec2.SecurityGroup(this, 'ServiceSecurityGroup', {
      vpc: props.vpc,
      securityGroupName: `${props.projectName}-${props.environment}-ecs-sg`,
      description: 'Security group for WordPress ECS service',
      allowAllOutbound: true,
    });

    // Fargateサービスの作成
    this.service = new ecs.FargateService(this, 'Service', {
      serviceName: `${props.projectName}-${props.environment}-service`,
      cluster: this.cluster,
      taskDefinition,
      desiredCount: props.desiredCount || 2,
      minHealthyPercent: 50,
      maxHealthyPercent: 200,
      securityGroups: [this.securityGroup],
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
      },
      platformVersion: ecs.FargatePlatformVersion.LATEST,
      circuitBreaker: {
        rollback: true, // デプロイ失敗時に自動ロールバック
      },
      enableExecuteCommand: true, // ECS Execを有効化（デバッグ用）
    });

    // ターゲットグループにサービスを登録
    if (props.targetGroup) {
      this.service.attachToApplicationTargetGroup(props.targetGroup);
    }

    // Auto Scaling設定
    const scaling = this.service.autoScaleTaskCount({
      minCapacity: props.minCapacity || 2,
      maxCapacity: props.maxCapacity || 10,
    });

    // CPU使用率ベースのスケーリング
    scaling.scaleOnCpuUtilization('CpuScaling', {
      targetUtilizationPercent: 70,
      scaleInCooldown: cdk.Duration.seconds(300),
      scaleOutCooldown: cdk.Duration.seconds(60),
    });

    // メモリ使用率ベースのスケーリング
    scaling.scaleOnMemoryUtilization('MemoryScaling', {
      targetUtilizationPercent: 80,
      scaleInCooldown: cdk.Duration.seconds(300),
      scaleOutCooldown: cdk.Duration.seconds(60),
    });

    // タグの追加
    cdk.Tags.of(this.cluster).add('Name', `${props.projectName}-${props.environment}-cluster`);
    cdk.Tags.of(this.cluster).add('Environment', props.environment);
    cdk.Tags.of(this.cluster).add('Project', props.projectName);

    // 出力
    new cdk.CfnOutput(this, 'ClusterName', {
      value: this.cluster.clusterName,
      description: 'ECS Cluster name',
      exportName: `${props.projectName}-${props.environment}-cluster-name`,
    });

    new cdk.CfnOutput(this, 'ServiceName', {
      value: this.service.serviceName,
      description: 'ECS Service name',
      exportName: `${props.projectName}-${props.environment}-service-name`,
    });

    new cdk.CfnOutput(this, 'RepositoryUri', {
      value: this.repository.repositoryUri,
      description: 'ECR Repository URI',
      exportName: `${props.projectName}-${props.environment}-ecr-uri`,
    });
  }
}
