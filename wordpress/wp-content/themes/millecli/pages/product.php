<?php
/**
 * Template Name: Product Template
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
        <h1>Product</h1>
    </header>

    <main>
        <h2>これはカスタムテンプレートです</h2>
        <p>xxx</p>
        <!-- ここに任意のコンテンツを追加 -->
    </main>

    <footer>
        <p>&copy; <?php echo date('Y'); ?> <?php bloginfo('name'); ?></p>
    </footer>

    <?php wp_footer(); ?>
</body>
</html>
