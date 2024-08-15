ARG PDNS_AUTH_VERSION=4.8
ARG PDNS_REC_VERSION=4.9

FROM alpine:3.19.1

ARG PDNS_AUTH_VERSION
ARG ENABLE_AUTH=yes
ARG PDNS_REC_VERSION
ARG ENABLE_REC=yes

LABEL maintainer="Nuno Souto <nsouto@lostlink.net>"

RUN apk add --no-cache \
    bash \
    coreutils \
    php82 \
    php82-phar \
    php82-intl \
    php82-json \
    php82-curl \
    php82-fileinfo \
    php82-mbstring \
    php82-tokenizer \
    mariadb-client \
    pdns~=${PDNS_AUTH_VERSION} \
    pdns-backend-mysql~=${PDNS_AUTH_VERSION} \
    pdns-backend-pipe~=${PDNS_AUTH_VERSION} \
    pdns-backend-remote~=${PDNS_AUTH_VERSION} \
    pdns-recursor~="${PDNS_REC_VERSION}" \
    pdns-doc \
    python3 \
    py3-pip \
	  supervisor \
    drill && \
    rm -rf /var/cache/apk/*

RUN python3 -m venv /root/venv; \
    . /root/venv/bin/activate; \
    pip3 install --no-cache-dir envtpl

ENV \
  TZ=UTC \
  ENABLE_AUTH=${ENABLE_AUTH} \
  AUTH_VERSION=${PDNS_AUTH_VERSION} \
  PDNS_AUTH_guardian=yes \
  PDNS_AUTH_setuid=pdns \
  PDNS_AUTH_setgid=pdns \
  PDNS_AUTH_config_dir=/etc/pdns \
  PDNS_AUTH_setuid=pdns \
  PDNS_AUTH_setgid=pdns \
  PDNS_AUTH_master=yes \
  PDNS_AUTH_slave=no \
  PDNS_AUTH_default_ttl=300 \
  PDNS_AUTH_expand_alias=yes \
  PDNS_AUTH_max_queue_length=50000 \
  PDNS_AUTH_zone_cache_refresh-interval=0 \
  PDNS_AUTH_api=yes \
  PDNS_AUTH_webserver=yes \
  PDNS_AUTH_webserver_address=0.0.0.0 \
  PDNS_AUTH_webserver_allow_from=0.0.0.0/0,::/0 \
  PIPE_DEFAULT_IPV4=127.0.0.1 \
  PIPE_DEFAULT_IPV6=::1 \
  PIPE_DEFAULT_MX=localhost \
  PDNS_AUTH_resolver=127.0.0.1:5353 \
  ENABLE_REC=${ENABLE_REC} \
  REC_VERSION=${PDNS_REC_VERSION} \
  PDNS_REC_daemon=no \
  PDNS_REC_setuid=pdns \
  PDNS_REC_setgid=pdns \
  PDNS_REC_local_port=5353 \
  PDNS_REC_local_address=0.0.0.0 \
  PDNS_REC_config_dir=/etc/pdns \
  PDNS_REC_include_dir=/etc/pdns/recursor.d

COPY --chmod=755 ./var/lib/powerdns/bin/default.sh /var/lib/powerdns/bin/default.sh
COPY --chmod=755 ./var/lib/powerdns/bin/default.pl /var/lib/powerdns/bin/default.pl
COPY --chmod=755 ./var/lib/powerdns/bin/powerdns /var/lib/powerdns/bin/powerdns
COPY ./var/lib/powerdns/bin/resources /var/lib/powerdns/bin/resources
COPY ./etc/pdns/pdns.conf.tpl /
COPY ./etc/pdns/recursor.d /etc/pdns/recursor.d
COPY ./etc/pdns/zones /etc/pdns/zones
COPY ./etc/pdns/recursor.conf.tpl /
COPY ./etc/supervisor/ /etc/supervisor/
COPY ./usr/local/bin/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh; \
    chmod 777 /var/run;

RUN rm  -rf /tmp/* /var/cache/apk/*

HEALTHCHECK --interval=10s --timeout=10s --retries=3 --start-period=2s CMD ["pdns_control", "ping"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

EXPOSE 53 53/udp 5353 5353/udp 8081
