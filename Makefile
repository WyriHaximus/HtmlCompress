# set all to phony
SHELL=bash

.PHONY: *

ifneq (,$(findstring icrosoft,$(shell cat /proc/version)))
    THREADS?=1
else
    THREADS?=$(shell nproc)
endif
DOCKER_AVAILABLE=$(shell ((command -v docker >/dev/null 2>&1) && echo 0 || echo 1))
TTY_AVAILABLE=$(shell (test -t 1 && echo 0) || echo 1)
CONTAINER_REGISTRY_REPO="ghcr.io/wyrihaximusnet/php"
SLIM_DOCKER_IMAGE="-slim"
NTS_OR_ZTS_DOCKER_IMAGE="nts"
OTEL_PHP_FIBERS_ENABLED?=true
NEEDS_DOCKER_SOCKET=FALSE
HAS_EXTRA_SERVICES=FALSE
ALL_HAS_DIRECT_DOCKER_TASKS=FALSE
CONTRIB_HAS_DIRECT_DOCKER_TASKS=FALSE
ON_INSTALL_OR_UPDATE_HAS_DIRECT_DOCKER_TASKS=FALSE
PHP_VERSION="8.4"
CONTAINER_NAME=$(shell echo "${CONTAINER_REGISTRY_REPO}:${PHP_VERSION}-${NTS_OR_ZTS_DOCKER_IMAGE}-alpine${SLIM_DOCKER_IMAGE}-dev")
CONTAINER_NAME_INTERACTIVE_SHELL=$(shell echo "${CONTAINER_REGISTRY_REPO}:${PHP_VERSION}-zts-alpine-dev")
COMPOSER_CACHE_DIR=$(shell (command -v composer >/dev/null 2>&1) && composer config --global cache-dir -q 2>/dev/null || echo ${HOME}/.composer-php/cache)
COMPOSER_CONTAINER_CACHE_DIR=$(shell ((command -v docker >/dev/null 2>&1) && docker run --rm $(if $(filter 0,$(TTY_AVAILABLE)),-it,-i) ${CONTAINER_NAME} composer config --global cache-dir -q) || echo ${HOME}/.composer-php/cache)

ifneq ("$(wildcard /.you-are-in-a-wyrihaximus.net-php-docker-image)","")
    IN_DOCKER=TRUE
else
    IN_DOCKER=FALSE
endif

ifeq ("$(GITHUB_ACTIONS)","true")
    IN_CI=TRUE
else
    IN_CI=FALSE
endif

ifeq ("$(IN_CI)","TRUE")
    MUTATION_THREADS?=1
else
    MUTATION_THREADS?=$(THREADS)
endif

ifeq ("$(IN_DOCKER)","TRUE")
	DOCKER_RUN:=
	DOCKER_RUN_WITHOUT_NETWORK_FOR_COMPOSER:=
	DOCKER_RUN_WITH_SOCKET:=
	DOCKER_SHELL:=
	DOCKER_INTERACTIVE_SHELL:=
else
    ifeq ($(DOCKER_AVAILABLE),0)
        DOCKER_DEFAULT_SECURITY_OPS=--cap-drop=ALL --security-opt="no-new-privileges=true" --user="`id -u`:`id -g`"
        DOCKER_COMMON_OPS:=-v "`pwd`:`pwd`" -w "`pwd`" -v "`pwd`/.git:`pwd`/.git:ro" -v "${COMPOSER_CACHE_DIR}:${COMPOSER_CONTAINER_CACHE_DIR}" --ulimit nofile=1000000 -e THREADS="${THREADS}" -e MUTATION_THREADS="${MUTATION_THREADS}" -e OTEL_PHP_DISABLED_INSTRUMENTATIONS="all"
        ifneq ("$(wildcard etc/qa/zzz_disable_otel_attr_hooks.ini)","")
            DOCKER_COMMON_OPS:=${DOCKER_COMMON_OPS} -v "`pwd`/etc/qa/zzz_disable_otel_attr_hooks.ini:/usr/local/etc/php/conf.d/zzz_disable_otel_attr_hooks.ini:ro"
        endif
        DOCKER_COMMON_NON_INTERACTIVE_OPS:=-e OTEL_PHP_FIBERS_ENABLED="${OTEL_PHP_FIBERS_ENABLED}"
        DOCKER_COMMON_INTERACTIVE_OPS:=-e OTEL_PHP_FIBERS_ENABLED="false"
        ifeq ("$(NEEDS_DOCKER_SOCKET)","TRUE")
            ifneq ("$(wildcard /var/run/docker.sock)","")
                DOCKER_SECURITY_OPS:=
                DOCKER_SOCKET_OPS:=-v "/var/run/docker.sock:/var/run/docker.sock"
                DOCKER_SOCKET_CONTAINER_NAME_SUFFIX:=-root
            else
                DOCKER_SECURITY_OPS:=${DOCKER_DEFAULT_SECURITY_OPS}
                DOCKER_SOCKET_OPS:=
                DOCKER_SOCKET_CONTAINER_NAME_SUFFIX:=
            endif
        else
            DOCKER_SECURITY_OPS:=${DOCKER_DEFAULT_SECURITY_OPS}
            DOCKER_SOCKET_OPS:=
            DOCKER_SOCKET_CONTAINER_NAME_SUFFIX:=
        endif
        DOCKER_RUN:=docker run --rm -i ${DOCKER_SECURITY_OPS} ${DOCKER_COMMON_NON_INTERACTIVE_OPS} ${DOCKER_COMMON_OPS} "${CONTAINER_NAME}"
        DOCKER_RUN_WITHOUT_NETWORK_FOR_COMPOSER:=docker run --rm -i ${DOCKER_SECURITY_OPS} ${DOCKER_COMMON_NON_INTERACTIVE_OPS} -e COMPOSER_DISABLE_NETWORK="1" ${DOCKER_COMMON_OPS} "${CONTAINER_NAME}"
        DOCKER_RUN_WITH_SOCKET:=docker run --rm -i ${DOCKER_SECURITY_OPS} ${DOCKER_COMMON_NON_INTERACTIVE_OPS} ${DOCKER_COMMON_OPS} ${DOCKER_SOCKET_OPS} "${CONTAINER_NAME}${DOCKER_SOCKET_CONTAINER_NAME_SUFFIX}"
        ifeq ($(TTY_AVAILABLE),0)
            DOCKER_SHELL:=docker run --rm -it ${DOCKER_SECURITY_OPS} ${DOCKER_COMMON_NON_INTERACTIVE_OPS} ${DOCKER_COMMON_OPS} "${CONTAINER_NAME}"
            DOCKER_INTERACTIVE_SHELL:=docker run --rm -it ${DOCKER_SECURITY_OPS} ${DOCKER_COMMON_INTERACTIVE_OPS} ${DOCKER_COMMON_OPS} "${CONTAINER_NAME_INTERACTIVE_SHELL}"
        else
            DOCKER_SHELL:=$(DOCKER_RUN)
            DOCKER_INTERACTIVE_SHELL:=docker run --rm -i ${DOCKER_SECURITY_OPS} ${DOCKER_COMMON_INTERACTIVE_OPS} ${DOCKER_COMMON_OPS} "${CONTAINER_NAME_INTERACTIVE_SHELL}"
        endif
    else
        DOCKER_RUN:=
        DOCKER_RUN_WITHOUT_NETWORK_FOR_COMPOSER:=
        DOCKER_RUN_WITH_SOCKET:=
        DOCKER_SHELL:=
		DOCKER_INTERACTIVE_SHELL:=
    endif
endif

## Run everything extra points
all: ## Runs everything ####
ifeq ("$(ALL_HAS_DIRECT_DOCKER_TASKS)","TRUE")
	$(MAKE) all-raw
else
	$(DOCKER_RUN_WITH_SOCKET) make all-raw
endif
all-raw: ## The real runs everything, but due to sponge it has to be ran inside DOCKER_RUN ##U##
	$(MAKE) composer-validate syntax-php composer-normalize rector-upgrade cs-fix cs stan unit-testing mutation-testing composer-require-checker composer-unused backward-compatibility-check ## Count: 12


## Run a subset of everything for those that find everything intimidating
contrib: ## Runs a subset of everything (all) ####
ifeq ("$(CONTRIB_HAS_DIRECT_DOCKER_TASKS)","TRUE")
	$(MAKE) contrib-raw
else
	$(DOCKER_RUN_WITH_SOCKET) make contrib-raw
endif
contrib-raw: ## The real runs everything, but due to sponge it has to be ran inside DOCKER_RUN ##U##
	$(MAKE) cs-fix cs unit-testing composer-require-checker composer-unused ## Count: 5


## Temporary set of migrations to get all my repos in shape
migrations-git-enforce-gitattributes-contents: #### Enforce `.gitattributes` contents ##*I*##
	($(DOCKER_RUN) php -r 'file_put_contents(".gitattributes", base64_decode("IyBTZXQgdGhlIGRlZmF1bHQgYmVoYXZpb3IsIGluIGNhc2UgcGVvcGxlIGRvbid0IGhhdmUgY29yZS5hdXRvY3JsZiBzZXQuCiogdGV4dCBlb2w9bGYKCiMgVGhlc2UgZmlsZXMgYXJlIGJpbmFyeSBhbmQgc2hvdWxkIGJlIGxlZnQgdW50b3VjaGVkCiMgKGJpbmFyeSBpcyBhIG1hY3JvIGZvciAtdGV4dCAtZGlmZikKKi5wbmcgYmluYXJ5CiouanBnIGJpbmFyeQoqLmpwZWcgYmluYXJ5CiouZ2lmIGJpbmFyeQoqLmljbyBiaW5hcnkKKi53ZWJwIGJpbmFyeQoqLmJtcCBiaW5hcnkKKi50dGYgYmluYXJ5CiouYmxwIGJpbmFyeQoqLmRiMiBiaW5hcnkKCiMgSWdub3JpbmcgZmlsZXMgZm9yIGRpc3RyaWJ1dGlvbiBhcmNoaWV2ZXMKLmdpdGh1Yi8gZXhwb3J0LWlnbm9yZQpldGMvY2kvIGV4cG9ydC1pZ25vcmUKZXRjL2Rldi1hcHAvIGV4cG9ydC1pZ25vcmUKZXRjL3N0YXRlLyBleHBvcnQtaWdub3JlCmV0Yy9xYS8gZXhwb3J0LWlnbm9yZQpleGFtcGxlcy8gZXhwb3J0LWlnbm9yZQp0ZXN0cy8gZXhwb3J0LWlnbm9yZQp2YXIvIGV4cG9ydC1pZ25vcmUKLmRldmNvbnRhaW5lci5qc29uIGV4cG9ydC1pZ25vcmUKLmVkaXRvcmNvbmZpZyBleHBvcnQtaWdub3JlCi5naXRhdHRyaWJ1dGVzIGV4cG9ydC1pZ25vcmUKLmdpdGlnbm9yZSBleHBvcnQtaWdub3JlCkNPTlRSSUJVVElORy5tZCBleHBvcnQtaWdub3JlCmNvbXBvc2VyLmxvY2sgZXhwb3J0LWlnbm9yZQpNYWtlZmlsZSBleHBvcnQtaWdub3JlClJFQURNRS5tZCBleHBvcnQtaWdub3JlCgojIERpZmZpbmcKKi5waHAgZGlmZj1waHAK"));' || true)

migrations-git-enforce-editorconfig-contents: #### Enforce `.editorconfig` contents ##*I*##
	($(DOCKER_RUN) php -r 'file_put_contents(".editorconfig", base64_decode("cm9vdCA9IHRydWUKClsqXQpjaGFyc2V0ID0gdXRmLTgKaW5kZW50X3N0eWxlID0gc3BhY2UKaW5kZW50X3NpemUgPSA0Cmluc2VydF9maW5hbF9uZXdsaW5lID0gdHJ1ZQp0cmltX3RyYWlsaW5nX3doaXRlc3BhY2UgPSB0cnVlCgpbKi5qc29uXQppbmRlbnRfc2l6ZSA9IDIKClsqLnltbF0KaW5kZW50X3NpemUgPSAyCgpbKi55YW1sXQppbmRlbnRfc2l6ZSA9IDIKCltNYWtlZmlsZV0KaW5kZW50X3N0eWxlID0gdGFiCgpbKi5ta10KaW5kZW50X3N0eWxlID0gdGFiCgpbKi5uZW9uXQppbmRlbnRfc3R5bGUgPSB0YWIK"));' || true)

migrations-git-make-sure-gitignore-exists: #### Make sure `.gitignore` exists ##*I*##
	($(DOCKER_RUN) touch .gitignore || true)

migrations-git-make-sure-gitignore-ignores-var: #### Make sure `.gitignore` ignores `var/*` ##*I*##
	($(DOCKER_RUN) php -r '$$gitignoreFile = ".gitignore"; if (!file_exists($$gitignoreFile)) {exit;} $$txt = file_get_contents($$gitignoreFile); if (!is_string($$txt)) {exit;} if (strpos($$txt, "var/*") !== false) {exit;} file_put_contents($$gitignoreFile, "var/*\n", FILE_APPEND);' || true)

migrations-git-make-sure-gitignore-excludes-var-gitkeep: #### Make sure `.gitignore` excludes `var/.gitkeep` ##*I*##
	($(DOCKER_RUN) php -r '$$gitignoreFile = ".gitignore"; if (!file_exists($$gitignoreFile)) {exit;} $$txt = file_get_contents($$gitignoreFile); if (!is_string($$txt)) {exit;} if (strpos($$txt, "!var/.gitkeep") !== false) {exit;} file_put_contents($$gitignoreFile, "!var/.gitkeep\n", FILE_APPEND);' || true)

migrations-docs-update-readme-copyright-c-year-to-current: #### Update readme copyright year to current ##*I*##
	($(DOCKER_RUN) php -r '$$readmeFile = "README.md"; $$copyRight = "Copyright (c) "; $$currentYear = date("Y"); if (!file_exists($$readmeFile)) {exit;} $$readmeContents = file_get_contents($$readmeFile); foreach (range(2000, 2100) as $$year) { $$readmeContents = str_replace($$copyRight . $$year,  $$copyRight . $$currentYear, $$readmeContents); } file_put_contents($$readmeFile, $$readmeContents); ' || true)

migrations-docs-update-readme-copyright-year-to-current: #### Update readme copyright year to current ##*I*##
	($(DOCKER_RUN) php -r '$$readmeFile = "README.md"; $$copyRight = "Copyright "; $$currentYear = date("Y"); if (!file_exists($$readmeFile)) {exit;} $$readmeContents = file_get_contents($$readmeFile); foreach (range(2000, 2100) as $$year) { $$readmeContents = str_replace($$copyRight . $$year,  $$copyRight . $$currentYear, $$readmeContents); } file_put_contents($$readmeFile, $$readmeContents); ' || true)

migrations-docs-update-etc-readme-template-copyright-c-year-to-current: #### Update readme template in etc/ copyright year to current ##*I*##
	($(DOCKER_RUN) php -r '$$readmeFile = "etc/README.md.twig"; $$copyRight = "Copyright (c) "; $$currentYear = date("Y"); if (!file_exists($$readmeFile)) {exit;} $$readmeContents = file_get_contents($$readmeFile); foreach (range(2000, 2100) as $$year) { $$readmeContents = str_replace($$copyRight . $$year,  $$copyRight . $$currentYear, $$readmeContents); } file_put_contents($$readmeFile, $$readmeContents); ' || true)

migrations-docs-update-etc-readme-template-copyright-year-to-current: #### Update readme template in etc/ copyright year to current ##*I*##
	($(DOCKER_RUN) php -r '$$readmeFile = "etc/README.md.twig"; $$copyRight = "Copyright "; $$currentYear = date("Y"); if (!file_exists($$readmeFile)) {exit;} $$readmeContents = file_get_contents($$readmeFile); foreach (range(2000, 2100) as $$year) { $$readmeContents = str_replace($$copyRight . $$year,  $$copyRight . $$currentYear, $$readmeContents); } file_put_contents($$readmeFile, $$readmeContents); ' || true)

migrations-docs-create-license-when-it-doesnt-exists: #### Create license when it doesn't exists ##*I*##
	($(DOCKER_RUN) php -r '$$licenseFile = "LICENSE"; $$composerFIle = "composer.json"; if (file_exists($$licenseFile)) {exit;} if (file_exists($$composerFIle)) {$$json = json_decode(file_get_contents($$composerFIle), true); if (array_key_exists("license", $$json)) {if ($$json["license"] === "proprietary") {exit;}}}  file_put_contents($$licenseFile, base64_decode("VGhlIE1JVCBMaWNlbnNlIChNSVQpCgpDb3B5cmlnaHQgKGMpIDIwMDEgQ2Vlcy1KYW4gS2lld2lldAoKUGVybWlzc2lvbiBpcyBoZXJlYnkgZ3JhbnRlZCwgZnJlZSBvZiBjaGFyZ2UsIHRvIGFueSBwZXJzb24gb2J0YWluaW5nIGEgY29weQpvZiB0aGlzIHNvZnR3YXJlIGFuZCBhc3NvY2lhdGVkIGRvY3VtZW50YXRpb24gZmlsZXMgKHRoZSAiU29mdHdhcmUiKSwgdG8gZGVhbAppbiB0aGUgU29mdHdhcmUgd2l0aG91dCByZXN0cmljdGlvbiwgaW5jbHVkaW5nIHdpdGhvdXQgbGltaXRhdGlvbiB0aGUgcmlnaHRzCnRvIHVzZSwgY29weSwgbW9kaWZ5LCBtZXJnZSwgcHVibGlzaCwgZGlzdHJpYnV0ZSwgc3VibGljZW5zZSwgYW5kL29yIHNlbGwKY29waWVzIG9mIHRoZSBTb2Z0d2FyZSwgYW5kIHRvIHBlcm1pdCBwZXJzb25zIHRvIHdob20gdGhlIFNvZnR3YXJlIGlzCmZ1cm5pc2hlZCB0byBkbyBzbywgc3ViamVjdCB0byB0aGUgZm9sbG93aW5nIGNvbmRpdGlvbnM6CgpUaGUgYWJvdmUgY29weXJpZ2h0IG5vdGljZSBhbmQgdGhpcyBwZXJtaXNzaW9uIG5vdGljZSBzaGFsbCBiZSBpbmNsdWRlZCBpbiBhbGwKY29waWVzIG9yIHN1YnN0YW50aWFsIHBvcnRpb25zIG9mIHRoZSBTb2Z0d2FyZS4KClRIRSBTT0ZUV0FSRSBJUyBQUk9WSURFRCAiQVMgSVMiLCBXSVRIT1VUIFdBUlJBTlRZIE9GIEFOWSBLSU5ELCBFWFBSRVNTIE9SCklNUExJRUQsIElOQ0xVRElORyBCVVQgTk9UIExJTUlURUQgVE8gVEhFIFdBUlJBTlRJRVMgT0YgTUVSQ0hBTlRBQklMSVRZLApGSVRORVNTIEZPUiBBIFBBUlRJQ1VMQVIgUFVSUE9TRSBBTkQgTk9OSU5GUklOR0VNRU5ULiBJTiBOTyBFVkVOVCBTSEFMTCBUSEUKQVVUSE9SUyBPUiBDT1BZUklHSFQgSE9MREVSUyBCRSBMSUFCTEUgRk9SIEFOWSBDTEFJTSwgREFNQUdFUyBPUiBPVEhFUgpMSUFCSUxJVFksIFdIRVRIRVIgSU4gQU4gQUNUSU9OIE9GIENPTlRSQUNULCBUT1JUIE9SIE9USEVSV0lTRSwgQVJJU0lORyBGUk9NLApPVVQgT0YgT1IgSU4gQ09OTkVDVElPTiBXSVRIIFRIRSBTT0ZUV0FSRSBPUiBUSEUgVVNFIE9SIE9USEVSIERFQUxJTkdTIElOIFRIRQpTT0ZUV0FSRS4K"));' || true)

migrations-docs-update-license-copyright-c-year-to-current: #### Update license copyright year to current ##*I*##
	($(DOCKER_RUN) php -r '$$licenseFile = "LICENSE"; $$copyRight = "Copyright (c) "; $$currentYear = date("Y"); if (!file_exists($$licenseFile)) {exit;} $$licenseContents = file_get_contents($$licenseFile); foreach (range(2000, 2100) as $$year) { $$licenseContents = str_replace($$copyRight . $$year,  $$copyRight . $$currentYear, $$licenseContents); } file_put_contents($$licenseFile, $$licenseContents); ' || true)

migrations-docs-update-license-copyright-year-to-current: #### Update license copyright year to current ##*I*##
	($(DOCKER_RUN) php -r '$$licenseFile = "LICENSE"; $$copyRight = "Copyright "; $$currentYear = date("Y"); if (!file_exists($$licenseFile)) {exit;} $$licenseContents = file_get_contents($$licenseFile); foreach (range(2000, 2100) as $$year) { $$licenseContents = str_replace($$copyRight . $$year,  $$copyRight . $$currentYear, $$licenseContents); } file_put_contents($$licenseFile, $$licenseContents); ' || true)

migrations-docs-enforce-contributing-md-contents: #### Enforce CONTRIBUTING.md contents ##*I*##
	($(DOCKER_RUN) php -r '$$contributingFile = "CONTRIBUTING.md"; $$contributingContents = base64_decode("IyBDb250cmlidXRpbmcKClB1bGwgcmVxdWVzdHMgYXJlIGhpZ2hseSBhcHByZWNpYXRlZC4gSGVyZSdzIGEgcXVpY2sgZ3VpZGUuCgpGb3JrLCB0aGVuIGNsb25lIHRoZSByZXBvOgoKICAgIGdpdCBjbG9uZSBnaXRAZ2l0aHViLmNvbTp5b3VyLXVzZXJuYW1lL1tyZXBvXS5naXQKCkluc3RhbGwgZGVwZW5kZW5jaWVzOgoKICAgIG1ha2UgaW5zdGFsbAoKV29yayBvbiB0aGUgY29udHJpYnV0aW9uIGFuZCBjaGVjayBpZiBpdCBwYXNzZXMgYWxsIFFBIGNoZWNrcyB3aXRoOgoKICAgIG1ha2UKCklmIHNvbWUgb2YgdGhlIFBIUFN0YW4gb3Igb3RoZXIgY2hlY2tzIGFyZSB0byBzdHJpY3Qgb3IgaW50aW1pZGF0aW5nIHRoYXQgaXMgZmluZSwgZmluaXNoIHdoYXQgeW91IHdhbnQgdG8gY29udHJpYnV0ZSBhbmQgSSdsbCBoZWxwIHlvdSB3aXRoIHRob3NlLCBidXQgcGxlYXNlIG1ha2UgdGhlIGZvbGxvd2luZyBjb21tYW5kIHBhc3Nlcy4gSXQgcnVucyBhIHN1YnNldCBvZiBldmVyeXRoaW5nOgoKICAgIG1ha2UgY29udHJpYgoKWW91IGNhbiBsaXN0IGFsbCB0aGUgY29udHJpYiBjb21tYW5kcyB3aXRoOgoKICAgIG1ha2UgaGVscC1jb250cmliCgpQdXNoIHRvIHlvdXIgZm9yayBhbmQgW3N1Ym1pdCBhIHB1bGwgcmVxdWVzdF1bcHJdLgoKW3ByXTogaHR0cHM6Ly9kb2NzLmdpdGh1Yi5jb20vZW4vcHVsbC1yZXF1ZXN0cy9jb2xsYWJvcmF0aW5nLXdpdGgtcHVsbC1yZXF1ZXN0cy9wcm9wb3NpbmctY2hhbmdlcy10by15b3VyLXdvcmstd2l0aC1wdWxsLXJlcXVlc3RzL2NyZWF0aW5nLWEtcHVsbC1yZXF1ZXN0CgpDb250cmlidXRpbmcgd2l0aCBhbiBMTE0/IFRoaXMgcmVwbyBpbmNsdWRlcyBhbiBbYEFHRU5UUy5tZGBdKEFHRU5UUy5tZCkgd2l0aCBndWlkYW5jZSBmb3IgY29kaW5nIGFnZW50czsgcG9pbnRpbmcgeW91ciBhZ2VudCBhdCBpdCBoZWxwcyBhIGxvdC4gQmVmb3JlIHlvdSBvcGVuIGEgUFIsIHNraW0gdGhyb3VnaCB5b3VyIGNoYW5nZXMgc28geW91IGZlZWwgY29tZm9ydGFibGUgd2l0aCBldmVyeXRoaW5nIHlvdSdyZSBzdWJtaXR0aW5nLgo="); file_put_contents($$contributingFile, str_replace(["[repo]"], [basename(__DIR__)], $$contributingContents)); ' || true)

migrations-php-make-sure-var-exists: #### Make sure `var/` exists ##*I*##
	($(DOCKER_RUN) mkdir var || true)

migrations-php-make-sure-var-gitkeep-exists: #### Make sure `var/.gitkeep` exists ##*I*##
	($(DOCKER_RUN) touch var/.gitkeep || true)

migrations-php-make-sure-etc-exists: #### Make sure `etc/` exists ##*I*##
	($(DOCKER_RUN) mkdir etc || true)

migrations-php-make-sure-etc-ci-exists: #### Make sure `etc/ci/` exists ##*I*##
	($(DOCKER_RUN) mkdir etc/ci || true)

migrations-php-make-sure-etc-qa-exists: #### Make sure `etc/qa/` exists ##*I*##
	($(DOCKER_RUN) mkdir etc/qa || true)

migrations-php-move-psalm-xml-config-to-etc: #### Move `psalm.xml` to `etc/qa/psalm.xml` ##*I*##
	($(DOCKER_RUN) mv psalm.xml etc/qa/psalm.xml || true)

migrations-php-remove-psalm-xml-config: #### Make sure we remove `etc/qa/psalm.xml` ##*I*##
	($(DOCKER_RUN) rm etc/qa/psalm.xml || true)

migrations-php-remove-old-phpunit-xml-dist-config: #### Make sure we remove `phpunit.xml.dist` ##*I*##
	($(DOCKER_RUN) rm phpunit.xml.dist || true)

migrations-php-remove-old-phpunit-xml-config: #### Make sure we remove `phpunit.xml` ##*I*##
	($(DOCKER_RUN) rm phpunit.xml || true)

migrations-php-remove-old-php-cs-fiver-config: #### Make sure we remove `.php_cs` ##*I*##
	($(DOCKER_RUN) rm .php_cs || true)

migrations-php-remove-old-scrutinizer-yml-config: #### Make sure we remove `.scrutinizer.yml` ##*I*##
	($(DOCKER_RUN) rm .scrutinizer.yml || true)

migrations-php-remove-old-appveyor-yml-config: #### Make sure we remove `appveyor.yml` ##*I*##
	($(DOCKER_RUN) rm appveyor.yml || true)

migrations-php-remove-old-travis-yml-config: #### Make sure we remove `.travis.yml` ##*I*##
	($(DOCKER_RUN) rm .travis.yml || true)

migrations-php-ensure-etc-ci-markdown-link-checker-json-exists: #### Make sure we have `etc/ci/markdown-link-checker.json` ##*I*##
	($(DOCKER_RUN) php -r '$$markdownLinkCheckerFile = "etc/ci/markdown-link-checker.json"; $$json = json_decode("{\"httpHeaders\": [{\"urls\": [\"https://docs.github.com/\"],\"headers\": {\"Accept-Encoding\": \"zstd, br, gzip, deflate\"}}]}"); if (file_exists($$markdownLinkCheckerFile)) {exit;} file_put_contents($$markdownLinkCheckerFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\r\n");' || true)

migrations-php-ensure-etc-qa-coverage-guard-php-exists: #### Make sure we have `etc/qa/coverage-guard.php` ##*I*##
	($(DOCKER_RUN) php -r '$$coverageGuardFile = "etc/qa/coverage-guard.php"; $$coverageGuardConfig = base64_decode("PD9waHAKCmRlY2xhcmUoc3RyaWN0X3R5cGVzPTEpOwoKdXNlIFNoaXBNb25rXENvdmVyYWdlR3VhcmRcQ29uZmlnOwp1c2UgU2hpcE1vbmtcQ292ZXJhZ2VHdWFyZFxFeGNsdWRlclxJZ25vcmVUaHJvd05ld0V4Y2VwdGlvbkxpbmVFeGNsdWRlcjsKdXNlIFNoaXBNb25rXENvdmVyYWdlR3VhcmRcUnVsZVxFbmZvcmNlQ292ZXJhZ2VGb3JNZXRob2RzUnVsZTsKCnJldHVybiAoc3RhdGljIGZ1bmN0aW9uICgpOiBDb25maWcgewogICAgJGNvbmZpZyA9IG5ldyBDb25maWcoKTsKCiAgICAkY29uZmlnLT5hZGRSdWxlKG5ldyBFbmZvcmNlQ292ZXJhZ2VGb3JNZXRob2RzUnVsZSgKICAgICAgICByZXF1aXJlZENvdmVyYWdlUGVyY2VudGFnZTogMTAwLAogICAgICAgIG1pbkV4ZWN1dGFibGVMaW5lczogMSwKICAgICkpOwoKICAgICRjb25maWctPmFkZEV4ZWN1dGFibGVMaW5lRXhjbHVkZXIobmV3IElnbm9yZVRocm93TmV3RXhjZXB0aW9uTGluZUV4Y2x1ZGVyKFsKICAgICAgICBSdW50aW1lRXhjZXB0aW9uOjpjbGFzcywKICAgIF0pKTsKCiAgICByZXR1cm4gJGNvbmZpZzsKfSkoKTsK"); if (file_exists($$coverageGuardFile)) {exit;} file_put_contents($$coverageGuardFile, $$coverageGuardConfig);' || true)

migrations-php-ensure-etc-qa-zzz-disable-otel-attr-hooks-ini-exists: #### Make sure we have `etc/qa/zzz_disable_otel_attr_hooks.ini` ##*I*##
	($(DOCKER_RUN) php -r '$$otelAttrHooksIniFile = "etc/qa/zzz_disable_otel_attr_hooks.ini"; $$otelAttrHooksIniContents = base64_decode("OyBBdm9pZCB6ZW5kX21tX2hlYXAgY29ycnVwdGlvbiB3aXRoICNbV2l0aFNwYW5dIChtYW1tYXR1cyB1c2VzIGhvb2soKSBpbnN0ZWFkKS4KOyBTZWU6IGh0dHBzOi8vZ2l0aHViLmNvbS9vcGVuLXRlbGVtZXRyeS9vcGVudGVsZW1ldHJ5LXBocC1pbnN0cnVtZW50YXRpb24vcHVsbC8zMjEKOyBBbHJlYWR5IHNvbHZlZDogaHR0cHM6Ly9naXRodWIuY29tL29wZW4tdGVsZW1ldHJ5L29wZW50ZWxlbWV0cnktcGhwLWluc3RydW1lbnRhdGlvbi9wdWxsLzMxMwpvcGVudGVsZW1ldHJ5LmF0dHJfaG9va3NfZW5hYmxlZD1PZmYK"); if (file_exists($$otelAttrHooksIniFile)) {exit;} file_put_contents($$otelAttrHooksIniFile, $$otelAttrHooksIniContents);' || true)

migrations-php-move-infection-config-to-etc: #### Move `infection.json.dist` to `etc/qa/infection.json5` ##*I*##
	($(DOCKER_RUN) mv infection.json.dist etc/qa/infection.json5 || true)

migrations-php-infection-create-config-if-not-exists: #### Create Infection config file if it doesn't exists at `etc/qa/infection.json5` ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; $$infectionConfig = base64_decode("ewogICAgInRpbWVvdXQiOiAxMjAsCiAgICAic291cmNlIjogewogICAgICAgICJkaXJlY3RvcmllcyI6IFsKICAgICAgICAgICAgInNyYyIKICAgICAgICBdCiAgICB9LAogICAgImxvZ3MiOiB7CiAgICAgICAgInRleHQiOiAiLi4vLi4vdmFyL2luZmVjdGlvbi5sb2ciLAogICAgICAgICJzdW1tYXJ5IjogIi4uLy4uL3Zhci9pbmZlY3Rpb24tc3VtbWFyeS5sb2ciLAogICAgICAgICJqc29uIjogIi4uLy4uL3Zhci9pbmZlY3Rpb24uanNvbiIsCiAgICAgICAgInBlck11dGF0b3IiOiAiLi4vLi4vdmFyL2luZmVjdGlvbi1wZXItbXV0YXRvci5tZCIsCiAgICAgICAgImdpdGh1YiI6IHRydWUKICAgIH0sCiAgICAibWluTXNpIjogMTAwLAogICAgIm1pbkNvdmVyZWRNc2kiOiAxMDAsCiAgICAiaWdub3JlTXNpV2l0aE5vTXV0YXRpb25zIjogdHJ1ZSwKICAgICJtdXRhdG9ycyI6IHsKICAgICAgICAiQGRlZmF1bHQiOiB0cnVlCiAgICB9Cn0K"); if (file_exists($$infectionFile)) {exit;} file_put_contents($$infectionFile, $$infectionConfig);' || true)

migrations-php-remove-phpunit-config-dir-from-infection: #### Drop XXX from `etc/qa/infection.json5` ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("phpUnit", $$json)) {exit;} unset($$json["phpUnit"]); file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\r\n");' || true)

migrations-php-fix-logs-relative-paths-for-infection: #### Fix logs paths in `etc/qa/infection.json5` ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("logs", $$json)) {exit;} foreach ($$json["logs"] as $$logsKey => $$logsPath) { if (is_string($$json["logs"][$$logsKey]) && str_starts_with($$json["logs"][$$logsKey], "./var/infection")) { $$json["logs"][$$logsKey] = str_replace("./var/infection", "../../var/infection", $$json["logs"][$$logsKey]); } } file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\r\n");' || true)

migrations-php-infection-ensure-log-text-has-the-correct-path: #### Ensure infection's log.text has config directive has the correct path ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("logs", $$json)) { $$json["logs"] = []; } $$json["logs"]["text"] = "../../var/infection.log"; file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\r\n");' || true)

migrations-php-infection-ensure-log-summary-has-the-correct-path: #### Ensure infection's log.summary has config directive has the correct path ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("logs", $$json)) { $$json["logs"] = []; } $$json["logs"]["summary"] = "../../var/infection-summary.log"; file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\r\n");' || true)

migrations-php-infection-ensure-log-json-has-the-correct-path: #### Ensure infection's log.json has config directive has the correct path ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("logs", $$json)) { $$json["logs"] = []; } $$json["logs"]["json"] = "../../var/infection.json"; file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\r\n");' || true)

migrations-php-infection-ensure-log-per-mutator-has-the-correct-path: #### Ensure infection's log.perMutator has config directive has the correct path ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("logs", $$json)) { $$json["logs"] = []; } $$json["logs"]["perMutator"] = "../../var/infection-per-mutator.md"; file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\r\n");' || true)

migrations-php-add-github-true-to-for-infection: #### Ensure we configure infection to emit logs to GitHub in `etc/qa/infection.json5` ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("logs", $$json)) {exit;} if (array_key_exists("github", $$json["logs"])) {exit;} $$json["logs"]["github"] = true; file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\r\n");' || true)

migrations-php-make-paths-compatible-with-infection-0-32: #### We update path to be relative to `etc/qa/infection.json5` as of 0.32 ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("source", $$json)) {exit;} if (!array_key_exists("directories", $$json["source"])) {exit;} foreach ($$json["source"]["directories"] as $$key => $$value) { if (!str_starts_with($$value, "../../")) {$$json["source"]["directories"][$$key] = "../../" . $$value;} } file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\r\n");' || true)

migrations-php-set-phpunit-ensure-config-file-exists: #### Make sure we have a PHPUnit config file at `etc/qa/phpunit.xml` ##*I*##
	($(DOCKER_RUN) php -r '$$phpUnitConfigFIle = "etc/qa/phpunit.xml"; if (file_exists($$phpUnitConfigFIle)) {exit;} file_put_contents($$phpUnitConfigFIle, base64_decode("PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHBocHVuaXQKICAgIHhtbG5zOnhzaT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiCiAgICBib290c3RyYXA9Ii4uLy4uL3ZlbmRvci9hdXRvbG9hZC5waHAiCiAgICBjb2xvcnM9InRydWUiCiAgICB4c2k6bm9OYW1lc3BhY2VTY2hlbWFMb2NhdGlvbj0iLi4vLi4vdmVuZG9yL3BocHVuaXQvcGhwdW5pdC9waHB1bml0LnhzZCIKICAgIGNhY2hlRGlyZWN0b3J5PSIuLi8uLi92YXIvcGhwdW5pdC9jYWNoZSIKICAgIGRpc3BsYXlEZXRhaWxzT25UZXN0c1RoYXRUcmlnZ2VyRGVwcmVjYXRpb25zPSJ0cnVlIgogICAgZGlzcGxheURldGFpbHNPblRlc3RzVGhhdFRyaWdnZXJFcnJvcnM9InRydWUiCiAgICBkaXNwbGF5RGV0YWlsc09uVGVzdHNUaGF0VHJpZ2dlck5vdGljZXM9InRydWUiCiAgICBkaXNwbGF5RGV0YWlsc09uVGVzdHNUaGF0VHJpZ2dlcldhcm5pbmdzPSJ0cnVlIgogICAgZGlzcGxheURldGFpbHNPblBocHVuaXREZXByZWNhdGlvbnM9InRydWUiCj4KICAgIDx0ZXN0c3VpdGVzPgogICAgICAgIDx0ZXN0c3VpdGUgbmFtZT0iVGVzdCBTdWl0ZSI+CiAgICAgICAgICAgIDxkaXJlY3Rvcnk+Li4vLi4vdGVzdHMvPC9kaXJlY3Rvcnk+CiAgICAgICAgPC90ZXN0c3VpdGU+CiAgICA8L3Rlc3RzdWl0ZXM+CiAgICA8c291cmNlPgogICAgICAgIDxpbmNsdWRlPgogICAgICAgICAgICA8ZGlyZWN0b3J5IHN1ZmZpeD0iLnBocCI+Li4vLi4vc3JjLzwvZGlyZWN0b3J5PgogICAgICAgIDwvaW5jbHVkZT4KICAgIDwvc291cmNlPgogICAgPGNvdmVyYWdlPgogICAgICAgIDxyZXBvcnQ+CiAgICAgICAgICAgIDxjbG92ZXIgb3V0cHV0RmlsZT0iLi4vLi4vdmFyL3Rlc3RzL3VuaXQvY2xvdmVyLWNvdmVyYWdlLnhtbCIvPgogICAgICAgICAgICA8aHRtbCBvdXRwdXREaXJlY3Rvcnk9Ii4uLy4uL3Zhci90ZXN0cy91bml0L2NvdmVyYWdlLWh0bWwiLz4KICAgICAgICA8L3JlcG9ydD4KICAgIDwvY292ZXJhZ2U+CiAgICA8ZXh0ZW5zaW9ucz4KICAgICAgICA8Ym9vdHN0cmFwIGNsYXNzPSJFcmdlYm5pc1xQSFBVbml0XFNsb3dUZXN0RGV0ZWN0b3JcRXh0ZW5zaW9uIi8+CiAgICA8L2V4dGVuc2lvbnM+CjwvcGhwdW5pdD4K"));' || true)

migrations-php-set-phpunit-xsd-path-to-local: #### Ensure that the PHPUnit XDS referred in `etc/qa/phpunit.xml` points to `vendor/phpunit/phpunit/phpunit.xsd` so we don't go over the network ##*I*##
	($(DOCKER_RUN) php -r '$$phpUnitConfigFIle = "etc/qa/phpunit.xml"; if (!file_exists($$phpUnitConfigFIle)) {exit;} $$xml = file_get_contents($$phpUnitConfigFIle); if (!is_string($$xml)) {exit;} for ($$major = 0; $$major < 23; $$major++) { for ($$minor = 0; $$minor < 23; $$minor++) { $$xml = str_replace("https://schema.phpunit.de/" . $$major . "." . $$minor . "/phpunit.xsd", "../../vendor/phpunit/phpunit/phpunit.xsd", $$xml); } } file_put_contents($$phpUnitConfigFIle, $$xml);' || true)

migrations-php-set-phpunit-make-sure-we-see-all-the-warnings-deprecations-etc-etc-that-will-make-phpunit-do-a-non-happy-exit: #### Make sure we see all the warnings, deprecations, etc etc that will make PHPunit do a non-happy exit ##*I*##
	($(DOCKER_RUN) php -r '$$phpUnitConfigFIle = "etc/qa/phpunit.xml"; if (!file_exists($$phpUnitConfigFIle)) {exit;} $$xml = file_get_contents($$phpUnitConfigFIle); if (!is_string($$xml)) {exit;} $$xml = str_replace(base64_decode("PHBocHVuaXQgeG1sbnM6eHNpPSJodHRwOi8vd3d3LnczLm9yZy8yMDAxL1hNTFNjaGVtYS1pbnN0YW5jZSIgYm9vdHN0cmFwPSIuLi8uLi92ZW5kb3IvYXV0b2xvYWQucGhwIiBjb2xvcnM9InRydWUiIHhzaTpub05hbWVzcGFjZVNjaGVtYUxvY2F0aW9uPSIuLi8uLi92ZW5kb3IvcGhwdW5pdC9waHB1bml0L3BocHVuaXQueHNkIiBjYWNoZURpcmVjdG9yeT0iLi4vLi4vdmFyL3BocHVuaXQvY2FjaGUiPgo="), base64_decode("PHBocHVuaXQKICAgIHhtbG5zOnhzaT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiCiAgICBib290c3RyYXA9Ii4uLy4uL3ZlbmRvci9hdXRvbG9hZC5waHAiCiAgICBjb2xvcnM9InRydWUiCiAgICB4c2k6bm9OYW1lc3BhY2VTY2hlbWFMb2NhdGlvbj0iLi4vLi4vdmVuZG9yL3BocHVuaXQvcGhwdW5pdC9waHB1bml0LnhzZCIKICAgIGNhY2hlRGlyZWN0b3J5PSIuLi8uLi92YXIvcGhwdW5pdC9jYWNoZSIKICAgIGRpc3BsYXlEZXRhaWxzT25UZXN0c1RoYXRUcmlnZ2VyRGVwcmVjYXRpb25zPSJ0cnVlIgogICAgZGlzcGxheURldGFpbHNPblRlc3RzVGhhdFRyaWdnZXJFcnJvcnM9InRydWUiCiAgICBkaXNwbGF5RGV0YWlsc09uVGVzdHNUaGF0VHJpZ2dlck5vdGljZXM9InRydWUiCiAgICBkaXNwbGF5RGV0YWlsc09uVGVzdHNUaGF0VHJpZ2dlcldhcm5pbmdzPSJ0cnVlIgogICAgZGlzcGxheURldGFpbHNPblBocHVuaXREZXByZWNhdGlvbnM9InRydWUiCj4K"), $$xml); file_put_contents($$phpUnitConfigFIle, $$xml);' || true)

migrations-php-move-phpstan: #### Move `phpstan.neon` to `etc/qa/phpstan.neon` ##*I*##
	($(DOCKER_RUN) mv phpstan.neon etc/qa/phpstan.neon || true)

migrations-php-set-phpstan-ensure-config-file-exists: #### Make sure we have a PHPStan config file at `etc/qa/phpstan.neon` ##*I*##
	($(DOCKER_RUN) php -r '$$phpStanConfigFIle = "etc/qa/phpstan.neon"; if (file_exists($$phpStanConfigFIle)) {exit;} file_put_contents($$phpStanConfigFIle, "#parameters:");' || true)

migrations-php-set-phpstan-uncomment-parameters: #### Ensure PHPStan config as parameters not commented out in `etc/qa/phpstan.neon` ##*I*##
	($(DOCKER_RUN) php -r '$$phpStanConfigFIle = "etc/qa/phpstan.neon"; if (!file_exists($$phpStanConfigFIle)) {exit;} $$neon = file_get_contents($$phpStanConfigFIle); if (!is_string($$neon)) {exit;} if (!str_starts_with($$neon, "#parameters:")) {exit;} $$neon = str_replace("#parameters:", "parameters:", $$neon); file_put_contents($$phpStanConfigFIle, $$neon);' || true)

migrations-php-set-phpstan-add-parameters-if-it-isnt-present-in-the-config-file: #### Add parameters to PHPStan config file at `etc/qa/phpstan.neon` if it's not present ##*I*##
	($(DOCKER_RUN) php -r '$$phpStanConfigFIle = "etc/qa/phpstan.neon"; if (!file_exists($$phpStanConfigFIle)) {exit;} $$neon = file_get_contents($$phpStanConfigFIle); if (!is_string($$neon)) {exit;} if (strpos($$neon, "parameters:") !== false) {exit;} file_put_contents($$phpStanConfigFIle, "parameters:", FILE_APPEND);' || true)

migrations-php-set-phpstan-paths-in-config: #### Ensure PHPStan config has the `etc`, `src`, and (optionally) `tests` paths set in `etc/qa/phpstan.neon` ##*I*##
	($(DOCKER_RUN) php -r '$$phpStanConfigFIle = "etc/qa/phpstan.neon"; $$pathsString = "\n\tpaths:\n\t\t- ../../etc\n\t\t- ../../src\n\t\t- ../../tests"; $$pathsStringWithoutTests = "\n\tpaths:\n\t\t- ../../etc\n\t\t- ../../src"; if (!file_exists($$phpStanConfigFIle)) {exit;} $$neon = file_get_contents($$phpStanConfigFIle); if (!is_string($$neon)) {exit;} if (strpos($$neon, $$pathsString) !== false || strpos($$neon, $$pathsStringWithoutTests) !== false) {exit;} $$neon = str_replace("parameters:", "parameters:" . $$pathsString, $$neon); file_put_contents($$phpStanConfigFIle, $$neon);' || true)

migrations-php-set-phpstan-level-max-in-config: #### Ensure PHPStan config has level set to max in `etc/qa/phpstan.neon` ##*I*##
	($(DOCKER_RUN) php -r '$$phpStanConfigFIle = "etc/qa/phpstan.neon"; $$levelString = "\n\tlevel: max"; if (!file_exists($$phpStanConfigFIle)) {exit;} $$neon = file_get_contents($$phpStanConfigFIle); if (!is_string($$neon)) {exit;} if (strpos($$neon, $$levelString) !== false) {exit;} $$neon = str_replace("parameters:", "parameters:" . $$levelString, $$neon); file_put_contents($$phpStanConfigFIle, $$neon);' || true)

migrations-php-set-phpstan-resolve-ergebnis-noExtends-classesAllowedToBeExtended: #### Ensure PHPStan config uses ergebnis.noExtends.classesAllowedToBeExtended not ergebnis.classesAllowedToBeExtended ##*I*##
	($(DOCKER_RUN) php -r '$$phpStanConfigFIle = "etc/qa/phpstan.neon"; if (!file_exists($$phpStanConfigFIle)) {exit;} $$neon = file_get_contents($$phpStanConfigFIle); if (!is_string($$neon)) {exit;} $$neon = str_replace("\tergebnis:\n\t\tclassesAllowedToBeExtended:\n", "\tergebnis:\n\t\tnoExtends:\n\t\t\tclassesAllowedToBeExtended:\n", $$neon); file_put_contents($$phpStanConfigFIle, $$neon);' || true)

migrations-php-set-phpstan-drop-checkGenericClassInNonGenericObjectType: #### Ensure PHPStan config doesn't contain checkGenericClassInNonGenericObjectType as it's no longer a valid config option ##*I*##
	($(DOCKER_RUN) php -r '$$phpStanConfigFIle = "etc/qa/phpstan.neon"; if (!file_exists($$phpStanConfigFIle)) {exit;} $$neon = file_get_contents($$phpStanConfigFIle); if (!is_string($$neon)) {exit;} $$neon = str_replace("\tcheckGenericClassInNonGenericObjectType: false\n", "", $$neon); file_put_contents($$phpStanConfigFIle, $$neon);' || true)

migrations-php-phpstan-add-prefix-for-anything-that-starts-with-vendor-in-a-list: #### PHPStan add `../../` to anything in a list that starts with `vendor` ##*I*##
	($(DOCKER_RUN) php -r '$$phpStanConfigFIle = "etc/qa/phpstan.neon"; if (!file_exists($$phpStanConfigFIle)) {exit;} $$neon = file_get_contents($$phpStanConfigFIle); if (!is_string($$neon)) {exit;} $$neon = str_replace("- vendor", "- ../../vendor", $$neon); file_put_contents($$phpStanConfigFIle, $$neon);' || true)

migrations-php-set-phpstan-drop-include-test-utilities-rules: #### Ensure PHPStan config doesn't contain include for `wyrihaximus/async-utilities/rules.neon` as it's now an extension ##*I*##
	($(DOCKER_RUN) php -r '$$phpStanConfigFIle = "etc/qa/phpstan.neon"; if (!file_exists($$phpStanConfigFIle)) {exit;} $$neon = file_get_contents($$phpStanConfigFIle); if (!is_string($$neon)) {exit;} $$neon = str_replace("\nincludes:\n\t- ../../vendor/wyrihaximus/test-utilities/rules.neon\n", "", $$neon); file_put_contents($$phpStanConfigFIle, $$neon);' || true)

migrations-php-set-phpstan-drop-include-async-test-utilities-rules: #### Ensure PHPStan config doesn't contain include for `wyrihaximus/async-test-utilities/rules.neon` as it's now an extension ##*I*##
	($(DOCKER_RUN) php -r '$$phpStanConfigFIle = "etc/qa/phpstan.neon"; if (!file_exists($$phpStanConfigFIle)) {exit;} $$neon = file_get_contents($$phpStanConfigFIle); if (!is_string($$neon)) {exit;} $$neon = str_replace("\nincludes:\n\t- ../../vendor/wyrihaximus/async-test-utilities/rules.neon", "", $$neon); file_put_contents($$phpStanConfigFIle, $$neon);' || true)

migrations-php-set-rector-create-config-if-not-exists: #### Create Rector config file if it doesn't exists at `etc/qa/rector.php` ##*I*##
	($(DOCKER_RUN) php -r '$$rectorConfigFile = "etc/qa/rector.php"; $$defaultRectorConfig = base64_decode("PD9waHAKCmRlY2xhcmUoc3RyaWN0X3R5cGVzPTEpOwoKdXNlIFd5cmlIYXhpbXVzXFJlY3RvclBIUFxSZWN0b3JDb25maWc7CgpyZXR1cm4gUmVjdG9yQ29uZmlnOjpjb25maWd1cmUoZGlybmFtZShfX0RJUl9fLCAyKSk7Cg=="); if (file_exists($$rectorConfigFile)) {exit;} file_put_contents($$rectorConfigFile, $$defaultRectorConfig);' || true)

migrations-php-update-rector-from-testutilities-to-rectorphp-namespace-for-rector-config: #### Update RectorPHP config file `etc/qa/rector.php` from `TestUtilities` to `RectorPHP` namespace ##*I*##
	($(DOCKER_RUN) php -r '$$rectorConfigFile = "etc/qa/rector.php"; if (!file_exists($$rectorConfigFile)) {exit;} file_put_contents($$rectorConfigFile, str_replace("use WyriHaximus\\TestUtilities\\RectorConfig;", "use WyriHaximus\\RectorPHP\\RectorConfig;", file_get_contents($$rectorConfigFile)));' || true)

migrations-php-composer-unused-create-config-if-not-exists: #### Create Composer Unused config file if it doesn't exists at `etc/qa/composer-unused.php` ##*I*##
	($(DOCKER_RUN) php -r '$$composerUnusedConfigFile = "etc/qa/composer-unused.php"; $$composerUnusedConfig = "<?php declare(strict_types=1); use ComposerUnused\ComposerUnused\Configuration\Configuration; return static function (Configuration \$$config): Configuration {return \$$config;};"; if (file_exists($$composerUnusedConfigFile)) {exit;} file_put_contents($$composerUnusedConfigFile, $$composerUnusedConfig);' || true)

migrations-php-composer-unused-drop-commented-out-line-scattered-across-my-repos: #### Update Composer Unused config file dropping a commented out line that is scattered cross my repos ##*I*##
	($(DOCKER_RUN) php -r '$$composerUnusedConfigFile = "etc/qa/composer-unused.php"; if (!file_exists($$composerUnusedConfigFile)) {exit;} $$php = file_get_contents($$composerUnusedConfigFile); if (!is_string($$php)) {exit;} $$php = str_replace(base64_decode("Ly8gICAgICAgIC0+YWRkTmFtZWRGaWx0ZXIoTmFtZWRGaWx0ZXI6OmZyb21TdHJpbmcoJ3d5cmloYXhpbXVzL3BocHN0YW4tcnVsZXMtd3JhcHBlcicpKTsK"), "", $$php); file_put_contents($$composerUnusedConfigFile, $$php);' || true)

migrations-php-migrate-composer-unused-from-extra-unused-to-etc-qa-composer-used-php: #### Migrate Compose Unused from `composer.json` extra unused to `etc/qa/composer-unused.php` ##*I*##
	($(DOCKER_RUN) php -r '$$composerJsonFile = "composer.json"; $$composerUnusedFile = "etc/qa/composer-unused.php"; if (!file_exists($$composerJsonFile)) {exit;} $$json = json_decode(file_get_contents($$composerJsonFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("extra", $$json)) {exit;} if (!array_key_exists("unused", $$json["extra"])) {exit;} foreach ($$json["extra"]["unused"] as $$unusedPAckage) { file_put_contents($$composerUnusedFile, str_replace(base64_decode("cmV0dXJuIHN0YXRpYyBmbiAoQ29uZmlndXJhdGlvbiAkY29uZmlnKTogQ29uZmlndXJhdGlvbiA9PiAkY29uZmlnCg=="), base64_decode("cmV0dXJuIHN0YXRpYyBmbiAoQ29uZmlndXJhdGlvbiAkY29uZmlnKTogQ29uZmlndXJhdGlvbiA9PiAkY29uZmlnCg==") . "\r\n" . base64_decode("ICAgIC0+YWRkTmFtZWRGaWx0ZXIoXENvbXBvc2VyVW51c2VkXENvbXBvc2VyVW51c2VkXENvbmZpZ3VyYXRpb25cTmFtZWRGaWx0ZXI6OmZyb21TdHJpbmcoJwo=") . $$unusedPAckage . base64_decode("Jykp"), file_get_contents($$composerUnusedFile))); } unset($$json["extra"]["unused"]); file_put_contents($$composerJsonFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\r\n");' || true)

migrations-php-move-phpcs: #### Move `phpcs.xml.dist` to `etc/qa/phpcs.xml` ##*I*##
	($(DOCKER_RUN) mv phpcs.xml.dist etc/qa/phpcs.xml || true)

migrations-php-move-phpcs-not-dist: #### Move `phpcs.xml` to `etc/qa/phpcs.xml` ##*I*##
	($(DOCKER_RUN) mv phpcs.xml etc/qa/phpcs.xml || true)

migrations-php-set-phpcs-ensure-config-file-exists: #### Make sure we have a PHPCS config file at `etc/qa/phpcs.xml` ##*I*##
	($(DOCKER_RUN) php -r '$$phpcsConfigFile = "etc/qa/phpcs.xml"; if (file_exists($$phpcsConfigFile)) {exit;} file_put_contents($$phpcsConfigFile, base64_decode("PD94bWwgdmVyc2lvbj0iMS4wIj8+CjxydWxlc2V0PgogICAgPGFyZyBuYW1lPSJiYXNlcGF0aCIgdmFsdWU9Ii4uLy4uLyIgLz4KICAgIDxhcmcgbmFtZT0iZXh0ZW5zaW9ucyIgdmFsdWU9InBocCIgLz4gPCEtLSB3aGljaCBleHRlbnNpb25zIHRvIGxvb2sgZm9yIC0tPgogICAgPGFyZyBuYW1lPSJjb2xvcnMiIC8+CiAgICA8YXJnIG5hbWU9ImNhY2hlIiB2YWx1ZT0iLi4vLi4vdmFyLy5waHBjcy5jYWNoZSIgLz4gPCEtLSBjYWNoZSB0aGUgcmVzdWx0cyBhbmQgZG9uJ3QgY29tbWl0IHRoZW0gLS0+CiAgICA8YXJnIHZhbHVlPSJucCIgLz4gPCEtLSBuID0gaWdub3JlIHdhcm5pbmdzLCBwID0gc2hvdyBwcm9ncmVzcyAtLT4KCiAgICA8ZmlsZT4uLi8uLi9ldGM8L2ZpbGU+CiAgICA8ZmlsZT4uLi8uLi9zcmM8L2ZpbGU+CiAgICA8ZmlsZT4uLi8uLi90ZXN0czwvZmlsZT4KCiAgICA8cnVsZSByZWY9Ild5cmlIYXhpbXVzLU9TUyIgLz4KPC9ydWxlc2V0Pgo="));' || true)

migrations-php-phpcs-make-basepath-is-correct-relatively: #### Make sure PHPCS base path is has `../../` and not `.` ##*I*##
	($(DOCKER_RUN) php -r '$$phpcsConfigFile = "etc/qa/phpcs.xml"; if (!file_exists($$phpcsConfigFile)) {exit;} $$xml = file_get_contents($$phpcsConfigFile); if (!is_string($$xml)) {exit;} $$xml = str_replace("<arg name=\"basepath\" value=\".\" />", "<arg name=\"basepath\" value=\"../../\" />", $$xml); file_put_contents($$phpcsConfigFile, $$xml);' || true)

migrations-php-phpcs-make-cache-is-correct-relatively: #### Make sure PHPCS cache path is has `../../var/.phpcs.cache` and not `.phpcs.cache` ##*I*##
	($(DOCKER_RUN) php -r '$$phpcsConfigFile = "etc/qa/phpcs.xml"; if (!file_exists($$phpcsConfigFile)) {exit;} $$xml = file_get_contents($$phpcsConfigFile); if (!is_string($$xml)) {exit;} $$xml = str_replace("<arg name=\"cache\" value=\".phpcs.cache\" />", "<arg name=\"cache\" value=\"../../var/.phpcs.cache\" />", $$xml); file_put_contents($$phpcsConfigFile, $$xml);' || true)

migrations-php-phpcs-make-sure-config-has-correct-relative-path-for-etc: #### Make sure PHPCS has `../../` prefixing `etc/` to ensure correct relative path ##*I*##
	($(DOCKER_RUN) php -r '$$phpcsConfigFile = "etc/qa/phpcs.xml"; if (!file_exists($$phpcsConfigFile)) {exit;} $$xml = file_get_contents($$phpcsConfigFile); if (!is_string($$xml)) {exit;} $$xml = str_replace("<file>etc</file>", "<file>../../etc/</file>", $$xml); file_put_contents($$phpcsConfigFile, $$xml);' || true)

migrations-php-phpcs-make-sure-etc-has-no-trailing-slash: #### Make sure PHPCS has no tailing `/` on `etc` ##*I*##
	($(DOCKER_RUN) php -r '$$phpcsConfigFile = "etc/qa/phpcs.xml"; if (!file_exists($$phpcsConfigFile)) {exit;} $$xml = file_get_contents($$phpcsConfigFile); if (!is_string($$xml)) {exit;} $$xml = str_replace("<file>../../etc/</file>", "<file>../../etc</file>", $$xml); file_put_contents($$phpcsConfigFile, $$xml);' || true)

migrations-php-phpcs-make-sure-config-has-correct-relative-path-for-src: #### Make sure PHPCS has `../../` prefixing `src/` to ensure correct relative path ##*I*##
	($(DOCKER_RUN) php -r '$$phpcsConfigFile = "etc/qa/phpcs.xml"; if (!file_exists($$phpcsConfigFile)) {exit;} $$xml = file_get_contents($$phpcsConfigFile); if (!is_string($$xml)) {exit;} $$xml = str_replace("<file>src</file>", "<file>../../src/</file>", $$xml); file_put_contents($$phpcsConfigFile, $$xml);' || true)

migrations-php-phpcs-make-sure-src-has-no-trailing-slash: #### Make sure PHPCS has no tailing `/` on src ##*I*##
	($(DOCKER_RUN) php -r '$$phpcsConfigFile = "etc/qa/phpcs.xml"; if (!file_exists($$phpcsConfigFile)) {exit;} $$xml = file_get_contents($$phpcsConfigFile); if (!is_string($$xml)) {exit;} $$xml = str_replace("<file>../../src/</file>", "<file>../../src</file>", $$xml); file_put_contents($$phpcsConfigFile, $$xml);' || true)

migrations-php-phpcs-make-sure-config-has-correct-relative-path-for-tests: #### Make sure PHPCS has `../../` prefixing `tests/` to ensure correct relative path ##*I*##
	($(DOCKER_RUN) php -r '$$phpcsConfigFile = "etc/qa/phpcs.xml"; if (!file_exists($$phpcsConfigFile)) {exit;} $$xml = file_get_contents($$phpcsConfigFile); if (!is_string($$xml)) {exit;} $$xml = str_replace("<file>tests</file>", "<file>../../tests/</file>", $$xml); file_put_contents($$phpcsConfigFile, $$xml);' || true)

migrations-php-phpcs-make-sure-tests-has-no-trailing-slash: #### Make sure PHPCS has no tailing `/` on `tests` ##*I*##
	($(DOCKER_RUN) php -r '$$phpcsConfigFile = "etc/qa/phpcs.xml"; if (!file_exists($$phpcsConfigFile)) {exit;} $$xml = file_get_contents($$phpcsConfigFile); if (!is_string($$xml)) {exit;} $$xml = str_replace("<file>../../tests/</file>", "<file>../../tests</file>", $$xml); file_put_contents($$phpcsConfigFile, $$xml);' || true)

migrations-php-phpcs-make-sure-etc-is-ran-through: #### Make sure PHPCS runs through `etc` ##*I*##
	($(DOCKER_RUN) php -r '$$phpcsConfigFile = "etc/qa/phpcs.xml"; if (!file_exists($$phpcsConfigFile)) {exit;} $$xml = file_get_contents($$phpcsConfigFile); if (!is_string($$xml)) {exit;} if (strpos($$xml, "<file>../../etc</file>") !== false) {exit;} $$xml = str_replace("<file>../../src</file>", "<file>../../etc</file>\n    <file>../../src</file>", $$xml); file_put_contents($$phpcsConfigFile, $$xml);' || true)

migrations-phpcs-include-examples-directory-when-present: #### Make sure PHPCS runs through `examples` when it exists ##*I*##
	($(DOCKER_RUN) php -r 'if (!file_exists("examples/")) {exit;} $$phpcsConfigFile = "etc/qa/phpcs.xml"; if (!file_exists($$phpcsConfigFile)) {exit;} $$xml = file_get_contents($$phpcsConfigFile); if (!is_string($$xml)) {exit;} if (strpos($$xml, "<file>../../examples</file>") !== false) {exit;} $$xml = str_replace("<file>../../etc</file>", "<file>../../etc</file>\n    <file>../../examples</file>", $$xml); file_put_contents($$phpcsConfigFile, $$xml);' || true)

migrations-php-move-composer-require-checker: #### Move composer-require-checker.json to `etc/qa/composer-require-checker.json` ##*I*##
	($(DOCKER_RUN) mv composer-require-checker.json etc/qa/composer-require-checker.json || true)

migrations-php-composer-require-checker-create-config-if-not-exists: #### Create Composer Require Checker config file if it doesn't exists at `etc/qa/composer-require-checker.json` ##*I*##
	($(DOCKER_RUN) php -r '$$composerRequireCheckerConfigFile = "etc/qa/composer-require-checker.json"; $$composerRequireCheckerConfig = base64_decode("ewogICJzeW1ib2wtd2hpdGVsaXN0IiA6IFsKICAgICJudWxsIiwgInRydWUiLCAiZmFsc2UiLAogICAgInN0YXRpYyIsICJzZWxmIiwgInBhcmVudCIsCiAgICAiYXJyYXkiLCAic3RyaW5nIiwgImludCIsICJmbG9hdCIsICJib29sIiwgIml0ZXJhYmxlIiwgImNhbGxhYmxlIiwgInZvaWQiLCAib2JqZWN0IgogIF0sCiAgInBocC1jb3JlLWV4dGVuc2lvbnMiIDogWwogICAgIkNvcmUiLAogICAgImRhdGUiLAogICAgInBjcmUiLAogICAgIlBoYXIiLAogICAgIlJlZmxlY3Rpb24iLAogICAgIlNQTCIsCiAgICAic3RhbmRhcmQiCiAgXSwKICAic2Nhbi1maWxlcyIgOiBbXQp9Cg=="); if (file_exists($$composerRequireCheckerConfigFile)) {exit;} file_put_contents($$composerRequireCheckerConfigFile, $$composerRequireCheckerConfig);' || true)

migrations-inline-code-phpstan-remove-line-phpstan-ignore-next-line: #### Remove all lines that contains @phpstan-ignore-next-line ##*I*##
	($(DOCKER_RUN) php -r '$$possibleDirectories = ["src", "tests", "etc", "examples"]; foreach ($$possibleDirectories as $$possibleDirectory) { if (!file_exists($$possibleDirectory)) {continue;} $$i = new \RecursiveIteratorIterator(new \RecursiveDirectoryIterator($$possibleDirectory)); $$i->rewind(); while ($$i->valid()) { if (!is_file($$i->key()) || (is_file($$i->key()) && !str_ends_with($$i->key(), ".php"))) { $$i->next(); continue; } $$fileContents = explode("\n", file_get_contents($$i->key())); foreach ($$fileContents as $$lineNumber => $$lineContent) { if (str_contains($$lineContent, "@phpstan-ignore-next-line")) { unset($$fileContents[$$lineNumber]); } } file_put_contents($$i->key(), implode("\n", $$fileContents)); $$i->next(); } }' || true)

migrations-inline-code-phpstan-remove-rest-of-line-phpstan-ignore-line: #### Remove rest of line for all lines that contain @phpstan-ignore-line ##*I*##
	($(DOCKER_RUN) php -r '$$possibleDirectories = ["src", "tests", "etc", "examples"]; foreach ($$possibleDirectories as $$possibleDirectory) { if (!file_exists($$possibleDirectory)) {continue;} $$i = new \RecursiveIteratorIterator(new \RecursiveDirectoryIterator($$possibleDirectory)); $$i->rewind(); while ($$i->valid()) { if (!is_file($$i->key()) || (is_file($$i->key()) && !str_ends_with($$i->key(), ".php"))) { $$i->next(); continue; } $$fileContents = explode("\n", file_get_contents($$i->key())); foreach ($$fileContents as $$lineNumber => $$lineContent) { if (str_contains($$lineContent, "/** @phpstan-ignore-line")) { [$$fileContents[$$lineNumber]] = explode("/** @phpstan-ignore-line", $$lineContent); } } file_put_contents($$i->key(), implode("\n", $$fileContents)); $$i->next(); } }' || true)

migrations-inline-code-psalm-remove-line-psalm-suppress: #### Remove all lines that contain @psalm-suppress ##*I*##
	($(DOCKER_RUN) php -r '$$possibleDirectories = ["src", "tests", "etc", "examples"]; foreach ($$possibleDirectories as $$possibleDirectory) { if (!file_exists($$possibleDirectory)) {continue;} $$i = new \RecursiveIteratorIterator(new \RecursiveDirectoryIterator($$possibleDirectory)); $$i->rewind(); while ($$i->valid()) { if (!is_file($$i->key()) || (is_file($$i->key()) && !str_ends_with($$i->key(), ".php"))) { $$i->next(); continue; } $$fileContents = explode("\n", file_get_contents($$i->key())); foreach ($$fileContents as $$lineNumber => $$lineContent) { if (str_contains($$lineContent, "@psalm-suppress")) { unset($$fileContents[$$lineNumber]); } } file_put_contents($$i->key(), implode("\n", $$fileContents)); $$i->next(); } }' || true)

migrations-inline-code-remove-line-internal: #### Remove all lines that contain @internal ##*I*##
	($(DOCKER_RUN) php -r '$$possibleDirectories = ["src", "tests", "etc", "examples"]; foreach ($$possibleDirectories as $$possibleDirectory) { if (!file_exists($$possibleDirectory)) {continue;} $$i = new \RecursiveIteratorIterator(new \RecursiveDirectoryIterator($$possibleDirectory)); $$i->rewind(); while ($$i->valid()) { if (!is_file($$i->key()) || (is_file($$i->key()) && !str_ends_with($$i->key(), ".php"))) { $$i->next(); continue; } $$fileContents = explode("\n", file_get_contents($$i->key())); foreach ($$fileContents as $$lineNumber => $$lineContent) { if (str_contains($$lineContent, "@internal")) { unset($$fileContents[$$lineNumber]); } } file_put_contents($$i->key(), implode("\n", $$fileContents)); $$i->next(); } }' || true)

migrations-inline-code-phpunit-replace-expectexceptionmessage-with-expectexceptionmessageisorcontains: #### Replace self::expectExceptionMessage with self::expectExceptionMessageIsOrContains in all PHPUnit tests ##*I*##
	($(DOCKER_RUN) php -r '$$possibleDirectories = ["src", "tests", "etc", "examples"]; foreach ($$possibleDirectories as $$possibleDirectory) { if (!file_exists($$possibleDirectory)) {continue;} $$i = new \RecursiveIteratorIterator(new \RecursiveDirectoryIterator($$possibleDirectory)); $$i->rewind(); while ($$i->valid()) { if (!is_file($$i->key()) || (is_file($$i->key()) && !str_ends_with($$i->key(), ".php"))) { $$i->next(); continue; } $$fileContents = file_get_contents($$i->key()); if (str_contains($$fileContents, "#[Test]") && str_contains($$fileContents, "use PHPUnit\Framework\Attributes\Test;")) { $$fileContents = str_replace("self::expectExceptionMessage(", "self::expectExceptionMessageIsOrContains(", $$fileContents); file_put_contents($$i->key(), $$fileContents); } $$i->next(); } }' || true)

migrations-supported-features-php-ensure-we-only-cs-check-and-fix-tests-if-unit-tests-is-enabled: #### Ensure we only cs check/fix tests/ if unit-tests is enabled ##*I*##
	($(DOCKER_RUN) php -r 'if (in_array("unit-tests", ["code-style","composer-dependency-checkers","linux","macos","static-analysis","unit-tests","windows"])) {exit;} $$phpCSCongifFIle = "etc/qa/phpcs.xml"; $$fileContents = explode("\n", file_get_contents($$phpCSCongifFIle)); foreach ($$fileContents as $$lineNumber => $$lineContent) { if (str_contains($$lineContent, "<file>../../tests</file>")) { unset($$fileContents[$$lineNumber]); } } file_put_contents($$phpCSCongifFIle, implode("\n", $$fileContents));' || true)

migrations-supported-features-php-ensure-we-only-staticly-analyse-tests-with-phpstan-if-unit-tests-is-enabled: #### Ensure we only staticly analyse tests/ with PHPStan if unit-tests is enabled ##*I*##
	($(DOCKER_RUN) php -r 'if (in_array("unit-tests", ["code-style","composer-dependency-checkers","linux","macos","static-analysis","unit-tests","windows"])) {exit;} $$phpStanCongifFIle = "etc/qa/phpstan.neon"; $$fileContents = explode("\n", file_get_contents($$phpStanCongifFIle)); foreach ($$fileContents as $$lineNumber => $$lineContent) { if (str_contains($$lineContent, "- ../../tests")) { unset($$fileContents[$$lineNumber]); } } file_put_contents($$phpStanCongifFIle, implode("\n", $$fileContents));' || true)

migrations-supported-features-php-ensure-no-phpunit-config-file-is-present-when-unit-tests-are-disabled: #### Ensure we remove the PHPUnit config file when unit-tests aren't enabled ##*I*##
	($(DOCKER_RUN) php -r 'if (in_array("unit-tests", ["code-style","composer-dependency-checkers","linux","macos","static-analysis","unit-tests","windows"])) {exit;} @unlink("etc/qa/phpunit.xml");' || true)

migrations-supported-features-php-ensure-no-infectionphp-config-file-is-present-when-unit-tests-are-disabled: #### Ensure we remove the InfectionPHP config file when unit-tests aren't enabled ##*I*##
	($(DOCKER_RUN) php -r 'if (in_array("unit-tests", ["code-style","composer-dependency-checkers","linux","macos","static-analysis","unit-tests","windows"])) {exit;} @unlink("etc/qa/infection.json5");' || true)

migrations-supported-features-php-ensure-no-rector-config-file-is-present-when-code-style-is-disabled: #### Ensure we remove the RectorPHP config file when code-style isn't enabled ##*I*##
	($(DOCKER_RUN) php -r 'if (in_array("code-style", ["code-style","composer-dependency-checkers","linux","macos","static-analysis","unit-tests","windows"])) {exit;} @unlink("etc/qa/rector.php");' || true)

migrations-supported-features-php-ensure-no-phpcs-config-file-is-present-when-code-style-is-disabled: #### Ensure we remove the PHPCSS config file when code-style isn't enabled ##*I*##
	($(DOCKER_RUN) php -r 'if (in_array("code-style", ["code-style","composer-dependency-checkers","linux","macos","static-analysis","unit-tests","windows"])) {exit;} @unlink("etc/qa/phpcs.xml");' || true)

migrations-supported-features-php-ensure-no-composer-require-checker-config-file-is-present-when-composer-dependency-checkers-are-disabled: #### Ensure we remove the Composer Require Checker config file when composer-dependency-checkers aren't enabled ##*I*##
	($(DOCKER_RUN) php -r 'if (in_array("composer-dependency-checkers", ["code-style","composer-dependency-checkers","linux","macos","static-analysis","unit-tests","windows"])) {exit;} @unlink("etc/qa/composer-require-checker.json");' || true)

migrations-supported-features-php-ensure-no-composer-unused-config-file-is-present-when-composer-dependency-checkers-are-disabled: #### Ensure we remove the Composer Unused config file when composer-dependency-checkers aren't enabled ##*I*##
	($(DOCKER_RUN) php -r 'if (in_array("composer-dependency-checkers", ["code-style","composer-dependency-checkers","linux","macos","static-analysis","unit-tests","windows"])) {exit;} @unlink("etc/qa/composer-unused.php");' || true)

migrations-php-make-sure-github-exists: #### Make sure `.github/` exists ##*I*##
	($(DOCKER_RUN) mkdir .github || true)

migrations-github-codeowners: #### Ensure a `CODEOWNERS` file is present, create only if it doesn't exist yet ##*I*##
	($(DOCKER_RUN) php -r '$$codeOwnersFile = ".github/CODEOWNERS"; if (file_exists($$codeOwnersFile)) {exit;} file_put_contents($$codeOwnersFile, "*       @WyriHaximus" . PHP_EOL);' || true)

migrations-php-make-sure-github-workflows-exists: #### Make sure `.github/workflows` exists ##*I*##
	($(DOCKER_RUN) mkdir .github/workflows || true)

migrations-github-actions-remove-composer-diff: #### Remove `composer-diff.yaml` it has been folded into centralized workflows through `ci.yaml` ##*I*##
	($(DOCKER_RUN) rm .github/workflows/composer-diff.yaml || true)

migrations-github-actions-remove-markdown-check-links: #### Remove `markdown-check-links.yaml` it has been folded into centralized workflows through `ci.yaml` ##*I*##
	($(DOCKER_RUN) rm .github/workflows/markdown-check-links.yaml || true)

migrations-github-actions-remove-markdown-craft-release: #### Remove `craft-release.yaml` it has been folded into centralized workflows through `release-management.yaml` ##*I*##
	($(DOCKER_RUN) rm .github/workflows/craft-release.yaml || true)

migrations-github-actions-remove-set-milestone-on-pr: #### Remove `set-milestone-on-pr.yaml` it has been folded into centralized workflows through `release-management.yaml` ##*I*##
	($(DOCKER_RUN) rm .github/workflows/set-milestone-on-pr.yaml || true)

migrations-github-actions-move-ci: #### Move `.github/workflows/ci.yml` to `.github/workflows/ci.yaml` ##*I*##
	($(DOCKER_RUN) mv .github/workflows/ci.yml .github/workflows/ci.yaml || true)

migrations-github-actions-remove-ci-if-its-old-style-php-ci-workflow: #### Remove CI Workflow if its the old style PHP CI Workflow ##*I*##
	($(DOCKER_RUN) php -r '$$ciWorkflowFile = ".github/workflows/ci.yaml"; if (!file_exists($$ciWorkflowFile)) {exit;} $$yaml = file_get_contents($$ciWorkflowFile); if (!is_string($$yaml)) {exit;} if (strpos($$yaml, "composer: [lowest, locked, highest]") !== false || strpos($$yaml, "composer: [lowest, current, highest]") !== false || strpos($$yaml, "- run: make ${{ matrix.check }}") !== false || strpos($$yaml, trim(base64_decode("aWY6IG1hdHJpeC5jaGVjayA9PSAnYmFja3dhcmQtY29tcGF0aWJpbGl0eS1jaGVjaycK"))) !== false) { unlink($$ciWorkflowFile); }' || true)

migrations-github-actions-create-ci-if-not-exists: #### Create CI Workflow if it doesn't exists at `.github/workflows/ci.yaml` ##*I*##
	($(DOCKER_RUN) php -r '$$ciWorkflowFile = ".github/workflows/ci.yaml"; $$ciWorkflowContents = base64_decode("bmFtZTogQ29udGludW91cyBJbnRlZ3JhdGlvbgpvbjoKICBwdXNoOgogICAgYnJhbmNoZXM6CiAgICAgIC0gJ21haW4nCiAgICAgIC0gJ21hc3RlcicKICAgICAgLSAncmVmcy9oZWFkcy92WzAtOV0rLlswLTldKy5bMC05XSsnCiAgcHVsbF9yZXF1ZXN0OgojIyBUaGlzIHdvcmtmbG93IG5lZWRzIHRoZSBgcHVsbC1yZXF1ZXN0YCBwZXJtaXNzaW9ucyB0byB3b3JrIGZvciB0aGUgcGFja2FnZSBkaWZmaW5nCiMjIFJlZnM6IGh0dHBzOi8vZG9jcy5naXRodWIuY29tL2VuL2FjdGlvbnMvcmVmZXJlbmNlL3dvcmtmbG93LXN5bnRheC1mb3ItZ2l0aHViLWFjdGlvbnMjcGVybWlzc2lvbnMKcGVybWlzc2lvbnM6CiAgcHVsbC1yZXF1ZXN0czogd3JpdGUKICBjb250ZW50czogcmVhZApqb2JzOgogIGNpOgogICAgbmFtZTogQ29udGludW91cyBJbnRlZ3JhdGlvbgogICAgdXNlczogV3lyaUhheGltdXMvZ2l0aHViLXdvcmtmbG93cy8uZ2l0aHViL3dvcmtmbG93cy9wYWNrYWdlLnlhbWxANTM0Mzk0NGJlMmE2ZWY5NjMxODZiNWY0MTMxMjFmY2YzNjk4MGIzMyAjIHYxLjAuMAo="); if (file_exists($$ciWorkflowFile)) {exit;} file_put_contents($$ciWorkflowFile, $$ciWorkflowContents);' || true)

migrations-github-actions-move-release-management: #### Move `.github/workflows/release-managment.yaml` to `.github/workflows/release-management.yaml` ##*I*##
	($(DOCKER_RUN) mv .github/workflows/release-managment.yaml .github/workflows/release-management.yaml || true)

migrations-github-actions-fix-management-in-release-management-referenced-workflow-file: #### Fix management in release-management referenced workflow file ##*I*##
	($(DOCKER_RUN) sed -i -e 's/release-managment.yaml/release-management.yaml/g' .github/workflows/release-management.yaml || true)

migrations-github-actions-create-release-management-if-not-exists: #### Create Release Management Workflow if it doesn't exists at `.github/workflows/release-management.yaml` ##*I*##
	($(DOCKER_RUN) php -r '$$releaseManagementWorkflowFile = ".github/workflows/release-management.yaml"; $$releaseManagementWorkflowContents = base64_decode("bmFtZTogUmVsZWFzZSBNYW5hZ2VtZW50Cm9uOgogIHB1bGxfcmVxdWVzdDoKICAgIHR5cGVzOgogICAgICAtIG9wZW5lZAogICAgICAtIGxhYmVsZWQKICAgICAgLSB1bmxhYmVsZWQKICAgICAgLSBzeW5jaHJvbml6ZQogICAgICAtIHJlb3BlbmVkCiAgICAgIC0gbWlsZXN0b25lZAogICAgICAtIGRlbWlsZXN0b25lZAogICAgICAtIHJlYWR5X2Zvcl9yZXZpZXcKICBtaWxlc3RvbmU6CiAgICB0eXBlczoKICAgICAgLSBjbG9zZWQKcGVybWlzc2lvbnM6CiAgY29udGVudHM6IHdyaXRlCiAgaXNzdWVzOiB3cml0ZQogIHB1bGwtcmVxdWVzdHM6IHdyaXRlCmpvYnM6CiAgcmVsZWFzZS1tYW5hZ21lbnQ6CiAgICBuYW1lOiBSZWxlYXNlIE1hbmFnZW1lbnQKICAgIHVzZXM6IFd5cmlIYXhpbXVzL2dpdGh1Yi13b3JrZmxvd3MvLmdpdGh1Yi93b3JrZmxvd3MvcGFja2FnZS1yZWxlYXNlLW1hbmFnZW1lbnQueWFtbEA1MzQzOTQ0YmUyYTZlZjk2MzE4NmI1ZjQxMzEyMWZjZjM2OTgwYjMzICMgdjEuMC4wCiAgICB3aXRoOgogICAgICBtaWxlc3RvbmU6ICR7eyBnaXRodWIuZXZlbnQubWlsZXN0b25lLnRpdGxlIH19CiAgICAgIGRlc2NyaXB0aW9uOiAke3sgZ2l0aHViLmV2ZW50Lm1pbGVzdG9uZS50aXRsZSB9fQo="); if (file_exists($$releaseManagementWorkflowFile)) {exit;} file_put_contents($$releaseManagementWorkflowFile, $$releaseManagementWorkflowContents);' || true)

migrations-github-actions-ensure-runs-on-is-the-only-runs-on-variant-in-utils-yaml: #### Ensure `runsOn` is the only `runsOn` variant in `.github/workflows/utils.yaml` ##*I*##
	($(DOCKER_RUN) php -r '$$utilsWorkflowFile = ".github/workflows/utils.yaml"; if (!file_exists($$utilsWorkflowFile)) {exit;} $$yaml = file_get_contents($$utilsWorkflowFile); if (!is_string($$yaml)) {exit;} $$yaml = preg_replace("#(\s+)runsOn[A-Za-z0-9_]+:#", "$$1runsOn:", $$yaml); file_put_contents($$utilsWorkflowFile, $$yaml);' || true)

migrations-github-actions-pin-package-workflow-reference-at-v1-0-0: #### Pin WyriHaximus/github-workflows reusable workflow references to SHA `5343944be2a6ef963186b5f413121fcf36980b33` (`v1.0.0`) in `.github/workflows` ##*I*##
	($(DOCKER_RUN) php -r '$$workflowsDir = ".github/workflows"; if (!is_dir($$workflowsDir)) {exit;} foreach (scandir($$workflowsDir) as $$file) { if (!str_ends_with($$file, ".yaml")) {continue;} $$workflowFile = $$workflowsDir . "/" . $$file; $$yaml = file_get_contents($$workflowFile); if (!is_string($$yaml)) {continue;} $$newYaml = preg_replace("#(uses: WyriHaximus/github-workflows/.github/workflows/[a-z0-9-]+)\\.yaml@(main|v1\\.0\\.0)#", "$$1.yaml@5343944be2a6ef963186b5f413121fcf36980b33 # v1.0.0", $$yaml); if ($$newYaml === $$yaml) {continue;} file_put_contents($$workflowFile, $$newYaml); }' || true)

migrations-renovate-remove-dependabot-config: #### Make sure we remove `.github/dependabot.yml` ##*I*##
	($(DOCKER_RUN) rm .github/dependabot.yml || true)
	($(DOCKER_RUN) rm .github/dependabot.yaml || true)

migrations-renovate-move-config: #### Move `renovate.json` to `.github/renovate.json` ##*I*##
	($(DOCKER_RUN) mv renovate.json .github/renovate.json || true)

migrations-renovate-create-config-if-not-exists: #### Create Renovate Config if it doesn't exists at `.github/renovate.json` ##*I*##
	($(DOCKER_RUN) php -r '$$renovateConfigFile = ".github/renovate.json"; $$renovateConfigContents = base64_decode("ewogICIkc2NoZW1hIjogImh0dHBzOi8vZG9jcy5yZW5vdmF0ZWJvdC5jb20vcmVub3ZhdGUtc2NoZW1hLmpzb24iLAogICJleHRlbmRzIjogWwogICAgImdpdGh1Yj5XeXJpSGF4aW11cy9yZW5vdmF0ZS1jb25maWc6cGhwLXBhY2thZ2UiCiAgXQp9Cg=="); if (file_exists($$renovateConfigFile)) {exit;} file_put_contents($$renovateConfigFile, $$renovateConfigContents);' || true)

migrations-renovate-point-at-correct-config: #### Ensure `.github/renovate.json` points at github>WyriHaximus/renovate-config:php-package instead of local>WyriHaximus/renovate-config ##*I*##
	($(DOCKER_RUN) php -r '$$renovateFIle = ".github/renovate.json"; if (!file_exists($$renovateFIle)) {exit;} file_put_contents($$renovateFIle, str_replace("local>WyriHaximus/renovate-config", "github>WyriHaximus/renovate-config:php-package", file_get_contents($$renovateFIle)));' || true)

migrations-renovate-set-php-constraint: #### Always keep renovate's constraints.php in sync with `composer.json`'s `config.platform.php` ##*I*##
	($(DOCKER_RUN) php -r '$$composerFIle = "composer.json"; if (!file_exists($$composerFIle)) {exit;} $$json = json_decode(file_get_contents($$composerFIle), true); if (!array_key_exists("config", $$json)) {exit;} if (!array_key_exists("platform", $$json["config"])) {exit;} if (!array_key_exists("php", $$json["config"]["platform"])) {exit;} $$phpVersionConstraint = str_replace(".13", ".x", $$json["config"]["platform"]["php"]); $$renovateFIle = ".github/renovate.json"; if (!file_exists($$renovateFIle)) {exit;} $$json = json_decode(file_get_contents($$renovateFIle), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("constraints", $$json)) {$$json["constraints"] = [];} $$json["constraints"]["php"] = $$phpVersionConstraint; file_put_contents($$renovateFIle, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\r\n");' || true)

migrations-renovate-set-composer-constraint: #### Always keep renovate's `constraints.composer` at `2.x` ##*I*##
	($(DOCKER_RUN) php -r '$$renovateFIle = ".github/renovate.json"; if (!file_exists($$renovateFIle)) {exit;} $$json = json_decode(file_get_contents($$renovateFIle), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("constraints", $$json)) {$$json["constraints"] = [];} $$json["constraints"]["composer"] = "2.x"; file_put_contents($$renovateFIle, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\r\n");' || true)

migrations-git-enforce-agents-md-contents: #### Enforce `AGENTS.md` contents ##*I*##
	($(DOCKER_RUN) php -r 'file_put_contents("AGENTS.md", base64_decode("IyBJbnN0cnVjdGlvbiBFY29ub215IChjaGVjayBiZWZvcmUgRVZFUlkgaW5zdHJ1Y3Rpb24geW91IGFkZCkKCkJlZm9yZSBhZGRpbmcgYW4gaW5zdHJ1Y3Rpb24gQU5ZV0hFUkUg4oCUIEFHRU5UUy5tZHMsIHJ1bGVzLCBhZ2VudHMsIHNraWxscywgaG9va3MsIGNvbmZpZ3M6IHByZWZlciB0aGUgTkFUSVZFIG1lY2hhbmlzbSAoZnJvbnRtYXR0ZXIgZmllbGQsIGNvbmZpZyBrZXksIGV4aXN0aW5nIHJ1bGUsIGEgcm91dGVyIHRvIHRoZSBzaW5nbGUgc291cmNlKSBvdmVyIG5ldyBwcm9zZSwgYW5kIHByZWZlciBERUxFVElORyBwcm9zZSBvdmVyIGFkZGluZyBpdC4gRXZlcnkgYWRkZWQgaW5zdHJ1Y3Rpb24gaXMgYSBjb250cmFkaWN0aW9uLWFuZC1kcmlmdCBzdXJmYWNlOyBjb25kZW5zZWQgY29waWVzIG9mIGFub3RoZXIgYXJ0aWZhY3QncyBjb250ZW50IGRyaWZ0IHNpbGVudGx5LiBTdWNjZXNzIG1ldHJpYzogdGhlIGRpZmYgc2hyaW5rcyBvciBob2xkcyB3aGlsZSBjYXBhYmlsaXR5IGdyb3dzLiBDb25zaXN0ZW5jeSBiZWF0cyB0b2tlbiB0aHJpZnQuCgojIFByb2plY3QgSW5zdHJ1Y3Rpb25zCgojIyBEZXBlbmRlbmNpZXMKLSBJbnN0YWxsOiBgbWFrZSBpbnN0YWxsYC4KLSBSZXF1aXJlIGEgbmV3IHBhY2thZ2U6IGBtYWtlIGNvbXBvc2VyLXJlcXVpcmUgIlBBQ0tBR0VOQU1FImAgb3IgYG1ha2UgY29tcG9zZXItcmVxdWlyZSAiUEFDS0FHRU5BTUUgLS1kZXYiYC4KCiMjIEV4ZWN1dGluZyBjb21tYW5kcwotIERvIG5vdyB1c2UgYGNkYCBmb3IgZXZlcnl0aGluZywgeW91J3JlIGFscmVhZHkgaW4gdGhlIHJvb3QhCi0gQ2hlY2sgYG1ha2UgaGVscGAgZm9yIGFsbCBhdmFpbGFibGUgY29tbWFuZHMuCi0gQ2hlY2sgYG1ha2UgaGVscC1jb250cmliYCBmb3IgYWxsIGF2YWlsYWJsZSBjb250cmliIGNvbW1hbmRzLgotIE5lZWQgc29tZXRoaW5nIGN1c3RvbSB0aGF0IGlzIG5vdCBpbiB0aGUgbGlzdD8gVXNlIGBtYWtlIHJ1biAiWU9VUiBDT01NQU5EIEhFUkUiYCB0byBydW4gYSBjb21tYW5kIGluIHRoZSBjb250YWluZXIgYW5kIHJ1biB3aGF0ZXZlciB5b3UgcmVxdWlyZSB0aGVyZS4KLSBJZiBhIHBhY2thZ2UgbmVlZHMgY3VzdG9tIGBtYWtlYCBjb21tYW5kcywgcHV0IHRoZW0gaW4gYGV0Yy9NYWtlZmlsZWAsIHRoZW4gcnVuIGBtYWtlIGluc3RhbGxgIHRvIG1ha2UgdGhlbSBhdmFpbGFibGUgdGhyb3VnaCB0aGUgcm9vdCBgTWFrZWZpbGVgLgoKIyMgRmxvdwotIEFmdGVyIGVhY2ggbG9naWNhbCBibG9jayBvZiBjaGFuZ2VzIG1hZGUgZW5zdXJlIGBtYWtlIGNvbnRyaWJgIHBhc3Nlcy4KLSBCZWZvcmUgeW91IHJldHVybiB0byB0aGUgdXNlcyBydW4gYG1ha2VgIHRvIGVuc3VyZSBhbGwgUUEgY2hlY2tzIHBhc3MuCi0gVXNlIGBtYWtlIHVuaXQtdGVzdGluZy1maWx0ZXIgVEVTVENMQVNTTkFNRV9PUl9URVNUTUVUSE9ETkFNRWAgdG8gcnVuIGEgc3BlY2lmaWMgdGVzdC4KLSBBbHdheXMgYWRkIHVuaXQgdGVzdHMgZm9yIG5ldyBjb2RlLgotIElmIGBjb21wb3Nlci5sb2NrYCBpcyBvdXQgb2Ygc3luYyB3aXRoIGBjb21wb3Nlci5qc29uYCwgcnVuIGBtYWtlIHVwZGF0ZWAuCgojIyBXcml0aW5nIGNvZGUKLSBLZWVwIHRoaW5ncyBzaW1wbGUsIG9uY2UgZG9uZSBpbXBsZW1lbnRpbmcgYSBmZWF0dXJlLCBpdGVyYXRlIG9uIGltcHJvdmluZyBpdC4gTGVzcyBjb2RlIGlzIG1vcmUuCi0gTWFrZSBzdXJlIHRoZSBjb2RlIGlzIHJlYWRhYmxlIGFuZCBlYXN5IHRvIHVuZGVyc3RhbmQuCi0gUHJlZmVyIGEgbG9naWNhbCBibG9jayBvZiBjb2RlIHRvIGJlIHdpdGhpbiBvbmUgc2NyZWVuIHNpemUgb3ZlciBzcGxpdHRpbmcgaXQgdXAgaW4gbXVsdGlwbGUgc21hbGxlciBmdW5jdGlvbnMuCi0gTWFrZSBhIGNsYXNzIHN0YXRpYyBpZiBpdCBkb2Vzbid0IGhvbGQgc3RhdGUuCi0gUHV0IGNsYXNzZXMgaW4gbG9naWNhbCBmb2xkZXJzLgotIE9uY2UgZG9uZSB3cml0aW5nIGNvZGUgaXRlcmF0ZSBvZiBpdCB0byBtYWtlIHN1cmUgaXQncyBlYXN5IHRvIHVuZGVyc3RhbmQgYW5kIG1haW50YWluLCB0aGF0IGl0J3MgZWFzeSB0byB0ZXN0LCBhbmQgdGhhdCBpdCBkb2Vzbid0IGR1cGxpY2F0ZSBjb2RlLgotIFNlYXJjaCBleGlzdGluZyBjb2RlIGZvciBleGFtcGxlcyBvZiBob3cgdG8gZG8gdGhpbmdzLgotIFNlYXJjaCBleGlzdGluZyBjb2RlIGZvciBjbGFzc2VzL21ldGhvZHMgeW91IGNhbiB1c2UgaW5zdGVhZCBvZiB3cml0aW5nIHlvdXIgb3duLgoKIyMgTWFya2Rvd24KLSBBbHdheXMgbGluayBldmVyeSByZWZlcmVuY2UgdGhhdCBoYXMgYSBVUkwgKGBbbGFiZWxdKHVybClgKTsgbmV2ZXIgYmFyZSBiYWNrdGlja3Mgb3IgcGxhaW4gdGV4dCBhbG9uZQotIENvbXBvc2VyIHBhY2thZ2VzIOKGkiBHaXRIdWIgcmVwbyAocmVzb2x2ZSB2aWEgUGFja2FnaXN0KTsgZG9jcyBhbmQgc3BlY3Mg4oaSIGNhbm9uaWNhbCBVUkwKCiMjIFVuaXQgdGVzdHMKLSBUZXN0IHRoZSBoYXBweSBmbG93cyAoUEhQVW5pdCkKLSBUZXN0IHRoZSB1bmhhcHB5IGZsb3dzIChQSFBVbml0KQotIFRlc3QgdGhlIGVkZ2UgY2FzZXMgKFBIUFVuaXQpCi0gVGVzdCB0aGUgZnV6enkgY2FzZXMgKFBIUFVuaXQpCi0gMTAwJSBjb3ZlcmFnZSBpcyByZXF1aXJlZCAoUEhQVW5pdCkKLSAxMDAlIE1TSSBpcyByZXF1aXJlZCAobXV0YXRpb24gdGVzdGluZyAoSW5mZWN0aW9uUEhQKSkKLSAxMDAlIHR5cGUgY292ZXJhZ2UgaXMgcmVxdWlyZWQgKFBIUFN0YW4pCi0gVXNlIGRhdGFwcm92aWRlcnMgd2hlcmV2ZXIgcG9zc2libGUgKFBIUFVuaXQpCi0gUHJlZmVyIGNyZWF0aW5nIHN1YnMgYW5kIHNwaWVzIG92ZXIgbW9ja3MKLSBMb29rIGF0IFtgd3lyaWhheGltdXMvdGVzdC11dGlsaXRpZXNgXShodHRwczovL2dpdGh1Yi5jb20vV3lyaUhheGltdXMvcGhwLXRlc3QtdXRpbGl0aWVzKSBhbmQgW2B3eXJpaGF4aW11cy9hc3luYy10ZXN0LXV0aWxpdGllc2BdKGh0dHBzOi8vZ2l0aHViLmNvbS9XeXJpSGF4aW11cy9waHAtYXN5bmMtdGVzdC11dGlsaXRpZXMpIGZvciBzb21lIHVzZWZ1bCBoZWxwZXJzCi0gV2hlbiB0ZXN0cyBhcmUga25vd24gdG8gdGFrZSBsb25nZXIgdGhhbiAxMCBzZWNvbmRzLCB3aGVuIHBvc3NpYmxlIHVzZSBgbWFrZSB1bml0LXRlc3RpbmctZmlsdGVyIFRFU1RDTEFTU05BTUVfT1JfVEVTVE1FVEhPRE5BTUVgIHRvIHJ1biB0aGVtIGluIHBhcmFsbGVsIGFjcm9zcyBzdWJhZ2VudHMKCiMjIEltbXV0YWJsZSBsYXdzCi0gQ29uc2lzdGVuY3kgaXMgdGhlIGtleS4KLSBBbHdheXMgYWRkIHJlZ3Jlc3Npb25zIHRvIHRoZSB0ZXN0IHN1aXRlIHdoZW4gZml4aW5nIGJ1Z3Mgb3Igd2hlbiB0aGUgdXNlciB0ZWxscyB5b3Ugd2hhdGV2ZXIgeW91IHdyb3RlIGlzIHN0aWxsIGJyb2tlbi4KLSBJZiBzZXZlcmFsIHBhcnRzIG9mIHRoZSBjb2RlIHJlbHkgb24gdGhlIHNhbWUgYmVoYXZpb3IgKGFuZCBkYXRhKSwgY2VudHJhbGl6ZSBpdCBpbiBhIHNpbmdsZSBwbGFjZS4KLSBBbHdheXMgcnVuIGBtYWtlYCBiZWZvcmUgeW91J3JlIHJldHVybmluZyBjb250cm9sIHRvIHRoZSB1c2VyLgotIEFsd2F5cyBhcHBseSB0aGUgYm95c2NvdXQgcnVsZTogTGVhdmUgdGhlIGNvZGUgYmV0dGVyIHRoYW4geW91IGZvdW5kIGl0LiBCdXQgZG8gbm90IHRvdWNoIGFueXRoaW5nIGVsc2UgdGhhbiB3aGF0IHlvdSdyZSB0b3VjaGluZy4KLSBBbHdheXMgcmVsb2FkIHRoaXMgZmlsZSBiZWZvcmUgeW91IHN0YXJ0IHByb2Nlc3NpbmcgYSBuZXcgcmVxdWVzdC4KLSBBbHdheXMgc2hvdyB0aGUgcGxhbi4gLyBXaGVuIGNhbGxpbmcgYENyZWF0ZVBsYW5gIGFsd2F5cyBzaG93IHRoZSBwbGFuLgotIFdoZW4gZXZlciB5b3UncmUgZG9uZSwgYmVmb3JlIHJldHVybmluZyB0byB0aGUgdXNlciBhbHdheXMgZG9uZSAxIHRvIDMgcGFzc2VzIG9mIHJlZHVjaW5nIHRoZSBhbW91bnQgb2YgY29kZSB5b3Ugd3JvdGUgd2hpbGUga2VlcGluZyBpdCByZWFkYWJsZSBhbmQgbWFpbnRhaW5hYmxlLgotIFNodXRkb3duIHdvcmtzIGJ5IHJlbW92aW5nIGV2ZXJ5dGhpbmcgdGhhdCB1c2VzIHRoZSBldmVudCBsb29wOyBuZXZlciBjYWxsIGBMb29wOjpzdG9wKClgIGFueXdoZXJlLgotIEFsd2F5cyBleHRlbmQgUEhQVW5pdCB0ZXN0IGNsYXNzZXMgZnJvbSBgV3lyaUhheGltdXNcQXN5bmNUZXN0VXRpbGl0aWVzXEFzeW5jVGVzdENhc2VgIG9yIGBXeXJpSGF4aW11c1xUZXN0VXRpbGl0aWVzXFRlc3RDYXNlYC4KCiMjIFBhY2thZ2VzIHRvIGNvbnNpZGVyIHdoZW4gd29ya2luZyB3aXRoIGxvZ2dpbmcKLSBbYHd5cmloYXhpbXVzL3Bzci0zLWNvbnRleHQtbG9nZ2VyYF0oaHR0cHM6Ly9naXRodWIuY29tL1d5cmlIYXhpbXVzL3BocC1wc3ItMy1jb250ZXh0LWxvZ2dlcikg4oCUIFBTUi0zIGRlY29yYXRvcjsgbWVyZ2UgZGVmYXVsdCBjb250ZXh0IChvcHRpb25hbCBgW1ByZWZpeF1gKSBpbnRvIGV2ZXJ5IGxvZyBjYWxsCi0gW2B3eXJpaGF4aW11cy9wc3ItMy1maWx0ZXJgXShodHRwczovL2dpdGh1Yi5jb20vV3lyaUhheGltdXMvcGhwLXBzci0zLWZpbHRlcikg4oCUIFBTUi0zIGZpbHRlciBkZWNvcmF0b3JzOyBwYXNzIG9yIGRyb3AgbG9ncyBieSBjb250ZXh0IHBhdGgsIGxldmVsLCBtZXNzYWdlIGtleXdvcmQsIG9yIHN0cmlwIG5lc3RlZCBgW1ByZWZpeF1gIGNoYWlucyAocGFpcnMgd2l0aCBjb250ZXh0LWxvZ2dlcikKLSBbYHd5cmloYXhpbXVzL3Bzci0zLWNhbGxhYmxlLXRocm93YWJsZS1sb2dnZXJgXShodHRwczovL2dpdGh1Yi5jb20vV3lyaUhheGltdXMvcGhwLXBzci0zLWNhbGxhYmxlLXRocm93YWJsZS1sb2dnZXIpIOKAlCBgQ2FsbGFibGVUaHJvd2FibGVMb2dnZXI6OmNyZWF0ZSgpYCBmb3IgcmVhY3QvcHJvbWlzZSByZWplY3Rpb24gaGFuZGxlcnMgYW5kIFJ4UEhQIGVycm9yIGNhbGxiYWNrcwotIFtgd3lyaWhheGltdXMvbW9ub2xvZy1wcm9jZXNzb3JzYF0oaHR0cHM6Ly9naXRodWIuY29tL1d5cmlIYXhpbXVzL3BocC1tb25vbG9nLXByb2Nlc3NvcnMpIOKAlCBNb25vbG9nIHJlY29yZCBwcm9jZXNzb3JzIChgQ29weVByb2Nlc3NvcmAsIGBFeGNlcHRpb25DbGFzc1Byb2Nlc3NvcmAsIGBUcmFjZVByb2Nlc3NvcmAsIGBSdW50aW1lUHJvY2Vzc29yYCwg4oCmKQoKIyMgRm9yYmlkZGVuIGNvbW1hbmRzCi0gTmV2ZXIgY2FsbCwgYXR0ZW1wdCBvciBldmVuIGNvbnNpZGVyIHRvIHVzZSBgc3Vkb2AKLSBOZXZlciBjYWxsLCBhdHRlbXB0IG9yIGV2ZW4gY29uc2lkZXIgdG8gdXNlIGBzdWAKLSBOZXZlciBjYWxsLCBhdHRlbXB0IG9yIGV2ZW4gY29uc2lkZXIgdG8gdXNlIGBzdWRvIHN1YAotIE5ldmVyIGNhbGwsIGF0dGVtcHQgb3IgZXZlbiBjb25zaWRlciB0byB1c2UgYGNkYAotIE5ldmVyIGNhbGwsIGF0dGVtcHQgb3IgZXZlbiBjb25zaWRlciB0byB1c2UgYGRvY2tlcmAKLSBBbnkgY29tbWFuZCBub3QgaW4gdGhlIGFsbG93ZWQgY29tbWFuZHMgbGlzdAotIE5ldmVyLCBldmVyLCBldmVyIHVzZSBgIOKAlCBgIGluIGRvY3VtZW50YXRpb24hISEhIQoKIyMgRm9yYmlkZGVuIGFjdGlvbnMKLSBDcmVhdGUgZGVhZC91bnVzZWQgbWV0aG9kcy9jbGFzc2VzL2Z1bmN0aW9ucy9jb2RlCi0gVXNpbmcgdGhlIGBhc3NlcnRgIGZ1bmN0aW9uCi0gQXNzaWduaW5nIGEgcHJvcGVydHkgdG8gYSB2YXJpYWJsZSB3aXRob3V0IGFzc2lnbmluZyBhIG5ldyB2YWx1ZSB0byBpdAotIE5ldmVyIHVwZGF0ZSBgTWFrZWZpbGVgIG9yIGBBR0VOVFMubWRgIG91dHNpZGUgW2B3eXJpaGF4aW11cy9tYWtlZmlsZXNgXShodHRwczovL2dpdGh1Yi5jb20vV3lyaUhheGltdXMvTWFrZWZpbGVzKTsgc3VnZ2VzdCBjaGFuZ2VzIHRvIHRoYXQgcmVwb3NpdG9yeSBpbnN0ZWFkCgojIyBSZWNvdmVyeQotIFdoZW4geW91IGdldCBgRXJyb3I6IFJldHJpYWJsZUVycm9yOiBbY2FuY2VsZWRdIGh0dHAvMiBzdHJlYW0gY2xvc2VkIHdpdGggZXJyb3IgY29kZSBDQU5DRUwgKDB4OClgIHJldHJ5IHRoZSByZXF1ZXN0Cg=="));' || true)


## Our default jobs

on-install-or-update: ## Tasks, like migrations, that specifically have be run after composer install or update. These will also run by self hosted Renovate ####
ifeq ("$(ON_INSTALL_OR_UPDATE_HAS_DIRECT_DOCKER_TASKS)","TRUE")
	$(DOCKER_RUN_WITH_SOCKET) $(MAKE) migrations-git-enforce-gitattributes-contents migrations-git-enforce-editorconfig-contents migrations-git-make-sure-gitignore-exists migrations-git-make-sure-gitignore-ignores-var migrations-git-make-sure-gitignore-excludes-var-gitkeep migrations-docs-update-readme-copyright-c-year-to-current migrations-docs-update-readme-copyright-year-to-current migrations-docs-update-etc-readme-template-copyright-c-year-to-current migrations-docs-update-etc-readme-template-copyright-year-to-current migrations-docs-create-license-when-it-doesnt-exists migrations-docs-update-license-copyright-c-year-to-current migrations-docs-update-license-copyright-year-to-current migrations-docs-enforce-contributing-md-contents migrations-php-make-sure-var-exists migrations-php-make-sure-var-gitkeep-exists migrations-php-make-sure-etc-exists migrations-php-make-sure-etc-ci-exists migrations-php-make-sure-etc-qa-exists migrations-php-move-psalm-xml-config-to-etc migrations-php-remove-psalm-xml-config migrations-php-remove-old-phpunit-xml-dist-config migrations-php-remove-old-phpunit-xml-config migrations-php-remove-old-php-cs-fiver-config migrations-php-remove-old-scrutinizer-yml-config migrations-php-remove-old-appveyor-yml-config migrations-php-remove-old-travis-yml-config migrations-php-ensure-etc-ci-markdown-link-checker-json-exists migrations-php-ensure-etc-qa-coverage-guard-php-exists migrations-php-ensure-etc-qa-zzz-disable-otel-attr-hooks-ini-exists migrations-php-move-infection-config-to-etc migrations-php-infection-create-config-if-not-exists migrations-php-remove-phpunit-config-dir-from-infection migrations-php-fix-logs-relative-paths-for-infection migrations-php-infection-ensure-log-text-has-the-correct-path migrations-php-infection-ensure-log-summary-has-the-correct-path migrations-php-infection-ensure-log-json-has-the-correct-path migrations-php-infection-ensure-log-per-mutator-has-the-correct-path migrations-php-add-github-true-to-for-infection migrations-php-make-paths-compatible-with-infection-0-32 migrations-php-set-phpunit-ensure-config-file-exists migrations-php-set-phpunit-xsd-path-to-local migrations-php-set-phpunit-make-sure-we-see-all-the-warnings-deprecations-etc-etc-that-will-make-phpunit-do-a-non-happy-exit migrations-php-move-phpstan migrations-php-set-phpstan-ensure-config-file-exists migrations-php-set-phpstan-uncomment-parameters migrations-php-set-phpstan-add-parameters-if-it-isnt-present-in-the-config-file migrations-php-set-phpstan-paths-in-config migrations-php-set-phpstan-level-max-in-config migrations-php-set-phpstan-resolve-ergebnis-noExtends-classesAllowedToBeExtended migrations-php-set-phpstan-drop-checkGenericClassInNonGenericObjectType migrations-php-phpstan-add-prefix-for-anything-that-starts-with-vendor-in-a-list migrations-php-set-phpstan-drop-include-test-utilities-rules migrations-php-set-phpstan-drop-include-async-test-utilities-rules migrations-php-set-rector-create-config-if-not-exists migrations-php-update-rector-from-testutilities-to-rectorphp-namespace-for-rector-config migrations-php-composer-unused-create-config-if-not-exists migrations-php-composer-unused-drop-commented-out-line-scattered-across-my-repos migrations-php-migrate-composer-unused-from-extra-unused-to-etc-qa-composer-used-php migrations-php-move-phpcs migrations-php-move-phpcs-not-dist migrations-php-set-phpcs-ensure-config-file-exists migrations-php-phpcs-make-basepath-is-correct-relatively migrations-php-phpcs-make-cache-is-correct-relatively migrations-php-phpcs-make-sure-config-has-correct-relative-path-for-etc migrations-php-phpcs-make-sure-etc-has-no-trailing-slash migrations-php-phpcs-make-sure-config-has-correct-relative-path-for-src migrations-php-phpcs-make-sure-src-has-no-trailing-slash migrations-php-phpcs-make-sure-config-has-correct-relative-path-for-tests migrations-php-phpcs-make-sure-tests-has-no-trailing-slash migrations-php-phpcs-make-sure-etc-is-ran-through migrations-phpcs-include-examples-directory-when-present migrations-php-move-composer-require-checker migrations-php-composer-require-checker-create-config-if-not-exists migrations-inline-code-phpstan-remove-line-phpstan-ignore-next-line migrations-inline-code-phpstan-remove-rest-of-line-phpstan-ignore-line migrations-inline-code-psalm-remove-line-psalm-suppress migrations-inline-code-remove-line-internal migrations-inline-code-phpunit-replace-expectexceptionmessage-with-expectexceptionmessageisorcontains migrations-supported-features-php-ensure-we-only-cs-check-and-fix-tests-if-unit-tests-is-enabled migrations-supported-features-php-ensure-we-only-staticly-analyse-tests-with-phpstan-if-unit-tests-is-enabled migrations-supported-features-php-ensure-no-phpunit-config-file-is-present-when-unit-tests-are-disabled migrations-supported-features-php-ensure-no-infectionphp-config-file-is-present-when-unit-tests-are-disabled migrations-supported-features-php-ensure-no-rector-config-file-is-present-when-code-style-is-disabled migrations-supported-features-php-ensure-no-phpcs-config-file-is-present-when-code-style-is-disabled migrations-supported-features-php-ensure-no-composer-require-checker-config-file-is-present-when-composer-dependency-checkers-are-disabled migrations-supported-features-php-ensure-no-composer-unused-config-file-is-present-when-composer-dependency-checkers-are-disabled migrations-php-make-sure-github-exists migrations-github-codeowners migrations-php-make-sure-github-workflows-exists migrations-github-actions-remove-composer-diff migrations-github-actions-remove-markdown-check-links migrations-github-actions-remove-markdown-craft-release migrations-github-actions-remove-set-milestone-on-pr migrations-github-actions-move-ci migrations-github-actions-remove-ci-if-its-old-style-php-ci-workflow migrations-github-actions-create-ci-if-not-exists migrations-github-actions-move-release-management migrations-github-actions-fix-management-in-release-management-referenced-workflow-file migrations-github-actions-create-release-management-if-not-exists migrations-github-actions-ensure-runs-on-is-the-only-runs-on-variant-in-utils-yaml migrations-github-actions-pin-package-workflow-reference-at-v1-0-0 migrations-renovate-remove-dependabot-config migrations-renovate-move-config migrations-renovate-create-config-if-not-exists migrations-renovate-point-at-correct-config migrations-renovate-set-php-constraint migrations-renovate-set-composer-constraint migrations-git-enforce-agents-md-contents composer-validate syntax-php composer-normalize rector-upgrade cs-fix ## Count: 113
else
	$(DOCKER_RUN_WITH_SOCKET) $(MAKE) migrations-git-enforce-gitattributes-contents migrations-git-enforce-editorconfig-contents migrations-git-make-sure-gitignore-exists migrations-git-make-sure-gitignore-ignores-var migrations-git-make-sure-gitignore-excludes-var-gitkeep migrations-docs-update-readme-copyright-c-year-to-current migrations-docs-update-readme-copyright-year-to-current migrations-docs-update-etc-readme-template-copyright-c-year-to-current migrations-docs-update-etc-readme-template-copyright-year-to-current migrations-docs-create-license-when-it-doesnt-exists migrations-docs-update-license-copyright-c-year-to-current migrations-docs-update-license-copyright-year-to-current migrations-docs-enforce-contributing-md-contents migrations-php-make-sure-var-exists migrations-php-make-sure-var-gitkeep-exists migrations-php-make-sure-etc-exists migrations-php-make-sure-etc-ci-exists migrations-php-make-sure-etc-qa-exists migrations-php-move-psalm-xml-config-to-etc migrations-php-remove-psalm-xml-config migrations-php-remove-old-phpunit-xml-dist-config migrations-php-remove-old-phpunit-xml-config migrations-php-remove-old-php-cs-fiver-config migrations-php-remove-old-scrutinizer-yml-config migrations-php-remove-old-appveyor-yml-config migrations-php-remove-old-travis-yml-config migrations-php-ensure-etc-ci-markdown-link-checker-json-exists migrations-php-ensure-etc-qa-coverage-guard-php-exists migrations-php-ensure-etc-qa-zzz-disable-otel-attr-hooks-ini-exists migrations-php-move-infection-config-to-etc migrations-php-infection-create-config-if-not-exists migrations-php-remove-phpunit-config-dir-from-infection migrations-php-fix-logs-relative-paths-for-infection migrations-php-infection-ensure-log-text-has-the-correct-path migrations-php-infection-ensure-log-summary-has-the-correct-path migrations-php-infection-ensure-log-json-has-the-correct-path migrations-php-infection-ensure-log-per-mutator-has-the-correct-path migrations-php-add-github-true-to-for-infection migrations-php-make-paths-compatible-with-infection-0-32 migrations-php-set-phpunit-ensure-config-file-exists migrations-php-set-phpunit-xsd-path-to-local migrations-php-set-phpunit-make-sure-we-see-all-the-warnings-deprecations-etc-etc-that-will-make-phpunit-do-a-non-happy-exit migrations-php-move-phpstan migrations-php-set-phpstan-ensure-config-file-exists migrations-php-set-phpstan-uncomment-parameters migrations-php-set-phpstan-add-parameters-if-it-isnt-present-in-the-config-file migrations-php-set-phpstan-paths-in-config migrations-php-set-phpstan-level-max-in-config migrations-php-set-phpstan-resolve-ergebnis-noExtends-classesAllowedToBeExtended migrations-php-set-phpstan-drop-checkGenericClassInNonGenericObjectType migrations-php-phpstan-add-prefix-for-anything-that-starts-with-vendor-in-a-list migrations-php-set-phpstan-drop-include-test-utilities-rules migrations-php-set-phpstan-drop-include-async-test-utilities-rules migrations-php-set-rector-create-config-if-not-exists migrations-php-update-rector-from-testutilities-to-rectorphp-namespace-for-rector-config migrations-php-composer-unused-create-config-if-not-exists migrations-php-composer-unused-drop-commented-out-line-scattered-across-my-repos migrations-php-migrate-composer-unused-from-extra-unused-to-etc-qa-composer-used-php migrations-php-move-phpcs migrations-php-move-phpcs-not-dist migrations-php-set-phpcs-ensure-config-file-exists migrations-php-phpcs-make-basepath-is-correct-relatively migrations-php-phpcs-make-cache-is-correct-relatively migrations-php-phpcs-make-sure-config-has-correct-relative-path-for-etc migrations-php-phpcs-make-sure-etc-has-no-trailing-slash migrations-php-phpcs-make-sure-config-has-correct-relative-path-for-src migrations-php-phpcs-make-sure-src-has-no-trailing-slash migrations-php-phpcs-make-sure-config-has-correct-relative-path-for-tests migrations-php-phpcs-make-sure-tests-has-no-trailing-slash migrations-php-phpcs-make-sure-etc-is-ran-through migrations-phpcs-include-examples-directory-when-present migrations-php-move-composer-require-checker migrations-php-composer-require-checker-create-config-if-not-exists migrations-inline-code-phpstan-remove-line-phpstan-ignore-next-line migrations-inline-code-phpstan-remove-rest-of-line-phpstan-ignore-line migrations-inline-code-psalm-remove-line-psalm-suppress migrations-inline-code-remove-line-internal migrations-inline-code-phpunit-replace-expectexceptionmessage-with-expectexceptionmessageisorcontains migrations-supported-features-php-ensure-we-only-cs-check-and-fix-tests-if-unit-tests-is-enabled migrations-supported-features-php-ensure-we-only-staticly-analyse-tests-with-phpstan-if-unit-tests-is-enabled migrations-supported-features-php-ensure-no-phpunit-config-file-is-present-when-unit-tests-are-disabled migrations-supported-features-php-ensure-no-infectionphp-config-file-is-present-when-unit-tests-are-disabled migrations-supported-features-php-ensure-no-rector-config-file-is-present-when-code-style-is-disabled migrations-supported-features-php-ensure-no-phpcs-config-file-is-present-when-code-style-is-disabled migrations-supported-features-php-ensure-no-composer-require-checker-config-file-is-present-when-composer-dependency-checkers-are-disabled migrations-supported-features-php-ensure-no-composer-unused-config-file-is-present-when-composer-dependency-checkers-are-disabled migrations-php-make-sure-github-exists migrations-github-codeowners migrations-php-make-sure-github-workflows-exists migrations-github-actions-remove-composer-diff migrations-github-actions-remove-markdown-check-links migrations-github-actions-remove-markdown-craft-release migrations-github-actions-remove-set-milestone-on-pr migrations-github-actions-move-ci migrations-github-actions-remove-ci-if-its-old-style-php-ci-workflow migrations-github-actions-create-ci-if-not-exists migrations-github-actions-move-release-management migrations-github-actions-fix-management-in-release-management-referenced-workflow-file migrations-github-actions-create-release-management-if-not-exists migrations-github-actions-ensure-runs-on-is-the-only-runs-on-variant-in-utils-yaml migrations-github-actions-pin-package-workflow-reference-at-v1-0-0 migrations-renovate-remove-dependabot-config migrations-renovate-move-config migrations-renovate-create-config-if-not-exists migrations-renovate-point-at-correct-config migrations-renovate-set-php-constraint migrations-renovate-set-composer-constraint migrations-git-enforce-agents-md-contents composer-validate syntax-php composer-normalize rector-upgrade cs-fix ## Count: 113
endif

composer-validate: ## Ensure we don't require any package we don't use in this package directly ##*IC*##
	$(DOCKER_SHELL) composer validate

syntax-php: ## Lint PHP syntax ##*ILH*##
	$(DOCKER_RUN) vendor/bin/parallel-lint --exclude vendor .

composer-normalize: ## Normalize composer.json ##*I*##
	@before="$$( $(DOCKER_RUN) php -r 'echo hash_file("sha512", "composer.json");' )"; \
	$(DOCKER_RUN) composer normalize --no-update-lock; \
	after="$$( $(DOCKER_RUN) php -r 'echo hash_file("sha512", "composer.json");' )"; \
	[ "$$before" = "$$after" ] || $(MAKE) update-lock

rector-upgrade: ## Upgrade any automatically upgradable old code ##*I*##^code-style^##
	$(DOCKER_RUN) vendor/bin/rector -c ./etc/qa/rector.php

cs-fix: ## Fix any automatically fixable code style issues ##*EI*##^code-style^##
	$(DOCKER_RUN) vendor/bin/phpcbf --parallel=1 --cache=./var/.phpcs.cache.json --standard=./etc/qa/phpcs.xml || $(MAKE) cs

cs-fix-debug: ## Fix any automatically fixable code style issues, but with debugging output ####^code-style^##
	$(DOCKER_RUN) vendor/bin/phpcbf --parallel=1 --cache=./var/.phpcs.cache.json --standard=./etc/qa/phpcs.xml -vvvv

cs: ## Check the code for code style issues ##*ELCH*##^code-style^##
	$(DOCKER_SHELL) vendor/bin/phpcs --parallel=1 --cache=./var/.phpcs.cache.json --standard=./etc/qa/phpcs.xml

stan: ## Run static analysis (PHPStan) ##*LCH*##^static-analysis^##
	$(DOCKER_SHELL) vendor/bin/phpstan analyse --ansi --configuration=./etc/qa/phpstan.neon

unit-testing: ## Run tests ##*AE*##^unit-tests^##
	$(DOCKER_RUN_WITH_SOCKET) vendor/bin/phpunit --colors=always -c ./etc/qa/phpunit.xml --coverage-text --coverage-html ./var/phpunit/coverage --coverage-clover ./var/phpunit/coverage/clover.xml
	$(MAKE) coverage-guard

unit-testing-filter: ## Run tests with specified filter ####^unit-tests^##
	$(DOCKER_RUN_WITH_SOCKET) vendor/bin/phpunit --colors=always --filter=$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS)) -c ./etc/qa/phpunit.xml --coverage-text --coverage-html ./var/phpunit/coverage --coverage-clover ./var/phpunit/coverage/clover.xml

unit-testing-raw: ## Run tests ##*D*##^unit-tests^##
	php vendor/phpunit/phpunit/phpunit --colors=always -c ./etc/qa/phpunit.xml --coverage-text --coverage-html ./var/phpunit/coverage --coverage-clover ./var/phpunit/coverage/clover.xml
	$(MAKE) coverage-guard-raw

coverage-guard: ## Enforce code coverage rules ####
	$(DOCKER_RUN) vendor/bin/coverage-guard check ./var/phpunit/coverage/clover.xml --config=./etc/qa/coverage-guard.php

coverage-guard-raw: ## Enforce code coverage rules ####
	php vendor/bin/coverage-guard check ./var/phpunit/coverage/clover.xml --config=./etc/qa/coverage-guard.php

mutation-testing: ## Run mutation testing ##*LCH*##^static-analysis|unit-tests^##
	$(DOCKER_RUN_WITH_SOCKET) vendor/bin/infection --ansi --log-verbosity=all --ignore-msi-with-no-mutations --configuration=./etc/qa/infection.json5 --static-analysis-tool=phpstan --static-analysis-tool-options="--memory-limit=-1" --threads=$(MUTATION_THREADS)

mutation-testing-raw: ## Run mutation testing ####^static-analysis|unit-tests^##
	vendor/bin/infection --ansi --log-verbosity=all --ignore-msi-with-no-mutations --configuration=./etc/qa/infection.json5 --static-analysis-tool=phpstan --static-analysis-tool-options="--memory-limit=-1" --threads=$(MUTATION_THREADS)

composer-require-checker: ## Ensure we require every package used in this package directly ##*EC*##^composer-dependency-checkers^##
	$(DOCKER_SHELL) vendor/bin/composer-require-checker --ignore-parse-errors --ansi -vvv --config-file=./etc/qa/composer-require-checker.json

composer-unused: ## Ensure we don't require any package we don't use in this package directly ##*EC*##^composer-dependency-checkers^##
	$(DOCKER_SHELL) vendor/bin/composer-unused --ansi --configuration=./etc/qa/composer-unused.php

backward-compatibility-check: ## Check code for backwards incompatible changes ##*C*##
	$(MAKE) backward-compatibility-check-raw || true

backward-compatibility-check-raw: ## Check code for backwards incompatible changes, doesn't ignore the failure ###
	$(DOCKER_SHELL) vendor/bin/roave-backward-compatibility-check

install: ### Install dependencies ####
ifeq ("$(ON_INSTALL_OR_UPDATE_HAS_DIRECT_DOCKER_TASKS)","TRUE")
	$(DOCKER_SHELL) composer install --no-scripts
	$(MAKE) on-install-or-update
else
	$(DOCKER_SHELL) composer install
endif

composer-require: ### Require passed dependencies ####
	$(DOCKER_INTERACTIVE_SHELL) composer require -W $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))

composer-why: ### Show why a specific dependency is loaded ####
	$(DOCKER_INTERACTIVE_SHELL) composer why $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))

composer-outdated: ### Show outdated packages ####
	$(DOCKER_SHELL) composer outdated

update: ### Update dependencies ####
ifeq ("$(ON_INSTALL_OR_UPDATE_HAS_DIRECT_DOCKER_TASKS)","TRUE")
	$(DOCKER_SHELL) composer update -W --no-scripts
	$(MAKE) on-install-or-update
else
	$(DOCKER_SHELL) composer update -W
endif

update-lock: ### Update lockfile ####
	$(DOCKER_RUN_WITHOUT_NETWORK_FOR_COMPOSER) composer update --lock --no-scripts || $(DOCKER_RUN) composer update --lock --no-scripts

outdated: ### Show outdated dependencies ####
	$(DOCKER_SHELL) composer outdated

composer-show: ### Show dependencies ####
	$(DOCKER_SHELL) composer show

shell: ## Provides Shell access in the expected environment ####
	$(DOCKER_INTERACTIVE_SHELL) bash

run: ## Provides access in the expected environment to run a single command and then return ####
	$(DOCKER_RUN) $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))

help: ## Show this help ####
	@printf "\033[33mUsage:\033[0m\n  make [target]\n\n\033[33mTargets:\033[0m\n"
	@printf '%b\n' 'all: ## Runs everything\nbackward-compatibility-check: ## Check code for backwards incompatible changes\nbackward-compatibility-check-raw: ## Check code for backwards incompatible changes, doesn'\''t ignore the failure\ncomposer-normalize: ## Normalize composer.json\ncomposer-outdated: ## Show outdated packages\ncomposer-require: ## Require passed dependencies\ncomposer-require-checker: ## Ensure we require every package used in this package directly\ncomposer-show: ## Show dependencies\ncomposer-unused: ## Ensure we don'\''t require any package we don'\''t use in this package directly\ncomposer-validate: ## Ensure we don'\''t require any package we don'\''t use in this package directly\ncomposer-why: ## Show why a specific dependency is loaded\ncontrib: ## Runs a subset of everything (all)\ncoverage-guard: ## Enforce code coverage rules\ncoverage-guard-raw: ## Enforce code coverage rules\ncs: ## Check the code for code style issues\ncs-fix: ## Fix any automatically fixable code style issues\ncs-fix-debug: ## Fix any automatically fixable code style issues, but with debugging output\nhelp: ## Show this help\nhelp-contrib: ## Show the migrations help\nhelp-migrations: ## Show the migrations help\ninstall: ## Install dependencies\nmutation-testing: ## Run mutation testing\nmutation-testing-raw: ## Run mutation testing\non-install-or-update: ## Tasks, like migrations, that specifically have be run after composer install or update. These will also run by self hosted Renovate\noutdated: ## Show outdated dependencies\nrector-upgrade: ## Upgrade any automatically upgradable old code\nrun: ## Provides access in the expected environment to run a single command and then return\nshell: ## Provides Shell access in the expected environment\nstan: ## Run static analysis (PHPStan)\nsupported-features: ## CI: List the features this package supports\nsyntax-php: ## Lint PHP syntax\ntask-list-ci-all: ## CI: Generate a JSON array of jobs to run on all variations\ntask-list-ci-dos: ## CI: Generate a JSON array of jobs to run Directly on the OS variations\ntask-list-ci-high: ## CI: Generate a JSON array of jobs to run against the highest dependencies on the primary threading target\ntask-list-ci-locked: ## CI: Generate a JSON array of jobs to run against the locked dependencies on the primary threading target\ntask-list-ci-low: ## CI: Generate a JSON array of jobs to run against the lowest dependencies on the primary threading target\nunit-testing: ## Run tests\nunit-testing-filter: ## Run tests with specified filter\nunit-testing-raw: ## Run tests\nupdate: ## Update dependencies\nupdate-lock: ## Update lockfile' | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[32m%-32s\033[0m %s\n", $$1, $$2}' | tr -d '#'

help-migrations: ## Show the migrations help ####
	@printf "\033[33mUsage:\033[0m\n  make [target]\n\n\033[33mTargets:\033[0m\n"
	@printf '%b\n' 'migrations-docs-create-license-when-it-doesnt-exists: ## Create license when it doesn'\''t exists\nmigrations-docs-enforce-contributing-md-contents: ## Enforce CONTRIBUTING.md contents\nmigrations-docs-update-etc-readme-template-copyright-c-year-to-current: ## Update readme template in etc/ copyright year to current\nmigrations-docs-update-etc-readme-template-copyright-year-to-current: ## Update readme template in etc/ copyright year to current\nmigrations-docs-update-license-copyright-c-year-to-current: ## Update license copyright year to current\nmigrations-docs-update-license-copyright-year-to-current: ## Update license copyright year to current\nmigrations-docs-update-readme-copyright-c-year-to-current: ## Update readme copyright year to current\nmigrations-docs-update-readme-copyright-year-to-current: ## Update readme copyright year to current\nmigrations-git-enforce-agents-md-contents: ## Enforce `AGENTS.md` contents\nmigrations-git-enforce-editorconfig-contents: ## Enforce `.editorconfig` contents\nmigrations-git-enforce-gitattributes-contents: ## Enforce `.gitattributes` contents\nmigrations-git-make-sure-gitignore-excludes-var-gitkeep: ## Make sure `.gitignore` excludes `var/.gitkeep`\nmigrations-git-make-sure-gitignore-exists: ## Make sure `.gitignore` exists\nmigrations-git-make-sure-gitignore-ignores-var: ## Make sure `.gitignore` ignores `var/*`\nmigrations-github-actions-create-ci-if-not-exists: ## Create CI Workflow if it doesn'\''t exists at `.github/workflows/ci.yaml`\nmigrations-github-actions-create-release-management-if-not-exists: ## Create Release Management Workflow if it doesn'\''t exists at `.github/workflows/release-management.yaml`\nmigrations-github-actions-ensure-runs-on-is-the-only-runs-on-variant-in-utils-yaml: ## Ensure `runsOn` is the only `runsOn` variant in `.github/workflows/utils.yaml`\nmigrations-github-actions-fix-management-in-release-management-referenced-workflow-file: ## Fix management in release-management referenced workflow file\nmigrations-github-actions-move-ci: ## Move `.github/workflows/ci.yml` to `.github/workflows/ci.yaml`\nmigrations-github-actions-move-release-management: ## Move `.github/workflows/release-managment.yaml` to `.github/workflows/release-management.yaml`\nmigrations-github-actions-pin-package-workflow-reference-at-v1-0-0: ## Pin WyriHaximus/github-workflows reusable workflow references to SHA `5343944be2a6ef963186b5f413121fcf36980b33` (`v1.0.0`) in `.github/workflows`\nmigrations-github-actions-remove-ci-if-its-old-style-php-ci-workflow: ## Remove CI Workflow if its the old style PHP CI Workflow\nmigrations-github-actions-remove-composer-diff: ## Remove `composer-diff.yaml` it has been folded into centralized workflows through `ci.yaml`\nmigrations-github-actions-remove-markdown-check-links: ## Remove `markdown-check-links.yaml` it has been folded into centralized workflows through `ci.yaml`\nmigrations-github-actions-remove-markdown-craft-release: ## Remove `craft-release.yaml` it has been folded into centralized workflows through `release-management.yaml`\nmigrations-github-actions-remove-set-milestone-on-pr: ## Remove `set-milestone-on-pr.yaml` it has been folded into centralized workflows through `release-management.yaml`\nmigrations-github-codeowners: ## Ensure a `CODEOWNERS` file is present, create only if it doesn'\''t exist yet\nmigrations-inline-code-phpstan-remove-line-phpstan-ignore-next-line: ## Remove all lines that contains @phpstan-ignore-next-line\nmigrations-inline-code-phpstan-remove-rest-of-line-phpstan-ignore-line: ## Remove rest of line for all lines that contain @phpstan-ignore-line\nmigrations-inline-code-phpunit-replace-expectexceptionmessage-with-expectexceptionmessageisorcontains: ## Replace self::expectExceptionMessage with self::expectExceptionMessageIsOrContains in all PHPUnit tests\nmigrations-inline-code-psalm-remove-line-psalm-suppress: ## Remove all lines that contain @psalm-suppress\nmigrations-inline-code-remove-line-internal: ## Remove all lines that contain @internal\nmigrations-php-add-github-true-to-for-infection: ## Ensure we configure infection to emit logs to GitHub in `etc/qa/infection.json5`\nmigrations-php-composer-require-checker-create-config-if-not-exists: ## Create Composer Require Checker config file if it doesn'\''t exists at `etc/qa/composer-require-checker.json`\nmigrations-php-composer-unused-create-config-if-not-exists: ## Create Composer Unused config file if it doesn'\''t exists at `etc/qa/composer-unused.php`\nmigrations-php-composer-unused-drop-commented-out-line-scattered-across-my-repos: ## Update Composer Unused config file dropping a commented out line that is scattered cross my repos\nmigrations-php-ensure-etc-ci-markdown-link-checker-json-exists: ## Make sure we have `etc/ci/markdown-link-checker.json`\nmigrations-php-ensure-etc-qa-coverage-guard-php-exists: ## Make sure we have `etc/qa/coverage-guard.php`\nmigrations-php-ensure-etc-qa-zzz-disable-otel-attr-hooks-ini-exists: ## Make sure we have `etc/qa/zzz_disable_otel_attr_hooks.ini`\nmigrations-php-fix-logs-relative-paths-for-infection: ## Fix logs paths in `etc/qa/infection.json5`\nmigrations-php-infection-create-config-if-not-exists: ## Create Infection config file if it doesn'\''t exists at `etc/qa/infection.json5`\nmigrations-php-infection-ensure-log-json-has-the-correct-path: ## Ensure infection'\''s log.json has config directive has the correct path\nmigrations-php-infection-ensure-log-per-mutator-has-the-correct-path: ## Ensure infection'\''s log.perMutator has config directive has the correct path\nmigrations-php-infection-ensure-log-summary-has-the-correct-path: ## Ensure infection'\''s log.summary has config directive has the correct path\nmigrations-php-infection-ensure-log-text-has-the-correct-path: ## Ensure infection'\''s log.text has config directive has the correct path\nmigrations-php-make-paths-compatible-with-infection-0-32: ## We update path to be relative to `etc/qa/infection.json5` as of 0.32\nmigrations-php-make-sure-etc-ci-exists: ## Make sure `etc/ci/` exists\nmigrations-php-make-sure-etc-exists: ## Make sure `etc/` exists\nmigrations-php-make-sure-etc-qa-exists: ## Make sure `etc/qa/` exists\nmigrations-php-make-sure-github-exists: ## Make sure `.github/` exists\nmigrations-php-make-sure-github-workflows-exists: ## Make sure `.github/workflows` exists\nmigrations-php-make-sure-var-exists: ## Make sure `var/` exists\nmigrations-php-make-sure-var-gitkeep-exists: ## Make sure `var/.gitkeep` exists\nmigrations-php-migrate-composer-unused-from-extra-unused-to-etc-qa-composer-used-php: ## Migrate Compose Unused from `composer.json` extra unused to `etc/qa/composer-unused.php`\nmigrations-php-move-composer-require-checker: ## Move composer-require-checker.json to `etc/qa/composer-require-checker.json`\nmigrations-php-move-infection-config-to-etc: ## Move `infection.json.dist` to `etc/qa/infection.json5`\nmigrations-php-move-phpcs: ## Move `phpcs.xml.dist` to `etc/qa/phpcs.xml`\nmigrations-php-move-phpcs-not-dist: ## Move `phpcs.xml` to `etc/qa/phpcs.xml`\nmigrations-php-move-phpstan: ## Move `phpstan.neon` to `etc/qa/phpstan.neon`\nmigrations-php-move-psalm-xml-config-to-etc: ## Move `psalm.xml` to `etc/qa/psalm.xml`\nmigrations-php-phpcs-make-basepath-is-correct-relatively: ## Make sure PHPCS base path is has `../../` and not `.`\nmigrations-php-phpcs-make-cache-is-correct-relatively: ## Make sure PHPCS cache path is has `../../var/.phpcs.cache` and not `.phpcs.cache`\nmigrations-php-phpcs-make-sure-config-has-correct-relative-path-for-etc: ## Make sure PHPCS has `../../` prefixing `etc/` to ensure correct relative path\nmigrations-php-phpcs-make-sure-config-has-correct-relative-path-for-src: ## Make sure PHPCS has `../../` prefixing `src/` to ensure correct relative path\nmigrations-php-phpcs-make-sure-config-has-correct-relative-path-for-tests: ## Make sure PHPCS has `../../` prefixing `tests/` to ensure correct relative path\nmigrations-php-phpcs-make-sure-etc-has-no-trailing-slash: ## Make sure PHPCS has no tailing `/` on `etc`\nmigrations-php-phpcs-make-sure-etc-is-ran-through: ## Make sure PHPCS runs through `etc`\nmigrations-php-phpcs-make-sure-src-has-no-trailing-slash: ## Make sure PHPCS has no tailing `/` on src\nmigrations-php-phpcs-make-sure-tests-has-no-trailing-slash: ## Make sure PHPCS has no tailing `/` on `tests`\nmigrations-php-phpstan-add-prefix-for-anything-that-starts-with-vendor-in-a-list: ## PHPStan add `../../` to anything in a list that starts with `vendor`\nmigrations-php-remove-old-appveyor-yml-config: ## Make sure we remove `appveyor.yml`\nmigrations-php-remove-old-php-cs-fiver-config: ## Make sure we remove `.php_cs`\nmigrations-php-remove-old-phpunit-xml-config: ## Make sure we remove `phpunit.xml`\nmigrations-php-remove-old-phpunit-xml-dist-config: ## Make sure we remove `phpunit.xml.dist`\nmigrations-php-remove-old-scrutinizer-yml-config: ## Make sure we remove `.scrutinizer.yml`\nmigrations-php-remove-old-travis-yml-config: ## Make sure we remove `.travis.yml`\nmigrations-php-remove-phpunit-config-dir-from-infection: ## Drop XXX from `etc/qa/infection.json5`\nmigrations-php-remove-psalm-xml-config: ## Make sure we remove `etc/qa/psalm.xml`\nmigrations-php-set-phpcs-ensure-config-file-exists: ## Make sure we have a PHPCS config file at `etc/qa/phpcs.xml`\nmigrations-php-set-phpstan-add-parameters-if-it-isnt-present-in-the-config-file: ## Add parameters to PHPStan config file at `etc/qa/phpstan.neon` if it'\''s not present\nmigrations-php-set-phpstan-drop-checkGenericClassInNonGenericObjectType: ## Ensure PHPStan config doesn'\''t contain checkGenericClassInNonGenericObjectType as it'\''s no longer a valid config option\nmigrations-php-set-phpstan-drop-include-async-test-utilities-rules: ## Ensure PHPStan config doesn'\''t contain include for `wyrihaximus/async-test-utilities/rules.neon` as it'\''s now an extension\nmigrations-php-set-phpstan-drop-include-test-utilities-rules: ## Ensure PHPStan config doesn'\''t contain include for `wyrihaximus/async-utilities/rules.neon` as it'\''s now an extension\nmigrations-php-set-phpstan-ensure-config-file-exists: ## Make sure we have a PHPStan config file at `etc/qa/phpstan.neon`\nmigrations-php-set-phpstan-level-max-in-config: ## Ensure PHPStan config has level set to max in `etc/qa/phpstan.neon`\nmigrations-php-set-phpstan-paths-in-config: ## Ensure PHPStan config has the `etc`, `src`, and (optionally) `tests` paths set in `etc/qa/phpstan.neon`\nmigrations-php-set-phpstan-resolve-ergebnis-noExtends-classesAllowedToBeExtended: ## Ensure PHPStan config uses ergebnis.noExtends.classesAllowedToBeExtended not ergebnis.classesAllowedToBeExtended\nmigrations-php-set-phpstan-uncomment-parameters: ## Ensure PHPStan config as parameters not commented out in `etc/qa/phpstan.neon`\nmigrations-php-set-phpunit-ensure-config-file-exists: ## Make sure we have a PHPUnit config file at `etc/qa/phpunit.xml`\nmigrations-php-set-phpunit-make-sure-we-see-all-the-warnings-deprecations-etc-etc-that-will-make-phpunit-do-a-non-happy-exit: ## Make sure we see all the warnings, deprecations, etc etc that will make PHPunit do a non-happy exit\nmigrations-php-set-phpunit-xsd-path-to-local: ## Ensure that the PHPUnit XDS referred in `etc/qa/phpunit.xml` points to `vendor/phpunit/phpunit/phpunit.xsd` so we don'\''t go over the network\nmigrations-php-set-rector-create-config-if-not-exists: ## Create Rector config file if it doesn'\''t exists at `etc/qa/rector.php`\nmigrations-php-update-rector-from-testutilities-to-rectorphp-namespace-for-rector-config: ## Update RectorPHP config file `etc/qa/rector.php` from `TestUtilities` to `RectorPHP` namespace\nmigrations-phpcs-include-examples-directory-when-present: ## Make sure PHPCS runs through `examples` when it exists\nmigrations-renovate-create-config-if-not-exists: ## Create Renovate Config if it doesn'\''t exists at `.github/renovate.json`\nmigrations-renovate-move-config: ## Move `renovate.json` to `.github/renovate.json`\nmigrations-renovate-point-at-correct-config: ## Ensure `.github/renovate.json` points at github>WyriHaximus/renovate-config:php-package instead of local>WyriHaximus/renovate-config\nmigrations-renovate-remove-dependabot-config: ## Make sure we remove `.github/dependabot.yml`\nmigrations-renovate-set-composer-constraint: ## Always keep renovate'\''s `constraints.composer` at `2.x`\nmigrations-renovate-set-php-constraint: ## Always keep renovate'\''s constraints.php in sync with `composer.json`'\''s `config.platform.php`\nmigrations-supported-features-php-ensure-no-composer-require-checker-config-file-is-present-when-composer-dependency-checkers-are-disabled: ## Ensure we remove the Composer Require Checker config file when composer-dependency-checkers aren'\''t enabled\nmigrations-supported-features-php-ensure-no-composer-unused-config-file-is-present-when-composer-dependency-checkers-are-disabled: ## Ensure we remove the Composer Unused config file when composer-dependency-checkers aren'\''t enabled\nmigrations-supported-features-php-ensure-no-infectionphp-config-file-is-present-when-unit-tests-are-disabled: ## Ensure we remove the InfectionPHP config file when unit-tests aren'\''t enabled\nmigrations-supported-features-php-ensure-no-phpcs-config-file-is-present-when-code-style-is-disabled: ## Ensure we remove the PHPCSS config file when code-style isn'\''t enabled\nmigrations-supported-features-php-ensure-no-phpunit-config-file-is-present-when-unit-tests-are-disabled: ## Ensure we remove the PHPUnit config file when unit-tests aren'\''t enabled\nmigrations-supported-features-php-ensure-no-rector-config-file-is-present-when-code-style-is-disabled: ## Ensure we remove the RectorPHP config file when code-style isn'\''t enabled\nmigrations-supported-features-php-ensure-we-only-cs-check-and-fix-tests-if-unit-tests-is-enabled: ## Ensure we only cs check/fix tests/ if unit-tests is enabled\nmigrations-supported-features-php-ensure-we-only-staticly-analyse-tests-with-phpstan-if-unit-tests-is-enabled: ## Ensure we only staticly analyse tests/ with PHPStan if unit-tests is enabled' | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[32m%-32s\033[0m %s\n", $$1, $$2}' | tr -d '#'

help-contrib: ## Show the migrations help ####
	@printf "\033[33mUsage:\033[0m\n  make [target]\n\n\033[33mTargets:\033[0m\n"
	@printf '%b\n' 'composer-require-checker: ## Ensure we require every package used in this package directly\ncomposer-unused: ## Ensure we don'\''t require any package we don'\''t use in this package directly\ncs: ## Check the code for code style issues\ncs-fix: ## Fix any automatically fixable code style issues\nunit-testing: ## Run tests' | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[32m%-32s\033[0m %s\n", $$1, $$2}' | tr -d '#'

task-list-ci:
	@echo "[]"

task-list-ci-all: ## CI: Generate a JSON array of jobs to run on all variations
	@echo "[\"composer-validate\",\"syntax-php\",\"cs\",\"stan\",\"unit-testing\",\"mutation-testing\",\"composer-require-checker\",\"composer-unused\",\"backward-compatibility-check\"]" ## Count: 9

task-list-ci-dos: ## CI: Generate a JSON array of jobs to run Directly on the OS variations
	@echo "[\"unit-testing-raw\"]" ## Count: 1

task-list-ci-low: ## CI: Generate a JSON array of jobs to run against the lowest dependencies on the primary threading target
	@echo "[\"syntax-php\",\"cs\",\"stan\",\"mutation-testing\"]" ## Count: 4

task-list-ci-locked: ## CI: Generate a JSON array of jobs to run against the locked dependencies on the primary threading target
	@echo "[\"composer-validate\",\"cs\",\"stan\",\"mutation-testing\",\"composer-require-checker\",\"composer-unused\",\"backward-compatibility-check\"]" ## Count: 7

task-list-ci-high: ## CI: Generate a JSON array of jobs to run against the highest dependencies on the primary threading target
	@echo "[\"syntax-php\",\"cs\",\"stan\",\"mutation-testing\"]" ## Count: 4

supported-features: ## CI: List the features this package supports
	@echo "[\"code-style\",\"composer-dependency-checkers\",\"linux\",\"macos\",\"static-analysis\",\"unit-tests\",\"windows\"]" ## Count: 7


## Catch-all for targets that pass through extra arguments (e.g. `make run ls`)
%:
	@:

