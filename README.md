# WordPress Docker

Docker と AWS CDK を利用した本格的な WordPress 開発・デプロイ環境

## 📋 目次

- [特徴](#-特徴)
- [システム構成](#-システム構成)
- [前提条件](#-前提条件)
- [クイックスタート](#-クイックスタート)
- [ディレクトリ構造](#-ディレクトリ構造)
- [開発環境](#-開発環境)
- [本番環境へのデプロイ](#-本番環境へのデプロイ)
- [コスト概算](#-コスト概算)
- [トラブルシューティング](#-トラブルシューティング)

## ✨ 特徴

### 開発環境

- 🐳 Docker Compose による簡単な環境構築
- 🎨 Tailwind CSS のホットリロード対応
- 📦 WordPress カスタムテーマ開発対応
- 🔄 データベース永続化

### 本番環境（AWS）

- ☁️ CloudFront + ALB + ECS (Fargate) + RDS 構成
- 🛡️ WAF による Web アプリケーション保護（オプション）
- 🔒 Secrets Manager による認証情報の安全な管理
- 📊 CloudWatch による監視・ログ管理
- 🚀 Auto Scaling 対応
- 🌐 Multi-AZ 高可用性構成

## 🏗️ システム構成

### 開発環境

```
┌─────────────────────────────────────┐
│        localhost:8000               │
│  ┌──────────────────────────────┐  │
│  │   WordPress Container        │  │
│  │   (+ Tailwind CSS Builder)   │  │
│  └──────────┬───────────────────┘  │
│             │                       │
│  ┌──────────▼───────────────────┐  │
│  │   MySQL Container            │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
```

### 本番環境（AWS）

```
                    ┌──────────────┐
                    │   Route 53   │ (オプション)
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │  CloudFront  │ ◄─── WAF (オプション)
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
         ┌─────────►│     ALB      │
         │          └──────┬───────┘
         │                 │
         │   ┌─────────────▼──────────────┐
         │   │         VPC                │
         │   │  ┌────────────────────┐    │
         │   │  │  ECS Fargate       │    │
         │   │  │  (WordPress)       │    │
         │   │  └─────────┬──────────┘    │
         │   │            │                │
         │   │  ┌─────────▼──────────┐    │
         │   │  │  RDS MySQL         │    │
         │   │  │  (Multi-AZ)        │    │
         │   │  └────────────────────┘    │
         │   └────────────────────────────┘
         │
         └─── Secrets Manager (DB認証情報)
```

## 📦 前提条件

### 開発環境

- Docker Desktop 4.0 以上
- Docker Compose 2.0 以上

### 本番デプロイ

- AWS CLI 2.0 以上
- AWS CDK 2.0 以上
- Node.js 18.0 以上
- AWS アカウント（適切な権限設定済み）

## 🚀 クイックスタート

### 1. リポジトリのクローン

```bash
git clone <repository-url>
cd wordpress-docker
```

### 2. 初期セットアップ

```bash
# 環境変数ファイルの作成
cp .env.example .env

# 必要に応じて .env を編集
vim .env

# 初期セットアップの実行
./new.sh
```

### 3. 開発環境へアクセス

ブラウザで http://localhost:8000 にアクセス

## 📁 ディレクトリ構造

```
wordpress-docker/
├── .env.example              # 環境変数テンプレート
├── .env                      # 環境変数（要作成）
├── .dockerignore             # Docker除外設定
├── Dockerfile                # 本番用Dockerイメージ
├── docker-compose.yml        # 開発環境設定
├── docker-compose.prod.yml   # 本番ビルド用設定
├── new.sh                    # 初期セットアップスクリプト
├── dev.sh                    # 開発環境操作スクリプト
├── deploy.sh                 # AWSデプロイスクリプト
├── README.md                 # このファイル
├── wordpress/                # WordPressファイル
│   └── wp-content/
│       └── themes/
│           └── millecli/     # カスタムテーマ
└── cdk/                      # AWS CDKプロジェクト
    ├── bin/
    │   └── wordpress-stack.ts
    ├── lib/
    │   ├── vpc-stack.ts      # VPC構成
    │   ├── rds-stack.ts      # RDSデータベース
    │   ├── ecs-stack.ts      # ECS Fargate
    │   ├── alb-stack.ts      # Application Load Balancer
    │   ├── cloudfront-stack.ts  # CloudFront CDN
    │   └── waf-stack.ts      # WAF設定
    ├── package.json
    ├── tsconfig.json
    └── cdk.json
```

## 🔧 開発環境

### 基本コマンド

```bash
# 開発環境の起動
./dev.sh start

# 開発環境の停止
./dev.sh stop

# 開発環境の再起動
./dev.sh restart

# ログの表示
./dev.sh logs

# コンテナの状態確認
./dev.sh status

# WordPressコンテナにログイン
./dev.sh shell

# データベースコンテナにログイン
./dev.sh db-shell

# イメージの再ビルド
./dev.sh build

# 環境のクリーンアップ
./dev.sh clean
```

### Tailwind CSS 開発

カスタムテーマ `millecli` では Tailwind CSS が使用できます：

```bash
# テーマディレクトリ
cd wordpress/wp-content/themes/millecli

# CSSの編集
vim src/css/tailwind.css

# ビルドは自動で行われます（ホットリロード）
```

## ☁️ 本番環境へのデプロイ

### デプロイ前の準備

1. **AWS 認証情報の設定**

```bash
aws configure
```

2. **環境変数の設定**
   [.env](.env) ファイルを編集：

```env
AWS_REGION=ap-northeast-1
AWS_ACCOUNT_ID=123456789012
PROJECT_NAME=wordpress-docker
ENVIRONMENT=production
RDS_DATABASE_NAME=wordpress
```

3. **CDK 依存関係のインストール**

```bash
cd cdk
npm install
cd ..
```

### デプロイの実行

```bash
./deploy.sh
```

デプロイスクリプトは対話式で以下を設定できます：

- プロジェクト名
- 環境（production/staging/development）
- **WAF の有効/無効** ⚠️

### WAF について

WAF（Web Application Firewall）を有効にすると、以下の保護が提供されます：

✅ **保護機能**

- SQL Injection 攻撃の防御
- XSS（クロスサイトスクリプティング）攻撃の防御
- WordPress 特化型攻撃パターンの検出
- DDoS 攻撃の軽減
- 管理画面へのレート制限

⚠️ **注意事項**

- 追加料金が発生します（約 $6〜10/月 + リクエスト数）
- 詳細: [AWS WAF 料金](https://aws.amazon.com/waf/pricing/)

### デプロイ後の確認

デプロイが完了すると、CloudFront の URL が表示されます：

```
https://xxxxxxxxxxxxxx.cloudfront.net
```

**注意**: CloudFront の配信が完全に有効になるまで 15〜30 分かかります。

## 💰 コスト概算

### 最小構成（WAF 無効）

| サービス               | 月額概算     |
| ---------------------- | ------------ |
| VPC                    | 無料         |
| ALB                    | $16          |
| ECS Fargate (2 タスク) | $30          |
| RDS db.t3.micro        | $15          |
| CloudFront             | $1〜         |
| **合計**               | **約 $62〜** |

### フル構成（WAF 有効）

| サービス | 月額概算       |
| -------- | -------------- |
| 最小構成 | $62            |
| WAF      | $6〜10         |
| **合計** | **約 $68〜72** |

※ 実際の費用はトラフィック量により変動します

## 🧹 リソースの削除

### 開発環境

```bash
./dev.sh clean
```

### 本番環境（AWS）

```bash
cd cdk
cdk destroy --all
cd ..
```

⚠️ **警告**: この操作は元に戻せません。必ずバックアップを取ってから実行してください。

## 🐛 トラブルシューティング

### 開発環境

**Q: コンテナが起動しない**

```bash
# ログを確認
./dev.sh logs

# クリーンな状態から再起動
./dev.sh clean
./new.sh
```

**Q: データベース接続エラー**

```bash
# データベースコンテナの状態を確認
docker-compose ps

# データベースコンテナを再起動
docker-compose restart db
```

**Q: Tailwind CSS がビルドされない**

```bash
# Tailwindコンテナのログを確認
docker-compose logs tailwind

# コンテナを再起動
docker-compose restart tailwind
```

### 本番環境

**Q: デプロイが失敗する**

1. AWS 認証情報を確認: `aws sts get-caller-identity`
2. CDK Bootstrap を実行: `cd cdk && cdk bootstrap`
3. IAM 権限を確認

**Q: CloudFront 経由でアクセスできない**

- CloudFront の配信完了まで 15〜30 分待つ
- オリジンのヘルスチェックを確認
- ALB のターゲットグループを確認

**Q: ECS タスクが起動しない**

```bash
# ECSタスクのログを確認
aws ecs describe-tasks --cluster <cluster-name> --tasks <task-id>

# CloudWatch Logsを確認
aws logs tail /ecs/<project-name>-<environment> --follow
```

## 📚 参考資料

- [WordPress 公式ドキュメント](https://wordpress.org/support/)
- [Docker 公式ドキュメント](https://docs.docker.com/)
- [AWS CDK 公式ドキュメント](https://docs.aws.amazon.com/cdk/)
- [AWS ECS 公式ドキュメント](https://docs.aws.amazon.com/ecs/)
- [AWS WAF 公式ドキュメント](https://docs.aws.amazon.com/waf/)

## 📝 ライセンス

MIT

## 🤝 貢献

プルリクエストを歓迎します！

---

**Happy Coding! 🚀**
