ARG CADDY_TAG=latest
ARG CADDY_BUILDER_TAG=builder

FROM caddy:${CADDY_BUILDER_TAG} AS builder

RUN xcaddy build \
    --with github.com/pberkel/caddy-storage-redis \
    --with github.com/yroc92/postgres-storage \
    --with github.com/zhangjiayin/caddy-mysql-storage \
    --with github.com/caddy-dns/powerdns \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/mholt/caddy-l4 \
    --with github.com/hslatman/caddy-crowdsec-bouncer/http \
    --with github.com/darkweak/souin/plugins/caddy

# TODO: Build the octane image locally and use it here, instead of pulling from dockerhub
#  This should work on GithubAction and locally using the docker buildx build command
#  https://www.docker.com/blog/dockerfiles-now-support-multiple-build-contexts/
#  https://github.com/docker/build-push-action#path-context

FROM caddy:${CADDY_TAG}

LABEL maintainer="Nuno Souto <nsouto@lostlink.net>"

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

COPY ./etc/caddy/ /etc/caddy/

EXPOSE 80 443 2019
