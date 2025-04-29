<?php
/**
 * Template Name: Doctors Template
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
            <h1 class="text-3xl font-bold text-blue-600">医師紹介</h1>
            <nav class="mt-4">
                <ul class="flex space-x-6">
                    <li><a href="/" class="text-blue-500 hover:text-blue-700 transition">ホーム</a></li>
                    <li><a href="/doctors" class="text-blue-500 hover:text-blue-700 transition font-medium">医師紹介</a></li>
                    <li><a href="/services" class="text-blue-500 hover:text-blue-700 transition">サービス</a></li>
                    <li><a href="/product" class="text-blue-500 hover:text-blue-700 transition">製品情報</a></li>
                    <li><a href="/info" class="text-blue-500 hover:text-blue-700 transition">お知らせ</a></li>
                </ul>
            </nav>
        </div>
    </header>

    <main class="container mx-auto px-4 py-8">
        <section class="bg-white rounded-lg shadow-lg p-6 mb-8">
            <h2 class="text-2xl font-semibold text-gray-800 mb-6">当院の医師紹介</h2>
            <p class="text-gray-600 mb-8">当院には経験豊かな専門医が在籍しています。皆様のお悩みに親身にお答えします。</p>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                <!-- 医師1 -->
                <div class="bg-white border border-gray-200 rounded-lg shadow-md overflow-hidden">
                    <div class="p-6">
                        <div class="flex items-center mb-4">
                            <div class="w-24 h-24 bg-gray-300 rounded-full mr-4"></div>
                            <div>
                                <h3 class="text-xl font-semibold text-gray-800">山田 太郎</h3>
                                <p class="text-blue-600">院長 / 内科医</p>
                            </div>
                        </div>
                        <div class="mb-4">
                            <h4 class="font-medium text-gray-700 mb-2">専門分野</h4>
                            <div class="flex flex-wrap gap-2">
                                <span class="bg-blue-100 text-blue-800 text-xs font-medium px-2.5 py-0.5 rounded-full">一般内科</span>
                                <span class="bg-blue-100 text-blue-800 text-xs font-medium px-2.5 py-0.5 rounded-full">生活習慣病</span>
                                <span class="bg-blue-100 text-blue-800 text-xs font-medium px-2.5 py-0.5 rounded-full">老年医学</span>
                            </div>
                        </div>
                        <p class="text-gray-600 mb-4">東京大学医学部卒業。30年以上の臨床経験を持ち、特に生活習慣病の予防と治療に力を入れています。</p>
                        <div class="border-t border-gray-200 pt-4">
                            <h4 class="font-medium text-gray-700 mb-2">診療日</h4>
                            <p class="text-gray-600">月曜日、水曜日、金曜日</p>
                        </div>
                    </div>
                </div>
                
                <!-- 医師2 -->
                <div class="bg-white border border-gray-200 rounded-lg shadow-md overflow-hidden">
                    <div class="p-6">
                        <div class="flex items-center mb-4">
                            <div class="w-24 h-24 bg-gray-300 rounded-full mr-4"></div>
                            <div>
                                <h3 class="text-xl font-semibold text-gray-800">佐藤 花子</h3>
                                <p class="text-blue-600">副院長 / 小児科医</p>
                            </div>
                        </div>
                        <div class="mb-4">
                            <h4 class="font-medium text-gray-700 mb-2">専門分野</h4>
                            <div class="flex flex-wrap gap-2">
                                <span class="bg-blue-100 text-blue-800 text-xs font-medium px-2.5 py-0.5 rounded-full">小児科</span>
                                <span class="bg-blue-100 text-blue-800 text-xs font-medium px-2.5 py-0.5 rounded-full">アレルギー科</span>
                                <span class="bg-blue-100 text-blue-800 text-xs font-medium px-2.5 py-0.5 rounded-full">予防接種</span>
                            </div>
                        </div>
                        <p class="text-gray-600 mb-4">京都大学医学部卒業。子どものアレルギー疾患に精通しており、小さな患者さんに寄り添った診療を心がけています。</p>
                        <div class="border-t border-gray-200 pt-4">
                            <h4 class="font-medium text-gray-700 mb-2">診療日</h4>
                            <p class="text-gray-600">火曜日、木曜日、土曜日</p>
                        </div>
                    </div>
                </div>
                
                <!-- 医師3 -->
                <div class="bg-white border border-gray-200 rounded-lg shadow-md overflow-hidden">
                    <div class="p-6">
                        <div class="flex items-center mb-4">
                            <div class="w-24 h-24 bg-gray-300 rounded-full mr-4"></div>
                            <div>
                                <h3 class="text-xl font-semibold text-gray-800">鈴木 一郎</h3>
                                <p class="text-blue-600">整形外科医</p>
                            </div>
                        </div>
                        <div class="mb-4">
                            <h4 class="font-medium text-gray-700 mb-2">専門分野</h4>
                            <div class="flex flex-wrap gap-2">
                                <span class="bg-blue-100 text-blue-800 text-xs font-medium px-2.5 py-0.5 rounded-full">整形外科</span>
                                <span class="bg-blue-100 text-blue-800 text-xs font-medium px-2.5 py-0.5 rounded-full">スポーツ医学</span>
                                <span class="bg-blue-100 text-blue-800 text-xs font-medium px-2.5 py-0.5 rounded-full">リハビリテーション</span>
                            </div>
                        </div>
                        <p class="text-gray-600 mb-4">大阪大学医学部卒業。プロスポーツチームのドクターも務める。怪我の予防からリハビリまで一貫した診療を提供。</p>
                        <div class="border-t border-gray-200 pt-4">
                            <h4 class="font-medium text-gray-700 mb-2">診療日</h4>
                            <p class="text-gray-600">月曜日、木曜日、金曜日</p>
                        </div>
                    </div>
                </div>
                
                <!-- 医師4 -->
                <div class="bg-white border border-gray-200 rounded-lg shadow-md overflow-hidden">
                    <div class="p-6">
                        <div class="flex items-center mb-4">
                            <div class="w-24 h-24 bg-gray-300 rounded-full mr-4"></div>
                            <div>
                                <h3 class="text-xl font-semibold text-gray-800">田中 美咲</h3>
                                <p class="text-blue-600">皮膚科医</p>
                            </div>
                        </div>
                        <div class="mb-4">
                            <h4 class="font-medium text-gray-700 mb-2">専門分野</h4>
                            <div class="flex flex-wrap gap-2">
                                <span class="bg-blue-100 text-blue-800 text-xs font-medium px-2.5 py-0.5 rounded-full">皮膚科</span>
                                <span class="bg-blue-100 text-blue-800 text-xs font-medium px-2.5 py-0.5 rounded-full">アトピー性皮膚炎</span>
                                <span class="bg-blue-100 text-blue-800 text-xs font-medium px-2.5 py-0.5 rounded-full">美容皮膚科</span>
                            </div>
                        </div>
                        <p class="text-gray-600 mb-4">順天堂大学医学部卒業。難治性皮膚疾患の専門家。最新の治療法を積極的に導入し、患者さんの肌の悩みを解決します。</p>
                        <div class="border-t border-gray-200 pt-4">
                            <h4 class="font-medium text-gray-700 mb-2">診療日</h4>
                            <p class="text-gray-600">火曜日、水曜日、金曜日</p>
                        </div>
                    </div>
                </div>
            </div>
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
