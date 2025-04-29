<?php
/**
 * Template Name: Root Template
 */
?>

<!DOCTYPE html>
<html <?php language_attributes(); ?>>
<head>
    <meta charset="<?php bloginfo('charset'); ?>">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <?php wp_head(); ?>
</head>
<body <?php body_class(); ?>>
    <?php wp_body_open(); ?>
    
    <header>
        <h1>トップページ</h1>
    </header>

    <main>
        <h2>これはカスタムテンプレートです</h2>
        <p>管理画面からの固定ページ作成なしで表示されています。</p>
        <!-- ここに任意のコンテンツを追加 -->
    </main>

    <footer>
        <p>&copy; <?php echo date('Y'); ?> <?php bloginfo('name'); ?></p>
    </footer>

    <?php wp_footer(); ?>
</body>
</html>
