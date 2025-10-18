#!/bin/bash

# ===========================================
# WordPress Docker 初期セットアップスクリプト
# ===========================================
# このスクリプトは初回のみ実行してください
# 実行方法: ./new.sh

set -e

# カラー設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ロゴ表示
echo -e "${BLUE}"
cat << "EOF"
╦ ╦┌─┐┬─┐┌┬┐╔═╗┬─┐┌─┐┌─┐┌─┐  ╔╦╗┌─┐┌─┐┬┌─┌─┐┬─┐
║║║│ │├┬┘ ││╠═╝├┬┘├┤ └─┐└─┐   ║║│ ││  ├┴┐├┤ ├┬┘
╚╩╝└─┘┴└──┴┘╩  ┴└─└─┘└─┘└─┘  ═╩╝└─┘└─┘┴ ┴└─┘┴└─
EOF
echo -e "${NC}"
echo -e "${GREEN}WordPress Docker 初期セットアップ${NC}\n"

# ===========================================
# 前提条件チェック
# ===========================================
echo -e "${YELLOW}[1/7] 前提条件をチェック中...${NC}"

# Dockerがインストールされているか確認
if ! command -v docker &> /dev/null; then
    echo -e "${RED}エラー: Dockerがインストールされていません${NC}"
    echo "https://www.docker.com/get-started からDockerをインストールしてください"
    exit 1
fi

# Docker Composeがインストールされているか確認
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}エラー: Docker Composeがインストールされていません${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker: $(docker --version)${NC}"
echo -e "${GREEN}✓ Docker Compose: $(docker-compose --version)${NC}\n"

# ===========================================
# 環境変数ファイルの作成
# ===========================================
echo -e "${YELLOW}[2/7] 環境変数ファイルを作成中...${NC}"

if [ ! -f .env ]; then
    cp .env.example .env
    echo -e "${GREEN}✓ .env ファイルを作成しました${NC}"
    echo -e "${YELLOW}※ .env ファイルを編集して、適切な値を設定してください${NC}\n"
else
    echo -e "${YELLOW}! .env ファイルは既に存在します${NC}\n"
fi

# ===========================================
# 既存のコンテナとボリュームのクリーンアップ
# ===========================================
echo -e "${YELLOW}[3/7] 既存のコンテナをクリーンアップ中...${NC}"

# 既存のコンテナを停止・削除
docker-compose down -v 2>/dev/null || true

echo -e "${GREEN}✓ クリーンアップ完了${NC}\n"

# ===========================================
# Dockerイメージのビルド
# ===========================================
echo -e "${YELLOW}[4/7] Dockerイメージをビルド中...${NC}"

docker-compose build --no-cache

echo -e "${GREEN}✓ イメージビルド完了${NC}\n"

# ===========================================
# コンテナの起動
# ===========================================
echo -e "${YELLOW}[5/7] コンテナを起動中...${NC}"

docker-compose up -d

# データベースの起動を待つ
echo -e "${BLUE}データベースの準備ができるまで待機中...${NC}"
sleep 15

echo -e "${GREEN}✓ コンテナ起動完了${NC}\n"

# ===========================================
# WordPressのインストール確認
# ===========================================
echo -e "${YELLOW}[6/7] WordPressの状態を確認中...${NC}"

# WordPressが起動するまで待つ
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if curl -sf http://localhost:8000 > /dev/null 2>&1; then
        echo -e "${GREEN}✓ WordPressが正常に起動しました${NC}\n"
        break
    fi
    attempt=$((attempt + 1))
    echo -n "."
    sleep 2
done

if [ $attempt -eq $max_attempts ]; then
    echo -e "\n${RED}警告: WordPressの起動確認がタイムアウトしました${NC}"
    echo -e "${YELLOW}docker-compose logs で詳細を確認してください${NC}\n"
fi

# ===========================================
# .gitignoreへの追加確認
# ===========================================
echo -e "${YELLOW}[7/8] .gitignore設定の確認...${NC}"

# wordpress/ディレクトリが存在するか確認
if [ -d "wordpress" ]; then
    echo -e "${BLUE}wordpress/ ディレクトリが作成されました${NC}"
    echo -e "${YELLOW}デバッグ目的で一時的にGit管理下に含めることができます${NC}"
    echo -e "${BLUE}.gitignore に wordpress/ を追加しますか？ [y/N]: ${NC}"
    read -r response

    case "$response" in
        [yY][eE][sS]|[yY])
            # .gitignoreに追加
            if [ -f .gitignore ]; then
                if ! grep -q "^wordpress/$" .gitignore; then
                    echo "wordpress/" >> .gitignore
                    echo -e "${GREEN}✓ .gitignore に wordpress/ を追加しました${NC}\n"
                else
                    echo -e "${YELLOW}! wordpress/ は既に .gitignore に含まれています${NC}\n"
                fi
            else
                echo "wordpress/" > .gitignore
                echo -e "${GREEN}✓ .gitignore を作成し、wordpress/ を追加しました${NC}\n"
            fi
            ;;
        *)
            echo -e "${GREEN}✓ wordpress/ を Git管理下に含めます（デバッグモード）${NC}\n"
            ;;
    esac
else
    echo -e "${YELLOW}! wordpress/ ディレクトリが見つかりません${NC}\n"
fi

# ===========================================
# 完了メッセージ
# ===========================================
echo -e "${YELLOW}[8/8] セットアップ完了!${NC}\n"

echo -e "${GREEN}===========================================${NC}"
echo -e "${GREEN}  WordPress開発環境のセットアップが完了しました！${NC}"
echo -e "${GREEN}===========================================${NC}\n"

echo -e "${BLUE}📋 次のステップ:${NC}"
echo -e "  1. ブラウザで ${GREEN}http://localhost:8000${NC} にアクセス"
echo -e "  2. WordPressの初期設定を完了してください\n"

echo -e "${BLUE}🔧 便利なコマンド:${NC}"
echo -e "  • 開発環境を起動: ${GREEN}./dev.sh${NC}"
echo -e "  • コンテナ停止: ${GREEN}docker-compose down${NC}"
echo -e "  • ログ確認: ${GREEN}docker-compose logs -f${NC}"
echo -e "  • コンテナ状態確認: ${GREEN}docker-compose ps${NC}\n"

echo -e "${BLUE}☁️  AWSデプロイ:${NC}"
echo -e "  • デプロイ実行: ${GREEN}./deploy.sh${NC}\n"

echo -e "${YELLOW}===========================================${NC}"
echo -e "${YELLOW}  開発を楽しんでください！ 🚀${NC}"
echo -e "${YELLOW}===========================================${NC}\n"
