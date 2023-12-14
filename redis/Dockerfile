ARG REDIS_TAG=latest

FROM redis:${REDIS_TAG}

LABEL maintainer="Nuno Souto <nsouto@lostlink.net>"

RUN mkdir -p /usr/local/etc/redis
COPY ./redis.conf /usr/local/etc/redis/redis.conf

VOLUME /data

EXPOSE 6379

CMD ["redis-server", "/usr/local/etc/redis/redis.conf"]
