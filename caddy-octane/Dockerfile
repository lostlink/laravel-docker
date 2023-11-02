ARG OCTANE_TAG=latest
ARG CADDY_TAG=latest

# TODO: Build the octane image locally and use it here, instead of pulling from dockerhub
#  This should work on GithubAction and locally using the docker buildx build command
#  https://www.docker.com/blog/dockerfiles-now-support-multiple-build-contexts/
#  https://github.com/docker/build-push-action#path-context

FROM lostlink/octane:${OCTANE_TAG}

LABEL maintainer="Nuno Souto <nsouto@lostlink.net>"

COPY --from=lostlink/caddy:${CADDY_TAG} /usr/bin/caddy /usr/bin/caddy

COPY ./etc/supervisor/ /etc/supervisor/
COPY ./etc/caddy/ /etc/caddy/

EXPOSE 80 443 2019 9000
