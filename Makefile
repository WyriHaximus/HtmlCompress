# set all to phony
SHELL=bash

.PHONY: *

DOCKER_AVAILABLE=$(shell ((command -v docker >/dev/null 2>&1) && echo 0 || echo 1))
CONTAINER_REGISTRY_REPO="ghcr.io/wyrihaximusnet/php"
COMPOSER_SHOW_EXTENSION_LIST_PROD=$(shell (((command -v composer >/dev/null 2>&1) && composer show -t --no-plugins) || docker run --rm -v "`pwd`:`pwd`" -w `pwd` ${CONTAINER_REGISTRY_REPO}:8.4-nts-alpine-slim-dev composer show -t --no-plugins) | grep -o "\-\-\(ext-\).\+" | sort | uniq | cut -d- -f4- | tr -d '\n' | grep . | sed  '/^$$/d' | xargs | sed -e 's/ /, /g' | tr -cd '[:alnum:],' | sed 's/.$$//')
COMPOSER_SHOW_EXTENSION_LIST_DEV=$(shell (((command -v composer >/dev/null 2>&1) && composer show -s --no-plugins) || docker run --rm -v "`pwd`:`pwd`" -w `pwd` ${CONTAINER_REGISTRY_REPO}:8.4-nts-alpine-slim-dev composer show -s --no-plugins) | grep -o "\(ext-\).\+" | sort | uniq | cut -d- -f2- | cut -d" " -f1 | xargs | sed -e 's/ /, /g' | tr -cd '[:alnum:],')
COMPOSER_SHOW_EXTENSION_LIST=$(shell echo "${COMPOSER_SHOW_EXTENSION_LIST_PROD},${COMPOSER_SHOW_EXTENSION_LIST_DEV}")
SLIM_DOCKER_IMAGE=$(shell php -r 'echo count(array_intersect(["gd", "vips"], explode(",", "${COMPOSER_SHOW_EXTENSION_LIST}"))) > 0 ? "" : "-slim";')
NTS_OR_ZTS_DOCKER_IMAGE=$(shell php -r 'echo count(array_intersect(["parallel"], explode(",", "${COMPOSER_SHOW_EXTENSION_LIST}"))) > 0 ? "zts" : "nts";')
PHP_VERSION:=$(shell (((command -v docker >/dev/null 2>&1) && docker run --rm -v "`pwd`:`pwd`" ${CONTAINER_REGISTRY_REPO}:8.4-nts-alpine-slim php -r "echo json_decode(file_get_contents('`pwd`/composer.json'), true)['config']['platform']['php'];") || echo "8.3") | php -r "echo str_replace('|', '.', explode('.', implode('|', explode('.', stream_get_contents(STDIN), 2)), 2)[0]);")
CONTAINER_NAME=$(shell echo "${CONTAINER_REGISTRY_REPO}:${PHP_VERSION}-${NTS_OR_ZTS_DOCKER_IMAGE}-alpine${SLIM_DOCKER_IMAGE}-dev")
COMPOSER_CACHE_DIR=$(shell (command -v composer >/dev/null 2>&1) && composer config --global cache-dir -q || echo ${HOME}/.composer-php/cache)
COMPOSER_CONTAINER_CACHE_DIR=$(shell ((command -v docker >/dev/null 2>&1) && docker run --rm -it ${CONTAINER_NAME} composer config --global cache-dir -q) || echo ${HOME}/.composer-php/cache)

ifneq ("$(wildcard /.you-are-in-a-wyrihaximus.net-php-docker-image)","")
    IN_DOCKER=TRUE
else
    IN_DOCKER=FALSE
endif

ifeq ("$(IN_DOCKER)","TRUE")
	DOCKER_RUN:=
else
    ifeq ($(DOCKER_AVAILABLE),0)
        DOCKER_RUN:=docker run --rm -it \
            -v "`pwd`:`pwd`" \
            -v "${COMPOSER_CACHE_DIR}:${COMPOSER_CONTAINER_CACHE_DIR}" \
            -w "`pwd`" \
            -e OTEL_PHP_FIBERS_ENABLED="true" \
            "${CONTAINER_NAME}"
    else
        DOCKER_RUN:=
    endif
endif

ifneq (,$(findstring icrosoft,$(shell cat /proc/version)))
    THREADS=1
else
    THREADS=$(shell nproc)
endif

## Run everything extra point
all: ## Runs everything ####
	$(DOCKER_RUN) make all-raw
all-raw: ## The real runs everything, but due to sponge it has to be ran inside DOCKER_RUN ##U##
	((command -v sponge >/dev/null 2>&1) && (sh -c '$(shell printf "%s %s" $(MAKE) $(shell cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' | grep -v "##*I*##" | grep -v "####" | grep -v "##U##" | awk 'BEGIN {FS = ":.*?## "}; {printf "%s\n", $$1}' | sponge | tr '\r\n' '_') | tr '_' ' ')') || (grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -v "##*I*##" | grep -v "####" | grep -v "##U##" | awk 'BEGIN {FS = ":.*?## "}; {printf "%s\n", $$1}' | xargs -o $(MAKE)))


## Temporary set of migrations to get all my repos in shape
migrations-php-remove-psalm-xml-config: #### Make sure we remove etc/qa/psalm.xml ##*I*##
	($(DOCKER_RUN) rm etc/qa/psalm.xml || true)

migrations-php-move-infection: #### Move infection.json.dist to etc/qa/infection.json5 ##*I*##
	($(DOCKER_RUN) mv infection.json.dist etc/qa/infection.json5 || true)

migrations-php-remove-phpunit-config-dir-from-infection: #### Drop XXX from etc/qa/infection.json5 ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("phpUnit", $$json)) {exit;} unset($$json["phpUnit"]); file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\r\n");' || true)

migrations-php-fix-logs-relative-paths-for-infection: #### Fix logs paths in etc/qa/infection.json5 ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("logs", $$json)) {exit;} foreach ($$json["logs"] as $$logsKey => $$logsPath) { if (is_string($$json["logs"][$$logsKey]) && str_starts_with($$json["logs"][$$logsKey], "./var/infection")) { $$json["logs"][$$logsKey] = str_replace("./var/infection", "../../var/infection", $$json["logs"][$$logsKey]); } } file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\r\n");' || true)

migrations-php-add-github-true-to-for-infection: #### Ensure we configure infection to emit logs to GitHub in etc/qa/infection.json5 ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("logs", $$json)) {exit;} if (array_key_exists("github", $$json["logs"])) {exit;} $$json["logs"]["github"] = true; file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\r\n");' || true)

migrations-php-set-phpunit-xsd-path-to-local: #### Ensure that the PHPUnit XDS referred in etc/qa/phpunit.xml points to vendor/phpunit/phpunit/phpunit.xsd so we don't go over the network ##*I*##
	($(DOCKER_RUN) php -r '$$phpUnitConfigFIle = "etc/qa/phpunit.xml"; if (!file_exists($$phpUnitConfigFIle)) {exit;} $$xml = file_get_contents($$phpUnitConfigFIle); if (!is_string($$xml)) {exit;} for ($$major = 0; $$major < 23; $$major++) { for ($$minor = 0; $$minor < 23; $$minor++) { $$xml = str_replace("https://schema.phpunit.de/" . $$major . "." . $$minor . "/phpunit.xsd", "../../vendor/phpunit/phpunit/phpunit.xsd", $$xml); } } file_put_contents($$phpUnitConfigFIle, $$xml);' || true)

migrations-php-set-phpstan-paths-in-config: #### Ensure PHPStan config has the etc, src, and tests paths set in etc/qa/phpstan.neon ##*I*##
	($(DOCKER_RUN) php -r '$$phpStanConfigFIle = "etc/qa/phpstan.neon"; $$pathsString = "\n\tpaths:\n\t\t- ../../etc\n\t\t- ../../src\n\t\t- ../../tests"; if (!file_exists($$phpStanConfigFIle)) {exit;} $$neon = file_get_contents($$phpStanConfigFIle); if (!is_string($$neon)) {exit;} if (strpos($$neon, $$pathsString) !== false) {exit;} $$neon = str_replace("parameters:", "parameters:" . $$pathsString, $$neon); file_put_contents($$phpStanConfigFIle, $$neon);' || true)

migrations-php-set-phpstan-level-max-in-config: #### Ensure PHPStan config has level set to max in etc/qa/phpstan.neon ##*I*##
	($(DOCKER_RUN) php -r '$$phpStanConfigFIle = "etc/qa/phpstan.neon"; $$levelString = "\n\tlevel: max"; if (!file_exists($$phpStanConfigFIle)) {exit;} $$neon = file_get_contents($$phpStanConfigFIle); if (!is_string($$neon)) {exit;} if (strpos($$neon, $$levelString) !== false) {exit;} $$neon = str_replace("parameters:", "parameters:" . $$levelString, $$neon); file_put_contents($$phpStanConfigFIle, $$neon);' || true)

migrations-php-set-phpstan-uncomment-parameters: #### Ensure PHPStan config as parameters not commented out in etc/qa/phpstan.neon ##*I*##
	($(DOCKER_RUN) php -r '$$phpStanConfigFIle = "etc/qa/phpstan.neon"; if (!file_exists($$phpStanConfigFIle)) {exit;} $$neon = file_get_contents($$phpStanConfigFIle); if (!is_string($$neon)) {exit;} if (!str_starts_with($$neon, "#parameters:")) {exit;} $$neon = str_replace("#parameters:", "parameters:", $$neon); file_put_contents($$phpStanConfigFIle, $$neon);' || true)

migrations-php-set-rector-create-config-if-not-exists: #### Create Rector config file if it doesn't exists at etc/qa/rector.php ##*I*##
	($(DOCKER_RUN) php -r '$$rectorConfigFile = "etc/qa/rector.php"; $$defaultRectorConfig = "<?php declare(strict_types=1); use WyriHaximus\TestUtilities\RectorConfig; return RectorConfig::configure(dirname(__DIR__, 2));"; if (file_exists($$rectorConfigFile)) {exit;} file_put_contents($$rectorConfigFile, $$defaultRectorConfig);' || true)

migrations-php-make-sure-etc-is-ran-through-phpcs: #### Make sure PHPCS runs through etc ##*I*##
	($(DOCKER_RUN) php -r '$$phpcsConfigFile = "etc/qa/phpcs.xml"; if (!file_exists($$phpcsConfigFile)) {exit;} $$xml = file_get_contents($$phpcsConfigFile); if (!is_string($$xml)) {exit;} if (strpos($$xml, "<file>../../etc</file>") !== false) {exit;} $$xml = str_replace("<file>../../src</file>", "<file>../../etc</file>\n    <file>../../src</file>", $$xml); file_put_contents($$phpcsConfigFile, $$xml);' || true)

migrations-github-codeowners: #### Ensure a CODEOWNERS file is present, create only if it doesn't exist yet ##*I*##
	($(DOCKER_RUN) php -r '$$codeOwnersFile = ".github/CODEOWNERS"; if (file_exists($$codeOwnersFile)) {exit;} file_put_contents($$codeOwnersFile, "*       @WyriHaximus" . PHP_EOL);' || true)

migrations-github-actions-move-release-management: #### Move .github/workflows/release-managment.yaml to .github/workflows/release-management.yaml ##*I*##
	($(DOCKER_RUN) mv .github/workflows/release-managment.yaml .github/workflows/release-management.yaml || true)

migrations-github-actions-fix-management-in-release-management-referenced-workflow-file: #### Fix management in release-management referenced workflow file ##*I*##
	($(DOCKER_RUN) sed -i -e 's/release-managment.yaml/release-management.yaml/g' .github/workflows/release-management.yaml || true)

migrations-renovate-move-config: #### Move renovate.json to .github/renovate.json ##*I*##
	($(DOCKER_RUN) mv renovate.json .github/renovate.json || true)

migrations-renovate-point-at-correct-config: #### Ensure .github/renovate.json points at github>WyriHaximus/renovate-config:php-package instead of local>WyriHaximus/renovate-config ##*I*##
	($(DOCKER_RUN) php -r '$$renovateFIle = ".github/renovate.json"; if (!file_exists($$renovateFIle)) {exit;} file_put_contents($$renovateFIle, str_replace("local>WyriHaximus/renovate-config", "github>WyriHaximus/renovate-config:php-package", file_get_contents($$renovateFIle)));' || true)


## Our default jobs
on-install-or-update: ## Runs everything ####
	((command -v sponge >/dev/null 2>&1) && (sh -c '$(shell printf "%s %s" $(MAKE) $(shell cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' | grep -E "##\*(I|ILH)\*##" | awk 'BEGIN {FS = ":.*?## "}; {printf "%s\n", $$1}' | sponge | tr '\r\n' '_') | tr '_' ' ')') || (grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "##\*(I|ILH)\*##" | awk 'BEGIN {FS = ":.*?## "}; {printf "%s\n", $$1}' | xargs -o $(MAKE)))

syntax-php: ## Lint PHP syntax ##*ILH*##
	$(DOCKER_RUN) vendor/bin/parallel-lint --exclude vendor .

composer-normalize: ### Normalize composer.json ##*I*##
	$(DOCKER_RUN) composer normalize
	$(DOCKER_RUN) COMPOSER_DISABLE_NETWORK=1 composer update --lock --no-scripts || $(DOCKER_RUN) composer update --lock --no-scripts

rector-upgrade: ## Upgrade any automatically upgradable old code ##*I*##
	$(DOCKER_RUN) vendor/bin/rector -c ./etc/qa/rector.php

cs-fix: ## Fix any automatically fixable code style issues ##*I*##
	$(DOCKER_RUN) vendor/bin/phpcbf --parallel=1 --cache=./var/.phpcs.cache.json --standard=./etc/qa/phpcs.xml || $(DOCKER_RUN) vendor/bin/phpcbf --parallel=1 --cache=./var/.phpcs.cache.json --standard=./etc/qa/phpcs.xml || $(DOCKER_RUN) vendor/bin/phpcbf --parallel=1 --cache=./var/.phpcs.cache.json --standard=./etc/qa/phpcs.xml -vvvv

cs: ## Check the code for code style issues ##*LCH*##
	$(DOCKER_RUN) vendor/bin/phpcs --parallel=1 --cache=./var/.phpcs.cache.json --standard=./etc/qa/phpcs.xml

stan: ## Run static analysis (PHPStan) ##*LCH*##
	$(DOCKER_RUN) vendor/bin/phpstan analyse --ansi --configuration=./etc/qa/phpstan.neon

unit-testing: ## Run tests ##*A*##
	$(DOCKER_RUN) vendor/bin/phpunit --colors=always -c ./etc/qa/phpunit.xml --coverage-text --coverage-html ./var/tests-unit-coverage-html --coverage-clover ./var/tests-unit-clover-coverage.xml

unit-testing-raw: ## Run tests ##*D*## ####
	php vendor/phpunit/phpunit/phpunit --colors=always -c ./etc/qa/phpunit.xml --coverage-text --coverage-html ./var/tests-unit-coverage-html --coverage-clover ./var/tests-unit-clover-coverage.xml

mutation-testing: ## Run mutation testing ##*LCH*##
	$(DOCKER_RUN) vendor/bin/infection --ansi --log-verbosity=all --ignore-msi-with-no-mutations --configuration=./etc/qa/infection.json5 --static-analysis-tool=phpstan --static-analysis-tool-options="--memory-limit=-1" --threads=$(THREADS) || (cat ./var/infection.log && false)

mutation-testing-raw: ## Run mutation testing ####
	vendor/bin/infection --ansi --log-verbosity=all --ignore-msi-with-no-mutations --configuration=./etc/qa/infection.json5 --static-analysis-tool=phpstan --static-analysis-tool-options="--memory-limit=-1" --threads=$(THREADS) || (cat ./var/infection.log && false)

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
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -v "##U##" | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[32m%-32s\033[0m %s\n", $$1, $$2}' | tr -d '#'

task-list-ci-all: ## CI: Generate a JSON array of jobs to run on all variations
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "##\*A\*##" | grep -v "##U##" | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "%s\n", $$1}' | jq --raw-input --slurp -c 'split("\n")| .[0:-1]'

task-list-ci-dos: ## CI: Generate a JSON array of jobs to run Directly on the OS variations
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "##\*D\*##" | grep -v "##U##" | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "%s\n", $$1}' | jq --raw-input --slurp -c 'split("\n")| .[0:-1]'

task-list-ci-low: ## CI: Generate a JSON array of jobs to run against the lowest dependencies on the primary threading target
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "##\*(L|LC|LCH|LH)\*##" | grep -v "###" | grep -v "##U##" | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "%s\n", $$1}' | jq --raw-input --slurp -c 'split("\n")| .[0:-1]'

task-list-ci-locked: ## CI: Generate a JSON array of jobs to run against the locked dependencies on the primary threading target
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "##\*(C|LC|LCH|CH)\*##" | grep -v "###" | grep -v "##U##" | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "%s\n", $$1}' | jq --raw-input --slurp -c 'split("\n")| .[0:-1]'

task-list-ci-high: ## CI: Generate a JSON array of jobs to run against the highest dependencies on the primary threading target
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "##\*(H|LH|LCH|LC)\*##" | grep -v "###" | grep -v "##U##" | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "%s\n", $$1}' | jq --raw-input --slurp -c 'split("\n")| .[0:-1]'

