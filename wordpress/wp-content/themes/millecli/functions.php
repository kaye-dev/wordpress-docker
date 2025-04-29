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

// カスタムページの設定
function millecli_custom_pages() {
    // カスタムページの定義（ページ名 => テンプレートパス）
    return array(
        'root'     => 'root.php',
        'home'     => 'pages/home.php',
        'product'  => 'pages/product.php',
        'services' => 'pages/services.php',
        'info'     => 'pages/info.php',
        'doctors'  => 'pages/doctors.php',
    );
}

// リライト処理
function custom_rewrite_rules() {
    // カスタムページの設定を取得
    $custom_pages = millecli_custom_pages();
    
    // トップページのリライトルール
    add_rewrite_rule('^$', 'index.php?pagename=root', 'top');
    
    // その他のカスタムページのリライトルール
    foreach ($custom_pages as $page => $template) {
        if ($page !== 'root') {
            add_rewrite_rule('^' . $page . '/?$', 'index.php?pagename=' . $page, 'top');
        }
    }
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
    
    // トップページの場合
    if (is_front_page() && is_home()) {
        $new_template = locate_template(array('root.php'));
        if (!empty($new_template)) {
            return $new_template;
        }
    }
    
    // カスタムページの処理
    if (isset($wp_query->query['pagename'])) {
        $pagename = $wp_query->query['pagename'];
        $custom_pages = millecli_custom_pages();
        
        if (isset($custom_pages[$pagename])) {
            $new_template = locate_template(array($custom_pages[$pagename]));
            if (!empty($new_template)) {
                return $new_template;
            }
        }
    }
    
    return $template;
}
add_filter('template_include', 'load_custom_template');
