#!/bin/bash

# ===========================================
# WordPress Docker 開発環境スクリプト
# ===========================================
# 実行方法: ./scripts/dev.sh

set -e

# プロジェクトルートに移動
cd "$(dirname "$0")/.."

# カラー設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# ===========================================
# 関数定義
# ===========================================

# 入力プロンプト（デフォルト値付き）
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local value

    # プロンプトを表示して入力を受け取る（/dev/ttyを使って直接ターミナルから読み取る）
    printf "${CYAN}%s${NC} (default: ${GREEN}%s${NC}): " "$prompt" "$default" >&2
    read value </dev/tty

    # 入力値またはデフォルト値を返す（標準出力に出力）
    printf "%s\n" "${value:-$default}"
}

# Yes/No確認プロンプト
confirm() {
    local prompt="$1"
    local default="$2"
    local value

    while true; do
        if [ "$default" = "y" ]; then
            printf "${CYAN}%s ${NC}[${GREEN}Y${NC}/n]: " "$prompt" >&2
        else
            printf "${CYAN}%s ${NC}[y/${GREEN}N${NC}]: " "$prompt" >&2
        fi

        read value </dev/tty
        value=${value:-$default}

        case "$value" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo -e "${RED}  ✗ y または n を入力してください${NC}" >&2 ;;
        esac
    done
}

# .envファイルのインタラクティブセットアップ
setup_env() {
    echo -e "\n${BLUE}===========================================\n"
    echo -e "WordPress 環境変数の設定\n"
    echo -e "===========================================${NC}\n"

    # .env.exampleから値を読み込む
    if [ -f .env.example ]; then
        set +e
        source .env.example 2>/dev/null
        set -e
    fi

    # デフォルト値の事前設定
    MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-wordpress}"
    MYSQL_DATABASE="${MYSQL_DATABASE:-wordpress}"
    MYSQL_USER="${MYSQL_USER:-wordpress}"
    MYSQL_PASSWORD="${MYSQL_PASSWORD:-wordpress}"
    WORDPRESS_DB_HOST="${WORDPRESS_DB_HOST:-db:3306}"
    WORDPRESS_DB_NAME="${WORDPRESS_DB_NAME:-wordpress}"
    WORDPRESS_DB_USER="${WORDPRESS_DB_USER:-wordpress}"
    WORDPRESS_DB_PASSWORD="${WORDPRESS_DB_PASSWORD:-wordpress}"
    WORDPRESS_PORT="${WORDPRESS_PORT:-8000}"
    WP_TITLE="${WP_TITLE:-Newsider HP}"
    WP_ADMIN_USER="${WP_ADMIN_USER:-admin}"
    WP_ADMIN_PASSWORD="${WP_ADMIN_PASSWORD:-admin}"
    WP_ADMIN_EMAIL="${WP_ADMIN_EMAIL:-admin@example.com}"

    echo -e "${GREEN}デフォルト設定で素早くセットアップできます${NC}"
    echo -e "${GREEN}カスタマイズする場合は、各項目で値を入力してください${NC}\n"

    # クイックセットアップか詳細設定か選択
    if confirm "デフォルト設定で開始しますか？" "y"; then
        echo -e "\n${GREEN}✓ デフォルト設定を使用します${NC}\n"

        # 最小限の確認のみ
        WORDPRESS_PORT=$(prompt_with_default "WordPressポート番号" "${WORDPRESS_PORT}")
        WP_TITLE=$(prompt_with_default "サイトタイトル" "${WP_TITLE}")

    else
        echo -e "\n${YELLOW}詳細設定モード${NC}\n"

        # データベース設定
        echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${MAGENTA}【データベース設定】${NC}"
        echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        MYSQL_ROOT_PASSWORD=$(prompt_with_default "MySQL ROOTパスワード" "${MYSQL_ROOT_PASSWORD}")
        MYSQL_DATABASE=$(prompt_with_default "データベース名" "${MYSQL_DATABASE}")
        MYSQL_USER=$(prompt_with_default "データベースユーザー名" "${MYSQL_USER}")
        MYSQL_PASSWORD=$(prompt_with_default "データベースパスワード" "${MYSQL_PASSWORD}")

        echo ""

        # WordPress設定
        echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${MAGENTA}【WordPress接続設定】${NC}"
        echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        WORDPRESS_DB_HOST=$(prompt_with_default "データベースホスト" "${WORDPRESS_DB_HOST}")
        WORDPRESS_DB_NAME=$(prompt_with_default "WordPressデータベース名" "${WORDPRESS_DB_NAME}")
        WORDPRESS_DB_USER=$(prompt_with_default "WordPressデータベースユーザー" "${WORDPRESS_DB_USER}")
        WORDPRESS_DB_PASSWORD=$(prompt_with_default "WordPressデータベースパスワード" "${WORDPRESS_DB_PASSWORD}")
        WORDPRESS_PORT=$(prompt_with_default "WordPressポート番号" "${WORDPRESS_PORT}")

        echo ""

        # WordPress初期設定
        echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${MAGENTA}【WordPress初期セットアップ】${NC}"
        echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        WP_TITLE=$(prompt_with_default "サイトタイトル" "${WP_TITLE}")
        WP_ADMIN_USER=$(prompt_with_default "管理者ユーザー名" "${WP_ADMIN_USER}")
        WP_ADMIN_PASSWORD=$(prompt_with_default "管理者パスワード" "${WP_ADMIN_PASSWORD}")
        WP_ADMIN_EMAIL=$(prompt_with_default "管理者メールアドレス" "${WP_ADMIN_EMAIL}")
    fi

    # サイトURLを自動生成
    WP_URL="http://localhost:${WORDPRESS_PORT}"

    # .envファイルに書き込み
    cat > .env << EOF
# ===========================================
# WordPress Docker 環境変数設定
# ===========================================
# このファイルは ./scripts/dev.sh により自動生成されました
# 生成日時: $(date '+%Y-%m-%d %H:%M:%S')

# -------------------------------------------
# 開発環境設定
# -------------------------------------------
# MySQL設定
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_DATABASE=${MYSQL_DATABASE}
MYSQL_USER=${MYSQL_USER}
MYSQL_PASSWORD=${MYSQL_PASSWORD}

# WordPress設定
WORDPRESS_DB_HOST=${WORDPRESS_DB_HOST}
WORDPRESS_DB_NAME=${WORDPRESS_DB_NAME}
WORDPRESS_DB_USER=${WORDPRESS_DB_USER}
WORDPRESS_DB_PASSWORD=${WORDPRESS_DB_PASSWORD}

# WordPress開発用ポート
WORDPRESS_PORT=${WORDPRESS_PORT}

# WordPress初期セットアップ設定（WP-CLI用）
WP_URL=${WP_URL}
WP_TITLE=${WP_TITLE}
WP_ADMIN_USER=${WP_ADMIN_USER}
WP_ADMIN_PASSWORD=${WP_ADMIN_PASSWORD}
WP_ADMIN_EMAIL=${WP_ADMIN_EMAIL}

# -------------------------------------------
# 本番環境設定（AWS）
# -------------------------------------------
# 以下は必要に応じて設定してください
# 詳細は .env.example を参照

AWS_REGION=ap-northeast-1
AWS_ACCOUNT_ID=
PROJECT_NAME=wordpress-docker
ENVIRONMENT=production
RDS_INSTANCE_TYPE=db.t3.micro
RDS_ALLOCATED_STORAGE=20
RDS_DATABASE_NAME=wordpress
RDS_USERNAME=admin
RDS_PASSWORD=
ECS_TASK_CPU=512
ECS_TASK_MEMORY=1024
ECS_DESIRED_COUNT=2
ECS_MIN_CAPACITY=2
ECS_MAX_CAPACITY=10
CLOUDFRONT_PRICE_CLASS=PriceClass_All
ENABLE_WAF=false
DOMAIN_NAME=
CERTIFICATE_ARN=
TAG_OWNER=
TAG_PROJECT=wordpress-docker
TAG_ENVIRONMENT=production
EOF

    echo -e "\n${GREEN}✓ .envファイルを作成しました${NC}\n"
}

# Dockerコンテナの存在確認
check_containers() {
    if docker ps -a --format '{{.Names}}' | grep -q "newsider_hp"; then
        return 0
    else
        return 1
    fi
}

# 開発環境を起動
start_dev() {
    echo -e "${BLUE}===========================================\n"
    echo -e "WordPress 開発環境の起動\n"
    echo -e "===========================================${NC}\n"

    # .envファイルの確認とセットアップ
    if [ ! -f .env ]; then
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}  初回セットアップが必要です${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        setup_env
    fi

    # コンテナの存在確認
    if check_containers; then
        echo -e "${YELLOW}既存のコンテナが見つかりました${NC}"
        echo -e "${YELLOW}起動中...${NC}\n"
        docker-compose start
    else
        echo -e "${YELLOW}新規環境を構築します${NC}"
        echo -e "${YELLOW}起動中...${NC}\n"
        docker-compose up -d

        echo -e "\n${BLUE}データベースの準備を待機中...${NC}"
        sleep 10
    fi

    echo -e "\n${GREEN}✓ 開発環境が起動しました${NC}\n"
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}WordPress: ${GREEN}http://localhost:$(grep WORDPRESS_PORT .env | cut -d= -f2)${NC}"
    echo -e "${BLUE}管理画面: ${GREEN}http://localhost:$(grep WORDPRESS_PORT .env | cut -d= -f2)/wp-admin${NC}"
    echo -e "${BLUE}===========================================${NC}\n"
    echo -e "${CYAN}ログ確認: ${NC}docker-compose logs -f"
    echo -e "${CYAN}停止: ${NC}docker-compose stop"
    echo -e "${CYAN}完全削除: ${NC}./scripts/del.sh\n"
}

# ===========================================
# メイン処理
# ===========================================

start_dev
