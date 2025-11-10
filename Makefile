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
	((shell command -v sponge >/dev/null 2>&1) && (sh -c '$(shell printf "%s %s" $(MAKE) $(shell cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' | grep -v "##*I*##" | grep -v "####" | grep -v "##U##" | awk 'BEGIN {FS = ":.*?## "}; {printf "%s\n", $$1}' | sponge | tr '\r\n' '_') | tr '_' ' ')') || (grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -v "##*I*##" | grep -v "####" | grep -v "##U##" | awk 'BEGIN {FS = ":.*?## "}; {printf "%s\n", $$1}' | xargs -o $(MAKE)))


## Temporary set of migrations to get all my repos in shape
migrations-git-enforce-gitattributes-contents: #### Enforce .gitattributes contents ##*I*##
	($(DOCKER_RUN) php -r 'file_put_contents(".gitattributes", base64_decode("IyBTZXQgdGhlIGRlZmF1bHQgYmVoYXZpb3IsIGluIGNhc2UgcGVvcGxlIGRvbid0IGhhdmUgY29yZS5hdXRvY3JsZiBzZXQuCiogdGV4dCBlb2w9bGYKCiMgSWdub3JpbmcgZmlsZXMgZm9yIGRpc3RyaWJ1dGlvbiBhcmNoaWV2ZXMKLmdpdGh1Yi8gZXhwb3J0LWlnbm9yZQpldGMvIGV4cG9ydC1pZ25vcmUKZXhhbXBsZXMvIGV4cG9ydC1pZ25vcmUKdGVzdHMvIGV4cG9ydC1pZ25vcmUKdmFyLyBleHBvcnQtaWdub3JlCi5kZXZjb250YWluZXIuanNvbiBleHBvcnQtaWdub3JlCi5lZGl0b3Jjb25maWcgZXhwb3J0LWlnbm9yZQouZ2l0YXR0cmlidXRlcyBleHBvcnQtaWdub3JlCi5naXRpZ25vcmUgZXhwb3J0LWlnbm9yZQpDT05UUklCVVRJTkcubWQgZXhwb3J0LWlnbm9yZQpjb21wb3Nlci5sb2NrIGV4cG9ydC1pZ25vcmUKTWFrZWZpbGUgZXhwb3J0LWlnbm9yZQpSRUFETUUubWQgZXhwb3J0LWlnbm9yZQoKIyBEaWZmaW5nCioucGhwIGRpZmY9cGhwCg=="));' || true)

migrations-git-make-sure-gitignore-exists: #### Make sure .gitignore exists ##*I*##
	($(DOCKER_RUN) touch .gitignore || true)

migrations-git-make-sure-gitignore-ignores-var: #### Make sure .gitignore ignores var/* ##*I*##
	($(DOCKER_RUN) php -r '$$gitignoreFile = ".gitignore"; if (!file_exists($$gitignoreFile)) {exit;} $$txt = file_get_contents($$gitignoreFile); if (!is_string($$txt)) {exit;} if (strpos($$txt, "var/*") !== false) {exit;} file_put_contents($$gitignoreFile, "var/*\n", FILE_APPEND);' || true)

migrations-git-make-sure-gitignore-excludes-var-gitkeep: #### Make sure .gitignore excludes var/.gitkeep ##*I*##
	($(DOCKER_RUN) php -r '$$gitignoreFile = ".gitignore"; if (!file_exists($$gitignoreFile)) {exit;} $$txt = file_get_contents($$gitignoreFile); if (!is_string($$txt)) {exit;} if (strpos($$txt, "!var/.gitkeep") !== false) {exit;} file_put_contents($$gitignoreFile, "!var/.gitkeep\n", FILE_APPEND);' || true)

migrations-php-make-sure-var-exists: #### Make sure var/ exists ##*I*##
	($(DOCKER_RUN) mkdir var || true)

migrations-php-make-sure-var-gitkeep-exists: #### Make sure var/.gitkeep exists ##*I*##
	($(DOCKER_RUN) touch var/.gitkeep || true)

migrations-php-make-sure-etc-exists: #### Make sure etc/ exists ##*I*##
	($(DOCKER_RUN) mkdir etc || true)

migrations-php-make-sure-etc-ci-exists: #### Make sure etc/ci/ exists ##*I*##
	($(DOCKER_RUN) mkdir etc/ci || true)

migrations-php-make-sure-etc-qa-exists: #### Make sure etc/qa/ exists ##*I*##
	($(DOCKER_RUN) mkdir etc/qa || true)

migrations-php-move-psalm-xml-config-to-etc: #### Move psalm.xml to etc/qa/psalm.xml ##*I*##
	($(DOCKER_RUN) mv psalm.xml etc/qa/psalm.xml || true)

migrations-php-remove-psalm-xml-config: #### Make sure we remove etc/qa/psalm.xml ##*I*##
	($(DOCKER_RUN) rm etc/qa/psalm.xml || true)

migrations-php-remove-old-phpunit-xml-dist-config: #### Make sure we remove phpunit.xml.dist ##*I*##
	($(DOCKER_RUN) rm phpunit.xml.dist || true)

migrations-php-remove-old-phpunit-xml-config: #### Make sure we remove phpunit.xml ##*I*##
	($(DOCKER_RUN) rm phpunit.xml || true)

migrations-php-ensure-etc-ci-markdown-link-checker-json-exists: #### Make sure we have etc/ci/markdown-link-checker.json ##*I*##
	($(DOCKER_RUN) php -r '$$markdownLinkCheckerFile = "etc/ci/markdown-link-checker.json"; $$json = json_decode("{\"httpHeaders\": [{\"urls\": [\"https://docs.github.com/\"],\"headers\": {\"Accept-Encoding\": \"zstd, br, gzip, deflate\"}}]}"); if (file_exists($$markdownLinkCheckerFile)) {exit;} file_put_contents($$markdownLinkCheckerFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\r\n");' || true)

migrations-php-move-infection-config-to-etc: #### Move infection.json.dist to etc/qa/infection.json5 ##*I*##
	($(DOCKER_RUN) mv infection.json.dist etc/qa/infection.json5 || true)

migrations-php-infection-create-config-if-not-exists: #### Create Infection config file if it doesn't exists at etc/qa/infection.json5 ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; $$infectionConfig = base64_decode("ewogICAgInRpbWVvdXQiOiAxMjAsCiAgICAic291cmNlIjogewogICAgICAgICJkaXJlY3RvcmllcyI6IFsKICAgICAgICAgICAgInNyYyIKICAgICAgICBdCiAgICB9LAogICAgImxvZ3MiOiB7CiAgICAgICAgInRleHQiOiAiLi4vLi4vdmFyL2luZmVjdGlvbi5sb2ciLAogICAgICAgICJzdW1tYXJ5IjogIi4uLy4uL3Zhci9pbmZlY3Rpb24tc3VtbWFyeS5sb2ciLAogICAgICAgICJqc29uIjogIi4uLy4uL3Zhci9pbmZlY3Rpb24uanNvbiIsCiAgICAgICAgInBlck11dGF0b3IiOiAiLi4vLi4vdmFyL2luZmVjdGlvbi1wZXItbXV0YXRvci5tZCIsCiAgICAgICAgImdpdGh1YiI6IHRydWUKICAgIH0sCiAgICAibWluTXNpIjogMTAwLAogICAgIm1pbkNvdmVyZWRNc2kiOiAxMDAsCiAgICAiaWdub3JlTXNpV2l0aE5vTXV0YXRpb25zIjogdHJ1ZSwKICAgICJtdXRhdG9ycyI6IHsKICAgICAgICAiQGRlZmF1bHQiOiB0cnVlCiAgICB9Cn0K"); if (file_exists($$infectionFile)) {exit;} file_put_contents($$infectionFile, $$infectionConfig);' || true)

migrations-php-remove-phpunit-config-dir-from-infection: #### Drop XXX from etc/qa/infection.json5 ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("phpUnit", $$json)) {exit;} unset($$json["phpUnit"]); file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\r\n");' || true)

migrations-php-fix-logs-relative-paths-for-infection: #### Fix logs paths in etc/qa/infection.json5 ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("logs", $$json)) {exit;} foreach ($$json["logs"] as $$logsKey => $$logsPath) { if (is_string($$json["logs"][$$logsKey]) && str_starts_with($$json["logs"][$$logsKey], "./var/infection")) { $$json["logs"][$$logsKey] = str_replace("./var/infection", "../../var/infection", $$json["logs"][$$logsKey]); } } file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\r\n");' || true)

migrations-php-infection-ensure-log-text-has-the-correct-path: #### Ensure infection's log.text has config directive has the correct path ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("logs", $$json)) { $$json["logs"] = []; } $$json["logs"]["text"] = "../../var/infection.log"; file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\r\n");' || true)

migrations-php-infection-ensure-log-summary-has-the-correct-path: #### Ensure infection's log.summary has config directive has the correct path ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("logs", $$json)) { $$json["logs"] = []; } $$json["logs"]["summary"] = "../../var/infection-summary.log"; file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\r\n");' || true)

migrations-php-infection-ensure-log-json-has-the-correct-path: #### Ensure infection's log.json has config directive has the correct path ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("logs", $$json)) { $$json["logs"] = []; } $$json["logs"]["json"] = "../../var/infection.json"; file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\r\n");' || true)

migrations-php-infection-ensure-log-per-mutator-has-the-correct-path: #### Ensure infection's log.perMutator has config directive has the correct path ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("logs", $$json)) { $$json["logs"] = []; } $$json["logs"]["perMutator"] = "../../var/infection-per-mutator.md"; file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\r\n");' || true)

migrations-php-add-github-true-to-for-infection: #### Ensure we configure infection to emit logs to GitHub in etc/qa/infection.json5 ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("logs", $$json)) {exit;} if (array_key_exists("github", $$json["logs"])) {exit;} $$json["logs"]["github"] = true; file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\r\n");' || true)

migrations-php-set-phpunit-ensure-config-file-exists: #### Make sure we have a PHPUnit config file at etc/qa/phpunit.xml ##*I*##
	($(DOCKER_RUN) php -r '$$phpUnitConfigFIle = "etc/qa/phpunit.xml"; if (file_exists($$phpUnitConfigFIle)) {exit;} file_put_contents($$phpUnitConfigFIle, base64_decode("PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHBocHVuaXQgeG1sbnM6eHNpPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxL1hNTFNjaGVtYS1pbnN0YW5jZSIgYm9vdHN0cmFwPSIuLi8uLi92ZW5kb3IvYXV0b2xvYWQucGhwIiBjb2xvcnM9InRydWUiIHhzaTpub05hbWVzcGFjZVNjaGVtYUxvY2F0aW9uPSIuLi8uLi92ZW5kb3IvcGhwdW5pdC9waHB1bml0L3BocHVuaXQueHNkIiBjYWNoZURpcmVjdG9yeT0iLi4vLi4vdmFyL3BocHVuaXQvY2FjaGUiPgogICAgPHRlc3RzdWl0ZXM+CiAgICAgICAgPHRlc3RzdWl0ZSBuYW1lPSJUZXN0IFN1aXRlIj4KICAgICAgICAgICAgPGRpcmVjdG9yeT4uLi8uLi90ZXN0cy88L2RpcmVjdG9yeT4KICAgICAgICA8L3Rlc3RzdWl0ZT4KICAgIDwvdGVzdHN1aXRlcz4KICAgIDxzb3VyY2U+CiAgICAgICAgPGluY2x1ZGU+CiAgICAgICAgICAgIDxkaXJlY3Rvcnkgc3VmZml4PSIucGhwIj4uLi8uLi9zcmMvPC9kaXJlY3Rvcnk+CiAgICAgICAgPC9pbmNsdWRlPgogICAgPC9zb3VyY2U+CiAgICA8ZXh0ZW5zaW9ucz4KICAgICAgICA8Ym9vdHN0cmFwIGNsYXNzPSJFcmdlYm5pc1xQSFBVbml0XFNsb3dUZXN0RGV0ZWN0b3JcRXh0ZW5zaW9uIi8+CiAgICA8L2V4dGVuc2lvbnM+CjwvcGhwdW5pdD4K"));' || true)

migrations-php-set-phpunit-xsd-path-to-local: #### Ensure that the PHPUnit XDS referred in etc/qa/phpunit.xml points to vendor/phpunit/phpunit/phpunit.xsd so we don't go over the network ##*I*##
	($(DOCKER_RUN) php -r '$$phpUnitConfigFIle = "etc/qa/phpunit.xml"; if (!file_exists($$phpUnitConfigFIle)) {exit;} $$xml = file_get_contents($$phpUnitConfigFIle); if (!is_string($$xml)) {exit;} for ($$major = 0; $$major < 23; $$major++) { for ($$minor = 0; $$minor < 23; $$minor++) { $$xml = str_replace("https://schema.phpunit.de/" . $$major . "." . $$minor . "/phpunit.xsd", "../../vendor/phpunit/phpunit/phpunit.xsd", $$xml); } } file_put_contents($$phpUnitConfigFIle, $$xml);' || true)

migrations-php-move-phpstan: #### Move phpstan.neon to etc/qa/phpstan.neon ##*I*##
	($(DOCKER_RUN) mv phpstan.neon etc/qa/phpstan.neon || true)

migrations-php-set-phpstan-ensure-config-file-exists: #### Make sure we have a PHPStan config file at etc/qa/phpstan.neon ##*I*##
	($(DOCKER_RUN) php -r '$$phpStanConfigFIle = "etc/qa/phpstan.neon"; if (file_exists($$phpStanConfigFIle)) {exit;} file_put_contents($$phpStanConfigFIle, "#parameters:");' || true)

migrations-php-set-phpstan-uncomment-parameters: #### Ensure PHPStan config as parameters not commented out in etc/qa/phpstan.neon ##*I*##
	($(DOCKER_RUN) php -r '$$phpStanConfigFIle = "etc/qa/phpstan.neon"; if (!file_exists($$phpStanConfigFIle)) {exit;} $$neon = file_get_contents($$phpStanConfigFIle); if (!is_string($$neon)) {exit;} if (!str_starts_with($$neon, "#parameters:")) {exit;} $$neon = str_replace("#parameters:", "parameters:", $$neon); file_put_contents($$phpStanConfigFIle, $$neon);' || true)

migrations-php-set-phpstan-add-parameters-if-it-isnt-present-in-the-config-file: #### Add parameters to PHPStan config file at etc/qa/phpstan.neon if it's not present ##*I*##
	($(DOCKER_RUN) php -r '$$phpStanConfigFIle = "etc/qa/phpstan.neon"; if (!file_exists($$phpStanConfigFIle)) {exit;} $$neon = file_get_contents($$phpStanConfigFIle); if (!is_string($$neon)) {exit;} if (strpos($$neon, "parameters:") !== false) {exit;} file_put_contents($$phpStanConfigFIle, "parameters:", FILE_APPEND);' || true)

migrations-php-set-phpstan-paths-in-config: #### Ensure PHPStan config has the etc, src, and tests paths set in etc/qa/phpstan.neon ##*I*##
	($(DOCKER_RUN) php -r '$$phpStanConfigFIle = "etc/qa/phpstan.neon"; $$pathsString = "\n\tpaths:\n\t\t- ../../etc\n\t\t- ../../src\n\t\t- ../../tests"; if (!file_exists($$phpStanConfigFIle)) {exit;} $$neon = file_get_contents($$phpStanConfigFIle); if (!is_string($$neon)) {exit;} if (strpos($$neon, $$pathsString) !== false) {exit;} $$neon = str_replace("parameters:", "parameters:" . $$pathsString, $$neon); file_put_contents($$phpStanConfigFIle, $$neon);' || true)

migrations-php-set-phpstan-level-max-in-config: #### Ensure PHPStan config has level set to max in etc/qa/phpstan.neon ##*I*##
	($(DOCKER_RUN) php -r '$$phpStanConfigFIle = "etc/qa/phpstan.neon"; $$levelString = "\n\tlevel: max"; if (!file_exists($$phpStanConfigFIle)) {exit;} $$neon = file_get_contents($$phpStanConfigFIle); if (!is_string($$neon)) {exit;} if (strpos($$neon, $$levelString) !== false) {exit;} $$neon = str_replace("parameters:", "parameters:" . $$levelString, $$neon); file_put_contents($$phpStanConfigFIle, $$neon);' || true)

migrations-php-set-phpstan-resolve-ergebnis-noExtends-classesAllowedToBeExtended: #### Ensure PHPStan config uses ergebnis.noExtends.classesAllowedToBeExtended not ergebnis.classesAllowedToBeExtended ##*I*##
	($(DOCKER_RUN) php -r '$$phpStanConfigFIle = "etc/qa/phpstan.neon"; if (!file_exists($$phpStanConfigFIle)) {exit;} $$neon = file_get_contents($$phpStanConfigFIle); if (!is_string($$neon)) {exit;} $$neon = str_replace("\tergebnis:\n\t\tclassesAllowedToBeExtended:\n", "\tergebnis:\n\t\tnoExtends:\n\t\t\tclassesAllowedToBeExtended:\n", $$neon); file_put_contents($$phpStanConfigFIle, $$neon);' || true)

migrations-php-set-phpstan-drop-checkGenericClassInNonGenericObjectType: #### Ensure PHPStan config doesn't contain checkGenericClassInNonGenericObjectType as it's no longer a valid config option ##*I*##
	($(DOCKER_RUN) php -r '$$phpStanConfigFIle = "etc/qa/phpstan.neon"; if (!file_exists($$phpStanConfigFIle)) {exit;} $$neon = file_get_contents($$phpStanConfigFIle); if (!is_string($$neon)) {exit;} $$neon = str_replace("\tcheckGenericClassInNonGenericObjectType: false\n", "", $$neon); file_put_contents($$phpStanConfigFIle, $$neon);' || true)

migrations-php-phpstan-add-prefix-for-anything-that-starts-with-vendor-in-a-list: #### PHPStan add ../../ to anything in a list that starts with vendor ##*I*##
	($(DOCKER_RUN) php -r '$$phpStanConfigFIle = "etc/qa/phpstan.neon"; if (!file_exists($$phpStanConfigFIle)) {exit;} $$neon = file_get_contents($$phpStanConfigFIle); if (!is_string($$neon)) {exit;} $$neon = str_replace("- vendor", "- ../../vendor", $$neon); file_put_contents($$phpStanConfigFIle, $$neon);' || true)

migrations-php-set-phpstan-drop-include-test-utilities-rules: #### Ensure PHPStan config doesn't contain include for wyrihaximus/async-utilities/rules.neon as it's now an extension ##*I*##
	($(DOCKER_RUN) php -r '$$phpStanConfigFIle = "etc/qa/phpstan.neon"; if (!file_exists($$phpStanConfigFIle)) {exit;} $$neon = file_get_contents($$phpStanConfigFIle); if (!is_string($$neon)) {exit;} $$neon = str_replace("\nincludes:\n\t- ../../vendor/wyrihaximus/test-utilities/rules.neon\n", "", $$neon); file_put_contents($$phpStanConfigFIle, $$neon);' || true)

migrations-php-set-phpstan-drop-include-async-test-utilities-rules: #### Ensure PHPStan config doesn't contain include for wyrihaximus/async-test-utilities/rules.neon as it's now an extension ##*I*##
	($(DOCKER_RUN) php -r '$$phpStanConfigFIle = "etc/qa/phpstan.neon"; if (!file_exists($$phpStanConfigFIle)) {exit;} $$neon = file_get_contents($$phpStanConfigFIle); if (!is_string($$neon)) {exit;} $$neon = str_replace("\nincludes:\n\t- ../../vendor/wyrihaximus/async-test-utilities/rules.neon\n", "", $$neon); file_put_contents($$phpStanConfigFIle, $$neon);' || true)

migrations-php-set-rector-create-config-if-not-exists: #### Create Rector config file if it doesn't exists at etc/qa/rector.php ##*I*##
	($(DOCKER_RUN) php -r '$$rectorConfigFile = "etc/qa/rector.php"; $$defaultRectorConfig = "<?php declare(strict_types=1); use WyriHaximus\TestUtilities\RectorConfig; return RectorConfig::configure(dirname(__DIR__, 2));"; if (file_exists($$rectorConfigFile)) {exit;} file_put_contents($$rectorConfigFile, $$defaultRectorConfig);' || true)

migrations-php-composer-unused-create-config-if-not-exists: #### Create Composer Unused config file if it doesn't exists at etc/qa/composer-unused.php ##*I*##
	($(DOCKER_RUN) php -r '$$composerUnusedConfigFile = "etc/qa/composer-unused.php"; $$composerUnusedConfig = "<?php declare(strict_types=1); use ComposerUnused\ComposerUnused\Configuration\Configuration; return static function (Configuration \$$config): Configuration {return \$$config;};"; if (file_exists($$composerUnusedConfigFile)) {exit;} file_put_contents($$composerUnusedConfigFile, $$composerUnusedConfig);' || true)

migrations-php-composer-unused-drop-commented-out-line-scattered-across-my-repos: #### Update Composer Unused config file dropping a commented out line that is scattered cross my repos ##*I*##
	($(DOCKER_RUN) php -r '$$composerUnusedConfigFile = "etc/qa/composer-unused.php"; if (!file_exists($$composerUnusedConfigFile)) {exit;} $$php = file_get_contents($$composerUnusedConfigFile); if (!is_string($$php)) {exit;} $$php = str_replace(base64_decode("Ly8gICAgICAgIC0+YWRkTmFtZWRGaWx0ZXIoTmFtZWRGaWx0ZXI6OmZyb21TdHJpbmcoJ3d5cmloYXhpbXVzL3BocHN0YW4tcnVsZXMtd3JhcHBlcicpKTs="), "", $$php); file_put_contents($$composerUnusedConfigFile, $$php);' || true)

migrations-php-move-phpcs: #### Move phpcs.xml.dist to etc/qa/phpcs.xml ##*I*##
	($(DOCKER_RUN) mv phpcs.xml.dist etc/qa/phpcs.xml || true)

migrations-php-move-phpcs-not-dist: #### Move phpcs.xml to etc/qa/phpcs.xml ##*I*##
	($(DOCKER_RUN) mv phpcs.xml etc/qa/phpcs.xml || true)

migrations-php-set-phpcs-ensure-config-file-exists: #### Make sure we have a PHPCS config file at etc/qa/phpcs.xml ##*I*##
	($(DOCKER_RUN) php -r '$$phpcsConfigFile = "etc/qa/phpcs.xml"; if (file_exists($$phpcsConfigFile)) {exit;} file_put_contents($$phpcsConfigFile, base64_decode("PD94bWwgdmVyc2lvbj0iMS4wIj8+CjxydWxlc2V0PgogICAgPGFyZyBuYW1lPSJiYXNlcGF0aCIgdmFsdWU9Ii4uLy4uLyIgLz4KICAgIDxhcmcgbmFtZT0iZXh0ZW5zaW9ucyIgdmFsdWU9InBocCIgLz4gPCEtLSB3aGljaCBleHRlbnNpb25zIHRvIGxvb2sgZm9yIC0tPgogICAgPGFyZyBuYW1lPSJjb2xvcnMiIC8+CiAgICA8YXJnIG5hbWU9ImNhY2hlIiB2YWx1ZT0iLi4vLi4vdmFyLy5waHBjcy5jYWNoZSIgLz4gPCEtLSBjYWNoZSB0aGUgcmVzdWx0cyBhbmQgZG9uJ3QgY29tbWl0IHRoZW0gLS0+CiAgICA8YXJnIHZhbHVlPSJucCIgLz4gPCEtLSBuID0gaWdub3JlIHdhcm5pbmdzLCBwID0gc2hvdyBwcm9ncmVzcyAtLT4KCiAgICA8ZmlsZT4uLi8uLi9ldGM8L2ZpbGU+CiAgICA8ZmlsZT4uLi8uLi9zcmM8L2ZpbGU+CiAgICA8ZmlsZT4uLi8uLi90ZXN0czwvZmlsZT4KCiAgICA8cnVsZSByZWY9Ild5cmlIYXhpbXVzLU9TUyIgLz4KPC9ydWxlc2V0Pgo="));' || true)

migrations-php-phpcs-make-basepath-is-correct-relatively: #### Make sure PHPCS base path is has ../../ and not . ##*I*##
	($(DOCKER_RUN) php -r '$$phpcsConfigFile = "etc/qa/phpcs.xml"; if (!file_exists($$phpcsConfigFile)) {exit;} $$xml = file_get_contents($$phpcsConfigFile); if (!is_string($$xml)) {exit;} $$xml = str_replace("<arg name=\"basepath\" value=\".\" />", "<arg name=\"basepath\" value=\"../../\" />", $$xml); file_put_contents($$phpcsConfigFile, $$xml);' || true)

migrations-php-phpcs-make-cache-is-correct-relatively: #### Make sure PHPCS cache path is has ../../var/.phpcs.cache and not .phpcs.cache ##*I*##
	($(DOCKER_RUN) php -r '$$phpcsConfigFile = "etc/qa/phpcs.xml"; if (!file_exists($$phpcsConfigFile)) {exit;} $$xml = file_get_contents($$phpcsConfigFile); if (!is_string($$xml)) {exit;} $$xml = str_replace("<arg name=\"cache\" value=\".phpcs.cache\" />", "<arg name=\"cache\" value=\"../../var/.phpcs.cache\" />", $$xml); file_put_contents($$phpcsConfigFile, $$xml);' || true)

migrations-php-phpcs-make-sure-config-has-correct-relative-path-for-etc: #### Make sure PHPCS has ../../ prefixing etc/ to ensure correct relative path ##*I*##
	($(DOCKER_RUN) php -r '$$phpcsConfigFile = "etc/qa/phpcs.xml"; if (!file_exists($$phpcsConfigFile)) {exit;} $$xml = file_get_contents($$phpcsConfigFile); if (!is_string($$xml)) {exit;} $$xml = str_replace("<file>etc</file>", "<file>../../etc/</file>", $$xml); file_put_contents($$phpcsConfigFile, $$xml);' || true)

migrations-php-phpcs-make-sure-etc-has-no-trailing-slash: #### Make sure PHPCS has no tailing / on etc ##*I*##
	($(DOCKER_RUN) php -r '$$phpcsConfigFile = "etc/qa/phpcs.xml"; if (!file_exists($$phpcsConfigFile)) {exit;} $$xml = file_get_contents($$phpcsConfigFile); if (!is_string($$xml)) {exit;} $$xml = str_replace("<file>../../etc/</file>", "<file>../../etc</file>", $$xml); file_put_contents($$phpcsConfigFile, $$xml);' || true)

migrations-php-phpcs-make-sure-config-has-correct-relative-path-for-src: #### Make sure PHPCS has ../../ prefixing src/ to ensure correct relative path ##*I*##
	($(DOCKER_RUN) php -r '$$phpcsConfigFile = "etc/qa/phpcs.xml"; if (!file_exists($$phpcsConfigFile)) {exit;} $$xml = file_get_contents($$phpcsConfigFile); if (!is_string($$xml)) {exit;} $$xml = str_replace("<file>src</file>", "<file>../../src/</file>", $$xml); file_put_contents($$phpcsConfigFile, $$xml);' || true)

migrations-php-phpcs-make-sure-src-has-no-trailing-slash: #### Make sure PHPCS has no tailing / on src ##*I*##
	($(DOCKER_RUN) php -r '$$phpcsConfigFile = "etc/qa/phpcs.xml"; if (!file_exists($$phpcsConfigFile)) {exit;} $$xml = file_get_contents($$phpcsConfigFile); if (!is_string($$xml)) {exit;} $$xml = str_replace("<file>../../src/</file>", "<file>../../src</file>", $$xml); file_put_contents($$phpcsConfigFile, $$xml);' || true)

migrations-php-phpcs-make-sure-config-has-correct-relative-path-for-tests: #### Make sure PHPCS has ../../ prefixing tests/ to ensure correct relative path ##*I*##
	($(DOCKER_RUN) php -r '$$phpcsConfigFile = "etc/qa/phpcs.xml"; if (!file_exists($$phpcsConfigFile)) {exit;} $$xml = file_get_contents($$phpcsConfigFile); if (!is_string($$xml)) {exit;} $$xml = str_replace("<file>tests</file>", "<file>../../tests/</file>", $$xml); file_put_contents($$phpcsConfigFile, $$xml);' || true)

migrations-php-phpcs-make-sure-tests-has-no-trailing-slash: #### Make sure PHPCS has no tailing / on tests ##*I*##
	($(DOCKER_RUN) php -r '$$phpcsConfigFile = "etc/qa/phpcs.xml"; if (!file_exists($$phpcsConfigFile)) {exit;} $$xml = file_get_contents($$phpcsConfigFile); if (!is_string($$xml)) {exit;} $$xml = str_replace("<file>../../tests/</file>", "<file>../../tests</file>", $$xml); file_put_contents($$phpcsConfigFile, $$xml);' || true)

migrations-php-phpcs-make-sure-etc-is-ran-through: #### Make sure PHPCS runs through etc ##*I*##
	($(DOCKER_RUN) php -r '$$phpcsConfigFile = "etc/qa/phpcs.xml"; if (!file_exists($$phpcsConfigFile)) {exit;} $$xml = file_get_contents($$phpcsConfigFile); if (!is_string($$xml)) {exit;} if (strpos($$xml, "<file>../../etc</file>") !== false) {exit;} $$xml = str_replace("<file>../../src</file>", "<file>../../etc</file>\n    <file>../../src</file>", $$xml); file_put_contents($$phpcsConfigFile, $$xml);' || true)

migrations-php-move-composer-require-checker: #### Move composer-require-checker.json to etc/qa/composer-require-checker.json ##*I*##
	($(DOCKER_RUN) mv composer-require-checker.json etc/qa/composer-require-checker.json || true)

migrations-php-composer-require-checker-create-config-if-not-exists: #### Create Composer Require Checker config file if it doesn't exists at etc/qa/composer-require-checker.json ##*I*##
	($(DOCKER_RUN) php -r '$$composerRequireCheckerConfigFile = "etc/qa/composer-require-checker.json"; $$composerRequireCheckerConfig = base64_decode("ewogICJzeW1ib2wtd2hpdGVsaXN0IiA6IFsKICAgICJudWxsIiwgInRydWUiLCAiZmFsc2UiLAogICAgInN0YXRpYyIsICJzZWxmIiwgInBhcmVudCIsCiAgICAiYXJyYXkiLCAic3RyaW5nIiwgImludCIsICJmbG9hdCIsICJib29sIiwgIml0ZXJhYmxlIiwgImNhbGxhYmxlIiwgInZvaWQiLCAib2JqZWN0IgogIF0sCiAgInBocC1jb3JlLWV4dGVuc2lvbnMiIDogWwogICAgIkNvcmUiLAogICAgImRhdGUiLAogICAgInBjcmUiLAogICAgIlBoYXIiLAogICAgIlJlZmxlY3Rpb24iLAogICAgIlNQTCIsCiAgICAic3RhbmRhcmQiCiAgXSwKICAic2Nhbi1maWxlcyIgOiBbXQp9Cg=="); if (file_exists($$composerRequireCheckerConfigFile)) {exit;} file_put_contents($$composerRequireCheckerConfigFile, $$composerRequireCheckerConfig);' || true)

migrations-php-make-sure-github-exists: #### Make sure .github/ exists ##*I*##
	($(DOCKER_RUN) mkdir .github || true)

migrations-github-codeowners: #### Ensure a CODEOWNERS file is present, create only if it doesn't exist yet ##*I*##
	($(DOCKER_RUN) php -r '$$codeOwnersFile = ".github/CODEOWNERS"; if (file_exists($$codeOwnersFile)) {exit;} file_put_contents($$codeOwnersFile, "*       @WyriHaximus" . PHP_EOL);' || true)

migrations-php-make-sure-github-workflows-exists: #### Make sure .github/workflows exists ##*I*##
	($(DOCKER_RUN) mkdir .github/workflows || true)

migrations-github-actions-remove-composer-diff: #### Remove composer-diff.yaml it has been folded into centralized workflows through ci.yaml ##*I*##
	($(DOCKER_RUN) rm .github/workflows/composer-diff.yaml || true)

migrations-github-actions-remove-markdown-check-links: #### Remove markdown-check-links.yaml it has been folded into centralized workflows through ci.yaml ##*I*##
	($(DOCKER_RUN) rm .github/workflows/markdown-check-links.yaml || true)

migrations-github-actions-remove-markdown-craft-release: #### Remove craft-release.yaml it has been folded into centralized workflows through release-management.yaml ##*I*##
	($(DOCKER_RUN) rm .github/workflows/craft-release.yaml || true)

migrations-github-actions-remove-set-milestone-on-pr: #### Remove set-milestone-on-pr.yaml it has been folded into centralized workflows through release-management.yaml ##*I*##
	($(DOCKER_RUN) rm .github/workflows/set-milestone-on-pr.yaml || true)

migrations-github-actions-move-ci: #### Move .github/workflows/ci.yml to .github/workflows/ci.yaml ##*I*##
	($(DOCKER_RUN) mv .github/workflows/ci.yml .github/workflows/ci.yaml || true)

migrations-github-actions-remove-ci-if-its-old-style-php-ci-workflow: #### Remove CI Workflow if its the old style PHP CI Workflow ##*I*##
	($(DOCKER_RUN) php -r '$$ciWorkflowFile = ".github/workflows/ci.yaml"; if (!file_exists($$ciWorkflowFile)) {exit;} $$yaml = file_get_contents($$ciWorkflowFile); if (!is_string($$yaml)) {exit;} if (strpos($$yaml, "composer: [lowest, locked, highest]") !== false || strpos($$yaml, "composer: [lowest, current, highest]") !== false || strpos($$yaml, "- run: make ${{ matrix.check }}") !== false || strpos($$yaml, base64_decode("aWY6IG1hdHJpeC5jaGVjayA9PSAnYmFja3dhcmQtY29tcGF0aWJpbGl0eS1jaGVjayc=")) !== false) { unlink($$ciWorkflowFile); }' || true)

migrations-github-actions-create-ci-if-not-exists: #### Create CI Workflow if it doesn't exists at .github/workflows/ci.yaml ##*I*##
	($(DOCKER_RUN) php -r '$$ciWorkflowFile = ".github/workflows/ci.yaml"; $$ciWorkflowContents = base64_decode("bmFtZTogQ29udGludW91cyBJbnRlZ3JhdGlvbgpvbjoKICBwdXNoOgogICAgYnJhbmNoZXM6CiAgICAgIC0gJ21haW4nCiAgICAgIC0gJ21hc3RlcicKICAgICAgLSAncmVmcy9oZWFkcy92WzAtOV0rLlswLTldKy5bMC05XSsnCiAgcHVsbF9yZXF1ZXN0OgojIyBUaGlzIHdvcmtmbG93IG5lZWRzIHRoZSBgcHVsbC1yZXF1ZXN0YCBwZXJtaXNzaW9ucyB0byB3b3JrIGZvciB0aGUgcGFja2FnZSBkaWZmaW5nCiMjIFJlZnM6IGh0dHBzOi8vZG9jcy5naXRodWIuY29tL2VuL2FjdGlvbnMvcmVmZXJlbmNlL3dvcmtmbG93LXN5bnRheC1mb3ItZ2l0aHViLWFjdGlvbnMjcGVybWlzc2lvbnMKcGVybWlzc2lvbnM6CiAgcHVsbC1yZXF1ZXN0czogd3JpdGUKICBjb250ZW50czogcmVhZApqb2JzOgogIGNpOgogICAgbmFtZTogQ29udGludW91cyBJbnRlZ3JhdGlvbgogICAgdXNlczogV3lyaUhheGltdXMvZ2l0aHViLXdvcmtmbG93cy8uZ2l0aHViL3dvcmtmbG93cy9wYWNrYWdlLnlhbWxAbWFpbgo="); if (file_exists($$ciWorkflowFile)) {exit;} file_put_contents($$ciWorkflowFile, $$ciWorkflowContents);' || true)

migrations-github-actions-move-release-management: #### Move .github/workflows/release-managment.yaml to .github/workflows/release-management.yaml ##*I*##
	($(DOCKER_RUN) mv .github/workflows/release-managment.yaml .github/workflows/release-management.yaml || true)

migrations-github-actions-fix-management-in-release-management-referenced-workflow-file: #### Fix management in release-management referenced workflow file ##*I*##
	($(DOCKER_RUN) sed -i -e 's/release-managment.yaml/release-management.yaml/g' .github/workflows/release-management.yaml || true)

migrations-github-actions-create-release-management-if-not-exists: #### Create Release Management Workflow if it doesn't exists at .github/workflows/release-management.yaml ##*I*##
	($(DOCKER_RUN) php -r '$$releaseManagementWorkflowFile = ".github/workflows/release-management.yaml"; $$releaseManagementWorkflowContents = base64_decode("bmFtZTogUmVsZWFzZSBNYW5hZ2VtZW50Cm9uOgogIHB1bGxfcmVxdWVzdDoKICAgIHR5cGVzOgogICAgICAtIG9wZW5lZAogICAgICAtIGxhYmVsZWQKICAgICAgLSB1bmxhYmVsZWQKICAgICAgLSBzeW5jaHJvbml6ZQogICAgICAtIHJlb3BlbmVkCiAgICAgIC0gbWlsZXN0b25lZAogICAgICAtIGRlbWlsZXN0b25lZAogICAgICAtIHJlYWR5X2Zvcl9yZXZpZXcKICBtaWxlc3RvbmU6CiAgICB0eXBlczoKICAgICAgLSBjbG9zZWQKcGVybWlzc2lvbnM6CiAgY29udGVudHM6IHdyaXRlCiAgaXNzdWVzOiB3cml0ZQogIHB1bGwtcmVxdWVzdHM6IHdyaXRlCmpvYnM6CiAgcmVsZWFzZS1tYW5hZ21lbnQ6CiAgICBuYW1lOiBSZWxlYXNlIE1hbmFnZW1lbnQKICAgIHVzZXM6IFd5cmlIYXhpbXVzL2dpdGh1Yi13b3JrZmxvd3MvLmdpdGh1Yi93b3JrZmxvd3MvcGFja2FnZS1yZWxlYXNlLW1hbmFnZW1lbnQueWFtbEBtYWluCiAgICB3aXRoOgogICAgICBtaWxlc3RvbmU6ICR7eyBnaXRodWIuZXZlbnQubWlsZXN0b25lLnRpdGxlIH19CiAgICAgIGRlc2NyaXB0aW9uOiAke3sgZ2l0aHViLmV2ZW50Lm1pbGVzdG9uZS50aXRsZSB9fQo="); if (file_exists($$releaseManagementWorkflowFile)) {exit;} file_put_contents($$releaseManagementWorkflowFile, $$releaseManagementWorkflowContents);' || true)

migrations-renovate-remove-dependabot-config: #### Make sure we remove .github/dependabot.yml ##*I*##
	($(DOCKER_RUN) rm .github/dependabot.yml || true)
	($(DOCKER_RUN) rm .github/dependabot.yaml || true)

migrations-renovate-move-config: #### Move renovate.json to .github/renovate.json ##*I*##
	($(DOCKER_RUN) mv renovate.json .github/renovate.json || true)

migrations-renovate-create-config-if-not-exists: #### Create Renovate Config if it doesn't exists at .github/renovate.json ##*I*##
	($(DOCKER_RUN) php -r '$$renovateConfigFile = ".github/renovate.json"; $$renovateConfigContents = base64_decode("ewogICIkc2NoZW1hIjogImh0dHBzOi8vZG9jcy5yZW5vdmF0ZWJvdC5jb20vcmVub3ZhdGUtc2NoZW1hLmpzb24iLAogICJleHRlbmRzIjogWwogICAgImdpdGh1Yj5XeXJpSGF4aW11cy9yZW5vdmF0ZS1jb25maWc6cGhwLXBhY2thZ2UiCiAgXQp9Cg=="); if (file_exists($$renovateConfigFile)) {exit;} file_put_contents($$renovateConfigFile, $$renovateConfigContents);' || true)

migrations-renovate-point-at-correct-config: #### Ensure .github/renovate.json points at github>WyriHaximus/renovate-config:php-package instead of local>WyriHaximus/renovate-config ##*I*##
	($(DOCKER_RUN) php -r '$$renovateFIle = ".github/renovate.json"; if (!file_exists($$renovateFIle)) {exit;} file_put_contents($$renovateFIle, str_replace("local>WyriHaximus/renovate-config", "github>WyriHaximus/renovate-config:php-package", file_get_contents($$renovateFIle)));' || true)


## Our default jobs

on-install-or-update: ## Runs everything ####
	((shell command -v sponge >/dev/null 2>&1) && (sh -c '$(shell printf "%s %s" $(MAKE) $(shell cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' | grep -E "##\*(I|ILH)\*##" | awk 'BEGIN {FS = ":.*?## "}; {printf "%s\n", $$1}' | sponge | tr '\r\n' '_') | tr '_' ' ')') || (grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -E "##\*(I|ILH)\*##" | awk 'BEGIN {FS = ":.*?## "}; {printf "%s\n", $$1}' | xargs -o $(MAKE)))

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

