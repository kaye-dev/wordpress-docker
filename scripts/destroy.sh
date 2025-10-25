#!/bin/bash

# ===========================================
# WordPress Docker AWS リソース削除スクリプト
# ===========================================
# このスクリプトでAWSのリソースを削除します
# 実行方法: ./destroy.sh

set -e

# カラー設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ロゴ表示
echo -e "${RED}"
cat << "EOF"
╔═╗╦ ╦╔═╗  ╔╦╗┌─┐┌─┐┌┬┐┬─┐┌─┐┬ ┬
╠═╣║║║╚═╗   ║║├┤ └─┐ │ ├┬┘│ │└┬┘
╩ ╩╚╩╝╚═╝  ═╩╝└─┘└─┘ ┴ ┴└─└─┘ ┴
EOF
echo -e "${NC}"
echo -e "${RED}WordPress Docker AWS リソース削除${NC}\n"

# ===========================================
# 前提条件チェック
# ===========================================
echo -e "${YELLOW}[1/6] 前提条件をチェック中...${NC}"

# AWS CLIの確認
if ! command -v aws &> /dev/null; then
    echo -e "${RED}エラー: AWS CLIがインストールされていません${NC}"
    exit 1
fi

# AWS CDKの確認
if ! command -v cdk &> /dev/null; then
    echo -e "${RED}エラー: AWS CDKがインストールされていません${NC}"
    exit 1
fi

echo -e "${GREEN}✓ AWS CLI: $(aws --version | head -n 1)${NC}"
echo -e "${GREEN}✓ AWS CDK: $(cdk --version)${NC}\n"

# AWSアカウント情報の確認
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo -e "${RED}エラー: AWS認証情報が設定されていません${NC}"
    echo -e "${YELLOW}aws configure を実行してください${NC}"
    exit 1
fi

AWS_REGION=$(aws configure get region || echo "ap-northeast-1")
echo -e "${GREEN}✓ AWS Account ID: ${AWS_ACCOUNT_ID}${NC}"
echo -e "${GREEN}✓ AWS Region: ${AWS_REGION}${NC}\n"

# .envファイルの確認
if [ ! -f .env ]; then
    echo -e "${RED}エラー: .env ファイルが見つかりません${NC}"
    exit 1
fi

# 環境変数の読み込み
source .env

# ===========================================
# 削除設定の対話式入力
# ===========================================
echo -e "${YELLOW}[2/6] 削除設定を行います${NC}\n"

# プロジェクト名
read -p "プロジェクト名 [${PROJECT_NAME:-wordpress-docker}]: " INPUT_PROJECT_NAME
PROJECT_NAME=${INPUT_PROJECT_NAME:-${PROJECT_NAME:-wordpress-docker}}

# 環境名
echo -e "\n${BLUE}削除対象の環境を選択してください:${NC}"
echo "  1) production (本番環境)"
echo "  2) staging (ステージング環境)"
echo "  3) development (開発環境)"
read -p "選択 [1]: " ENV_CHOICE

case $ENV_CHOICE in
    2) ENVIRONMENT="staging" ;;
    3) ENVIRONMENT="development" ;;
    *) ENVIRONMENT="production" ;;
esac

# 設定の確認
echo -e "\n${RED}===========================================${NC}"
echo -e "${RED}リソース削除の確認${NC}"
echo -e "${RED}===========================================${NC}"
echo -e "プロジェクト名: ${YELLOW}${PROJECT_NAME}${NC}"
echo -e "環境: ${YELLOW}${ENVIRONMENT}${NC}"
echo -e "AWSリージョン: ${YELLOW}${AWS_REGION}${NC}"
echo -e "AWSアカウントID: ${YELLOW}${AWS_ACCOUNT_ID}${NC}"
echo -e "${RED}===========================================${NC}\n"

echo -e "${RED}警告: この操作により、以下のリソースが削除されます:${NC}"
echo -e "  • CloudFrontディストリビューション"
echo -e "  • ALB (Application Load Balancer)"
echo -e "  • ECSクラスターとサービス"
echo -e "  • RDSデータベース (データが失われます)"
echo -e "  • EFSファイルシステム (データが失われます)"
echo -e "  • ECRリポジトリ (Dockerイメージが削除されます)"
echo -e "  • VPCとネットワーク関連リソース"
if [ -n "$ENABLE_WAF" ] && [ "$ENABLE_WAF" = "true" ]; then
    echo -e "  • WAF (Web Application Firewall)"
fi
echo ""

read -p "本当に削除しますか? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}削除をキャンセルしました${NC}"
    exit 0
fi

echo ""
read -p "最終確認: '${ENVIRONMENT}' 環境のすべてのリソースを削除します。よろしいですか? (yes/no): " FINAL_CONFIRM
if [ "$FINAL_CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}削除をキャンセルしました${NC}"
    exit 0
fi

export PROJECT_NAME=$PROJECT_NAME
export ENVIRONMENT=$ENVIRONMENT
export AWS_REGION=$AWS_REGION
export AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID

# ===========================================
# ECRイメージの削除
# ===========================================
echo -e "\n${YELLOW}[3/6] ECRリポジトリのイメージを削除中...${NC}"

ECR_REPO_NAME="${PROJECT_NAME}-${ENVIRONMENT}"

# ECRリポジトリが存在するか確認
if aws ecr describe-repositories --repository-names ${ECR_REPO_NAME} --region ${AWS_REGION} &> /dev/null; then
    echo "ECRリポジトリ ${ECR_REPO_NAME} のイメージを削除中..."

    # すべてのイメージを取得して削除
    IMAGE_IDS=$(aws ecr list-images --repository-name ${ECR_REPO_NAME} --region ${AWS_REGION} --query 'imageIds[*]' --output json)

    if [ "$IMAGE_IDS" != "[]" ]; then
        aws ecr batch-delete-image \
            --repository-name ${ECR_REPO_NAME} \
            --region ${AWS_REGION} \
            --image-ids "$IMAGE_IDS" > /dev/null 2>&1 || true
        echo -e "${GREEN}✓ ECRイメージを削除しました${NC}"
    else
        echo -e "${YELLOW}! ECRイメージはありませんでした${NC}"
    fi
else
    echo -e "${YELLOW}! ECRリポジトリが見つかりませんでした${NC}"
fi

# ===========================================
# S3バケットの削除（CloudFrontログ用）
# ===========================================
echo -e "\n${YELLOW}[4/6] S3バケットを空にしています...${NC}"

# CloudFrontスタックからS3バケット名を取得
CLOUDFRONT_STACK="${PROJECT_NAME}-${ENVIRONMENT}-CloudFrontStack"
LOG_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name ${CLOUDFRONT_STACK} \
    --query 'Stacks[0].Outputs[?OutputKey==`LogBucketName`].OutputValue' \
    --output text 2>/dev/null || echo "")

if [ -n "$LOG_BUCKET" ] && [ "$LOG_BUCKET" != "None" ]; then
    echo "S3バケット ${LOG_BUCKET} を空にしています..."
    aws s3 rm s3://${LOG_BUCKET} --recursive 2>/dev/null || true
    echo -e "${GREEN}✓ S3バケットを空にしました${NC}"
else
    echo -e "${YELLOW}! S3バケットが見つかりませんでした${NC}"
fi

# ===========================================
# CDKスタックの削除
# ===========================================
echo -e "\n${YELLOW}[5/6] CDKスタックを削除中...${NC}"
echo -e "${CYAN}これには15〜30分かかる場合があります...${NC}\n"

cd cdk

# スタックのリストを取得（逆順で削除）
STACKS=(
    "${PROJECT_NAME}-${ENVIRONMENT}-CloudFrontStack"
    "${PROJECT_NAME}-${ENVIRONMENT}-EcsStack"
    "${PROJECT_NAME}-${ENVIRONMENT}-RdsStack"
    "${PROJECT_NAME}-${ENVIRONMENT}-VpcStack"
)

# 各スタックを削除
for STACK in "${STACKS[@]}"; do
    echo -e "${BLUE}スタック ${STACK} を削除中...${NC}"

    # スタックが存在するか確認
    if aws cloudformation describe-stacks --stack-name ${STACK} --region ${AWS_REGION} &> /dev/null; then
        cdk destroy ${STACK} --force || {
            echo -e "${YELLOW}警告: スタック ${STACK} の削除に失敗しました。手動で確認してください。${NC}"
        }
    else
        echo -e "${YELLOW}! スタック ${STACK} は既に削除されています${NC}"
    fi
done

cd ..

echo -e "\n${GREEN}✓ CDKスタックの削除が完了しました${NC}\n"

# ===========================================
# 削除完了の確認
# ===========================================
echo -e "${YELLOW}[6/6] 削除結果を確認中...${NC}\n"

echo -e "${BLUE}残存スタックの確認:${NC}"
for STACK in "${STACKS[@]}"; do
    if aws cloudformation describe-stacks --stack-name ${STACK} --region ${AWS_REGION} &> /dev/null; then
        STATUS=$(aws cloudformation describe-stacks --stack-name ${STACK} --query 'Stacks[0].StackStatus' --output text)
        echo -e "  ${YELLOW}${STACK}: ${STATUS}${NC}"
    else
        echo -e "  ${GREEN}${STACK}: 削除済み${NC}"
    fi
done

# ===========================================
# 削除完了
# ===========================================
echo ""
echo -e "${GREEN}===========================================${NC}"
echo -e "${GREEN}  リソースの削除が完了しました！${NC}"
echo -e "${GREEN}===========================================${NC}\n"

echo -e "${BLUE}📋 削除情報:${NC}"
echo -e "  プロジェクト: ${GREEN}${PROJECT_NAME}${NC}"
echo -e "  環境: ${GREEN}${ENVIRONMENT}${NC}"
echo -e "  リージョン: ${GREEN}${AWS_REGION}${NC}"
echo ""

echo -e "${YELLOW}⚠️  注意事項:${NC}"
echo -e "  • CloudFrontディストリビューションの削除には最大30分かかります"
echo -e "  • 削除中のスタックがある場合は、AWSコンソールで状態を確認してください"
echo -e "  • RDSとEFSのデータは完全に削除され、復元できません"
echo ""

echo -e "${BLUE}🔍 確認方法:${NC}"
echo -e "  • CloudFormationコンソール: https://console.aws.amazon.com/cloudformation/home?region=${AWS_REGION}"
echo -e "  • 削除が失敗した場合は、依存リソースを手動で削除してください"
echo ""

echo -e "${GREEN}===========================================${NC}"
echo -e "${GREEN}  ご利用ありがとうございました！${NC}"
echo -e "${GREEN}===========================================${NC}\n"
