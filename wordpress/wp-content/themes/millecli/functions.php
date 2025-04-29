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
    // Tailwind CSS（優先度を高くするため先に読み込む）
    $tailwind_css_path = get_template_directory() . '/dist/css/style.css';
    if (file_exists($tailwind_css_path)) {
        // ファイルのmtimeを使ってバージョンを付与（キャッシュバスト）
        $tailwind_version = filemtime($tailwind_css_path);
        wp_enqueue_style('tailwind-css', get_template_directory_uri() . '/dist/css/style.css', array(), $tailwind_version);
    } else {
        // Tailwind CSSファイルが存在しない場合、ログに記録
        error_log('Tailwind CSS file not found: ' . $tailwind_css_path);
    }
    
    // メインのスタイルシート（後で読み込んで優先度を下げる）
    wp_enqueue_style('my-minimal-theme-style', get_stylesheet_uri(), array('tailwind-css'));
    
    // ブラウザキャッシュを無効化するための対策
    wp_add_inline_script('jquery-core', '
        // キャッシュ対策のためのリロード機能（開発時のみ）
        if (window.location.hostname === "localhost" || window.location.hostname === "127.0.0.1") {
            console.log("開発環境を検知しました。スタイル更新監視を有効化します。");
            let lastModified = "";
            setInterval(function() {
                fetch("/wp-content/themes/millecli/dist/css/style.css", { method: "HEAD" })
                    .then(response => {
                        const modified = response.headers.get("last-modified");
                        if (lastModified && lastModified !== modified) {
                            console.log("スタイルシートの変更を検知しました。リロードします。");
                            location.reload(true);
                        }
                        lastModified = modified;
                    });
            }, 3000); // 3秒ごとにチェック
        }
    ');
}
add_action('wp_enqueue_scripts', 'my_minimal_theme_scripts');

// キャッシュ対策のためのヘッダー追加
function add_cache_busting_headers() {
    if (is_user_logged_in()) {
        header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
        header('Pragma: no-cache');
        header('Expires: 0');
    }
}
add_action('send_headers', 'add_cache_busting_headers');

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
