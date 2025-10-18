# ===========================================
# Stage 1: Tailwind CSS Builder
# ===========================================
FROM node:18-alpine AS tailwind-builder

WORKDIR /build

# Tailwind CSSのビルド設定をコピー
COPY wordpress/wp-content/themes/millecli/package*.json ./
COPY wordpress/wp-content/themes/millecli/tailwind.config.js ./
COPY wordpress/wp-content/themes/millecli/postcss.config.js ./
COPY wordpress/wp-content/themes/millecli/src ./src

# 依存関係のインストールとビルド
RUN npm ci --only=production && \
    npm run build

# ===========================================
# Stage 2: WordPress Production Image
# ===========================================
FROM wordpress:6.4-php8.2-apache

# 環境変数の設定
ENV WORDPRESS_DB_HOST=localhost \
    WORDPRESS_DB_USER=wordpress \
    WORDPRESS_DB_PASSWORD=wordpress \
    WORDPRESS_DB_NAME=wordpress

# 必要なPHP拡張機能のインストール
RUN apt-get update && apt-get install -y \
    libzip-dev \
    zip \
    unzip \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    libfreetype6-dev \
    && docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
        --with-webp \
    && docker-php-ext-install -j$(nproc) \
        gd \
        zip \
        exif \
        opcache \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# PHP設定の最適化
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN { \
    echo 'upload_max_filesize=64M'; \
    echo 'post_max_size=64M'; \
    echo 'memory_limit=256M'; \
    echo 'max_execution_time=300'; \
    echo 'max_input_time=300'; \
    } > /usr/local/etc/php/conf.d/uploads.ini

# Apache設定の最適化
RUN a2enmod rewrite expires headers deflate

# WordPressファイルのコピー
COPY --chown=www-data:www-data wordpress /var/www/html

# Tailwind CSSのビルド結果をコピー
COPY --from=tailwind-builder --chown=www-data:www-data \
    /build/dist/css/style.css \
    /var/www/html/wp-content/themes/millecli/dist/css/style.css

# WordPress設定ファイルの権限設定
RUN chown -R www-data:www-data /var/www/html && \
    find /var/www/html -type d -exec chmod 755 {} \; && \
    find /var/www/html -type f -exec chmod 644 {} \;

# ヘルスチェック用スクリプトの追加
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Apache起動
CMD ["apache2-foreground"]

EXPOSE 80
