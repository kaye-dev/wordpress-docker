# Newsider HP WordPress

WordPress 開発環境を Docker と WP-CLI で自動セットアップ。AWS CDK による本番デプロイにも対応。

## クイックスタート

```bash
# 開発環境を起動（対話式セットアップ）
./scripts/dev.sh
```

初回実行時は対話式で設定を入力します。Enter キーでデフォルト値を使用できます。

起動後、ブラウザで <http://localhost:8000> にアクセス。

## 主な機能

- 🚀 **対話式セットアップ**: `.env`ファイルを対話形式で簡単作成
- 🔧 **WP-CLI 自動化**: WordPress のインストールと日本語設定を自動実行
- 🐳 **Docker Compose**: MySQL + WordPress + WP-CLI の完全な開発環境
- ☁️ **AWS デプロイ**: CDK による本番環境の構築

## 前提条件

- Docker Desktop
- (オプション) Node.js 18+ (npm scripts 使用時)
- (オプション) AWS CLI & CDK (AWS デプロイ時)

## コマンド

### 基本操作

```bash
# 開発環境の起動
./scripts/dev.sh
# または
npm run dev

# 完全削除（コンテナ・イメージ・ボリューム）
./scripts/del.sh
# または
npm run clean

# AWS デプロイ
./scripts/deploy.sh
# または
npm run deploy
```

### Docker Compose 操作

```bash
# 停止
docker-compose stop

# 再起動
docker-compose restart

# ログ確認
docker-compose logs -f
```

## プロジェクト構成

```text
newsider-hp-wp/
├── docker-compose.yml      # Docker Compose 設定
├── .env.example           # 環境変数テンプレート
├── scripts/               # 管理スクリプト
│   ├── dev.sh            # 開発環境起動
│   ├── del.sh            # 完全削除
│   ├── deploy.sh         # AWS デプロイ
│   └── wp-init.sh        # WP-CLI 初期化
├── wordpress/            # WordPress ファイル
└── docs/                 # 詳細ドキュメント
```

## ドキュメント

詳細な情報は `docs/` フォルダを参照してください：

- **[setup.md](docs/setup.md)** - セットアップ手順と設定項目
- **[commands.md](docs/commands.md)** - コマンドリファレンス
- **[environment.md](docs/environment.md)** - 環境変数の詳細
- **[architecture.md](docs/architecture.md)** - システム構成とアーキテクチャ

## トラブルシューティング

### ポートが使用されている

`.env`ファイルの`WORDPRESS_PORT`を変更してください。

### データベース接続エラー

データベースの起動を待ってから再度アクセスしてください。

### 完全にやり直したい

```bash
./scripts/del.sh
./scripts/dev.sh
```

詳細は [docs/setup.md](docs/setup.md) を参照してください。

## ライセンス

このプロジェクトは MIT ライセンスの下で公開されています。
