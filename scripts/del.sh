#!/bin/bash

# ===========================================
# WordPress Docker 完全削除スクリプト
# ===========================================
# すべてのコンテナ、イメージ、ボリュームを削除します
# 実行方法: ./scripts/del.sh

set -e

# プロジェクトルートに移動
cd "$(dirname "$0")/.."

# カラー設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ===========================================
# 警告メッセージ
# ===========================================

echo -e "\n${RED}=========================================="
echo -e "⚠️  警告: 完全削除を実行します"
echo -e "==========================================${NC}\n"

echo -e "${YELLOW}以下がすべて削除されます:${NC}"
echo -e "  • すべてのDockerコンテナ (wordpress_docker_*)"
echo -e "  • すべてのDockerイメージ"
echo -e "  • すべてのDockerボリューム（データベース含む）"
echo -e "  • wordpressディレクトリの内容\n"

echo -e "${RED}この操作は取り消せません！${NC}\n"

# 確認
read -p "本当に削除しますか？ (yes/no): " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${GREEN}キャンセルしました${NC}\n"
    exit 0
fi

echo -e "${YELLOW}もう一度確認します。本当によろしいですか？${NC}"
read -p "削除を実行 (yes/no): " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${GREEN}キャンセルしました${NC}\n"
    exit 0
fi

# ===========================================
# 削除処理
# ===========================================

echo -e "\n${BLUE}削除を開始します...${NC}\n"

# 1. コンテナの停止と削除
echo -e "${YELLOW}[1/5] コンテナを停止・削除中...${NC}"
docker-compose down -v 2>/dev/null || true
echo -e "${GREEN}✓ コンテナを削除しました${NC}\n"

# 2. Docker イメージの削除
echo -e "${YELLOW}[2/5] Dockerイメージを削除中...${NC}"
IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "wordpress_docker" || true)
if [ -n "$IMAGES" ]; then
    echo "$IMAGES" | xargs docker rmi -f 2>/dev/null || true
    echo -e "${GREEN}✓ Dockerイメージを削除しました${NC}\n"
else
    echo -e "${GREEN}✓ 削除するイメージはありません${NC}\n"
fi

# 3. WordPress公式イメージも削除（オプション）
echo -e "${YELLOW}[3/5] WordPress/MySQL公式イメージを確認中...${NC}"
read -p "WordPress/MySQL公式イメージも削除しますか？ (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker images | grep -E "wordpress|mysql" | awk '{print $1":"$2}' | xargs docker rmi -f 2>/dev/null || true
    echo -e "${GREEN}✓ 公式イメージを削除しました${NC}\n"
else
    echo -e "${GREEN}✓ 公式イメージはスキップしました${NC}\n"
fi

# 4. wordpressディレクトリの削除
echo -e "${YELLOW}[4/5] wordpressディレクトリを削除中...${NC}"
if [ -d "wordpress" ]; then
    # .gitkeepがある場合は保持
    if [ -f "wordpress/.gitkeep" ]; then
        rm -rf wordpress/*
        rm -rf wordpress/.[!.]*
        touch wordpress/.gitkeep
    else
        rm -rf wordpress
        mkdir -p wordpress
    fi
    echo -e "${GREEN}✓ wordpressディレクトリをクリーンアップしました${NC}\n"
else
    echo -e "${GREEN}✓ wordpressディレクトリは存在しません${NC}\n"
fi

# 5. 孤立したボリュームの削除
echo -e "${YELLOW}[5/5] 孤立したボリュームを削除中...${NC}"
docker volume prune -f 2>/dev/null || true
echo -e "${GREEN}✓ ボリュームをクリーンアップしました${NC}\n"

# ===========================================
# 完了メッセージ
# ===========================================

echo -e "${GREEN}=========================================="
echo -e "✓ 削除が完了しました"
echo -e "==========================================${NC}\n"

echo -e "${BLUE}次のステップ:${NC}"
echo -e "  • 再度セットアップ: ${GREEN}./scripts/dev.sh${NC}"
echo -e "  • .envファイルの確認: ${GREEN}cat .env${NC}\n"

echo -e "${YELLOW}注意: .envファイルは削除されていません${NC}"
echo -e "${YELLOW}必要に応じて手動で削除してください: ${NC}rm .env\n"
