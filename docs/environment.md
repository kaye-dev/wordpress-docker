# 環境変数リファレンス

## .env ファイル

環境変数は`.env`ファイルで管理されます。`.env.example`をコピーして使用するか、`./scripts/dev.sh`の対話式セットアップで自動生成できます。

```bash
# 手動でコピーする場合
cp .env.example .env
```

## 環境変数一覧

### MySQL 設定

#### MYSQL_ROOT_PASSWORD
- **説明**: MySQL の root ユーザーパスワード
- **デフォルト**: `wordpress`
- **使用場所**: MySQL コンテナ

#### MYSQL_DATABASE
- **説明**: 作成されるデータベース名
- **デフォルト**: `wordpress`
- **使用場所**: MySQL コンテナ

#### MYSQL_USER
- **説明**: MySQL のアプリケーション用ユーザー名
- **デフォルト**: `wordpress`
- **使用場所**: MySQL コンテナ

#### MYSQL_PASSWORD
- **説明**: MySQL のアプリケーション用パスワード
- **デフォルト**: `wordpress`
- **使用場所**: MySQL コンテナ

### WordPress データベース接続設定

#### WORDPRESS_DB_HOST
- **説明**: データベースのホスト名とポート
- **デフォルト**: `db:3306`
- **使用場所**: WordPress コンテナ、WP-CLI コンテナ
- **注意**: Docker Compose のサービス名`db`を使用

#### WORDPRESS_DB_NAME
- **説明**: WordPress が使用するデータベース名
- **デフォルト**: `wordpress`
- **使用場所**: WordPress コンテナ、WP-CLI コンテナ
- **注意**: `MYSQL_DATABASE`と同じ値を設定

#### WORDPRESS_DB_USER
- **説明**: WordPress がデータベースに接続する際のユーザー名
- **デフォルト**: `wordpress`
- **使用場所**: WordPress コンテナ、WP-CLI コンテナ
- **注意**: `MYSQL_USER`と同じ値を設定

#### WORDPRESS_DB_PASSWORD
- **説明**: WordPress がデータベースに接続する際のパスワード
- **デフォルト**: `wordpress`
- **使用場所**: WordPress コンテナ、WP-CLI コンテナ
- **注意**: `MYSQL_PASSWORD`と同じ値を設定

### WordPress 基本設定

#### WORDPRESS_PORT
- **説明**: ローカルホストで WordPress にアクセスする際のポート番号
- **デフォルト**: `8000`
- **使用場所**: docker-compose.yml のポートマッピング
- **例**: `8000`の場合、`http://localhost:8000`でアクセス

### WordPress 初期セットアップ（WP-CLI 用）

これらの環境変数は WP-CLI による自動インストール時に使用されます。

#### WP_URL
- **説明**: WordPress サイトの URL
- **デフォルト**: `http://localhost:8000`
- **使用場所**: WP-CLI 初期化スクリプト
- **注意**: `WORDPRESS_PORT`と整合性を取る

#### WP_TITLE
- **説明**: WordPress サイトのタイトル
- **デフォルト**: `Newsider HP`
- **使用場所**: WP-CLI 初期化スクリプト

#### WP_ADMIN_USER
- **説明**: WordPress 管理者のユーザー名
- **デフォルト**: `admin`
- **使用場所**: WP-CLI 初期化スクリプト
- **セキュリティ**: 本番環境では`admin`以外を推奨

#### WP_ADMIN_PASSWORD
- **説明**: WordPress 管理者のパスワード
- **デフォルト**: `admin`
- **使用場所**: WP-CLI 初期化スクリプト
- **セキュリティ**: 本番環境では強力なパスワードを設定

#### WP_ADMIN_EMAIL
- **説明**: WordPress 管理者のメールアドレス
- **デフォルト**: `admin@example.com`
- **使用場所**: WP-CLI 初期化スクリプト
- **注意**: 本番環境では有効なメールアドレスを設定

## 本番環境設定（AWS）

これらの変数は AWS へのデプロイ時に使用されます。詳細は[deploy.md](./deploy.md)を参照してください。

### AWS 基本設定

- `AWS_REGION`: AWS リージョン（デフォルト: `ap-northeast-1`）
- `AWS_ACCOUNT_ID`: AWS アカウント ID
- `PROJECT_NAME`: プロジェクト名
- `ENVIRONMENT`: 環境名（`production`, `staging`など）

### RDS 設定

- `RDS_INSTANCE_TYPE`: RDS インスタンスタイプ
- `RDS_ALLOCATED_STORAGE`: ストレージサイズ（GB）
- `RDS_DATABASE_NAME`: データベース名
- `RDS_USERNAME`: データベースユーザー名
- `RDS_PASSWORD`: データベースパスワード

### ECS 設定

- `ECS_TASK_CPU`: タスク CPU（例: `512`）
- `ECS_TASK_MEMORY`: タスクメモリ（例: `1024`）
- `ECS_DESIRED_COUNT`: 希望するタスク数
- `ECS_MIN_CAPACITY`: 最小キャパシティ
- `ECS_MAX_CAPACITY`: 最大キャパシティ

### その他の AWS 設定

- `CLOUDFRONT_PRICE_CLASS`: CloudFront の価格クラス
- `ENABLE_WAF`: WAF の有効化（`true`/`false`）
- `DOMAIN_NAME`: カスタムドメイン名
- `CERTIFICATE_ARN`: SSL 証明書の ARN

## 環境別の設定例

### 開発環境（ローカル）

```env
MYSQL_ROOT_PASSWORD=wordpress
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress
MYSQL_PASSWORD=wordpress

WORDPRESS_DB_HOST=db:3306
WORDPRESS_DB_NAME=wordpress
WORDPRESS_DB_USER=wordpress
WORDPRESS_DB_PASSWORD=wordpress
WORDPRESS_PORT=8000

WP_URL=http://localhost:8000
WP_TITLE=Newsider HP (Dev)
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=admin
WP_ADMIN_EMAIL=dev@example.com
```

### ステージング環境

```env
MYSQL_ROOT_PASSWORD=strong_password_here
MYSQL_DATABASE=newsider_staging
MYSQL_USER=newsider_user
MYSQL_PASSWORD=strong_password_here

WORDPRESS_DB_HOST=db:3306
WORDPRESS_DB_NAME=newsider_staging
WORDPRESS_DB_USER=newsider_user
WORDPRESS_DB_PASSWORD=strong_password_here
WORDPRESS_PORT=8000

WP_URL=https://staging.newsider.example.com
WP_TITLE=Newsider HP (Staging)
WP_ADMIN_USER=staging_admin
WP_ADMIN_PASSWORD=very_strong_password
WP_ADMIN_EMAIL=staging@newsider.example.com
```

### 本番環境

```env
MYSQL_ROOT_PASSWORD=very_strong_password_here
MYSQL_DATABASE=newsider_production
MYSQL_USER=newsider_prod
MYSQL_PASSWORD=very_strong_password_here

WORDPRESS_DB_HOST=db:3306
WORDPRESS_DB_NAME=newsider_production
WORDPRESS_DB_USER=newsider_prod
WORDPRESS_DB_PASSWORD=very_strong_password_here
WORDPRESS_PORT=80

WP_URL=https://newsider.example.com
WP_TITLE=Newsider HP
WP_ADMIN_USER=newsider_admin
WP_ADMIN_PASSWORD=extremely_strong_password
WP_ADMIN_EMAIL=admin@newsider.example.com
```

## セキュリティのベストプラクティス

1. **`.env`ファイルを Git にコミットしない**
   - `.gitignore`に`.env`が含まれていることを確認

2. **強力なパスワードを使用**
   - 本番環境では最低 16 文字以上
   - 英数字と記号を組み合わせる

3. **デフォルトのユーザー名を避ける**
   - `admin`は攻撃対象になりやすい
   - ユニークなユーザー名を使用

4. **環境ごとに異なる認証情報**
   - 開発、ステージング、本番で異なるパスワードを使用

5. **機密情報の管理**
   - AWS Secrets Manager の使用を検討
   - 環境変数の暗号化

## トラブルシューティング

### 環境変数が反映されない

```bash
# コンテナを再作成
docker-compose down
docker-compose up -d
```

### 設定値の確認

```bash
# 環境変数の確認
docker-compose config

# 特定のコンテナの環境変数を確認
docker-compose exec wordpress env | grep WORDPRESS
```

### .env ファイルの再生成

```bash
# 既存の .env を削除
rm .env

# 対話式で再生成
./scripts/dev.sh
```
