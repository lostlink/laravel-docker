ARG PDNS_VERSION=4.8

FROM alpine:3.18.4

ARG PDNS_VERSION

LABEL maintainer="Nuno Souto <nsouto@lostlink.net>"

RUN apk add --no-cache \
    pdns-recursor~="${PDNS_VERSION}" \
    py3-pip \
    python3 \
    drill && \
    rm -rf /var/cache/apk/*

RUN pip3 install --no-cache-dir envtpl

ENV \
  VERSION=${PDNS_VERSION} \
  PDNS_daemon=no \
  PDNS_setuid=recursor \
  PDNS_setgid=recursor \
  PDNS_local_port=53 \
  PDNS_local_address=0.0.0.0

COPY ./etc/pdns/recursor.conf.tpl /
COPY ./docker-entrypoint.sh /

ENTRYPOINT [ "/docker-entrypoint.sh" ]

EXPOSE 53 53/udp

CMD [ "/usr/sbin/pdns_recursor" ]
