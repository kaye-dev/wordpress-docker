# アーキテクチャ

## システム構成

```text
┌─────────────────────────────────────────────────────────┐
│                    Docker Compose                        │
│                                                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  WordPress   │  │    MySQL     │  │   WP-CLI     │  │
│  │  Container   │◄─┤  Container   │  │  Container   │  │
│  │              │  │              │  │              │  │
│  │  Port: 8000  │  │  Port: 3306  │  │ (One-time)   │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         ▲                  ▲                 ▲           │
│         │                  │                 │           │
│         └──────────────────┴─────────────────┘           │
│                    Volumes                                │
│         ./wordpress:/var/www/html                        │
│         db_data:/var/lib/mysql                           │
│                                                           │
│  ┌──────────────┐                                        │
│  │  Tailwind    │  (Optional)                            │
│  │  Builder     │                                        │
│  │              │                                        │
│  │  Node.js     │                                        │
│  └──────────────┘                                        │
└─────────────────────────────────────────────────────────┘
```

## コンテナ構成

### 1. WordPress Container (`newsider_hp_app`)

- **イメージ**: `wordpress:latest`
- **役割**: WordPress アプリケーション本体
- **ポート**: `8000:80` (ホスト:コンテナ)
- **ボリューム**: `./wordpress:/var/www/html`
- **依存**: MySQL コンテナ

#### WordPress 環境変数

- `WORDPRESS_DB_HOST`: データベースホスト
- `WORDPRESS_DB_USER`: データベースユーザー
- `WORDPRESS_DB_PASSWORD`: データベースパスワード
- `WORDPRESS_DB_NAME`: データベース名
- `WORDPRESS_LOCALE`: 言語設定（`ja`）

### 2. MySQL Container (`newsider_hp_db`)

- **イメージ**: `mysql:5.7`
- **役割**: WordPress のデータベース
- **ポート**: `3306` (内部のみ)
- **ボリューム**: `db_data:/var/lib/mysql`
- **Platform**: `linux/amd64` (M1/M2/M3 Mac 対応)

#### MySQL 環境変数

- `MYSQL_ROOT_PASSWORD`: root パスワード
- `MYSQL_DATABASE`: 初期データベース名
- `MYSQL_USER`: アプリケーション用ユーザー
- `MYSQL_PASSWORD`: アプリケーション用パスワード

### 3. WP-CLI Container (`newsider_hp_wpcli`)

- **イメージ**: `wordpress:cli`
- **役割**: WordPress の初期セットアップと管理
- **起動**: 一度だけ実行（`restart: "no"`）
- **ボリューム**:
  - `./wordpress:/var/www/html`
  - `./scripts:/scripts`

#### WP-CLI 環境変数

WordPress と同じデータベース設定に加え：

- `WP_URL`: サイト URL
- `WP_TITLE`: サイトタイトル
- `WP_ADMIN_USER`: 管理者ユーザー名
- `WP_ADMIN_PASSWORD`: 管理者パスワード
- `WP_ADMIN_EMAIL`: 管理者メールアドレス

#### 実行内容

- WordPress コアのインストール
- 日本語言語パックのインストール
- タイムゾーンの設定（Asia/Tokyo）
- 日付フォーマットの設定
- サンプル投稿の削除

### 4. Tailwind CSS Builder Container (`newsider_hp_tailwind_builder`)

- **イメージ**: `node:18-alpine`
- **役割**: Tailwind CSS のビルド（開発時）
- **ボリューム**: `./wordpress/wp-content/themes/millecli:/app`
- **コマンド**: `npm install && npm run dev`

## ディレクトリ構成

```text
newsider-hp-wp/
├── docker-compose.yml        # Docker Compose 設定
├── .env                       # 環境変数（Git 管理外）
├── .env.example              # 環境変数のテンプレート
├── package.json              # npm スクリプト定義
├── README.md                 # プロジェクト概要
│
├── docs/                     # ドキュメント
│   ├── setup.md             # セットアップガイド
│   ├── commands.md          # コマンドリファレンス
│   ├── environment.md       # 環境変数リファレンス
│   └── architecture.md      # アーキテクチャ（本ファイル）
│
├── scripts/                  # 管理スクリプト
│   ├── dev.sh              # 開発環境起動スクリプト
│   ├── del.sh              # 完全削除スクリプト
│   ├── deploy.sh           # AWS デプロイスクリプト
│   └── wp-init.sh          # WP-CLI 初期化スクリプト
│
└── wordpress/               # WordPress ファイル（ボリュームマウント）
    ├── wp-admin/
    ├── wp-content/
    │   ├── plugins/        # プラグイン
    │   └── themes/         # テーマ
    │       └── millecli/   # カスタムテーマ
    ├── wp-includes/
    └── wp-config.php       # WordPress 設定ファイル
```

## データフロー

### 初回起動時

```text
1. ./scripts/dev.sh 実行
   ↓
2. .env ファイルが無い場合
   → 対話式セットアップで .env 生成
   ↓
3. docker-compose up -d
   ↓
4. MySQL コンテナ起動
   → データベース初期化
   ↓
5. WordPress コンテナ起動
   → wp-config.php 生成
   ↓
6. WP-CLI コンテナ起動
   → WordPress インストール
   → 日本語設定
   → 完了後自動終了
   ↓
7. 起動完了
   → <http://localhost:8000> でアクセス可能
```

### 2 回目以降の起動

```text
1. ./scripts/dev.sh 実行
   ↓
2. .env ファイル存在確認
   ↓
3. 既存コンテナの確認
   ├─ 存在する → docker-compose start（高速起動）
   └─ 存在しない → docker-compose up -d（新規作成）
   ↓
4. 起動完了
```

## ネットワーク構成

Docker Compose はデフォルトで内部ネットワークを作成します：

```text
newsider-hp-wp_default (bridge network)
├── newsider_hp_app (WordPress)
│   └── 外部: localhost:8000
│   └── 内部: wordpress:80
├── newsider_hp_db (MySQL)
│   └── 内部: db:3306
└── newsider_hp_wpcli (WP-CLI)
    └── 一時的に接続
```

### ネットワークの特徴

- コンテナ間通信はサービス名で可能
  - 例: WordPress → `db:3306` で MySQL に接続
- ホストからは `localhost:8000` でアクセス
- MySQL は外部から直接アクセス不可（セキュリティ向上）

## ボリューム管理

### 名前付きボリューム (`db_data`)

- **用途**: MySQL のデータ永続化
- **場所**: Docker 管理領域
- **削除**: `docker-compose down -v` または `./scripts/del.sh`

### バインドマウント (`./wordpress`)

- **用途**: WordPress ファイルの永続化と編集
- **場所**: プロジェクトディレクトリ
- **利点**: ホストから直接ファイル編集可能

## セキュリティ考慮事項

### 開発環境

- デフォルトの認証情報（開発用）
- MySQL は外部公開されない
- `.env` ファイルは Git 管理外

### 本番環境への推奨事項

1. **認証情報の強化**

   - 強力なパスワードの使用
   - デフォルトユーザー名の変更

2. **ネットワークセキュリティ**

   - ファイアウォールの設定
   - SSL/TLS の有効化

3. **バックアップ**

   - 定期的なデータベースバックアップ
   - ファイルバックアップ

4. **アップデート**
   - WordPress コアの定期更新
   - プラグイン/テーマの更新

## パフォーマンス最適化

### 開発環境

- **ボリュームマウント**: ファイル変更を即座に反映
- **コンテナの再利用**: 起動時間の短縮

### 本番環境の推奨

- **キャッシュプラグイン**: W3 Total Cache, WP Super Cache
- **CDN の利用**: CloudFront など
- **オブジェクトキャッシュ**: Redis, Memcached
- **データベース最適化**: RDS の適切なインスタンスタイプ選択

## スケーリング戦略

### 水平スケーリング

- ECS/Fargate での複数タスク実行
- ALB によるロードバランシング
- RDS Read Replica の活用

### 垂直スケーリング

- ECS タスクの CPU/メモリ増強
- RDS インスタンスタイプの変更

詳細は [deploy.md](./deploy.md) を参照してください。
