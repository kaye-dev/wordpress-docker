<?php
/**
 * Template Name: Home Template
 */
?>

<!DOCTYPE html>
<html <?php language_attributes(); ?>>
<head>
    <meta charset="<?php bloginfo('charset'); ?>">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <?php wp_head(); ?>
</head>
<body <?php body_class('bg-gray-50 text-gray-800'); ?>>
    <?php wp_body_open(); ?>
    
    <header class="bg-white shadow-md">
        <div class="container mx-auto px-4 py-6">
            <h1 class="text-3xl font-bold text-blue-600">ホームページ</h1>
            <nav class="mt-4">
                <ul class="flex space-x-6">
                    <li><a href="/" class="text-blue-500 hover:text-blue-700 transition">ホーム</a></li>
                    <li><a href="/doctors" class="text-blue-500 hover:text-blue-700 transition">医師紹介</a></li>
                    <li><a href="/services" class="text-blue-500 hover:text-blue-700 transition">サービス</a></li>
                    <li><a href="/product" class="text-blue-500 hover:text-blue-700 transition">製品情報</a></li>
                    <li><a href="/info" class="text-blue-500 hover:text-blue-700 transition">お知らせ</a></li>
                </ul>
            </nav>
        </div>
    </header>

    <main class="container mx-auto px-4 py-8">
        <section class="bg-white rounded-lg shadow-lg p-6 mb-8">
            <h2 class="text-2xl font-semibold text-gray-800 mb-4">これはカスタムテンプレートです</h2>
            <p class="text-gray-600 mb-6">管理画面からの固定ページ作成なしで表示されています。</p>
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                <div class="bg-blue-50 p-4 rounded-lg">
                    <h3 class="text-xl font-medium text-blue-700 mb-2">特徴 1</h3>
                    <p class="text-gray-600">Tailwind CSSを使用したモダンなデザイン</p>
                </div>
                <div class="bg-blue-50 p-4 rounded-lg">
                    <h3 class="text-xl font-medium text-blue-700 mb-2">特徴 2</h3>
                    <p class="text-gray-600">レスポンシブレイアウト対応</p>
                </div>
                <div class="bg-blue-50 p-4 rounded-lg">
                    <h3 class="text-xl font-medium text-blue-700 mb-2">特徴 3</h3>
                    <p class="text-gray-600">カスタマイズが容易なコンポーネント</p>
                </div>
            </div>
        </section>
        
        <section class="bg-white rounded-lg shadow-lg p-6">
            <h2 class="text-2xl font-semibold text-gray-800 mb-4">お問い合わせ</h2>
            <p class="text-gray-600 mb-4">ご質問やご相談がございましたら、お気軽にお問い合わせください。</p>
            <button class="bg-blue-600 text-white px-6 py-2 rounded-md hover:bg-blue-700 transition">お問い合わせ</button>
        </section>
    </main>

    <footer class="bg-gray-800 text-white mt-12 py-8">
        <div class="container mx-auto px-4">
            <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
                <div>
                    <h3 class="text-xl font-semibold mb-4">サイトマップ</h3>
                    <ul class="space-y-2">
                        <li><a href="/" class="text-gray-300 hover:text-white transition">ホーム</a></li>
                        <li><a href="/doctors" class="text-gray-300 hover:text-white transition">医師紹介</a></li>
                        <li><a href="/services" class="text-gray-300 hover:text-white transition">サービス</a></li>
                        <li><a href="/product" class="text-gray-300 hover:text-white transition">製品情報</a></li>
                        <li><a href="/info" class="text-gray-300 hover:text-white transition">お知らせ</a></li>
                    </ul>
                </div>
                <div>
                    <h3 class="text-xl font-semibold mb-4">お問い合わせ</h3>
                    <address class="not-italic text-gray-300">
                        <p>〒123-4567</p>
                        <p>東京都千代田区</p>
                        <p>TEL: 03-1234-5678</p>
                        <p>FAX: 03-1234-5679</p>
                    </address>
                </div>
                <div>
                    <h3 class="text-xl font-semibold mb-4">営業時間</h3>
                    <p class="text-gray-300">平日: 9:00 - 18:00</p>
                    <p class="text-gray-300">土曜: 10:00 - 15:00</p>
                    <p class="text-gray-300">日祝: 休診</p>
                </div>
            </div>
            <div class="border-t border-gray-700 mt-8 pt-6 text-center">
                <p>&copy; <?php echo date('Y'); ?> <?php bloginfo('name'); ?>. All rights reserved.</p>
            </div>
        </div>
    </footer>

    <?php wp_footer(); ?>
</body>
</html>
