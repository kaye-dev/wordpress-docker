# セットアップガイド

## 前提条件

- Docker Desktop がインストールされていること
- macOS / Linux 環境（Windows の場合は WSL2 推奨）

## 初回セットアップ

### 1. 開発環境の起動

```bash
./scripts/dev.sh
```

初回実行時は対話式で設定を入力します。Enter キーを押すだけでデフォルト値が使用されます。

### 2. 設定項目

#### データベース設定

- **MySQL ROOT パスワード**: MySQL の root ユーザーパスワード
- **データベース名**: 作成するデータベース名
- **データベースユーザー名**: WordPress が使用するユーザー名
- **データベースパスワード**: WordPress が使用するパスワード

#### WordPress 接続設定

- **データベースホスト**: `db:3306` (デフォルト)
- **WordPress データベース名**: WordPress が接続する DB 名
- **WordPress データベースユーザー**: WordPress が使用する DB ユーザー
- **WordPress データベースパスワード**: WordPress が使用する DB パスワード
- **WordPress ポート番号**: ローカルでアクセスするポート番号

#### WordPress 初期セットアップ

- **サイト URL**: `http://localhost:8000` (デフォルト)
- **サイトタイトル**: サイトの名前
- **管理者ユーザー名**: 管理画面のログインユーザー名
- **管理者パスワード**: 管理画面のログインパスワード
- **管理者メールアドレス**: 管理者のメールアドレス

### 3. アクセス

設定完了後、以下の URL でアクセスできます：

- **フロントエンド**: <http://localhost:8000>
- **管理画面**: <http://localhost:8000/wp-admin>

## 2回目以降の起動

`.env`ファイルが既に存在する場合、対話なしで即座に起動します：

```bash
./scripts/dev.sh
```

既存のコンテナがあればそのまま起動、無ければ新規作成されます。

## 設定ファイルの編集

後から設定を変更したい場合は、`.env`ファイルを直接編集してください：

```bash
vi .env
# または
code .env
```

編集後は環境を再起動：

```bash
docker-compose down
./scripts/dev.sh
```

## トラブルシューティング

### コンテナが起動しない

```bash
# ログを確認
docker-compose logs

# 特定のサービスのログを確認
docker-compose logs wordpress
docker-compose logs db
```

### ポートが既に使用されている

`.env`ファイルの`WORDPRESS_PORT`を変更してください：

```env
WORDPRESS_PORT=8080
```

### データベース接続エラー

データベースの準備ができていない可能性があります。少し待ってから再度アクセスしてください。

### 完全にやり直したい

クリーンな状態から起動するには：

```bash
npm run clean:start
# または
./scripts/debug.sh
```

このコマンドは以下を自動的に実行します：
- コンテナとイメージの削除
- `.env`ファイルの削除
- `wordpress`ディレクトリのクリーンアップ
- クリーンな状態でアプリケーションを起動

手動で行う場合：

```bash
./scripts/del.sh
./scripts/dev.sh
```

### 設定だけやり直したい

`.env`ファイルだけを削除して再設定する場合：

```bash
rm .env
./scripts/dev.sh
```
