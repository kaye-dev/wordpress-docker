# WordPress Docker

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
- 📝 **カスタム投稿タイプ**: CPT UI プラグインをプレインストール
- 🔒 **セキュリティ強化**: 管理画面URLの変更（WPS Hide Login）
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

# クリーンな状態で起動（デバッグ用）
./scripts/debug.sh
# または
npm run clean:start

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
wordpress-docker-wp/
├── docker-compose.yml      # Docker Compose 設定
├── .env.example           # 環境変数テンプレート
├── scripts/               # 管理スクリプト
│   ├── dev.sh            # 開発環境起動
│   ├── debug.sh          # クリーンセットアップ
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

## セキュリティ設定

### 管理画面URLの変更

セキュリティ向上のため、初期セットアップ時に管理画面のログインURLを変更できます。

`.env`ファイルで設定：

```bash
WP_ADMIN_LOGIN_SLUG=my-admin
```

設定後の管理画面URL: `http://localhost:8000/my-admin`

**重要**:

- デフォルトの `/wp-admin` や `/wp-login.php` は404エラーになります
- カスタムURLを忘れないようにしてください
- ブックマークやパスワードマネージャーに保存することを推奨します

## プリインストールされているプラグイン

初期セットアップ時に以下のプラグインが自動的にインストール・有効化されます：

### Custom Post Type UI (CPT UI)

カスタム投稿タイプとカスタムタクソノミーをGUIで簡単に作成・管理できるプラグインです。

**主な機能**:

- カスタム投稿タイプの作成と管理
- カスタムタクソノミーの作成と管理
- 直感的な管理画面インターフェース
- コードを書かずに高度なコンテンツ構造を実現

**アクセス方法**: 管理画面の「CPT UI」メニューから利用できます。

### WPS Hide Login

管理画面のログインURLを変更してセキュリティを強化するプラグインです（オプション）。

`.env`ファイルで`WP_ADMIN_LOGIN_SLUG`を設定すると自動的に有効化されます。

## トラブルシューティング

### ポートが使用されている

`.env`ファイルの`WORDPRESS_PORT`を変更してください。

### データベース接続エラー

データベースの起動を待ってから再度アクセスしてください。

### 管理画面URLを忘れた

`.env`ファイルの`WP_ADMIN_LOGIN_SLUG`を確認するか、WP-CLIで変更できます：

```bash
docker-compose exec wpcli wp option get whl_page --allow-root
```

### 完全にやり直したい

クリーンな状態から起動するには、`clean:start`コマンドを使用します：

```bash
npm run clean:start
# または
./scripts/debug.sh
```

このコマンドは以下を自動的に実行します：
- すべてのコンテナとイメージを削除
- `.env`ファイルを削除
- クリーンな状態でアプリケーションを起動

手動で行う場合：

```bash
./scripts/del.sh
./scripts/dev.sh
```

詳細は [docs/setup.md](docs/setup.md) を参照してください。

## ライセンス

このプロジェクトは MIT ライセンスの下で公開されています。
