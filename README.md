# WordPress with Tailwind CSS

WordPressテーマでTailwind CSSを使用するためのDocker環境

## 使用方法

### Dockerでの起動 (推奨)

```bash
# コンテナ起動（WordPressとTailwindビルドが同時に実行されます）
docker-compose up -d
```

これだけでWordPressとTailwind CSSのビルド環境が起動します。
http://localhost:8000 でWordPressに、http://localhost:8000/wp-admin でダッシュボードにアクセスできます。

### 手動でのTailwind CSS開発

```bash
cd wordpress/wp-content/themes/millecli
npm install
npm run dev  # 開発モード（ウォッチ）
npm run build  # 本番ビルド
```

## ディレクトリ構造

```md
millecli/
├── dist/css/style.css      # ビルドされたTailwind CSS
├── src/css/tailwind.css    # Tailwindソース
├── tailwind.config.js      # Tailwind設定
└── postcss.config.js       # PostCSS設定
```

Tailwindのクラスはテーマ内のPHPファイルで直接使用できます。
