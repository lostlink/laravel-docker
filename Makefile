##
# Running `act` uses the defined github actions to build and push the images
# We should be able to build locally for DEV, and to pull from remote
# We can have a local repo to store images and that way we only leverage GHA
##

DOCKER_ORGANIZATION ?= lostlink
DOCKER_TAG ?= dev
ENVIRONMENT = .env

.EXPORT_ALL_VARIABLES:
sinclude $(ENVIRONMENT)

DOCKERFILES = $(shell find * -type f -name Dockerfile)
NAMES=$(subst /,\:,$(subst /Dockerfile,,$(subst docker/,,$(DOCKERFILES))))
EXISTING_IMAGES=$(shell docker images -a | grep $(DOCKER_ORGANIZATION) | awk '{print $$3}')

BUILD_ARGS = $(shell cat $(ENVIRONMENT) | grep -v "\#\#" | grep "\S" | awk -F "=" '{ print "--build-arg " $$1"="$$2;}' | xargs)

.PHONY: all clean push pull run exec check checkrebuild pull-base ci $(NAMES) $(DOCKERFILES)

help:
	@echo "A WIP smart Makefile for your dockerfiles"
	@echo ""
#	@echo "Read all Dockerfile within the current directory and generate dependendies automatically."
	@echo ""
	@echo "make all              ; build all images"
	@echo "make octane           ; build octane image"
	@echo "make push all         ; build and push all images"
	@echo "make push octane      ; build and push octane image"
#	@echo "make run nginx        ; build and run nginx image (for testing)"
#	@echo "make exec nginx       ; build and start interactive shell in nginx image (for debugging)"
#	@echo "make checkrebuild all ; build and check if image has update availables (using https://github.com/philpep/duuh)
#	@echo "                        and rebuild with --no-cache is image has updates"
	@echo "make pull-base        ; pull base images from docker hub used to bootstrap other images"
#	@echo "make ci               ; alias to make pull-base checkrebuild push all"
	@echo ""
#	@echo "You can chain actions, typically in CI environment you want make checkrebuild push all"
#	@echo "which rebuild and push only images having updates availables."

all: $(NAMES)

clean:
ifeq ($(EXISTING_IMAGES),)
	@echo "No images to remove in the $(DOCKER_ORGANIZATION) namespace"
else
	docker rmi --force $(EXISTING_IMAGES)
endif

# TODO: Allow to pass in versions from .env
pull-base:
	docker pull redis:$(REDIS_TAG)
	docker pull getmeili/meilisearch:$(MEILISEARCH_TAG)
	docker pull mysql:$(MYSQL_TAG)
	docker pull php:$(PHP_TAG)

$(NAMES): %: %/Dockerfile
#ifeq (push,$(filter push,$(MAKECMDGOALS)))
#	docker push $<
#endif
#ifeq (run,$(filter run,$(MAKECMDGOALS)))
#	docker run --rm -it $<
#endif
#ifeq (exec,$(filter exec,$(MAKECMDGOALS)))
#	docker run --entrypoint sh --rm -it $<
#endif
#ifeq (check,$(filter check,$(MAKECMDGOALS)))
#	duuh $<
#endif

$(DOCKERFILES): %:
ifeq (pull,$(filter pull,$(MAKECMDGOALS)))
	docker pull $(addprefix $(subst :,\:,$(DOCKER_ORGANIZATION)/),$(subst /,\:,$(subst /Dockerfile,,$(subst docker/,,$@))))
endif
ifeq (push,$(filter push,$(MAKECMDGOALS)))
	act -j $(subst /Dockerfile,,$@)
else
	docker build --tag $(addprefix $(subst :,\:,$(DOCKER_ORGANIZATION)/),$(subst /,\:,$(subst /Dockerfile,,$@))):$(DOCKER_TAG) $(BUILD_ARGS) -f $@ ./$(subst /Dockerfile,,$@)/.
endif
