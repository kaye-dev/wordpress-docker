# コマンドリファレンス

## npm scripts

### 開発環境の起動

```bash
npm run dev
# または
./scripts/dev.sh
```

初回実行時は対話式セットアップが開始されます。2回目以降は既存の設定で起動します。

### 完全削除

```bash
npm run clean
# または
./scripts/del.sh
```

すべてのコンテナ、イメージ、ボリューム、WordPressファイルを削除します。

### AWSデプロイ

```bash
npm run deploy
# または
./scripts/deploy.sh
```

AWS環境へのデプロイを実行します（詳細は[deploy.md](./deploy.md)を参照）。

## Docker Compose コマンド

### コンテナの管理

```bash
# すべてのコンテナを起動
docker-compose up -d

# すべてのコンテナを停止
docker-compose stop

# すべてのコンテナを停止して削除
docker-compose down

# すべてのコンテナを停止してボリュームも削除
docker-compose down -v

# 特定のサービスを再起動
docker-compose restart wordpress
docker-compose restart db
```

### ログの確認

```bash
# すべてのログをリアルタイム表示
docker-compose logs -f

# 特定のサービスのログを表示
docker-compose logs -f wordpress
docker-compose logs -f db
docker-compose logs -f wpcli

# 最新100行のログを表示
docker-compose logs --tail=100
```

### コンテナの状態確認

```bash
# 実行中のコンテナ一覧
docker-compose ps

# すべてのコンテナ（停止中も含む）
docker-compose ps -a
```

### コンテナに入る

```bash
# WordPressコンテナ
docker-compose exec wordpress bash

# データベースコンテナ
docker-compose exec db bash

# MySQLに接続
docker-compose exec db mysql -u wordpress -pwordpress wordpress
```

## WP-CLI コマンド

コンテナ内でWP-CLIを使用できます：

```bash
# WordPressコンテナに入る
docker-compose exec wordpress bash

# WP-CLIコマンドを実行（例）
wp plugin list --allow-root
wp theme list --allow-root
wp user list --allow-root
wp option get siteurl --allow-root
```

### よく使うWP-CLIコマンド

```bash
# プラグインのインストール
wp plugin install <plugin-name> --activate --allow-root

# テーマのインストール
wp theme install <theme-name> --activate --allow-root

# データベースのエクスポート
wp db export --allow-root

# データベースのインポート
wp db import <file.sql> --allow-root

# 検索と置換
wp search-replace 'old-url' 'new-url' --allow-root

# キャッシュのクリア
wp cache flush --allow-root
```

## 開発ワークフロー

### 通常の開発

```bash
# 1. 環境起動
npm run dev

# 2. コードを編集
# wordpress/wp-content/themes/millecli/ 内のファイルを編集

# 3. ログ確認（必要に応じて）
docker-compose logs -f

# 4. 作業終了時は停止
docker-compose stop
```

### プラグイン/テーマの開発

```bash
# 1. 環境起動
npm run dev

# 2. コンテナに入る
docker-compose exec wordpress bash

# 3. WP-CLIでプラグイン/テーマを生成
wp scaffold plugin my-plugin --allow-root
wp scaffold _s my-theme --allow-root

# 4. ファイルを編集
# wordpress/wp-content/plugins/my-plugin/
# wordpress/wp-content/themes/my-theme/
```

### データベースのバックアップ

```bash
# エクスポート
docker-compose exec wordpress wp db export /var/www/html/backup.sql --allow-root

# ローカルにコピー
docker cp newsider_hp_app:/var/www/html/backup.sql ./backup.sql
```

### データベースのリストア

```bash
# ローカルからコンテナにコピー
docker cp ./backup.sql newsider_hp_app:/var/www/html/backup.sql

# インポート
docker-compose exec wordpress wp db import /var/www/html/backup.sql --allow-root
```

## トラブルシューティングコマンド

### コンテナの完全再構築

```bash
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

### 使用されていないDockerリソースの削除

```bash
# 未使用のコンテナ、ネットワーク、イメージを削除
docker system prune

# ボリュームも含めて削除
docker system prune -a --volumes
```

### ディスク使用量の確認

```bash
docker system df
```
