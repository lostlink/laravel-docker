ARG OCTANE_TAG=latest

FROM caddy:builder AS builder

RUN xcaddy build \
    --with github.com/silinternational/certmagic-storage-dynamodb/v3 \
    --with github.com/caddy-dns/powerdns

# TODO: Build the octane image locally and use it here, instead of pulling from dockerhub
#  This should work on GithubAction and locally using the docker buildx build command
#  https://www.docker.com/blog/dockerfiles-now-support-multiple-build-contexts/
#  https://github.com/docker/build-push-action#path-context

FROM lostlink/octane:${OCTANE_TAG}

LABEL maintainer="Nuno Souto <nsouto@lostlink.net>"

ARG DOMAIN_API_CHECK_URL
ARG POWERDNS_SERVER_URL
ARG POWERDNS_API_TOKEN
ARG LETS_ENCRYPT_EMAIL
ARG DYNAMODB_TABLE_NAME
ARG AWS_REGION
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY

ENV DOMAIN_API_CHECK_URL=${DOMAIN_API_CHECK_URL}
ENV POWERDNS_SERVER_URL=${POWERDNS_SERVER_URL}
ENV POWERDNS_API_TOKEN=${POWERDNS_API_TOKEN}
ENV LETS_ENCRYPT_EMAIL=${LETS_ENCRYPT_EMAIL}
ENV DYNAMODB_TABLE_NAME=${DYNAMODB_TABLE_NAME}
ENV AWS_REGION=${AWS_REGION}
ENV AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
ENV AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

RUN apt-get update; \
    apt-get upgrade -yqq; \
    apt-get install -yqq --no-install-recommends --show-progress debian-keyring debian-archive-keyring apt-transport-https gpg; \
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg; \
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list; \
    apt-get update; \
    apt-get install -yqq --no-install-recommends --show-progress caddy;

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

COPY ./etc/supervisor/ /etc/supervisor/
COPY ./etc/caddy/ /etc/caddy/

EXPOSE 2080 2443 2019 9000
