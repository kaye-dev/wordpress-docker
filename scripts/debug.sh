#!/bin/bash

# ===========================================
# WordPress Docker デバッグ用スクリプト
# ===========================================
# コンテナ、イメージ、.envをすべて削除してクリーンな状態で起動します
# 実行方法: ./scripts/debug.sh または npm run debug

set -e

# プロジェクトルートに移動
cd "$(dirname "$0")/.."

# カラー設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ===========================================
# ヘッダー
# ===========================================

echo -e "\n${BLUE}=========================================="
echo -e "🔧 デバッグモード: クリーンセットアップ"
echo -e "==========================================${NC}\n"

echo -e "${YELLOW}以下を自動的に実行します:${NC}"
echo -e "  1. すべてのDockerコンテナを停止・削除"
echo -e "  2. Dockerイメージを削除"
echo -e "  3. .envファイルを削除"
echo -e "  4. クリーンな状態でアプリケーションを起動\n"

# ===========================================
# 削除処理
# ===========================================

echo -e "${CYAN}[1/4] コンテナを停止・削除中...${NC}"
docker-compose down -v 2>/dev/null || true
echo -e "${GREEN}✓ コンテナを削除しました${NC}\n"

echo -e "${CYAN}[2/4] Dockerイメージを削除中...${NC}"
IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "wordpress_docker" || true)
if [ -n "$IMAGES" ]; then
    echo "$IMAGES" | xargs docker rmi -f 2>/dev/null || true
    echo -e "${GREEN}✓ Dockerイメージを削除しました${NC}\n"
else
    echo -e "${GREEN}✓ 削除するイメージはありません${NC}\n"
fi

echo -e "${CYAN}[3/4] .envファイルを削除中...${NC}"
if [ -f .env ]; then
    rm -f .env
    echo -e "${GREEN}✓ .envファイルを削除しました${NC}\n"
else
    echo -e "${GREEN}✓ .envファイルは存在しません${NC}\n"
fi

# wordpressディレクトリのクリーンアップ
if [ -d "wordpress" ] && [ "$(ls -A wordpress 2>/dev/null)" ]; then
    echo -e "${CYAN}wordpressディレクトリをクリーンアップ中...${NC}"
    if [ -f "wordpress/.gitkeep" ]; then
        rm -rf wordpress/*
        rm -rf wordpress/.[!.]*
        touch wordpress/.gitkeep
    else
        rm -rf wordpress
        mkdir -p wordpress
    fi
    echo -e "${GREEN}✓ wordpressディレクトリをクリーンアップしました${NC}\n"
fi

# 孤立したボリュームの削除
docker volume prune -f 2>/dev/null || true

# ===========================================
# 開発環境の起動
# ===========================================

echo -e "${CYAN}[4/4] クリーンな状態でアプリケーションを起動中...${NC}\n"

# dev.shを実行
./scripts/dev.sh

# ===========================================
# 完了メッセージ
# ===========================================

echo -e "\n${GREEN}=========================================="
echo -e "✓ デバッグ環境のセットアップが完了しました"
echo -e "==========================================${NC}\n"

echo -e "${BLUE}デバッグのヒント:${NC}"
echo -e "  • ログ確認: ${GREEN}docker-compose logs -f${NC}"
echo -e "  • コンテナ一覧: ${GREEN}docker ps${NC}"
echo -e "  • 環境変数確認: ${GREEN}cat .env${NC}"
echo -e "  • 再デバッグ: ${GREEN}npm run debug${NC}\n"
