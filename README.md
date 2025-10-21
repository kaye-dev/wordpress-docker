# WordPress Docker

Docker と AWS CDK を利用した WordPress 開発・デプロイ環境

## 前提条件

- Docker Desktop 4.0+
- Node.js 18.0+
- AWS CLI 2.0+（本番デプロイ時）
- AWS CDK 2.0+（本番デプロイ時）

## セットアップ

```bash
# 1. 環境変数の設定
cp .env.example .env
vim .env  # 必要に応じて編集

# 2. 依存関係のインストール
npm install

# 3. 初期セットアップ
npm run new
```

開発環境: http://localhost:8000

## 開発環境

```bash
# 起動 / 停止
npm run dev start
npm run dev stop

# ログ確認 / 状態確認
npm run dev logs
npm run dev status

# コンテナにログイン
npm run dev shell      # WordPress
npm run dev db-shell   # MySQL

# クリーンアップ
npm run dev clean
```

## 本番デプロイ（AWS）

### 1. AWS設定

```bash
# 認証情報の設定
aws configure

# .envファイルを編集
vim .env
```

必要な環境変数:

- `AWS_REGION`
- `AWS_ACCOUNT_ID`
- `PROJECT_NAME`
- `ENVIRONMENT`

### 2. CDK依存関係

```bash
cd cdk
npm install
cd ..
```

### 3. デプロイ実行

```bash
npm run deploy
```

デプロイスクリプトで以下を設定:

- プロジェクト名
- 環境（production/staging/development）
- WAF有効/無効（追加料金: $6〜10/月）

デプロイ完了後、CloudFront URLが表示されます（反映まで15〜30分）

## リソースの削除

```bash
# 開発環境
npm run dev clean

# 本番環境（AWS）
cd cdk && cdk destroy --all
```

⚠️ 本番環境の削除は元に戻せません。必ずバックアップを取ってください。
