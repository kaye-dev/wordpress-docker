import * as cdk from 'aws-cdk-lib';
import * as wafv2 from 'aws-cdk-lib/aws-wafv2';
import { Construct } from 'constructs';

export interface WafStackProps extends cdk.StackProps {
  projectName: string;
  environment: string;
}

/**
 * WAFスタック（オプション）
 * - AWS Managed Rules
 * - レート制限
 * - SQL Injection/XSS保護
 * - WordPress特化ルール
 */
export class WafStack extends cdk.Stack {
  public readonly webAcl: wafv2.CfnWebACL;

  constructor(scope: Construct, id: string, props: WafStackProps) {
    super(scope, id, props);

    // Web ACLの作成
    this.webAcl = new wafv2.CfnWebACL(this, 'WebACL', {
      name: `${props.projectName}-${props.environment}-waf`,
      description: 'WAF for WordPress CloudFront Distribution',
      scope: 'CLOUDFRONT', // CloudFront用はus-east-1にデプロイ必要
      defaultAction: { allow: {} },

      visibilityConfig: {
        sampledRequestsEnabled: true,
        cloudWatchMetricsEnabled: true,
        metricName: `${props.projectName}-${props.environment}-waf-metric`,
      },

      rules: [
        // 1. AWS Managed Rules - Core Rule Set
        {
          name: 'AWSManagedRulesCommonRuleSet',
          priority: 1,
          statement: {
            managedRuleGroupStatement: {
              vendorName: 'AWS',
              name: 'AWSManagedRulesCommonRuleSet',
              excludedRules: [],
            },
          },
          overrideAction: { none: {} },
          visibilityConfig: {
            sampledRequestsEnabled: true,
            cloudWatchMetricsEnabled: true,
            metricName: 'AWSManagedRulesCommonRuleSetMetric',
          },
        },

        // 2. AWS Managed Rules - Known Bad Inputs
        {
          name: 'AWSManagedRulesKnownBadInputsRuleSet',
          priority: 2,
          statement: {
            managedRuleGroupStatement: {
              vendorName: 'AWS',
              name: 'AWSManagedRulesKnownBadInputsRuleSet',
              excludedRules: [],
            },
          },
          overrideAction: { none: {} },
          visibilityConfig: {
            sampledRequestsEnabled: true,
            cloudWatchMetricsEnabled: true,
            metricName: 'AWSManagedRulesKnownBadInputsRuleSetMetric',
          },
        },

        // 3. AWS Managed Rules - SQL Database
        {
          name: 'AWSManagedRulesSQLiRuleSet',
          priority: 3,
          statement: {
            managedRuleGroupStatement: {
              vendorName: 'AWS',
              name: 'AWSManagedRulesSQLiRuleSet',
              excludedRules: [],
            },
          },
          overrideAction: { none: {} },
          visibilityConfig: {
            sampledRequestsEnabled: true,
            cloudWatchMetricsEnabled: true,
            metricName: 'AWSManagedRulesSQLiRuleSetMetric',
          },
        },

        // 4. AWS Managed Rules - PHP Application
        {
          name: 'AWSManagedRulesPHPRuleSet',
          priority: 4,
          statement: {
            managedRuleGroupStatement: {
              vendorName: 'AWS',
              name: 'AWSManagedRulesPHPRuleSet',
              excludedRules: [],
            },
          },
          overrideAction: { none: {} },
          visibilityConfig: {
            sampledRequestsEnabled: true,
            cloudWatchMetricsEnabled: true,
            metricName: 'AWSManagedRulesPHPRuleSetMetric',
          },
        },

        // 5. AWS Managed Rules - WordPress Application
        {
          name: 'AWSManagedRulesWordPressRuleSet',
          priority: 5,
          statement: {
            managedRuleGroupStatement: {
              vendorName: 'AWS',
              name: 'AWSManagedRulesWordPressRuleSet',
              excludedRules: [],
            },
          },
          overrideAction: { none: {} },
          visibilityConfig: {
            sampledRequestsEnabled: true,
            cloudWatchMetricsEnabled: true,
            metricName: 'AWSManagedRulesWordPressRuleSetMetric',
          },
        },

        // 6. レート制限ルール（DDoS対策）
        {
          name: 'RateLimitRule',
          priority: 6,
          statement: {
            rateBasedStatement: {
              limit: 2000, // 5分間で2000リクエストまで
              aggregateKeyType: 'IP',
            },
          },
          action: { block: {} },
          visibilityConfig: {
            sampledRequestsEnabled: true,
            cloudWatchMetricsEnabled: true,
            metricName: 'RateLimitRuleMetric',
          },
        },

        // 7. WordPress管理画面へのレート制限（より厳格）
        {
          name: 'AdminAreaRateLimitRule',
          priority: 7,
          statement: {
            rateBasedStatement: {
              limit: 100, // 5分間で100リクエストまで
              aggregateKeyType: 'IP',
              scopeDownStatement: {
                orStatement: {
                  statements: [
                    {
                      byteMatchStatement: {
                        searchString: '/wp-admin',
                        fieldToMatch: { uriPath: {} },
                        textTransformations: [
                          {
                            priority: 0,
                            type: 'LOWERCASE',
                          },
                        ],
                        positionalConstraint: 'STARTS_WITH',
                      },
                    },
                    {
                      byteMatchStatement: {
                        searchString: '/wp-login',
                        fieldToMatch: { uriPath: {} },
                        textTransformations: [
                          {
                            priority: 0,
                            type: 'LOWERCASE',
                          },
                        ],
                        positionalConstraint: 'STARTS_WITH',
                      },
                    },
                  ],
                },
              },
            },
          },
          action: { block: {} },
          visibilityConfig: {
            sampledRequestsEnabled: true,
            cloudWatchMetricsEnabled: true,
            metricName: 'AdminAreaRateLimitRuleMetric',
          },
        },

        // 8. IP評判リスト（Amazon IP Reputation List）
        {
          name: 'AWSManagedRulesAmazonIpReputationList',
          priority: 8,
          statement: {
            managedRuleGroupStatement: {
              vendorName: 'AWS',
              name: 'AWSManagedRulesAmazonIpReputationList',
              excludedRules: [],
            },
          },
          overrideAction: { none: {} },
          visibilityConfig: {
            sampledRequestsEnabled: true,
            cloudWatchMetricsEnabled: true,
            metricName: 'AWSManagedRulesAmazonIpReputationListMetric',
          },
        },
      ],
    });

    // タグの追加
    cdk.Tags.of(this.webAcl).add('Name', `${props.projectName}-${props.environment}-waf`);
    cdk.Tags.of(this.webAcl).add('Environment', props.environment);
    cdk.Tags.of(this.webAcl).add('Project', props.projectName);

    // 出力
    new cdk.CfnOutput(this, 'WebAclArn', {
      value: this.webAcl.attrArn,
      description: 'WAF Web ACL ARN',
      exportName: `${props.projectName}-${props.environment}-waf-arn`,
    });

    new cdk.CfnOutput(this, 'WebAclId', {
      value: this.webAcl.attrId,
      description: 'WAF Web ACL ID',
    });
  }
}
