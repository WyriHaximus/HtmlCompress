# set all to phony
SHELL=bash

.PHONY: *

CONTAINER_REGISTRY_REPO="ghcr.io/wyrihaximusnet/php"
COMPOSER_SHOW_EXTENSION_LIST_PROD=$(shell composer show -t | grep -o "\-\-\(ext-\).\+" | sort | uniq | cut -d- -f4- | tr -d '\n' | grep . | sed  '/^$$/d' | xargs | sed -e 's/ /, /g' | tr -cd '[:alnum:],' | sed 's/.$$//')
COMPOSER_SHOW_EXTENSION_LIST_DEV=$(shell composer show -s | grep -o "\(ext-\).\+" | sort | uniq | cut -d- -f2- | cut -d" " -f1 | xargs | sed -e 's/ /, /g' | tr -cd '[:alnum:],')
COMPOSER_SHOW_EXTENSION_LIST=$(shell echo "${COMPOSER_SHOW_EXTENSION_LIST_PROD},${COMPOSER_SHOW_EXTENSION_LIST_DEV}")
SLIM_DOCKER_IMAGE=$(shell php -r 'echo count(array_intersect(["gd", "vips"], explode(",", "${COMPOSER_SHOW_EXTENSION_LIST}"))) > 0 ? "" : "-slim";')
NTS_OR_ZTS_DOCKER_IMAGE=$(shell php -r 'echo count(array_intersect(["parallel"], explode(",", "${COMPOSER_SHOW_EXTENSION_LIST}"))) > 0 ? "zts" : "nts";')
PHP_VERSION:=$(shell (((command -v docker >/dev/null 2>&1) && docker run --rm -v "`pwd`:`pwd`" ${CONTAINER_REGISTRY_REPO}:8.4-nts-alpine-slim php -r "echo json_decode(file_get_contents('`pwd`/composer.json'), true)['config']['platform']['php'];") || echo "8.3") | php -r "echo str_replace('|', '.', explode('.', implode('|', explode('.', stream_get_contents(STDIN), 2)), 2)[0]);")
CONTAINER_NAME=$(shell echo "${CONTAINER_REGISTRY_REPO}:${PHP_VERSION}-${NTS_OR_ZTS_DOCKER_IMAGE}-alpine${SLIM_DOCKER_IMAGE}-dev")
COMPOSER_CACHE_DIR=$(shell composer config --global cache-dir -q || echo ${HOME}/.composer-php/cache)
COMPOSER_CONTAINER_CACHE_DIR=$(shell ((command -v docker >/dev/null 2>&1) && docker run --rm -it ${CONTAINER_NAME} composer config --global cache-dir -q) || echo ${HOME}/.composer-php/cache)

ifneq ("$(wildcard /.you-are-in-a-wyrihaximus.net-php-docker-image)","")
    IN_DOCKER=TRUE
else
    IN_DOCKER=FALSE
endif

ifeq ("$(IN_DOCKER)","TRUE")
	DOCKER_RUN:=
else
	DOCKER_RUN:=docker run --rm -it \
		-v "`pwd`:`pwd`" \
		-v "${COMPOSER_CACHE_DIR}:${COMPOSER_CONTAINER_CACHE_DIR}" \
		-w "`pwd`" \
		-e OTEL_PHP_FIBERS_ENABLED="true" \
		"${CONTAINER_NAME}"
endif

ifneq (,$(findstring icrosoft,$(shell cat /proc/version)))
    THREADS=1
else
    THREADS=$(shell nproc)
endif

all: ## Runs everything ####
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -v "####" | awk 'BEGIN {FS = ":.*?## "}; {printf "%s\n", $$1}' | xargs -o $(MAKE)

on-install-or-update: ## Runs everything ####
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "##\*(I|ILH)\*##" | awk 'BEGIN {FS = ":.*?## "}; {printf "%s\n", $$1}' | xargs -o $(MAKE)

syntax-php: ## Lint PHP syntax ##*ILH*##
	$(DOCKER_RUN) vendor/bin/parallel-lint --exclude vendor .

composer-normalize: ### Normalize composer.json ##*I*##
	$(DOCKER_RUN) composer normalize
	$(DOCKER_RUN) composer update --lock --no-scripts

rector-upgrade: ## Upgrade any automatically upgradable old code ##*I*##
	$(DOCKER_RUN) vendor/bin/rector -c ./etc/qa/rector.php

cs-fix: ## Fix any automatically fixable code style issues ##*I*##
	$(DOCKER_RUN) vendor/bin/phpcbf --parallel=1 --cache=./var/.phpcs.cache.json --standard=./etc/qa/phpcs.xml || $(DOCKER_RUN) vendor/bin/phpcbf --parallel=1 --cache=./var/.phpcs.cache.json --standard=./etc/qa/phpcs.xml || $(DOCKER_RUN) vendor/bin/phpcbf --parallel=1 --cache=./var/.phpcs.cache.json --standard=./etc/qa/phpcs.xml -vvvv

cs: ## Check the code for code style issues ##*LCH*##
	$(DOCKER_RUN) vendor/bin/phpcs --parallel=1 --cache=./var/.phpcs.cache.json --standard=./etc/qa/phpcs.xml

stan: ## Run static analysis (PHPStan) ##*LCH*##
	$(DOCKER_RUN) vendor/bin/phpstan analyse etc src tests --level max --ansi -c ./etc/qa/phpstan.neon

unit-testing: ## Run tests ##*A*##
	$(DOCKER_RUN) vendor/bin/phpunit --colors=always -c ./etc/qa/phpunit.xml --coverage-text --coverage-html ./var/tests-unit-coverage-html --coverage-clover ./var/tests-unit-clover-coverage.xml

unit-testing-raw: ## Run tests ##*D*## ####
	php vendor/phpunit/phpunit/phpunit --colors=always -c ./etc/qa/phpunit.xml --coverage-text --coverage-html ./var/tests-unit-coverage-html --coverage-clover ./var/tests-unit-clover-coverage.xml

mutation-testing: ## Run mutation testing ##*LCH*##
	$(DOCKER_RUN) vendor/bin/infection --ansi --log-verbosity=all --ignore-msi-with-no-mutations --threads=$(THREADS) || (cat ./var/infection.log && false)

mutation-testing-raw: ## Run mutation testing ####
	vendor/bin/infection --ansi --log-verbosity=all --ignore-msi-with-no-mutations --threads=$(THREADS) || (cat ./var/infection.log && false)

composer-require-checker: ## Ensure we require every package used in this package directly ##*C*##
	$(DOCKER_RUN) vendor/bin/composer-require-checker --ignore-parse-errors --ansi -vvv --config-file=./etc/qa/composer-require-checker.json

composer-unused: ## Ensure we don't require any package we don't use in this package directly ##*C*##
	$(DOCKER_RUN) vendor/bin/composer-unused --ansi --configuration=./etc/qa/composer-unused.php

backward-compatibility-check: ## Check code for backwards incompatible changes ##*C*##
	$(MAKE) backward-compatibility-check-raw || true

backward-compatibility-check-raw: ## Check code for backwards incompatible changes, doesn't ignore the failure ###
	$(DOCKER_RUN) vendor/bin/roave-backward-compatibility-check

install: ### Install dependencies ####
	$(DOCKER_RUN) composer install

update: ### Update dependencies ####
	$(DOCKER_RUN) composer update -W

outdated: ### Show outdated dependencies ####
	$(DOCKER_RUN) composer outdated

shell: ## Provides Shell access in the expected environment ####
	$(DOCKER_RUN) bash


help: ## Show this help ####
	@printf "\033[33mUsage:\033[0m\n  make [target]\n\n\033[33mTargets:\033[0m\n"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[32m%-32s\033[0m %s\n", $$1, $$2}' | tr -d '#'

task-list-ci-all: ## CI: Generate a JSON array of jobs to run on all variations
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "##\*A\*##" | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "%s\n", $$1}' | jq --raw-input --slurp -c 'split("\n")| .[0:-1]'

task-list-ci-dos: ## CI: Generate a JSON array of jobs to run Directly on the OS variations
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "##\*D\*##" | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "%s\n", $$1}' | jq --raw-input --slurp -c 'split("\n")| .[0:-1]'

task-list-ci-low: ## CI: Generate a JSON array of jobs to run against the lowest dependencies on the primary threading target
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "##\*(L|LC|LCH|LH)\*##" | grep -v "###" | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "%s\n", $$1}' | jq --raw-input --slurp -c 'split("\n")| .[0:-1]'

task-list-ci-locked: ## CI: Generate a JSON array of jobs to run against the locked dependencies on the primary threading target
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "##\*(C|LC|LCH|CH)\*##" | grep -v "###" | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "%s\n", $$1}' | jq --raw-input --slurp -c 'split("\n")| .[0:-1]'

task-list-ci-high: ## CI: Generate a JSON array of jobs to run against the highest dependencies on the primary threading target
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "##\*(H|LH|LCH|LC)\*##" | grep -v "###" | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "%s\n", $$1}' | jq --raw-input --slurp -c 'split("\n")| .[0:-1]'

