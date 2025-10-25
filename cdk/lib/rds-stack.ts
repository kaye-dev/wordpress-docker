import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import { Construct } from 'constructs';

export interface RdsStackProps extends cdk.StackProps {
  projectName: string;
  environment: string;
  vpc: ec2.Vpc;
  instanceType?: ec2.InstanceType;
  allocatedStorage?: number;
  databaseName: string;
}

/**
 * RDSスタック
 * - MySQL 8.0
 * - Multi-AZ構成（高可用性）
 * - 自動バックアップ
 * - Secrets Managerで認証情報管理
 */
export class RdsStack extends cdk.Stack {
  public readonly database: rds.DatabaseInstance;
  public readonly databaseSecret: secretsmanager.Secret;
  public readonly securityGroup: ec2.SecurityGroup;

  constructor(scope: Construct, id: string, props: RdsStackProps) {
    super(scope, id, props);

    // データベース認証情報をSecrets Managerで管理
    this.databaseSecret = new secretsmanager.Secret(this, 'DatabaseSecret', {
      secretName: `${props.projectName}-${props.environment}-db-credentials`,
      description: 'WordPress Database Credentials',
      generateSecretString: {
        secretStringTemplate: JSON.stringify({
          username: 'admin',
        }),
        generateStringKey: 'password',
        excludeCharacters: '/@"\'\\', // WordPress互換性のため一部文字を除外
        passwordLength: 32,
      },
    });

    // RDS用セキュリティグループ
    this.securityGroup = new ec2.SecurityGroup(this, 'DatabaseSecurityGroup', {
      vpc: props.vpc,
      securityGroupName: `${props.projectName}-${props.environment}-rds-sg`,
      description: 'Security group for WordPress RDS database',
      allowAllOutbound: false,
    });

    // VPCのプライベートサブネットからのMySQLアクセスを許可
    this.securityGroup.addIngressRule(
      ec2.Peer.ipv4(props.vpc.vpcCidrBlock),
      ec2.Port.tcp(3306),
      'Allow MySQL access from VPC'
    );

    // サブネットグループの作成
    const subnetGroup = new rds.SubnetGroup(this, 'DatabaseSubnetGroup', {
      subnetGroupName: `${props.projectName}-${props.environment}-db-subnet-group`,
      description: 'Subnet group for WordPress database',
      vpc: props.vpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
      },
    });

    // パラメータグループの作成（WordPress最適化）
    const parameterGroup = new rds.ParameterGroup(this, 'DatabaseParameterGroup', {
      engine: rds.DatabaseInstanceEngine.mysql({
        version: rds.MysqlEngineVersion.VER_8_0_35,
      }),
      description: 'Parameter group for WordPress database',
      parameters: {
        character_set_server: 'utf8mb4',
        collation_server: 'utf8mb4_unicode_ci',
        max_connections: '500',
        innodb_buffer_pool_size: '{DBInstanceClassMemory*3/4}',
        slow_query_log: '1',
        long_query_time: '2',
        log_output: 'FILE',
      },
    });

    // RDSインスタンスの作成
    this.database = new rds.DatabaseInstance(this, 'Database', {
      instanceIdentifier: `${props.projectName}-${props.environment}-db`,
      engine: rds.DatabaseInstanceEngine.mysql({
        version: rds.MysqlEngineVersion.VER_8_0_35,
      }),
      instanceType: props.instanceType || ec2.InstanceType.of(
        ec2.InstanceClass.T3,
        ec2.InstanceSize.MICRO
      ),
      credentials: rds.Credentials.fromSecret(this.databaseSecret),
      vpc: props.vpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
      },
      securityGroups: [this.securityGroup],
      subnetGroup,
      parameterGroup,

      // データベース設定
      databaseName: props.databaseName,
      allocatedStorage: props.allocatedStorage || 20,
      maxAllocatedStorage: 100, // ストレージ自動スケーリング
      storageType: rds.StorageType.GP3,
      storageEncrypted: true, // 暗号化有効

      // 高可用性設定
      multiAz: true, // Multi-AZ構成

      // バックアップ設定
      backupRetention: cdk.Duration.days(7),
      preferredBackupWindow: '03:00-04:00', // UTC（日本時間12:00-13:00）
      preferredMaintenanceWindow: 'sun:17:00-sun:18:00', // UTC（日本時間月曜2:00-3:00）

      // 削除保護
      deletionProtection: props.environment === 'production',
      removalPolicy: props.environment === 'production'
        ? cdk.RemovalPolicy.SNAPSHOT
        : cdk.RemovalPolicy.DESTROY,

      // モニタリング
      monitoringInterval: cdk.Duration.seconds(60),
      enablePerformanceInsights: true,
      performanceInsightRetention: rds.PerformanceInsightRetention.DEFAULT,

      // CloudWatch Logsへのエクスポート
      cloudwatchLogsExports: ['error', 'general', 'slowquery'],
      cloudwatchLogsRetention: cdk.aws_logs.RetentionDays.ONE_MONTH,
    });

    // タグの追加
    cdk.Tags.of(this.database).add('Name', `${props.projectName}-${props.environment}-db`);
    cdk.Tags.of(this.database).add('Environment', props.environment);
    cdk.Tags.of(this.database).add('Project', props.projectName);

    // 出力
    new cdk.CfnOutput(this, 'DatabaseEndpoint', {
      value: this.database.dbInstanceEndpointAddress,
      description: 'Database endpoint address',
      exportName: `${props.projectName}-${props.environment}-db-endpoint`,
    });

    new cdk.CfnOutput(this, 'DatabasePort', {
      value: this.database.dbInstanceEndpointPort,
      description: 'Database port',
    });

    new cdk.CfnOutput(this, 'DatabaseSecretArn', {
      value: this.databaseSecret.secretArn,
      description: 'Database credentials secret ARN',
      exportName: `${props.projectName}-${props.environment}-db-secret-arn`,
    });

    new cdk.CfnOutput(this, 'DatabaseName', {
      value: props.databaseName,
      description: 'Database name',
    });
  }
}
