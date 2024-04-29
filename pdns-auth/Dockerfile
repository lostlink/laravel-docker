ARG PDNS_VERSION=4.7

FROM alpine:3.18.6

ARG PDNS_VERSION

LABEL maintainer="Nuno Souto <nsouto@lostlink.net>"

RUN apk add --no-cache \
    mariadb-client \
    pdns~=${PDNS_VERSION} \
    pdns-backend-mysql~=${PDNS_VERSION} \
    pdns-backend-pipe~=${PDNS_VERSION} \
    pdns-backend-remote~=${PDNS_VERSION} \
    pdns-doc \
    jq \
    py3-pip \
    python3

RUN pip3 install --no-cache-dir envtpl

ENV \
  VERSION=${PDNS_VERSION} \
  PDNS_guardian=yes \
  PDNS_setuid=pdns \
  PDNS_setgid=pdns

COPY --chmod=755 ./var/lib/powerdns/bin/default.sh /var/lib/powerdns/bin/default.sh
COPY ./etc/pdns/pdns.conf.tpl /
COPY ./docker-entrypoint.sh /

ENTRYPOINT [ "/docker-entrypoint.sh" ]

EXPOSE 53 53/udp

CMD [ "/usr/sbin/pdns_server" ]
