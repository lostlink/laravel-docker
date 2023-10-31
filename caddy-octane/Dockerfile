ARG OCTANE_TAG=latest
ARG CADDY_TAG=latest
ARG CADDY_BUILDER_TAG=builder

FROM caddy:${CADDY_BUILDER_TAG} AS builder

RUN xcaddy build \
    --with github.com/silinternational/certmagic-storage-dynamodb/v3 \
    --with github.com/caddy-dns/powerdns

# TODO: Build the octane image locally and use it here, instead of pulling from dockerhub
#  This should work on GithubAction and locally using the docker buildx build command
#  https://www.docker.com/blog/dockerfiles-now-support-multiple-build-contexts/
#  https://github.com/docker/build-push-action#path-context

FROM lostlink/octane:${OCTANE_TAG}

LABEL maintainer="Nuno Souto <nsouto@lostlink.net>"

ARG CADDY_ORIGIN_URL

ENV CADDY_ORIGIN_URL=${CADDY_ORIGIN_URL}

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

COPY ./etc/supervisor/ /etc/supervisor/
COPY ./etc/caddy/ /etc/caddy/

EXPOSE 80 443 2019 9000
