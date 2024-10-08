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

RUN touch database/database.sqlite && \
    php artisan migrate --force

###########################################
# Octane
###########################################
FROM php:${PHP_TAG}

LABEL maintainer="Nuno Souto <nsouto@lostlink.net>"

ARG WWWUSER=1000
ARG WWWGROUP=1000
ARG TIMEZONE=UTC
ARG OCTANE_SERVER="swoole"
ARG ENABLE_HORIZON=false
ARG ENABLE_SCHEDULER=false
ARG ENABLE_VECTOR=false
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
ARG INSTALL_INTL=true
ARG INSTALL_MEMCACHED=false
ARG INSTALL_MYSQL_CLIENT=true
ARG INSTALL_PDO_PGSQL=true
ARG INSTALL_PGSQL=true
ARG INSTALL_PG_CLIENT=true
ARG INSTALL_POSTGIS=true
ARG INSTALL_EXCIMER=true
ARG INSTALL_SWOOLE=true
ARG SWOOLE_SERVER=openswoole
ARG INSTALL_ROADRUNNER=true
ARG INSTALL_FRANKENPHP=true

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-color \
    OCTANE_SERVER=${OCTANE_SERVER} \
    ENABLE_HORIZON=${ENABLE_HORIZON} \
    ENABLE_SCHEDULER=${ENABLE_SCHEDULER} \
    ENABLE_VECTOR=${ENABLE_VECTOR} \
    COMPOSER_ALLOW_SUPERUSER=1 \
    ROOT=/var/www/html

WORKDIR $ROOT

SHELL ["/bin/bash", "-eou", "pipefail", "-c"]

RUN ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && \
    echo $TIMEZONE > /etc/timezone

RUN apt-get update; \
    apt-get upgrade -yqq; \
    pecl -q channel-update pecl.php.net; \
    apt-get install -yqq --no-install-recommends --show-progress \
            apt-utils \
            dnsutils \
            gnupg \
            gosu \
            git \
            curl \
            wget \
            jq \
            gettext \
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

    ###########################################
    # pdo_mysql
    ###########################################
RUN docker-php-ext-install pdo_mysql

    ###########################################
    # zip
    ###########################################
RUN docker-php-ext-configure zip \
    && docker-php-ext-install zip

    ###########################################
    # mbstring
    ###########################################
RUN docker-php-ext-install mbstring

    ###########################################
    # GD
    ###########################################
RUN docker-php-ext-configure gd \
        --prefix=/usr \
        --with-jpeg \
        --with-webp \
        --with-freetype \
    && docker-php-ext-install gd

    ###########################################
    # OPcache
    ###########################################
RUN if [ ${INSTALL_OPCACHE} = true ]; then \
        docker-php-ext-install opcache; \
    fi

    ###########################################
    # PHP Redis
    ###########################################
RUN if [ ${INSTALL_PHPREDIS} = true ]; then \
        pecl -q install -o -f redis && \
        rm -rf /tmp/pear && \
        docker-php-ext-enable redis; \
    fi

    ###########################################
    # PCNTL
    ###########################################
RUN if [ ${INSTALL_PCNTL} = true ]; then \
        docker-php-ext-install pcntl; \
    fi

    ###########################################
    # BCMath
    ###########################################
RUN if [ ${INSTALL_BCMATH} = true ]; then \
        docker-php-ext-install bcmath; \
    fi

    ###########################################
    # Exif
    ###########################################
RUN if [ ${INSTALL_EXIF} = true ]; then \
        docker-php-ext-install exif; \
    fi

    ###########################################
    # RDKAFKA
    ###########################################
RUN if [ ${INSTALL_RDKAFKA} = true ]; then \
        apt-get install -yqq --no-install-recommends --show-progress librdkafka-dev && \
        pecl -q install -o -f rdkafka && \
        docker-php-ext-enable rdkafka; \
    fi

    ###########################################################################
    # Human Language and Character Encoding Support
    ###########################################################################
RUN if [ ${INSTALL_INTL} = true ]; then \
        apt-get install -yqq --no-install-recommends --show-progress zlib1g-dev libicu-dev g++ && \
        docker-php-ext-configure intl && \
        docker-php-ext-install intl; \
    fi

    ###########################################
    # Memcached
    ###########################################
RUN if [ ${INSTALL_MEMCACHED} = true ]; then \
        pecl -q install -o -f memcached && \
        docker-php-ext-enable memcached; \
    fi

    ###########################################
    # MySQL Client
    ###########################################
RUN if [ ${INSTALL_MYSQL_CLIENT} = true ]; then \
        apt-get install -yqq --no-install-recommends --show-progress default-mysql-client; \
    fi

    ###########################################
    # pdo_pgsql
    ###########################################
RUN if [ ${INSTALL_PDO_PGSQL} = true ]; then \
        docker-php-ext-install pdo_pgsql; \
    fi

    ###########################################
    # pgsql
    ###########################################
RUN if [ ${INSTALL_PGSQL} = true ]; then \
        docker-php-ext-install pgsql; \
    fi

    ###########################################
    # pgsql client and postgis
    ###########################################
RUN if [ ${INSTALL_PG_CLIENT} = true ]; then \
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
    # Excimer
    ###########################################
RUN if [ ${INSTALL_EXCIMER} = true ]; then \
        pecl -q install -o -f excimer && \
        docker-php-ext-enable excimer; \
    fi

    ###########################################
    # OpenSwoole/Swoole extension
    ###########################################
RUN if [ ${INSTALL_SWOOLE} = true ]; then \
        apt-get install -yqq --no-install-recommends --show-progress libc-ares-dev && \
        pecl -q install -o -f -D 'enable-openssl="yes" enable-http2="yes" enable-swoole-curl="yes" enable-mysqlnd="yes" enable-cares="yes"' ${SWOOLE_SERVER} && \
        docker-php-ext-enable ${SWOOLE_SERVER}; \
    fi

    ###########################################
    # Install RoadRunner Binary
    ###########################################
RUN if [ "${INSTALL_ROADRUNNER}" = "true" ]; then \
        LATEST_VERSION=$(curl -s https://api.github.com/repos/roadrunner-server/roadrunner/releases/latest | jq -r .tag_name) && \
        if [ -z "$LATEST_VERSION" ]; then \
            echo "Failed to fetch the latest RoadRunner version"; \
            exit 1; \
        fi && \
        CLEAN_VERSION=${LATEST_VERSION#v} && \
        if [ "${TARGETARCH}" = "x86_64" ]; then \
            ROADRUNNER_ARCH="amd64"; \
        else \
            ROADRUNNER_ARCH="${TARGETARCH}"; \
        fi && \
        curl -LO https://github.com/roadrunner-server/roadrunner/releases/download/${LATEST_VERSION}/roadrunner-${CLEAN_VERSION}-linux-${ROADRUNNER_ARCH}.deb && \
        dpkg -i roadrunner-${CLEAN_VERSION}-linux-${ROADRUNNER_ARCH}.deb && \
        rm roadrunner-${CLEAN_VERSION}-linux-${ROADRUNNER_ARCH}.deb; \
    fi

    ###########################################
    # Install FrankenPHP
    ###########################################
RUN if [ "${INSTALL_FRANKENPHP}" = "true" ]; then \
        LATEST_VERSION=$(curl -s https://api.github.com/repos/dunglas/frankenphp/releases/latest | jq -r .tag_name) && \
        if [ -z "$LATEST_VERSION" ]; then \
            echo "Failed to fetch the latest FrankenPHP version"; \
            exit 1; \
        fi && \
        if [ "${TARGETARCH}" = "arm64" ]; then \
            FRANKENPHP_ARCH="aarch64"; \
        else \
            FRANKENPHP_ARCH="${TARGETARCH}"; \
        fi && \
        curl -LO https://github.com/dunglas/frankenphp/releases/download/${LATEST_VERSION}/frankenphp-linux-${FRANKENPHP_ARCH} && \
        chmod +x frankenphp-linux-${FRANKENPHP_ARCH} && \
        mv frankenphp-linux-${FRANKENPHP_ARCH} /usr/local/bin/frankenphp; \
    fi

RUN mkdir -p /root/.config/caddy /root/.local && \
    chmod 777 /root/.config/caddy /root/.local

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

###########################################
# Install Vector using .deb package
###########################################
RUN curl -LO https://packages.timber.io/vector/0.41.1/vector_0.41.1-1_${TARGETARCH}.deb \
    && dpkg -i vector_0.41.1-1_${TARGETARCH}.deb \
    && rm vector_0.41.1-1_${TARGETARCH}.deb

# Create the Vector configuration directory
RUN mkdir -p /etc/vector

# Copy the Vector configuration file
COPY ./etc/vector/vector.toml /etc/vector/vector.toml
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

RUN chown -R octane:octane /var/www/html

EXPOSE 9000 9001 9002

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
