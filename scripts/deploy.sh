#!/bin/bash

# ===========================================
# WordPress Docker AWS デプロイスクリプト
# ===========================================
# このスクリプトでAWSにデプロイします
# 実行方法: ./deploy.sh

set -e

# カラー設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ロゴ表示
echo -e "${CYAN}"
cat << "EOF"
╔═╗╦ ╦╔═╗  ╔╦╗┌─┐┌─┐┬  ┌─┐┬ ┬
╠═╣║║║╚═╗   ║║├┤ ├─┘│  │ │└┬┘
╩ ╩╚╩╝╚═╝  ═╩╝└─┘┴  ┴─┘└─┘ ┴
EOF
echo -e "${NC}"
echo -e "${GREEN}WordPress Docker AWS デプロイメント${NC}\n"

# ===========================================
# 前提条件チェック
# ===========================================
echo -e "${YELLOW}[1/8] 前提条件をチェック中...${NC}"

# AWS CLIの確認
if ! command -v aws &> /dev/null; then
    echo -e "${RED}エラー: AWS CLIがインストールされていません${NC}"
    echo "https://aws.amazon.com/cli/ からAWS CLIをインストールしてください"
    exit 1
fi

# AWS CDKの確認
if ! command -v cdk &> /dev/null; then
    echo -e "${RED}エラー: AWS CDKがインストールされていません${NC}"
    echo -e "${YELLOW}以下のコマンドでインストールしてください:${NC}"
    echo "npm install -g aws-cdk"
    exit 1
fi

# Dockerの確認
if ! command -v docker &> /dev/null; then
    echo -e "${RED}エラー: Dockerがインストールされていません${NC}"
    exit 1
fi

echo -e "${GREEN}✓ AWS CLI: $(aws --version | head -n 1)${NC}"
echo -e "${GREEN}✓ AWS CDK: $(cdk --version)${NC}"
echo -e "${GREEN}✓ Docker: $(docker --version)${NC}\n"

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
    echo -e "${YELLOW}.env.example をコピーして .env を作成してください${NC}"
    exit 1
fi

# 環境変数の読み込み
source .env

# ===========================================
# デプロイ設定の対話式入力
# ===========================================
echo -e "${YELLOW}[2/8] デプロイ設定を行います${NC}\n"

# プロジェクト名
read -p "プロジェクト名 [${PROJECT_NAME:-wordpress-docker}]: " INPUT_PROJECT_NAME
PROJECT_NAME=${INPUT_PROJECT_NAME:-${PROJECT_NAME:-wordpress-docker}}

# 環境名
echo -e "\n${BLUE}デプロイ環境を選択してください:${NC}"
echo "  1) production (本番環境)"
echo "  2) staging (ステージング環境)"
echo "  3) development (開発環境)"
read -p "選択 [1]: " ENV_CHOICE

case $ENV_CHOICE in
    2) ENVIRONMENT="staging" ;;
    3) ENVIRONMENT="development" ;;
    *) ENVIRONMENT="production" ;;
esac

# WAF設定（重要な対話部分）
echo -e "\n${BLUE}WAF（Web Application Firewall）を有効にしますか?${NC}"
echo -e "${CYAN}WAFは以下の保護を提供します:${NC}"
echo "  • SQL Injection攻撃からの保護"
echo "  • XSS（クロスサイトスクリプティング）攻撃からの保護"
echo "  • DDoS攻撃の軽減"
echo "  • WordPress特化型の攻撃パターン検出"
echo "  • レート制限による悪意あるトラフィックの制限"
echo ""
echo -e "${YELLOW}注意: WAFを有効にすると追加料金が発生します${NC}"
echo "料金詳細: https://aws.amazon.com/waf/pricing/"
echo ""
read -p "WAFを有効にしますか? (y/N): " -n 1 -r ENABLE_WAF_INPUT
echo

if [[ $ENABLE_WAF_INPUT =~ ^[Yy]$ ]]; then
    ENABLE_WAF="true"
    echo -e "${GREEN}✓ WAFを有効にします${NC}"
else
    ENABLE_WAF="false"
    echo -e "${YELLOW}! WAFは無効です（セキュリティリスクがあります）${NC}"
fi

# 設定の確認
echo -e "\n${CYAN}===========================================${NC}"
echo -e "${CYAN}デプロイ設定の確認${NC}"
echo -e "${CYAN}===========================================${NC}"
echo -e "プロジェクト名: ${GREEN}${PROJECT_NAME}${NC}"
echo -e "環境: ${GREEN}${ENVIRONMENT}${NC}"
echo -e "AWSリージョン: ${GREEN}${AWS_REGION}${NC}"
echo -e "AWSアカウントID: ${GREEN}${AWS_ACCOUNT_ID}${NC}"
echo -e "WAF有効化: ${GREEN}${ENABLE_WAF}${NC}"
echo -e "${CYAN}===========================================${NC}\n"

read -p "この設定でデプロイを続行しますか? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}デプロイをキャンセルしました${NC}"
    exit 0
fi

# .envファイルの更新
export PROJECT_NAME=$PROJECT_NAME
export ENVIRONMENT=$ENVIRONMENT
export AWS_REGION=$AWS_REGION
export AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID
export ENABLE_WAF=$ENABLE_WAF

# ===========================================
# Dockerイメージのビルドとプッシュ
# ===========================================
echo -e "\n${YELLOW}[3/8] Dockerイメージをビルド中...${NC}"

# 本番用イメージのビルド
docker build --platform linux/amd64 -t ${PROJECT_NAME}:latest -f Dockerfile .

echo -e "${GREEN}✓ Dockerイメージのビルドが完了しました${NC}\n"

# ===========================================
# CDK Bootstrap（初回のみ）
# ===========================================
echo -e "${YELLOW}[4/8] CDK環境を準備中...${NC}"

cd cdk

# package.jsonの依存関係をインストール
if [ ! -d "node_modules" ]; then
    echo "依存パッケージをインストール中..."
    npm install
fi

# CDK Bootstrap（初回のみ必要）
echo "CDK環境をブートストラップ中..."
cdk bootstrap aws://${AWS_ACCOUNT_ID}/${AWS_REGION} || true

# WAFを使用する場合はus-east-1もブートストラップ
if [ "$ENABLE_WAF" = "true" ]; then
    echo "WAF用にus-east-1をブートストラップ中..."
    cdk bootstrap aws://${AWS_ACCOUNT_ID}/us-east-1 || true
fi

echo -e "${GREEN}✓ CDK環境の準備が完了しました${NC}\n"

# ===========================================
# CDKデプロイ前の確認
# ===========================================
echo -e "${YELLOW}[5/8] デプロイ内容を確認中...${NC}"

# CDK Synthで構文チェック
cdk synth > /dev/null

# 変更差分の表示
echo -e "\n${BLUE}変更差分:${NC}"
cdk diff

echo ""
read -p "デプロイを実行しますか? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}デプロイをキャンセルしました${NC}"
    cd ..
    exit 0
fi

# ===========================================
# CDKデプロイの実行
# ===========================================
echo -e "\n${YELLOW}[6/8] AWS環境へデプロイ中...${NC}"
echo -e "${CYAN}これには10〜20分かかる場合があります...${NC}\n"

# すべてのスタックをデプロイ
cdk deploy --all --require-approval never

echo -e "\n${GREEN}✓ CDKデプロイが完了しました${NC}\n"

# ===========================================
# ECRへのイメージプッシュ
# ===========================================
echo -e "${YELLOW}[7/8] Dockerイメージを ECR にプッシュ中...${NC}"

# ECRリポジトリURLを取得
ECR_REPO=$(aws cloudformation describe-stacks \
    --stack-name ${PROJECT_NAME}-${ENVIRONMENT}-EcsStack \
    --query 'Stacks[0].Outputs[?OutputKey==`RepositoryUri`].OutputValue' \
    --output text)

if [ -z "$ECR_REPO" ]; then
    echo -e "${RED}エラー: ECRリポジトリが見つかりません${NC}"
    cd ..
    exit 1
fi

# ECRログイン
aws ecr get-login-password --region ${AWS_REGION} | \
    docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# イメージにタグ付け
docker tag ${PROJECT_NAME}:latest ${ECR_REPO}:latest

# ECRにプッシュ
docker push ${ECR_REPO}:latest

echo -e "${GREEN}✓ Dockerイメージのプッシュが完了しました${NC}\n"

# ===========================================
# ECSサービスの更新
# ===========================================
echo -e "${YELLOW}[8/8] ECSサービスを更新中...${NC}"

# クラスター名とサービス名を取得
CLUSTER_NAME="${PROJECT_NAME}-${ENVIRONMENT}-cluster"
SERVICE_NAME="${PROJECT_NAME}-${ENVIRONMENT}-service"

# サービスを強制的に新しいデプロイメントで更新
aws ecs update-service \
    --cluster ${CLUSTER_NAME} \
    --service ${SERVICE_NAME} \
    --force-new-deployment \
    --region ${AWS_REGION} > /dev/null

echo -e "${GREEN}✓ ECSサービスの更新が完了しました${NC}\n"

cd ..

# ===========================================
# デプロイ完了
# ===========================================
echo -e "${GREEN}===========================================${NC}"
echo -e "${GREEN}  デプロイが完了しました！ 🎉${NC}"
echo -e "${GREEN}===========================================${NC}\n"

# CloudFrontのURLを取得
CLOUDFRONT_URL=$(aws cloudformation describe-stacks \
    --stack-name ${PROJECT_NAME}-${ENVIRONMENT}-CloudFrontStack \
    --query 'Stacks[0].Outputs[?OutputKey==`WordPressUrl`].OutputValue' \
    --output text)

echo -e "${BLUE}📋 デプロイ情報:${NC}"
echo -e "  プロジェクト: ${GREEN}${PROJECT_NAME}${NC}"
echo -e "  環境: ${GREEN}${ENVIRONMENT}${NC}"
echo -e "  リージョン: ${GREEN}${AWS_REGION}${NC}"
if [ "$ENABLE_WAF" = "true" ]; then
    echo -e "  WAF: ${GREEN}有効${NC}"
else
    echo -e "  WAF: ${YELLOW}無効${NC}"
fi
echo ""
echo -e "${BLUE}🌐 アクセスURL:${NC}"
echo -e "  ${GREEN}${CLOUDFRONT_URL}${NC}"
echo ""
echo -e "${BLUE}⏱️  注意事項:${NC}"
echo -e "  • CloudFrontの配信が完全に有効になるまで15〜30分かかります"
echo -e "  • ECSタスクの起動とヘルスチェックに5〜10分かかります"
echo ""
echo -e "${BLUE}🔧 次のステップ:${NC}"
echo -e "  1. 上記URLにアクセスしてWordPressの初期設定を行う"
echo -e "  2. データベース接続が自動的に設定されています"
echo -e "  3. 管理画面: ${GREEN}${CLOUDFRONT_URL}/wp-admin${NC}"
echo ""
echo -e "${BLUE}📊 モニタリング:${NC}"
echo -e "  • CloudWatch: https://console.aws.amazon.com/cloudwatch/home?region=${AWS_REGION}"
echo -e "  • ECSコンソール: https://console.aws.amazon.com/ecs/home?region=${AWS_REGION}"
if [ "$ENABLE_WAF" = "true" ]; then
    echo -e "  • WAFコンソール: https://console.aws.amazon.com/wafv2/home?region=us-east-1"
fi
echo ""
echo -e "${YELLOW}===========================================${NC}"
echo -e "${YELLOW}  デプロイありがとうございました！ 🚀${NC}"
echo -e "${YELLOW}===========================================${NC}\n"
