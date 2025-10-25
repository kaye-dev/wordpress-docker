#!/bin/bash
set -e

# WordPressとMySQLの準備ができるまで待機
echo "Waiting for WordPress and MySQL to be ready..."
sleep 10

# WordPressがインストール済みかチェック
if ! wp core is-installed --allow-root 2>/dev/null; then
  echo "Installing WordPress..."

  # WordPress初期設定
  wp core install \
    --url="http://localhost:8000" \
    --title="Newsider HP" \
    --admin_user="admin" \
    --admin_password="admin" \
    --admin_email="admin@example.com" \
    --allow-root

  # 言語を日本語に設定
  echo "Setting language to Japanese..."
  wp language core install ja --allow-root
  wp site switch-language ja --allow-root

  # タイムゾーンを日本に設定
  echo "Setting timezone to Tokyo..."
  wp option update timezone_string 'Asia/Tokyo' --allow-root

  # 日付フォーマットを日本式に設定
  wp option update date_format 'Y年n月j日' --allow-root
  wp option update time_format 'H:i' --allow-root

  # デフォルトのHello Worldとサンプルページを削除（オプション）
  wp post delete 1 --force --allow-root 2>/dev/null || true
  wp post delete 2 --force --allow-root 2>/dev/null || true

  echo "WordPress installation completed!"
  echo "URL: http://localhost:8000"
  echo "Admin User: admin"
  echo "Admin Password: admin"
else
  echo "WordPress is already installed."
fi
