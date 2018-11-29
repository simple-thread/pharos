#!/bin/bash
# Docker_start.sh
# Script to provision a development environment
# with docker-ce and start pharos in a container as per docker-compose.yml

# 1. ID OS - Linux or OSX
# 2. If OSX, install homebrew
# 3. Install Docker-CE on osx (brew cask install docker/linux: apt-get install docker)
# 4. Run make build to build the latest version of Pharos
# 5. docker-compose up -f docker-compose-dev.yml
# 6. Connect to pharos.docker.localhost in your browser.

# -  make restart: docker-compose up -d -f docker-compose-dev.yml
#

REGISTRY = registry.gitlab.com/aptrust
REPOSITORY = container-registry
NAME=$(shell basename $(CURDIR))
VERSION = latest
TAG = $(NAME):$(VERSION)
REVISION=$(shell git rev-parse --short=2 HEAD)

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help build publish

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

revision: ## Show me the git hash
	echo "$(REVISION)"

build: ## Build the Pharos container
	docker build -t aptrust/$(TAG) -t $(TAG) -t $(NAME):$(REVISION) -t $(REGISTRY)/$(REPOSITORY)/$(TAG) .

up: ## Start containers for Pharos, Postgresql, Nginx
	docker-compose up -d

run: ## Just run Pharos in foreground
	docker run -p 9292:9292 $(TAG)


publish:
	docker tag aptrust/pharos registry.gitlab.com/aptrust/container-registry/pharos && \
	docker push registry.gitlab.com/aptrust/container-registry/pharos

# Docker release - build, tag and push the container
release: build publish ## Make a release by building and publishing the `{version}` as `latest` tagged containers to Gitlab

push: ## Push the Docker image up to the registry
	docker push  $(REGISTRY)/$(REPOSITORY)/$(TAG)

clean: ## Clean the generated/compiles files
