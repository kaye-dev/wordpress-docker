#!/bin/bash

# ===========================================
# WordPress Docker 開発環境起動スクリプト
# ===========================================
# このスクリプトで開発環境を起動します
# 実行方法: ./dev.sh [command]

set -e

# カラー設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ===========================================
# 関数定義
# ===========================================

# ヘルプメッセージ
show_help() {
    echo -e "${BLUE}WordPress Docker 開発環境${NC}\n"
    echo "使用方法: ./dev.sh [command]"
    echo ""
    echo "コマンド:"
    echo -e "  ${GREEN}start${NC}      開発環境を起動"
    echo -e "  ${GREEN}stop${NC}       開発環境を停止"
    echo -e "  ${GREEN}restart${NC}    開発環境を再起動"
    echo -e "  ${GREEN}logs${NC}       ログを表示（Ctrl+Cで終了）"
    echo -e "  ${GREEN}status${NC}     コンテナの状態を確認"
    echo -e "  ${GREEN}clean${NC}      コンテナとボリュームを削除"
    echo -e "  ${GREEN}shell${NC}      WordPressコンテナにログイン"
    echo -e "  ${GREEN}db-shell${NC}   データベースコンテナにログイン"
    echo -e "  ${GREEN}build${NC}      イメージを再ビルド"
    echo -e "  ${GREEN}help${NC}       このヘルプを表示"
    echo ""
}

# 開発環境を起動
start_dev() {
    echo -e "${YELLOW}開発環境を起動中...${NC}"

    if [ ! -f .env ]; then
        echo -e "${RED}エラー: .env ファイルが見つかりません${NC}"
        echo -e "${YELLOW}最初に ./new.sh を実行してください${NC}"
        exit 1
    fi

    docker-compose up -d

    echo -e "\n${GREEN}✓ 開発環境が起動しました${NC}"
    echo -e "${BLUE}WordPress: ${GREEN}http://localhost:8000${NC}"
    echo -e "${BLUE}ログ確認: ${GREEN}./dev.sh logs${NC}\n"
}

# 開発環境を停止
stop_dev() {
    echo -e "${YELLOW}開発環境を停止中...${NC}"
    docker-compose stop
    echo -e "${GREEN}✓ 開発環境を停止しました${NC}\n"
}

# 開発環境を再起動
restart_dev() {
    echo -e "${YELLOW}開発環境を再起動中...${NC}"
    docker-compose restart
    echo -e "${GREEN}✓ 開発環境を再起動しました${NC}\n"
}

# ログを表示
show_logs() {
    echo -e "${BLUE}ログを表示します（Ctrl+Cで終了）${NC}\n"
    docker-compose logs -f
}

# コンテナの状態を確認
show_status() {
    echo -e "${BLUE}コンテナの状態:${NC}\n"
    docker-compose ps
    echo ""
}

# クリーンアップ
clean_dev() {
    echo -e "${RED}警告: すべてのコンテナとボリュームを削除します${NC}"
    read -p "続行しますか？ (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}クリーンアップ中...${NC}"
        docker-compose down -v
        echo -e "${GREEN}✓ クリーンアップが完了しました${NC}\n"
    else
        echo -e "${YELLOW}キャンセルしました${NC}\n"
    fi
}

# WordPressコンテナにログイン
wordpress_shell() {
    echo -e "${BLUE}WordPressコンテナにログイン中...${NC}\n"
    docker-compose exec wordpress /bin/bash
}

# データベースコンテナにログイン
db_shell() {
    echo -e "${BLUE}データベースコンテナにログイン中...${NC}\n"
    docker-compose exec db mysql -u wordpress -pwordpress wordpress
}

# イメージを再ビルド
rebuild_dev() {
    echo -e "${YELLOW}イメージを再ビルド中...${NC}"
    docker-compose build --no-cache
    echo -e "${GREEN}✓ イメージの再ビルドが完了しました${NC}\n"
}

# ===========================================
# メイン処理
# ===========================================

# 引数がない場合はstartを実行
COMMAND=${1:-start}

case "$COMMAND" in
    start)
        start_dev
        ;;
    stop)
        stop_dev
        ;;
    restart)
        restart_dev
        ;;
    logs)
        show_logs
        ;;
    status)
        show_status
        ;;
    clean)
        clean_dev
        ;;
    shell)
        wordpress_shell
        ;;
    db-shell)
        db_shell
        ;;
    build)
        rebuild_dev
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}エラー: 不明なコマンド '$COMMAND'${NC}\n"
        show_help
        exit 1
        ;;
esac
