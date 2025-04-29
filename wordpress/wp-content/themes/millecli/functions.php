<?php
// テーマのセットアップ
function my_minimal_theme_setup() {
    // テーマサポートの追加
    add_theme_support('title-tag');
    add_theme_support('post-thumbnails');
    add_theme_support('html5', array(
        'search-form',
        'comment-form',
        'comment-list',
        'gallery',
        'caption',
    ));
    
    // ナビゲーションメニューの登録
    register_nav_menus(array(
        'primary' => __('Primary Menu', 'my-minimal-theme'),
    ));
}
add_action('after_setup_theme', 'my_minimal_theme_setup');

// スタイルシートとスクリプトの読み込み
function my_minimal_theme_scripts() {
    wp_enqueue_style('my-minimal-theme-style', get_stylesheet_uri());
}
add_action('wp_enqueue_scripts', 'my_minimal_theme_scripts');

// ウィジェットエリアの登録
function my_minimal_theme_widgets_init() {
    register_sidebar(array(
        'name'          => __('Sidebar', 'my-minimal-theme'),
        'id'            => 'sidebar-1',
        'description'   => __('Add widgets here to appear in your sidebar.', 'my-minimal-theme'),
        'before_widget' => '<section id="%1$s" class="widget %2$s">',
        'after_widget'  => '</section>',
        'before_title'  => '<h2 class="widget-title">',
        'after_title'   => '</h2>',
    ));
}
add_action('widgets_init', 'my_minimal_theme_widgets_init');

// リライト処理
function custom_rewrite_rules() {
    // '/home' にアクセスしたときの処理
    add_rewrite_rule('^home/?$', 'index.php?pagename=home', 'top');
    
    // '/product' にアクセスしたときの処理
    add_rewrite_rule('^product/?$', 'index.php?pagename=product', 'top');

    // '/services' にアクセスしたときの処理
    add_rewrite_rule('^services/?$', 'index.php?pagename=services', 'top');

    // '/info' にアクセスしたときの処理
    add_rewrite_rule('^info/?$', 'index.php?pagename=info', 'top');

    // '/doctors' にアクセスしたときの処理
    add_rewrite_rule('^doctors/?$', 'index.php?pagename=doctors', 'top');
}
add_action('init', 'custom_rewrite_rules');

// テーマ有効化時にリライトルールをフラッシュ
function my_rewrite_flush() {
    custom_rewrite_rules();
    flush_rewrite_rules();
}
add_action('after_switch_theme', 'my_rewrite_flush');

// カスタムテンプレートのロード
function load_custom_template($template) {
    global $wp_query;
    
    if (isset($wp_query->query['pagename'])) {
        if ($wp_query->query['pagename'] === 'home') {
            $new_template = locate_template(array('home.php'));
            if (!empty($new_template)) {
                return $new_template;
            }
        } elseif ($wp_query->query['pagename'] === 'product') {
            $new_template = locate_template(array('product.php'));
            if (!empty($new_template)) {
                return $new_template;
            }
        } elseif ($wp_query->query['pagename'] === 'services') {
            $new_template = locate_template(array('services.php'));
            if (!empty($new_template)) {
                return $new_template;
            }
        } elseif ($wp_query->query['pagename'] === 'info') {
            $new_template = locate_template(array('info.php'));
            if (!empty($new_template)) {
                return $new_template;
            }
        } elseif ($wp_query->query['pagename'] === 'doctors') {
            $new_template = locate_template(array('doctors.php'));
            if (!empty($new_template)) {
                return $new_template;
            }
        }
    }
    
    return $template;
}
add_filter('template_include', 'load_custom_template');
