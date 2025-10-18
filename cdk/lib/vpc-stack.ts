import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import { Construct } from 'constructs';

export interface VpcStackProps extends cdk.StackProps {
  projectName: string;
  environment: string;
}

/**
 * VPCスタック
 * - パブリックサブネット×2 (CloudFront/ALB用)
 * - プライベートサブネット×2 (ECS/RDS用)
 * - NATゲートウェイ×2 (高可用性)
 */
export class VpcStack extends cdk.Stack {
  public readonly vpc: ec2.Vpc;

  constructor(scope: Construct, id: string, props: VpcStackProps) {
    super(scope, id, props);

    // VPCの作成
    this.vpc = new ec2.Vpc(this, 'WordPressVpc', {
      vpcName: `${props.projectName}-${props.environment}-vpc`,
      maxAzs: 2, // 2つのアベイラビリティゾーンを使用
      natGateways: 2, // 各AZにNATゲートウェイを配置（高可用性）

      // IPアドレス範囲
      ipAddresses: ec2.IpAddresses.cidr('10.0.0.0/16'),

      // サブネット設定
      subnetConfiguration: [
        {
          name: 'Public',
          subnetType: ec2.SubnetType.PUBLIC,
          cidrMask: 24,
        },
        {
          name: 'Private',
          subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
          cidrMask: 24,
        },
        {
          name: 'Isolated', // RDS用（インターネットアクセス不要）
          subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
          cidrMask: 24,
        },
      ],

      // VPCエンドポイント（AWS APIへのプライベートアクセス）
      gatewayEndpoints: {
        S3: {
          service: ec2.GatewayVpcEndpointAwsService.S3,
        },
      },
    });

    // ECRアクセス用のVPCエンドポイント（プライベートサブネットからECRにアクセス）
    this.vpc.addInterfaceEndpoint('EcrDockerEndpoint', {
      service: ec2.InterfaceVpcEndpointAwsService.ECR_DOCKER,
      privateDnsEnabled: true,
    });

    this.vpc.addInterfaceEndpoint('EcrEndpoint', {
      service: ec2.InterfaceVpcEndpointAwsService.ECR,
      privateDnsEnabled: true,
    });

    // CloudWatch Logs用のVPCエンドポイント
    this.vpc.addInterfaceEndpoint('CloudWatchLogsEndpoint', {
      service: ec2.InterfaceVpcEndpointAwsService.CLOUDWATCH_LOGS,
      privateDnsEnabled: true,
    });

    // Secrets Manager用のVPCエンドポイント
    this.vpc.addInterfaceEndpoint('SecretsManagerEndpoint', {
      service: ec2.InterfaceVpcEndpointAwsService.SECRETS_MANAGER,
      privateDnsEnabled: true,
    });

    // タグの追加
    cdk.Tags.of(this.vpc).add('Name', `${props.projectName}-${props.environment}-vpc`);
    cdk.Tags.of(this.vpc).add('Environment', props.environment);
    cdk.Tags.of(this.vpc).add('Project', props.projectName);

    // 出力
    new cdk.CfnOutput(this, 'VpcId', {
      value: this.vpc.vpcId,
      description: 'VPC ID',
      exportName: `${props.projectName}-${props.environment}-vpc-id`,
    });

    new cdk.CfnOutput(this, 'VpcCidr', {
      value: this.vpc.vpcCidrBlock,
      description: 'VPC CIDR Block',
    });
  }
}
