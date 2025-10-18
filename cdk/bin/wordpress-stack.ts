#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import * as dotenv from 'dotenv';
import * as path from 'path';
import { VpcStack } from '../lib/vpc-stack';
import { RdsStack } from '../lib/rds-stack';
import { EcsStack } from '../lib/ecs-stack';
import { AlbStack } from '../lib/alb-stack';
import { CloudFrontStack } from '../lib/cloudfront-stack';
import { WafStack } from '../lib/waf-stack';

// 環境変数の読み込み（プロジェクトルートの.envを読み込む）
dotenv.config({ path: path.join(__dirname, '../../.env') });

const app = new cdk.App();

// 環境変数から設定を取得
const projectName = process.env.PROJECT_NAME || 'wordpress-docker';
const environment = process.env.ENVIRONMENT || 'production';
const region = process.env.AWS_REGION || 'ap-northeast-1';
const account = process.env.AWS_ACCOUNT_ID;
const enableWaf = process.env.ENABLE_WAF === 'true';

// AWS環境設定
const env = {
  account,
  region,
};

// WAF用環境（CloudFrontのWAFはus-east-1にデプロイ必要）
const wafEnv = {
  account,
  region: 'us-east-1',
};

// タグの共通設定
const tags = {
  Project: projectName,
  Environment: environment,
  ManagedBy: 'CDK',
};

// 1. VPCスタック
const vpcStack = new VpcStack(app, `${projectName}-${environment}-VpcStack`, {
  projectName,
  environment,
  env,
  description: `VPC infrastructure for ${projectName} ${environment}`,
});

// 2. RDSスタック
const rdsStack = new RdsStack(app, `${projectName}-${environment}-RdsStack`, {
  projectName,
  environment,
  vpc: vpcStack.vpc,
  databaseName: process.env.RDS_DATABASE_NAME || 'wordpress',
  env,
  description: `RDS MySQL database for ${projectName} ${environment}`,
});
rdsStack.addDependency(vpcStack);

// 3. ECSスタック
const ecsStack = new EcsStack(app, `${projectName}-${environment}-EcsStack`, {
  projectName,
  environment,
  vpc: vpcStack.vpc,
  databaseSecret: rdsStack.databaseSecret,
  databaseEndpoint: rdsStack.database.dbInstanceEndpointAddress,
  databaseName: process.env.RDS_DATABASE_NAME || 'wordpress',
  databaseSecurityGroup: rdsStack.securityGroup,
  taskCpu: parseInt(process.env.ECS_TASK_CPU || '512'),
  taskMemory: parseInt(process.env.ECS_TASK_MEMORY || '1024'),
  desiredCount: parseInt(process.env.ECS_DESIRED_COUNT || '2'),
  minCapacity: parseInt(process.env.ECS_MIN_CAPACITY || '2'),
  maxCapacity: parseInt(process.env.ECS_MAX_CAPACITY || '10'),
  env,
  description: `ECS Fargate cluster for ${projectName} ${environment}`,
});
ecsStack.addDependency(rdsStack);

// 4. ALBスタック
const albStack = new AlbStack(app, `${projectName}-${environment}-AlbStack`, {
  projectName,
  environment,
  vpc: vpcStack.vpc,
  ecsService: ecsStack.service,
  ecsSecurityGroup: ecsStack.securityGroup,
  env,
  description: `Application Load Balancer for ${projectName} ${environment}`,
});
albStack.addDependency(ecsStack);

// 5. WAFスタック（オプション）
let wafStack: WafStack | undefined;
if (enableWaf) {
  wafStack = new WafStack(app, `${projectName}-${environment}-WafStack`, {
    projectName,
    environment,
    env: wafEnv, // WAFはus-east-1にデプロイ
    description: `WAF Web ACL for ${projectName} ${environment}`,
    crossRegionReferences: true,
  });
}

// 6. CloudFrontスタック
const cloudFrontStack = new CloudFrontStack(app, `${projectName}-${environment}-CloudFrontStack`, {
  projectName,
  environment,
  loadBalancer: albStack.loadBalancer,
  webAclArn: wafStack?.webAcl.attrArn,
  env,
  description: `CloudFront distribution for ${projectName} ${environment}`,
  crossRegionReferences: true,
});
cloudFrontStack.addDependency(albStack);
if (wafStack) {
  cloudFrontStack.addDependency(wafStack);
}

// タグを全スタックに適用
Object.entries(tags).forEach(([key, value]) => {
  cdk.Tags.of(app).add(key, value);
});

app.synth();
