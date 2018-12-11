.PHONY: help

# ------------------------------------------------------
# VARIABLES
# ------------------------------------------------------
CWD=$(shell pwd)
DOCKER=docker
COMPOSE=docker-compose -f .docker/docker-compose.yml
COMPOSE_TEST=docker-compose -f .docker/docker-compose.test.yml

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

# ------------------------------------------------------
# MAIN COMMANDS
# ------------------------------------------------------
setup: environment verbose

build: setup				## Builds the docker image and tags it with a temp tag name (based on CI build number or manually passed).
	$(DOCKER) build --force-rm -t ${DOCKER_IMAGE} .
	$(DOCKER) tag ${DOCKER_IMAGE} ${DOCKER_IMAGE_TEST}

test: setup					## Executes `yarn test` inside the docker container with the temp tag name.
ifdef CI
	$(DOCKER) run -it --rm --user root -v ${CWD}/coverage:/home/node/app/coverage ${DOCKER_OPTS} ${DOCKER_IMAGE} yarn test
else
	$(DOCKER) run -it --rm --user root -v ${CWD}/coverage:/home/node/app/coverage ${DOCKER_OPTS} ${DOCKER_IMAGE} yarn install --offline --production=false
	$(DOCKER) run -it --rm --user root -v ${CWD}/coverage:/home/node/app/coverage ${DOCKER_OPTS} ${DOCKER_IMAGE} yarn test
endif

test-visual: setup	## Executes `yarn test:visual` inside the docker container with the temp tag name.
	$(COMPOSE_TEST) up -d chrome
	$(COMPOSE_TEST) run --rm test-container yarn test-visual || ($(COMPOSE_TEST) down && exit 1)
	$(COMPOSE_TEST) down

lint: setup					## Executes `yarn lint` inside the docker container with the temp tag name.
	$(DOCKER) run -it --rm ${DOCKER_OPTS} ${DOCKER_IMAGE} yarn lint

	# ------------------------------------------------------
# DEV COMMANDS
# ------------------------------------------------------
dev:											## [DEV] Start development environment (without storybook)
	$(COMPOSE) up --scale storybook=0 --scale nginx=0

dev-all:									## [DEV] Start development environment (with storybook and nginx proxy)
	$(COMPOSE) up

dev-with-proxy:						## [DEV] Start development environment (with nginx proxy)
	$(COMPOSE) up --scale storybook=0

storybook:								## [DEV] Start storybook
	$(COMPOSE) up --scale nginx=0 --scale project_name=0

console:									## [DEV] Attaching a console to the current environment
	$(COMPOSE) exec project_name sh || ($(COMPOSE) run project_name sh)

yarn:									## [DEV] Run `yarn` inside the dev container
	$(COMPOSE) exec project_name yarn || ($(COMPOSE) run project_name yarn)

down:										## [DEV] Stop docker containers
	$(COMPOSE) down

clean:										## [DEV] Stop docker containers and remove volumes
	$(COMPOSE) down -v

forcefully-remove-containers:	## [DEV] Remove all project_name related containers
	$(DOCKER) docker ps -a | grep 'project_name' | awk '{print $2}' | xargs $(DOCKER) rmi -f

test-update: setup				## [DEV] Update test snapshots
	$(DOCKER) run -it --rm ${DOCKER_OPTS} ${DOCKER_IMAGE} yarn update-test

test-update-visual: setup	## [DEV] Update the visual tests
	$(COMPOSE_TEST) up -d chrome
	$(COMPOSE_TEST) run --rm test-container-update yarn update-visual || ($(COMPOSE_TEST) down && exit 1)
	$(COMPOSE_TEST) down

# ------------------------------------------------------
# UTILS
# ------------------------------------------------------
# Sets GIT_COMMIT to the one provided by CircleCI or gets the local one via git.
export_git_commit:
ifdef CIRCLE_SHA1
	$(eval export GIT_COMMIT=${CIRCLE_SHA1})
else
	$(eval export GIT_COMMIT=$(shell git log --pretty=format:%h -1))
endif

export_docker_tag: export_git_commit
ifdef CI
	$(eval export DOCKER_TAG=${GIT_COMMIT})
else
	$(eval export DOCKER_TAG=development)
endif

export_project:
ifdef GKE_UTILITY_PROJECTNAME
	$(eval export PROJECT=${GKE_UTILITY_PROJECTNAME})
else
	$(eval export PROJECT=gke-utility)
endif

export_docker_image: export_project export_docker_tag
	$(eval export DOCKER_IMAGE=gcr.io/${PROJECT}/project_name:${DOCKER_TAG})
	$(eval export DOCKER_IMAGE_TEST=local/project_name:test)

export_version: export_docker_image
	$(eval export VERSION=`docker run --rm ${DOCKER_IMAGE} node -e "console.log(require('./package.json').version)"`)

export_docker_opts:
ifdef CI
	$(eval export DOCKER_OPTS=)
else
	$(eval export DOCKER_OPTS=-v ${CWD}:/home/node/app:cached -v node_modules:/home/node/app/node_modules -w="/home/node/app")
endif

# Set a bunch of environment variables
environment: export_git_commit export_docker_tag export_project export_docker_image export_docker_opts

# Display env vars
verbose: environment
	@echo "-----------------------------------"
	@echo "CI           = ${CI}"
	@echo "BRANCH       = ${CIRCLE_BRANCH}"
	@echo "BUILD NUMBER = ${CIRCLE_BUILD_NUM}"
	@echo "GIT COMMIT   = ${GIT_COMMIT}"
	@echo "DOCKER IMAGE = ${DOCKER_IMAGE}"
	@echo "-----------------------------------"

