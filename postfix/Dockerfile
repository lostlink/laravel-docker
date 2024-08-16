ARG POSTFIX_TAG=latest
ARG DEBIAN_TAG=bookworm-slim
ARG PHP_VERSION=8.3

FROM debian:${DEBIAN_TAG}

LABEL maintainer="Nuno Souto <nsouto@lostlink.net>"

ENV DEBIAN_FRONTEND=noninteractive \
    PDNS_REC_daemon=no \
    PDNS_REC_setuid=pdns \
    PDNS_REC_setgid=pdns \
    PDNS_REC_local_port=53 \
    PDNS_REC_local_address=0.0.0.0 \
    PDNS_REC_config_dir=/etc/pdns \
    PDNS_REC_include_dir=/etc/pdns/recursor.d

RUN apt-get update; \
    apt-get install -yqq --no-install-recommends --no-install-suggests  \
            wget \
            gnupg \
            lsb-release \
            ca-certificates \
            apt-transport-https \
            software-properties-common; \
    wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg; \
    sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'; \
    apt-get update; \
    apt-get upgrade -yqq; \
    apt-get install -yqq --no-install-recommends --no-install-suggests \
            apt-utils \
            dnsutils \
            php${PHP_VERSION} \
            php${PHP_VERSION}-cli \
            php${PHP_VERSION}-mailparse \
#            php${PHP_VERSION}-phar \
            php${PHP_VERSION}-intl \
#            php${PHP_VERSION}-json \
            php${PHP_VERSION}-curl \
#            php${PHP_VERSION}-fileinfo \
            php${PHP_VERSION}-mbstring \
            php${PHP_VERSION}-tokenizer \
            diceware \
            dovecot-imapd \
            dovecot-lmtpd \
            gettext-base \
            mailutils \
            opendkim \
            opendkim-tools \
            postfix \
            postfix-pcre \
            procmail \
            sasl2-bin \
            python3 \
            python3-pip \
            python3-venv \
            supervisor \
            pdns-recursor

RUN apt-get install -yqq --no-install-recommends --no-install-suggests \
            opendmarc

RUN python3 -m venv /root/venv; \
    . /root/venv/bin/activate; \
    pip3 install --no-cache-dir envtpl

RUN apt-get --quiet --quiet clean all \
    && rm --recursive --force /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY ./etc/postfix/main.cf /etc/postfix/main.cf
COPY ./etc/postfix/master.cf /etc/postfix/master.cf
COPY ./etc/postfix/virtual /etc/postfix/virtual
COPY ./etc/aliases /etc/aliases
COPY ./etc/pdns/recursor.conf.tpl /etc/pdns/recursor.conf.tpl
COPY ./etc/pdns/recursor.d /etc/pdns/recursor.d
COPY ./etc/pdns/zones /etc/pdns/zones
COPY ./etc/supervisor/ /etc/supervisor/

COPY --chmod=0755 ./usr/local/bin/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chmod=0755 ./usr/local/bin/mailparse.sh /usr/local/bin/mailparse.sh

HEALTHCHECK --interval=10s --timeout=10s --retries=3 --start-period=2s CMD ["postfix", "status"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

EXPOSE 25/TCP 587/TCP 993/TCP
