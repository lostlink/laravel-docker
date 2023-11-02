ARG PHP_TAG=latest
ARG COMPOSER_TAG=latest
ARG NODE_VERSION=lts.x

###########################################
# Default Laravel Install
###########################################
FROM composer:${COMPOSER_TAG} AS composer

WORKDIR /var/www/html

RUN composer create-project \
    --no-interaction \
    --prefer-dist \
    --ignore-platform-reqs \
    --ansi \
    --no-dev \
    laravel/laravel .

RUN composer require laravel/octane && \
    php artisan octane:install --server=swoole

RUN sed -i 's/LOG_CHANNEL=stack/LOG_CHANNEL=stderr/g' .env

###########################################
# Octane
###########################################
FROM php:${PHP_TAG}

LABEL maintainer="Nuno Souto <nsouto@lostlink.net>"

ARG WWWUSER=1000
ARG WWWGROUP=1000
ARG TIMEZONE=UTC
ARG ENABLE_HORIZON=false
ARG ENABLE_SCHEDULER=false
ARG TARGETARCH
ARG NODE_VERSION
ARG INCLUDE_NPM=true

###########################################
# PHP ARG Defaults
###########################################
ARG INSTALL_OPCACHE=true
ARG INSTALL_PHPREDIS=true
ARG INSTALL_PCNTL=true
ARG INSTALL_BCMATH=true
ARG INSTALL_EXIF=true
ARG INSTALL_RDKAFKA=false
ARG INSTALL_SWOOLE=true
ARG SWOOLE_SERVER=openswoole
ARG INSTALL_INTL=true
ARG INSTALL_MEMCACHED=false
ARG INSTALL_MYSQL_CLIENT=true
ARG INSTALL_PDO_PGSQL=false
ARG INSTALL_PGSQL=false
ARG INSTALL_PG_CLIENT=false
ARG INSTALL_POSTGIS=false

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-color \
    ENABLE_HORIZON=${ENABLE_HORIZON} \
    ENABLE_SCHEDULER=${ENABLE_SCHEDULER} \
    COMPOSER_ALLOW_SUPERUSER=1

ENV ROOT=/var/www/html
WORKDIR $ROOT

SHELL ["/bin/bash", "-eou", "pipefail", "-c"]

RUN ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && \
    echo $TIMEZONE > /etc/timezone

RUN apt-get update; \
    apt-get upgrade -yqq; \
    pecl -q channel-update pecl.php.net; \
    apt-get install -yqq --no-install-recommends --show-progress \
            apt-utils \
            gnupg \
            gosu \
            git \
            curl \
            wget \
            libcurl4-openssl-dev \
            ca-certificates \
            supervisor \
            libmemcached-dev \
            libz-dev \
            libbrotli-dev \
            libpq-dev \
            libjpeg-dev \
            libpng-dev \
            libfreetype6-dev \
            libssl-dev \
            libwebp-dev \
            libmcrypt-dev \
            libonig-dev \
            libzip-dev zip unzip \
            libargon2-1 \
            libidn2-0 \
            libpcre2-8-0 \
            libpcre3 \
            libxml2 \
            libzstd1 \
            procps

RUN \
    ###########################################
    # pdo_mysql
    ###########################################
    docker-php-ext-install pdo_mysql \
    ###########################################
    # zip
    ###########################################
    && docker-php-ext-configure zip \
    && docker-php-ext-install zip \
    ###########################################
    # mbstring
    ###########################################
    && docker-php-ext-install mbstring \
    ###########################################
    # GD
    ###########################################
    && docker-php-ext-configure gd \
        --prefix=/usr \
        --with-jpeg \
        --with-webp \
        --with-freetype \
    && docker-php-ext-install gd \
    ###########################################
    # OPcache
    ###########################################
    && if [ ${INSTALL_OPCACHE} = true ]; then \
          docker-php-ext-install opcache; \
       fi \
    ###########################################
    # PHP Redis
    ###########################################
    && if [ ${INSTALL_PHPREDIS} = true ]; then \
          pecl -q install -o -f redis && \
          rm -rf /tmp/pear && \
          docker-php-ext-enable redis; \
       fi \
    ###########################################
    # PCNTL
    ###########################################
    && if [ ${INSTALL_PCNTL} = true ]; then \
          docker-php-ext-install pcntl; \
       fi \
    ###########################################
    # BCMath
    ###########################################
    && if [ ${INSTALL_BCMATH} = true ]; then \
          docker-php-ext-install bcmath; \
       fi \
    ###########################################
    # Exif
    ###########################################
    && if [ ${INSTALL_EXIF} = true ]; then \
          docker-php-ext-install exif; \
       fi \
    ###########################################
    # RDKAFKA
    ###########################################
    && if [ ${INSTALL_RDKAFKA} = true ]; then \
          apt-get install -yqq --no-install-recommends --show-progress librdkafka-dev && \
          pecl -q install -o -f rdkafka && \
          docker-php-ext-enable rdkafka; \
       fi \
    ###########################################
    # OpenSwoole/Swoole extension
    ###########################################
    && if [ ${INSTALL_SWOOLE} = true ]; then \
          apt-get install -yqq --no-install-recommends --show-progress libc-ares-dev && \
          pecl -q install -o -f -D 'enable-openssl="yes" enable-http2="yes" enable-swoole-curl="yes" enable-mysqlnd="yes" enable-cares="yes"' ${SWOOLE_SERVER} && \
          docker-php-ext-enable ${SWOOLE_SERVER}; \
       fi \
    ###########################################
    # RoadRunner Binary
    ###########################################
    # TODO: Install RoadRunner Binary insted of swoole
    # when requested
    ###########################################################################
    # Human Language and Character Encoding Support
    ###########################################################################
    && if [ ${INSTALL_INTL} = true ]; then \
          apt-get install -yqq --no-install-recommends --show-progress zlib1g-dev libicu-dev g++ && \
          docker-php-ext-configure intl && \
          docker-php-ext-install intl; \
       fi \
    ###########################################
    # Memcached
    ###########################################
    && if [ ${INSTALL_MEMCACHED} = true ]; then \
          pecl -q install -o -f memcached && \
          docker-php-ext-enable memcached; \
       fi \
    ###########################################
    # MySQL Client
    ###########################################
    && if [ ${INSTALL_MYSQL_CLIENT} = true ]; then \
          apt-get install -yqq --no-install-recommends --show-progress default-mysql-client; \
       fi \
    ###########################################
    # pdo_pgsql
    ###########################################
    && if [ ${INSTALL_PDO_PGSQL} = true ]; then \
          docker-php-ext-install pdo_pgsql; \
       fi \
    ###########################################
    # pgsql
    ###########################################
    && if [ ${INSTALL_PGSQL} = true ]; then \
          docker-php-ext-install pgsql; \
       fi \
    ###########################################
    # pgsql client and postgis
    ###########################################
    && if [ ${INSTALL_PG_CLIENT} = true ]; then \
            apt-get install -yqq gnupg && \
            . /etc/os-release && \
            echo "deb http://apt.postgresql.org/pub/repos/apt $VERSION_CODENAME-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
            curl -sL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
            apt-get update -yqq && \
            apt-get install -yqq --no-install-recommends --show-progress postgresql-client-12 postgis; \
            if [ ${INSTALL_POSTGIS} = true ]; then \
              apt-get install -yqq --no-install-recommends --show-progress postgis; \
            fi && \
            apt-get purge -yqq gnupg; \
       fi

###########################################
# Include composer
###########################################
COPY --from=composer /usr/bin/composer /usr/local/bin/composer
###########################################

###########################################
# Include NPM
###########################################
RUN if [ ${INCLUDE_NPM} = true ]; then \
        curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION} | bash - && \
        apt-get install -y nodejs; \
    fi
###########################################

###########################################
# Laravel scheduler
###########################################
RUN wget -q "https://github.com/aptible/supercronic/releases/download/v0.2.1/supercronic-linux-${TARGETARCH}" -O /usr/bin/supercronic && \
    chmod +x /usr/bin/supercronic && \
    mkdir -p /etc/supercronic && \
    echo "*/1 * * * * php ${ROOT}/artisan schedule:run --verbose --no-interaction" > /etc/supercronic/laravel;
###########################################

RUN groupadd --force -g $WWWGROUP octane && \
    useradd -ms /bin/bash --no-log-init --no-user-group -g $WWWGROUP -u $WWWUSER octane

COPY ./usr/local/bin/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY ./utilities.sh /root/.docker/utilities.sh
COPY ./etc/supervisor/ /etc/supervisor/
COPY ./usr/local/etc/php/conf.d/php.ini /usr/local/etc/php/conf.d/octane.ini
COPY ./usr/local/etc/php/conf.d/opcache.ini /usr/local/etc/php/conf.d/opcache.ini

COPY --from=composer ${ROOT} ${ROOT}
RUN mkdir -p storage/framework/{sessions,views,cache} storage/logs bootstrap/cache && \
    chown -R octane:octane storage bootstrap/cache && \
    chmod -R ug+rwx storage bootstrap/cache

RUN chmod +x /usr/local/bin/entrypoint.sh; \
    chmod 777 /var/run; \
    cat /root/.docker/utilities.sh >> ~/.bashrc

RUN apt-get clean && \
    docker-php-source delete && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    rm /var/log/lastlog /var/log/faillog

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
