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
ALL_HAS_DIRECT_DOCKER_TASKS=TRUE
CONTRIB_HAS_DIRECT_DOCKER_TASKS=TRUE
ON_INSTALL_OR_UPDATE_HAS_DIRECT_DOCKER_TASKS=TRUE
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

ifeq ("$(IN_DOCKER)","TRUE")
	DOCKER_RUN:=
	DOCKER_RUN_WITHOUT_NETWORK_FOR_COMPOSER:=
	DOCKER_RUN_WITH_SOCKET:=
	DOCKER_SHELL:=
	DOCKER_INTERACTIVE_SHELL:=
	DOCKER_DEFAULT_SECURITY_OPS=
	DOCKER_WORKSPACE_BIND_OPS=--volumes-from $$(cat /etc/hostname) -w "`pwd`"
else
    ifeq ($(DOCKER_AVAILABLE),0)
        DOCKER_DEFAULT_SECURITY_OPS=--cap-drop=ALL --security-opt="no-new-privileges=true" --user="`id -u`:`id -g`"
        DOCKER_WORKSPACE_BIND_OPS=-v "`pwd`:`pwd`" -w "`pwd`"
        DOCKER_COMMON_OPS:=-v "`pwd`:`pwd`" -w "`pwd`" -v "`pwd`/.git:`pwd`/.git:ro" -v "${COMPOSER_CACHE_DIR}:${COMPOSER_CONTAINER_CACHE_DIR}" --ulimit nofile=1000000 -e THREADS="${THREADS}" -e XDG_DATA_HOME="`pwd`/var/cache/xdg" -e OTEL_PHP_DISABLED_INSTRUMENTATIONS="all"
        ifneq ("$(wildcard etc/qa/zzz_disable_otel_attr_hooks.ini)","")
            DOCKER_COMMON_OPS:=${DOCKER_COMMON_OPS} -v "`pwd`/etc/qa/zzz_disable_otel_attr_hooks.ini:/usr/local/etc/php/conf.d/zzz_disable_otel_attr_hooks.ini:ro"
        endif
        DOCKER_COMMON_NON_INTERACTIVE_OPS:=-e OTEL_PHP_FIBERS_ENABLED="${OTEL_PHP_FIBERS_ENABLED}"
        DOCKER_COMMON_INTERACTIVE_OPS:=-e OTEL_PHP_FIBERS_ENABLED="false"
        ifneq ("$(wildcard /var/run/docker.sock)","")
            DOCKER_SOCKET_OPS:=-v "/var/run/docker.sock:/var/run/docker.sock"
            DOCKER_SOCKET_GID:=$(shell stat -c '%g' /var/run/docker.sock 2>/dev/null || stat -f '%Ng' /var/run/docker.sock 2>/dev/null || echo 997)
            DOCKER_SOCKET_SECURITY_OPS:=--user="`id -u`:$(DOCKER_SOCKET_GID)"
        else
            DOCKER_SOCKET_OPS:=
            DOCKER_SOCKET_SECURITY_OPS:=
            DOCKER_SOCKET_GID:=
        endif
        ifeq ("$(NEEDS_DOCKER_SOCKET)","TRUE")
            ifneq ("$(wildcard /var/run/docker.sock)","")
                DOCKER_SECURITY_OPS:=
                DOCKER_SOCKET_CONTAINER_NAME_SUFFIX:=-root
            else
                DOCKER_SECURITY_OPS:=${DOCKER_DEFAULT_SECURITY_OPS}
                DOCKER_SOCKET_CONTAINER_NAME_SUFFIX:=
            endif
        else
            DOCKER_SECURITY_OPS:=${DOCKER_DEFAULT_SECURITY_OPS}
            DOCKER_SOCKET_CONTAINER_NAME_SUFFIX:=
        endif
        DOCKER_RUN:=docker run --rm -i ${DOCKER_SECURITY_OPS} ${DOCKER_COMMON_NON_INTERACTIVE_OPS} ${DOCKER_COMMON_OPS} "${CONTAINER_NAME}"
        DOCKER_RUN_WITHOUT_NETWORK_FOR_COMPOSER:=docker run --rm -i ${DOCKER_SECURITY_OPS} ${DOCKER_COMMON_NON_INTERACTIVE_OPS} -e COMPOSER_DISABLE_NETWORK="1" ${DOCKER_COMMON_OPS} "${CONTAINER_NAME}"
        DOCKER_RUN_WITH_SOCKET:=docker run --rm -i ${DOCKER_SOCKET_SECURITY_OPS} ${DOCKER_COMMON_NON_INTERACTIVE_OPS} ${DOCKER_COMMON_OPS} ${DOCKER_SOCKET_OPS} "${CONTAINER_NAME}${DOCKER_SOCKET_CONTAINER_NAME_SUFFIX}"
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
        DOCKER_DEFAULT_SECURITY_OPS=
        DOCKER_WORKSPACE_BIND_OPS=
    endif
endif

INFECTION_THREADS_DETECT=php -r '$$f="etc/qa/infection.json5"; if (!is_file($$f)) {echo "0"; exit;} $$j=json_decode(file_get_contents($$f), true); echo (is_array($$j) && array_key_exists("threads", $$j)) ? "1" : "0";'
ifeq ("$(IN_DOCKER)","TRUE")
    INFECTION_CONFIG_HAS_THREADS=$(shell $(INFECTION_THREADS_DETECT))
else ifneq ($(strip $(DOCKER_RUN)),)
    INFECTION_CONFIG_HAS_THREADS=$(shell $(DOCKER_RUN) $(INFECTION_THREADS_DETECT))
else
    INFECTION_CONFIG_HAS_THREADS=$(shell $(INFECTION_THREADS_DETECT))
endif
INFECTION_THREADS_CLI=$(if $(filter 1,$(INFECTION_CONFIG_HAS_THREADS)),,--threads=$(if $(filter TRUE,$(IN_CI)),1,$(THREADS)))

ifeq ("$(IN_DOCKER)","TRUE")
    ifneq ("$(wildcard /var/run/docker.sock)","")
        DOCKER_RUN_DOCUMENTATION=docker run --rm -i --user="`id -u`:`id -g`" $(DOCKER_WORKSPACE_BIND_OPS)
    else
        DOCKER_RUN_DOCUMENTATION=
    endif
else
    DOCKER_RUN_DOCUMENTATION=docker run --rm -i $(DOCKER_DEFAULT_SECURITY_OPS) $(DOCKER_WORKSPACE_BIND_OPS)
endif

## Run everything extra points
all: ## Runs everything ####
ifeq ("$(ALL_HAS_DIRECT_DOCKER_TASKS)","TRUE")
	$(MAKE) all-raw
else
	$(DOCKER_RUN_WITH_SOCKET) make all-raw
endif
all-raw: ## The real runs everything, but due to sponge it has to be ran inside DOCKER_RUN ##U##
	$(MAKE) composer-validate syntax-php composer-normalize rector-upgrade cs-fix cs stan unit-testing mutation-testing composer-require-checker composer-unused backward-compatibility-check documentation-qa ## Count: 13


## Run a subset of everything for those that find everything intimidating
contrib: ## Runs a subset of everything (all) ####
ifeq ("$(CONTRIB_HAS_DIRECT_DOCKER_TASKS)","TRUE")
	$(MAKE) contrib-raw
else
	$(DOCKER_RUN_WITH_SOCKET) make contrib-raw
endif
contrib-raw: ## The real runs everything, but due to sponge it has to be ran inside DOCKER_RUN ##U##
	$(MAKE) cs-fix cs unit-testing composer-require-checker composer-unused documentation-qa ## Count: 6


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

migrations-git-make-sure-gitignore-ignores-vale-styles-except-vocab: #### Ignore Vale styles except WyriHaximus vocab symlink ##*I*##
	($(DOCKER_RUN) php -r '$$gitignoreFile = ".gitignore"; if (!file_exists($$gitignoreFile)) {exit;} $$txt = file_get_contents($$gitignoreFile); if (!is_string($$txt)) {exit;} if (strpos($$txt, "etc/qa/vale/**") !== false) {exit;} file_put_contents($$gitignoreFile, "etc/qa/vale/**\n!etc/qa/vale/styles/\n!etc/qa/vale/styles/config/\n!etc/qa/vale/styles/config/vocabularies/\n!etc/qa/vale/styles/config/vocabularies/WyriHaximus/\n!etc/qa/vale/styles/config/vocabularies/WyriHaximus/accept.txt\n", FILE_APPEND);' || true)

migrations-docs-update-readme-copyright-to-unicode-and-year: #### Convert readme copyright symbol to Unicode and update year ##*I*##
	($(DOCKER_RUN) php -r '$$file = "README.md"; $$currentYear = date("Y"); if (!file_exists($$file)) {exit;} $$content = file_get_contents($$file); $$content = str_replace("Copyright (c)", "Copyright ©", $$content); foreach (range(2000, 2100) as $$year) { $$content = str_replace("Copyright $$year ", "Copyright $$currentYear ", $$content); } file_put_contents($$file, $$content);' || true)

migrations-docs-update-readme-copyright-unicode-year-to-current: #### Update readme copyright year (unicode symbol) to current ##*I*##
	($(DOCKER_RUN) php -r '$$file = "README.md"; $$copyRight = "Copyright © "; $$currentYear = date("Y"); if (!file_exists($$file)) {exit;} $$content = file_get_contents($$file); foreach (range(2000, 2100) as $$year) { $$content = str_replace($$copyRight . $$year,  $$copyRight . $$currentYear, $$content); } file_put_contents($$file, $$content);' || true)

migrations-docs-update-etc-readme-template-copyright-to-unicode-and-year: #### Convert readme template copyright symbol to Unicode and update year ##*I*##
	($(DOCKER_RUN) php -r '$$file = "etc/README.md.twig"; $$currentYear = date("Y"); if (!file_exists($$file)) {exit;} $$content = file_get_contents($$file); $$content = str_replace("Copyright (c)", "Copyright ©", $$content); foreach (range(2000, 2100) as $$year) { $$content = str_replace("Copyright $$year ", "Copyright $$currentYear ", $$content); } file_put_contents($$file, $$content);' || true)

migrations-docs-update-etc-readme-template-copyright-unicode-year-to-current: #### Update readme template copyright year (unicode symbol) to current ##*I*##
	($(DOCKER_RUN) php -r '$$file = "etc/README.md.twig"; $$copyRight = "Copyright © "; $$currentYear = date("Y"); if (!file_exists($$file)) {exit;} $$content = file_get_contents($$file); foreach (range(2000, 2100) as $$year) { $$content = str_replace($$copyRight . $$year,  $$copyRight . $$currentYear, $$content); } file_put_contents($$file, $$content);' || true)

migrations-docs-create-license-when-it-doesnt-exists: #### Create license when it doesn't exists ##*I*##
	($(DOCKER_RUN) php -r '$$licenseFile = "LICENSE"; $$composerFIle = "composer.json"; if (file_exists($$licenseFile)) {exit;} if (file_exists($$composerFIle)) {$$json = json_decode(file_get_contents($$composerFIle), true); if (array_key_exists("license", $$json)) {if ($$json["license"] === "proprietary") {exit;}}}  file_put_contents($$licenseFile, base64_decode("VGhlIE1JVCBMaWNlbnNlIChNSVQpCgpDb3B5cmlnaHQgKGMpIDIwMDEgQ2Vlcy1KYW4gS2lld2lldAoKUGVybWlzc2lvbiBpcyBoZXJlYnkgZ3JhbnRlZCwgZnJlZSBvZiBjaGFyZ2UsIHRvIGFueSBwZXJzb24gb2J0YWluaW5nIGEgY29weQpvZiB0aGlzIHNvZnR3YXJlIGFuZCBhc3NvY2lhdGVkIGRvY3VtZW50YXRpb24gZmlsZXMgKHRoZSAiU29mdHdhcmUiKSwgdG8gZGVhbAppbiB0aGUgU29mdHdhcmUgd2l0aG91dCByZXN0cmljdGlvbiwgaW5jbHVkaW5nIHdpdGhvdXQgbGltaXRhdGlvbiB0aGUgcmlnaHRzCnRvIHVzZSwgY29weSwgbW9kaWZ5LCBtZXJnZSwgcHVibGlzaCwgZGlzdHJpYnV0ZSwgc3VibGljZW5zZSwgYW5kL29yIHNlbGwKY29waWVzIG9mIHRoZSBTb2Z0d2FyZSwgYW5kIHRvIHBlcm1pdCBwZXJzb25zIHRvIHdob20gdGhlIFNvZnR3YXJlIGlzCmZ1cm5pc2hlZCB0byBkbyBzbywgc3ViamVjdCB0byB0aGUgZm9sbG93aW5nIGNvbmRpdGlvbnM6CgpUaGUgYWJvdmUgY29weXJpZ2h0IG5vdGljZSBhbmQgdGhpcyBwZXJtaXNzaW9uIG5vdGljZSBzaGFsbCBiZSBpbmNsdWRlZCBpbiBhbGwKY29waWVzIG9yIHN1YnN0YW50aWFsIHBvcnRpb25zIG9mIHRoZSBTb2Z0d2FyZS4KClRIRSBTT0ZUV0FSRSBJUyBQUk9WSURFRCAiQVMgSVMiLCBXSVRIT1VUIFdBUlJBTlRZIE9GIEFOWSBLSU5ELCBFWFBSRVNTIE9SCklNUExJRUQsIElOQ0xVRElORyBCVVQgTk9UIExJTUlURUQgVE8gVEhFIFdBUlJBTlRJRVMgT0YgTUVSQ0hBTlRBQklMSVRZLApGSVRORVNTIEZPUiBBIFBBUlRJQ1VMQVIgUFVSUE9TRSBBTkQgTk9OSU5GUklOR0VNRU5ULiBJTiBOTyBFVkVOVCBTSEFMTCBUSEUKQVVUSE9SUyBPUiBDT1BZUklHSFQgSE9MREVSUyBCRSBMSUFCTEUgRk9SIEFOWSBDTEFJTSwgREFNQUdFUyBPUiBPVEhFUgpMSUFCSUxJVFksIFdIRVRIRVIgSU4gQU4gQUNUSU9OIE9GIENPTlRSQUNULCBUT1JUIE9SIE9USEVSV0lTRSwgQVJJU0lORyBGUk9NLApPVVQgT0YgT1IgSU4gQ09OTkVDVElPTiBXSVRIIFRIRSBTT0ZUV0FSRSBPUiBUSEUgVVNFIE9SIE9USEVSIERFQUxJTkdTIElOIFRIRQpTT0ZUV0FSRS4K"));' || true)

migrations-docs-update-license-copyright-c-year-to-current: #### Update license copyright year to current ##*I*##
	($(DOCKER_RUN) php -r '$$licenseFile = "LICENSE"; $$copyRight = "Copyright © "; $$currentYear = date("Y"); if (!file_exists($$licenseFile)) {exit;} $$licenseContents = file_get_contents($$licenseFile); foreach (range(2000, 2100) as $$year) { $$licenseContents = str_replace($$copyRight . $$year,  $$copyRight . $$currentYear, $$licenseContents); } file_put_contents($$licenseFile, $$licenseContents); ' || true)

migrations-docs-update-license-copyright-year-to-current: #### Update license copyright year to current ##*I*##
	($(DOCKER_RUN) php -r '$$licenseFile = "LICENSE"; $$copyRight = "Copyright "; $$currentYear = date("Y"); if (!file_exists($$licenseFile)) {exit;} $$licenseContents = file_get_contents($$licenseFile); foreach (range(2000, 2100) as $$year) { $$licenseContents = str_replace($$copyRight . $$year,  $$copyRight . $$currentYear, $$licenseContents); } file_put_contents($$licenseFile, $$licenseContents); ' || true)

migrations-docs-enforce-contributing-md-contents: #### Enforce CONTRIBUTING.md contents ##*I*##
	($(DOCKER_RUN) php -r '$$contributingFile = "CONTRIBUTING.md"; $$contributingContents = base64_decode("IyBDb250cmlidXRpbmcKClB1bGwgcmVxdWVzdHMgYXJlIGhpZ2hseSBhcHByZWNpYXRlZC4gSGVyZSdzIGEgcXVpY2sgZ3VpZGUuCgpGb3JrLCB0aGVuIGNsb25lIHRoZSByZXBvOgoKICAgIGdpdCBjbG9uZSBnaXRAZ2l0aHViLmNvbTp5b3VyLXVzZXJuYW1lL1tyZXBvXS5naXQKCkluc3RhbGwgZGVwZW5kZW5jaWVzOgoKICAgIG1ha2UgaW5zdGFsbAoKV29yayBvbiB0aGUgY29udHJpYnV0aW9uIGFuZCBjaGVjayBpZiBpdCBwYXNzZXMgYWxsIFFBIGNoZWNrcyB3aXRoOgoKICAgIG1ha2UKCklmIHNvbWUgb2YgdGhlIFBIUFN0YW4gb3Igb3RoZXIgY2hlY2tzIGFyZSB0b28gc3RyaWN0IG9yIGludGltaWRhdGluZyB0aGF0IGlzIGZpbmUsIGZpbmlzaCB3aGF0IHlvdSB3YW50IHRvIGNvbnRyaWJ1dGUgYW5kIEknbGwgaGVscCB5b3Ugd2l0aCB0aG9zZSwgYnV0IHBsZWFzZSBtYWtlIHRoZSBmb2xsb3dpbmcgY29tbWFuZCBwYXNzZXMuIEl0IHJ1bnMgYSBzdWJzZXQgb2YgZXZlcnl0aGluZzoKCiAgICBtYWtlIGNvbnRyaWIKCllvdSBjYW4gbGlzdCBhbGwgdGhlIGNvbnRyaWIgY29tbWFuZHMgd2l0aDoKCiAgICBtYWtlIGhlbHAtY29udHJpYgoKIyMgRG9jdW1lbnRhdGlvbiBRQQoKQ2hhbmdlcyB0byBNYXJrZG93biAoYFJFQURNRS5tZGAsIGBDT05UUklCVVRJTkcubWRgLCBgQUdFTlRTLm1kYCwgYW5kIHNpbWlsYXIpIG11c3QgcGFzcyBkb2N1bWVudGF0aW9uIFFBLiBCb3RoIGBtYWtlYCBhbmQgYG1ha2UgY29udHJpYmAgcnVuIGBkb2N1bWVudGF0aW9uLXFhYCwgd2hpY2ggY2hlY2tzIHN0cnVjdHVyZSAoW21hcmtkb3dubGludC1jbGkyXShodHRwczovL2dpdGh1Yi5jb20vRGF2aWRBbnNvbi9tYXJrZG93bmxpbnQtY2xpMikpLCBsaW5rcyAoW2x5Y2hlZV0oaHR0cHM6Ly9naXRodWIuY29tL2x5Y2hlZXZlcnNlL2x5Y2hlZSkpLCBzcGVsbGluZyAoW2NzcGVsbF0oaHR0cHM6Ly9jc3BlbGwub3JnLykpLCBhbmQgcHJvc2UgKFtWYWxlXShodHRwczovL3ZhbGUuc2gvKSkuCgpUbyBydW4gb25seSB0aGUgZG9jdW1lbnRhdGlvbiBjaGVja3M6CgogICAgbWFrZSBkb2N1bWVudGF0aW9uLXFhCgpQdXNoIHRvIHlvdXIgZm9yayBhbmQgW3N1Ym1pdCBhIHB1bGwgcmVxdWVzdF1bcHJdLgoKW3ByXTogaHR0cHM6Ly9kb2NzLmdpdGh1Yi5jb20vZW4vcHVsbC1yZXF1ZXN0cy9jb2xsYWJvcmF0aW5nLXdpdGgtcHVsbC1yZXF1ZXN0cy9wcm9wb3NpbmctY2hhbmdlcy10by15b3VyLXdvcmstd2l0aC1wdWxsLXJlcXVlc3RzL2NyZWF0aW5nLWEtcHVsbC1yZXF1ZXN0CgpDb250cmlidXRpbmcgd2l0aCBhbiBMTE0/IFRoaXMgcmVwbyBpbmNsdWRlcyBhbiBbYEFHRU5UUy5tZGBdKEFHRU5UUy5tZCkgd2l0aCBndWlkYW5jZSBmb3IgY29kaW5nIGFnZW50czsgcG9pbnRpbmcgeW91ciBhZ2VudCBhdCBpdCBoZWxwcyBhIGxvdC4gQmVmb3JlIHlvdSBvcGVuIGEgUFIsIHNraW0gdGhyb3VnaCB5b3VyIGNoYW5nZXMgc28geW91IGZlZWwgY29tZm9ydGFibGUgd2l0aCBldmVyeXRoaW5nIHlvdSdyZSBzdWJtaXR0aW5nLgo="); file_put_contents($$contributingFile, str_replace(["[repo]"], [basename(__DIR__)], $$contributingContents)); ' || true)

migrations-docs-create-documentation-markdownlint-config-if-not-exists: #### Create `etc/qa/documentation.markdownlint-cli2.yaml` when missing ##*I*##
	($(DOCKER_RUN) php -r '$$configFile = "etc/qa/documentation.markdownlint-cli2.yaml"; if (file_exists($$configFile)) {exit;} if (!is_dir("etc/qa")) {mkdir("etc/qa", 0777, true);} file_put_contents($$configFile, base64_decode("Z2l0aWdub3JlOiB0cnVlCm5vUHJvZ3Jlc3M6IHRydWUKbm9CYW5uZXI6IHRydWUKZ2xvYnM6CiAgLSAiKiovKi5tZCIKaWdub3JlczoKICAtICJ2YXIvKioiCiAgLSAidmVuZG9yLyoqIgogIC0gIi4qLyoqIgpjb25maWc6CiAgTUQwMDQ6IGZhbHNlCiAgTUQwMDc6IGZhbHNlCiAgTUQwMTI6IGZhbHNlCiAgTUQwMTM6IGZhbHNlCiAgTUQwMjI6IGZhbHNlCiAgTUQwMjU6IGZhbHNlCiAgTUQwMjY6IGZhbHNlCiAgTUQwMzI6IGZhbHNlCiAgTUQwMzM6IGZhbHNlCiAgTUQwNDA6IGZhbHNlCiAgTUQwNDE6IGZhbHNlCg=="));' || true)

migrations-docs-create-lychee-config-if-not-exists: #### Create `etc/qa/lychee.toml` when missing ##*I*##
	($(DOCKER_RUN) php -r '$$configFile = "etc/qa/lychee.toml"; if (file_exists($$configFile)) {exit;} if (!is_dir("etc/qa")) {mkdir("etc/qa", 0777, true);} file_put_contents($$configFile, base64_decode("dmVyYm9zZSA9ICJ3YXJuIgpub19wcm9ncmVzcyA9IHRydWUKdGltZW91dCA9IDEyMAptYXhfcmV0cmllcyA9IDYKcmV0cnlfd2FpdF90aW1lID0gMwpleGNsdWRlX3BhdGggPSBbIl52YXIvIiwgIl52ZW5kb3IvIl0KCltob3N0cy4iZG9jcy5naXRodWIuY29tIl0KaGVhZGVycyA9IHsgQWNjZXB0LUVuY29kaW5nID0gInpzdGQsIGJyLCBnemlwLCBkZWZsYXRlIiB9Cg=="));' || true)

migrations-docs-prepend-lychee-timeout-if-missing: #### Prepend Lychee timeout 120 to etc/qa/lychee.toml when missing ##*I*##
	($(DOCKER_RUN) php -r '$$configFile = "etc/qa/lychee.toml"; $$line = "timeout = 120\n"; if (!file_exists($$configFile)) {exit;} $$content = file_get_contents($$configFile); if (!is_string($$content) || preg_match("/^\s*timeout\s*=/m", $$content)) {exit;} file_put_contents($$configFile, $$line . $$content);' || true)

migrations-docs-prepend-lychee-max-retries-if-missing: #### Prepend Lychee max_retries 6 to etc/qa/lychee.toml when missing ##*I*##
	($(DOCKER_RUN) php -r '$$configFile = "etc/qa/lychee.toml"; $$line = "max_retries = 6\n"; if (!file_exists($$configFile)) {exit;} $$content = file_get_contents($$configFile); if (!is_string($$content) || preg_match("/^\s*max_retries\s*=/m", $$content)) {exit;} file_put_contents($$configFile, $$line . $$content);' || true)

migrations-docs-prepend-lychee-retry-wait-time-if-missing: #### Prepend Lychee retry_wait_time 3 to etc/qa/lychee.toml when missing ##*I*##
	($(DOCKER_RUN) php -r '$$configFile = "etc/qa/lychee.toml"; $$line = "retry_wait_time = 3\n"; if (!file_exists($$configFile)) {exit;} $$content = file_get_contents($$configFile); if (!is_string($$content) || preg_match("/^\s*retry_wait_time\s*=/m", $$content)) {exit;} file_put_contents($$configFile, $$line . $$content);' || true)

migrations-docs-enforce-cspell-config-contents: #### Enforce `etc/qa/cspell.json` contents ##*I*##
	($(DOCKER_RUN) php -r '$$configFile = "etc/qa/cspell.json"; if (!is_dir("etc/qa")) {mkdir("etc/qa", 0777, true);} file_put_contents($$configFile, base64_decode("ewogICAgInZlcnNpb24iOiAiMC4yIiwKICAgICJsYW5ndWFnZSI6ICJlbiIsCiAgICAiYWxsb3dDb21wb3VuZFdvcmRzIjogdHJ1ZSwKICAgICJpZ25vcmVQYXRocyI6IFsKICAgICAgICAidmFyLyoqIiwKICAgICAgICAidmVuZG9yLyoqIiwKICAgICAgICAiLiovKioiCiAgICBdLAogICAgIndvcmRzIjogWwogICAgICAgICJBaVRlbGxzIiwKICAgICAgICAiQXN5bmMiLAogICAgICAgICJDU3BlbGwiLAogICAgICAgICJDZWVzLUphbiIsCiAgICAgICAgIkNvbXBvc2VyIiwKICAgICAgICAiRGlhdGF4aXMiLAogICAgICAgICJGaWdsZXQiLAogICAgICAgICJHSEEiLAogICAgICAgICJHaXRIdWIiLAogICAgICAgICJJbmZlY3Rpb25QSFAiLAogICAgICAgICJLaWV3aWV0IiwKICAgICAgICAiTVNJIiwKICAgICAgICAiTWFrZWZpbGUiLAogICAgICAgICJNYWtlZmlsZXMiLAogICAgICAgICJNYW1tYXR1cyIsCiAgICAgICAgIk1hbW1hdHVzUEhQIiwKICAgICAgICAiTW9ub2xvZyIsCiAgICAgICAgIk5UUyIsCiAgICAgICAgIk9URUwiLAogICAgICAgICJQSFBDUyIsCiAgICAgICAgIlBIUFN0YW4iLAogICAgICAgICJQSFBVbml0IiwKICAgICAgICAiUFNSIiwKICAgICAgICAiUGFja2FnaXN0IiwKICAgICAgICAiUmVub3ZhdGUiLAogICAgICAgICJSZXRyaWFibGUiLAogICAgICAgICJSb2F2ZSIsCiAgICAgICAgIlJ4UEhQIiwKICAgICAgICAiU0hBcyIsCiAgICAgICAgIlRlc3Rjb250YWluZXJzIiwKICAgICAgICAiVmFsZSIsCiAgICAgICAgIldTTCIsCiAgICAgICAgIld5cmlIYXhpbXVzIiwKICAgICAgICAiWlRTIiwKICAgICAgICAiYmFja3RpY2siLAogICAgICAgICJib3lzY291dCIsCiAgICAgICAgImNvZGVzcGVsbCIsCiAgICAgICAgImNvbmZpZyIsCiAgICAgICAgImNvbmZpZ3MiLAogICAgICAgICJkYXRhcHJvdmlkZXIiLAogICAgICAgICJkYXRhcHJvdmlkZXJzIiwKICAgICAgICAiZGVwcyIsCiAgICAgICAgImRldiIsCiAgICAgICAgImZyb250bWF0dGVyIiwKICAgICAgICAiZ2hjciIsCiAgICAgICAgImhlYWx0aHoiLAogICAgICAgICJpbmxpbmVkIiwKICAgICAgICAibHljaGVlIiwKICAgICAgICAibHljaGVldmVyc2UiLAogICAgICAgICJtYWtlZmlsZXMiLAogICAgICAgICJtYXJrZG93bmxpbnQiLAogICAgICAgICJwaHBzdGFuIiwKICAgICAgICAicGhwdW5pdCIsCiAgICAgICAgInByZXBlbmRzIiwKICAgICAgICAicmVwbyIsCiAgICAgICAgInJlcG9zIiwKICAgICAgICAic3ViYWdlbnQiLAogICAgICAgICJzdWJhZ2VudHMiLAogICAgICAgICJzdWJsaWNlbnNlIiwKICAgICAgICAic3VidGFyZ2V0cyIsCiAgICAgICAgInZhcmlhZGljIiwKICAgICAgICAidmhvc3RzIiwKICAgICAgICAid29yZGxpc3RzIiwKICAgICAgICAid3lyaWhheGltdXMiLAogICAgICAgICJ3eXJpaGF4aW11c25ldCIKICAgIF0KfQo="));' || true)

migrations-docs-enforce-vale-config-contents: #### Enforce `etc/qa/vale.ini` contents ##*I*##
	($(DOCKER_RUN) php -r '$$configFile = "etc/qa/vale.ini"; if (!is_dir("etc/qa")) {mkdir("etc/qa", 0777, true);} file_put_contents($$configFile, base64_decode("U3R5bGVzUGF0aCA9IHZhbGUvc3R5bGVzCk1pbkFsZXJ0TGV2ZWwgPSB3YXJuaW5nClZvY2FiID0gV3lyaUhheGltdXMKUGFja2FnZXMgPSBodHRwczovL2dpdGh1Yi5jb20vamRrYXRvL2RpYXRheGlzL3JlbGVhc2VzL2Rvd25sb2FkL3YwLjEuMC9EaWF0YXhpcy56aXAsIFwKICAgICAgICAgICBodHRwczovL2dpdGh1Yi5jb20vdmFsZS1jbGkvd3JpdGUtZ29vZC9yZWxlYXNlcy9kb3dubG9hZC92MC40LjEvd3JpdGUtZ29vZC56aXAsIFwKICAgICAgICAgICBodHRwczovL2dpdGh1Yi5jb20vdmFsZS1jbGkvcmVhZGFiaWxpdHkvcmVsZWFzZXMvZG93bmxvYWQvdjAuMi4wL1JlYWRhYmlsaXR5LnppcCwgXAogICAgICAgICAgIGh0dHBzOi8vZ2l0aHViLmNvbS92YWxlLWNsaS9wcm9zZWxpbnQvcmVsZWFzZXMvZG93bmxvYWQvdjAuMy40L3Byb3NlbGludC56aXAsIFwKICAgICAgICAgICBodHRwczovL2dpdGh1Yi5jb20vdmFsZS1jbGkvYWxleC9yZWxlYXNlcy9kb3dubG9hZC92MC4yLjMvYWxleC56aXAsIFwKICAgICAgICAgICBodHRwczovL2dpdGh1Yi5jb20vYTExeWZyZWQvbmVpZ2hib3IvcmVsZWFzZXMvZG93bmxvYWQvdjIuMi4wL25laWdoYm9yLnppcCwgXAogICAgICAgICAgIGh0dHBzOi8vZ2l0aHViLmNvbS9qZGthdG8vYTExeS9yZWxlYXNlcy9kb3dubG9hZC92MC4xLjAvQTExeS56aXAsIFwKICAgICAgICAgICBodHRwczovL2dpdGh1Yi5jb20va3Jpc2huYXN1bmthbS92YWxlLWFpLXRlbGxzL3JlbGVhc2VzL2Rvd25sb2FkL3YxLjAuMC9BaVRlbGxzLnppcAoKWypdCkJhc2VkT25TdHlsZXMgPSBWYWxlLCB3cml0ZS1nb29kLCBSZWFkYWJpbGl0eSwgcHJvc2VsaW50LCBhbGV4LCBuZWlnaGJvciwgQTExeSwgQWlUZWxscwoKVmFsZS5UZXJtcyA9IE5PClJlYWRhYmlsaXR5ID0gc3VnZ2VzdGlvbgpIb3dUby5PcGVuaW5nID0gc3VnZ2VzdGlvbgpIb3dUby5TdGVwcyA9IHN1Z2dlc3Rpb24KCltDT05UUklCVVRJTkcubWRdCkJhc2VkT25TdHlsZXMgPSBWYWxlLCB3cml0ZS1nb29kLCBSZWFkYWJpbGl0eSwgcHJvc2VsaW50LCBhbGV4LCBuZWlnaGJvciwgQTExeSwgQWlUZWxscywgSG93VG8KCltldGMvYWkvKioubWRdCkJhc2VkT25TdHlsZXMgPSBWYWxlLCB3cml0ZS1nb29kLCBSZWFkYWJpbGl0eSwgcHJvc2VsaW50LCBhbGV4LCBuZWlnaGJvciwgQTExeSwgQWlUZWxscywgUmVmZXJlbmNlCgpbUkVBRE1FLm1kXQpCYXNlZE9uU3R5bGVzID0gVmFsZSwgd3JpdGUtZ29vZCwgUmVhZGFiaWxpdHksIHByb3NlbGludCwgYWxleCwgbmVpZ2hib3IsIEExMXksIEFpVGVsbHMsIEV4cGxhbmF0aW9uCg=="));' || true)

migrations-docs-enforce-vale-vocab-contents: #### Enforce `etc/qa/vale-vocab.txt` contents ##*I*##
	($(DOCKER_RUN) php -r '$$configFile = "etc/qa/vale-vocab.txt"; if (!is_dir("etc/qa")) {mkdir("etc/qa", 0777, true);} file_put_contents($$configFile, base64_decode("QWlUZWxscwpBc3luYwpDU3BlbGwKQ2Vlcy1KYW4KQ29tcG9zZXIKRGlhdGF4aXMKRmlnbGV0CkdIQQpHaXRIdWIKSW5mZWN0aW9uUEhQCktpZXdpZXQKTVNJCk1ha2VmaWxlCk1ha2VmaWxlcwpNYW1tYXR1cwpNYW1tYXR1c1BIUApNb25vbG9nCk5UUwpPVEVMClBIUENTClBIUFN0YW4KUEhQVW5pdApQU1IKUGFja2FnaXN0ClJlbm92YXRlClJldHJpYWJsZQpSb2F2ZQpSeFBIUApTSEFzClRlc3Rjb250YWluZXJzClZhbGUKV1NMCld5cmlIYXhpbXVzClpUUwpiYWNrdGljawpib3lzY291dApjb2Rlc3BlbGwKY29uZmlnCmNvbmZpZ3MKZGF0YXByb3ZpZGVyCmRhdGFwcm92aWRlcnMKZGVwcwpkZXYKZnJvbnRtYXR0ZXIKZ2hjcgpoZWFsdGh6CmlubGluZWQKbHljaGVlCmx5Y2hlZXZlcnNlCm1ha2VmaWxlcwptYXJrZG93bmxpbnQKcGhwc3RhbgpwaHB1bml0CnByZXBlbmRzCnJlcG8KcmVwb3MKc3ViYWdlbnQKc3ViYWdlbnRzCnN1YmxpY2Vuc2UKc3VidGFyZ2V0cwp2YXJpYWRpYwp2aG9zdHMKd29yZGxpc3RzCnd5cmloYXhpbXVzCnd5cmloYXhpbXVzbmV0Cg=="));' || true)

migrations-docs-enrich-qa-wordlists-with-php-symbols: #### Merge PHP symbol and Composer package names into etc/qa documentation wordlists ##*I*##
	($(DOCKER_RUN) php -r '$$autoload = getcwd() . "/vendor/autoload.php"; if (!is_file($$autoload)) {exit;} require $$autoload; \WyriHaximus\Makefiles\Documentation\WordlistDocumentationConfigSync::enrichQaWordlistsWithPhpSymbols(getcwd());' || true)

migrations-docs-sync-wordlist-to-qa-wordlists: #### Merge etc/wordlist.txt into etc/qa documentation wordlists ##*I*##
	($(DOCKER_RUN) php -r '$$autoload = getcwd() . "/vendor/autoload.php"; if (!is_file($$autoload)) {exit;} require $$autoload; \WyriHaximus\Makefiles\Documentation\WordlistDocumentationConfigSync::syncWordlistToQaWordlists(getcwd());' || true)

migrations-docs-create-vale-vocab-symlink-if-not-exists: #### Create WyriHaximus Vale vocab symlink when missing ##*I*##
	($(DOCKER_RUN) php -r '$$link = "etc/qa/vale/styles/config/vocabularies/WyriHaximus/accept.txt"; if (is_link($$link)) {exit;} if (!is_dir("etc/qa")) {mkdir("etc/qa", 0777, true);} if (!is_dir(dirname($$link))) {mkdir(dirname($$link), 0777, true);} symlink("../../../../../vale-vocab.txt", $$link);' || true)

migrations-docs-update-readme-github-actions-badge-yml-to-yaml: #### Update GitHub Actions badge workflow file extension from `.yml` to `.yaml` in `README.md` ##*I*##
	($(DOCKER_RUN) php -r '$$readmeFile = "README.md"; if (!file_exists($$readmeFile)) {exit;} $$readmeContents = file_get_contents($$readmeFile); if (!is_string($$readmeContents)) {exit;} if (str_contains($$readmeContents, "[![") && str_contains($$readmeContents, "badge.svg")) { $$readmeContents = preg_replace_callback("#(https://github\.com/[^/\s\)]+/[^/\s\)]+/actions/workflows/[^/\s\)\?]+)\.yml#", function($$m) { return $$m[1] . ".yaml"; }, $$readmeContents); file_put_contents($$readmeFile, $$readmeContents); }' || true)

migrations-docs-update-agents-phpunit-version: #### Update PHPUnit version in AGENTS.md dataproviders link to match installed version ##*I*##
	($(DOCKER_RUN) php -r '$$agentsFile = "AGENTS.md"; if (!file_exists($$agentsFile)) {exit;} $$agentsContents = file_get_contents($$agentsFile); if (!is_string($$agentsContents)) {exit;} $$versionLine = trim(shell_exec("composer show phpunit/phpunit 2>/dev/null | grep versions")); if (!$$versionLine) {exit;} if (!preg_match("/^\s*versions\s*:\s*\*\s*(\d+)\./", $$versionLine, $$matches)) {exit;} $$majorVersion = $$matches[1]; $$agentsContents = preg_replace_callback("#(https://phpunit\.readthedocs\.io/en/)\d+\.0/writing-tests-for-phpunit\.html\#data-providers#", function($$m) use ($$majorVersion) { return $$m[1] . "$$majorVersion.0/writing-tests-for-phpunit.html#data-providers"; }, $$agentsContents); file_put_contents($$agentsFile, $$agentsContents);' || true)

migrations-docs-add-readme-license-vale-comments: #### Add Vale annotation comments to MIT license block in README.md ##*I*##
	($(DOCKER_RUN) php -r '$$readmeFile = "README.md"; if (!file_exists($$readmeFile)) {exit;} $$readmeContents = file_get_contents($$readmeFile); if (!is_string($$readmeContents)) {exit;} $$readmeContents = str_replace(base64_decode("UGVybWlzc2lvbiBpcyBoZXJlYnkgZ3JhbnRlZCwgZnJlZSBvZiBjaGFyZ2UsIHRvIGFueSBwZXJzb24gb2J0YWluaW5nIGEgY29weQpvZiB0aGlzIHNvZnR3YXJlIGFuZCBhc3NvY2lhdGVkIGRvY3VtZW50YXRpb24gZmlsZXMgKHRoZSAiU29mdHdhcmUiKSwgdG8gZGVhbAppbiB0aGUgU29mdHdhcmUgd2l0aG91dCByZXN0cmljdGlvbiwgaW5jbHVkaW5nIHdpdGhvdXQgbGltaXRhdGlvbiB0aGUgcmlnaHRzCnRvIHVzZSwgY29weSwgbW9kaWZ5LCBtZXJnZSwgcHVibGlzaCwgZGlzdHJpYnV0ZSwgc3VibGljZW5zZSwgYW5kL29yIHNlbGwKY29waWVzIG9mIHRoZSBTb2Z0d2FyZSwgYW5kIHRvIHBlcm1pdCBwZXJzb25zIHRvIHdob20gdGhlIFNvZnR3YXJlIGlzCmZ1cm5pc2hlZCB0byBkbyBzbywgc3ViamVjdCB0byB0aGUgZm9sbG93aW5nIGNvbmRpdGlvbnM6CgpUaGUgYWJvdmUgY29weXJpZ2h0IG5vdGljZSBhbmQgdGhpcyBwZXJtaXNzaW9uIG5vdGljZSBzaGFsbCBiZSBpbmNsdWRlZCBpbiBhbGwKY29waWVzIG9yIHN1YnN0YW50aWFsIHBvcnRpb25zIG9mIHRoZSBTb2Z0d2FyZS4KClRIRSBTT0ZUV0FSRSBJUyBQUk9WSURFRCAiQVMgSVMiLCBXSVRIT1VUIFdBUlJBTlRZIE9GIEFOWSBLSU5ELCBFWFBSRVNTIE9SCklNUExJRUQsIElOQ0xVRElORyBCVVQgTk9UIExJTUlURUQgVE8gVEhFIFdBUlJBTlRJRVMgT0YgTUVSQ0hBTlRBQklMSVRZLApGSVRORVNTIEZPUiBBIFBBUlRJQ1VMQVIgUFVSUE9TRSBBTkQgTk9OSU5GUklOR0VNRU5ULiBJTiBOTyBFVkVOVCBTSEFMTCBUSEUKQVVUSE9SUyBPUiBDT1BZUklHSFQgSE9MREVSUyBCRSBMSUFCTEUgRk9SIEFOWSBDTEFJTSwgREFNQUdFUyBPUiBPVEhFUgpMSUFCSUxJVFksIFdIRVRIRVIgSU4gQU4gQUNUSU9OIE9GIENPTlRSQUNULCBUT1JUIE9SIE9USEVSV0lTRSwgQVJJU0lORyBGUk9NLApPVVQgT0YgT1IgSU4gQ09OTkVDVElPTiBXSVRIIFRIRSBTT0ZUV0FSRSBPUiBUSEUgVVNFIE9SIE9USEVSIERFQUxJTkdTIElOIFRIRQpTT0ZUV0FSRS4K"), base64_decode("PCEtLSB2YWxlIHdyaXRlLWdvb2QgPSBOTyAtLT4KUGVybWlzc2lvbiBpcyBoZXJlYnkgZ3JhbnRlZCwgZnJlZSBvZiBjaGFyZ2UsIHRvIGFueSBwZXJzb24gb2J0YWluaW5nIGEgY29weQpvZiB0aGlzIHNvZnR3YXJlIGFuZCBhc3NvY2lhdGVkIGRvY3VtZW50YXRpb24gZmlsZXMgKHRoZSAiU29mdHdhcmUiKSwgdG8gZGVhbAppbiB0aGUgU29mdHdhcmUgd2l0aG91dCByZXN0cmljdGlvbiwgaW5jbHVkaW5nIHdpdGhvdXQgbGltaXRhdGlvbiB0aGUgcmlnaHRzCnRvIHVzZSwgY29weSwgbW9kaWZ5LCBtZXJnZSwgcHVibGlzaCwgZGlzdHJpYnV0ZSwgc3VibGljZW5zZSwgYW5kL29yIHNlbGwKY29waWVzIG9mIHRoZSBTb2Z0d2FyZSwgYW5kIHRvIHBlcm1pdCBwZXJzb25zIHRvIHdob20gdGhlIFNvZnR3YXJlIGlzCmZ1cm5pc2hlZCB0byBkbyBzbywgc3ViamVjdCB0byB0aGUgZm9sbG93aW5nIGNvbmRpdGlvbnM6CgpUaGUgYWJvdmUgY29weXJpZ2h0IG5vdGljZSBhbmQgdGhpcyBwZXJtaXNzaW9uIG5vdGljZSBzaGFsbCBiZSBpbmNsdWRlZCBpbiBhbGwKY29waWVzIG9yIHN1YnN0YW50aWFsIHBvcnRpb25zIG9mIHRoZSBTb2Z0d2FyZS4KCjwhLS0gdmFsZSBuZWlnaGJvci5BbGxDYXBzUHJvc2UgPSBOTyAtLT4KVEhFIFNPRlRXQVJFIElTIFBST1ZJREVEICJBUyBJUyIsIFdJVEhPVVQgV0FSUkFOVFkgT0YgQU5ZIEtJTkQsIEVYUFJFU1MgT1IKSU1QTElFRCwgSU5DTFVESU5HIEJVVCBOT1QgTElNSVRFRCBUTyBUSEUgV0FSUkFOVElFUyBPRiBNRVJDSEFOVEFCSUxJVFksCkZJVE5FU1MgRk9SIEEgUEFSVElDVUxBUiBQVVJQT1NFIEFORCBOT05JTkZSSU5HRU1FTlQuIElOIE5PIEVWRU5UIFNIQUxMIFRIRQpBVVRIT1JTIE9SIENPUFlSSUdIVCBIT0xERVJTIEJFIExJQUJMRSBGT1IgQU5ZIENMQUlNLCBEQU1BR0VTIE9SIE9USEVSCkxJQUJJTElUWSwgV0hFVEhFUiBJTiBBTiBBQ1RJT04gT0YgQ09OVFJBQ1QsIFRPUlQgT1IgT1RIRVJXSVNFLCBBUklTSU5HIEZST00sCk9VVCBPRiBPUiBJTiBDT05ORUNUSU9OIFdJVEggVEhFIFNPRlRXQVJFIE9SIFRIRSBVU0UgT1IgT1RIRVIgREVBTElOR1MgSU4gVEhFClNPRlRXQVJFLgo8IS0tIHZhbGUgbmVpZ2hib3IuQWxsQ2Fwc1Byb3NlID0geWVzIC0tPgo8IS0tIHZhbGUgd3JpdGUtZ29vZCA9IHllcyAtLT4K"), $$readmeContents); file_put_contents($$readmeFile, $$readmeContents);' || true)

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
	($(DOCKER_RUN) php -r '$$markdownLinkCheckerFile = "etc/ci/markdown-link-checker.json"; $$json = json_decode("{\"httpHeaders\": [{\"urls\": [\"https://docs.github.com/\"],\"headers\": {\"Accept-Encoding\": \"zstd, br, gzip, deflate\"}}]}"); if (file_exists($$markdownLinkCheckerFile)) {exit;} file_put_contents($$markdownLinkCheckerFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");' || true)

migrations-php-ensure-etc-qa-coverage-guard-php-exists: #### Make sure we have `etc/qa/coverage-guard.php` ##*I*##
	($(DOCKER_RUN) php -r '$$coverageGuardFile = "etc/qa/coverage-guard.php"; $$coverageGuardConfig = base64_decode("PD9waHAKCmRlY2xhcmUoc3RyaWN0X3R5cGVzPTEpOwoKdXNlIFNoaXBNb25rXENvdmVyYWdlR3VhcmRcQ29uZmlnOwp1c2UgU2hpcE1vbmtcQ292ZXJhZ2VHdWFyZFxFeGNsdWRlclxJZ25vcmVUaHJvd05ld0V4Y2VwdGlvbkxpbmVFeGNsdWRlcjsKdXNlIFNoaXBNb25rXENvdmVyYWdlR3VhcmRcUnVsZVxFbmZvcmNlQ292ZXJhZ2VGb3JNZXRob2RzUnVsZTsKCnJldHVybiAoc3RhdGljIGZ1bmN0aW9uICgpOiBDb25maWcgewogICAgJGNvbmZpZyA9IG5ldyBDb25maWcoKTsKCiAgICAkY29uZmlnLT5hZGRSdWxlKG5ldyBFbmZvcmNlQ292ZXJhZ2VGb3JNZXRob2RzUnVsZSgKICAgICAgICByZXF1aXJlZENvdmVyYWdlUGVyY2VudGFnZTogODAsCiAgICAgICAgbWluRXhlY3V0YWJsZUxpbmVzOiAxLAogICAgKSk7CgogICAgJGNvbmZpZy0+YWRkRXhlY3V0YWJsZUxpbmVFeGNsdWRlcihuZXcgSWdub3JlVGhyb3dOZXdFeGNlcHRpb25MaW5lRXhjbHVkZXIoWwogICAgICAgIFJ1bnRpbWVFeGNlcHRpb246OmNsYXNzLAogICAgXSkpOwoKICAgIHJldHVybiAkY29uZmlnOwp9KSgpOwo="); if (file_exists($$coverageGuardFile)) {exit;} file_put_contents($$coverageGuardFile, $$coverageGuardConfig);' || true)

migrations-php-ensure-etc-qa-zzz-disable-otel-attr-hooks-ini-exists: #### Make sure we have `etc/qa/zzz_disable_otel_attr_hooks.ini` ##*I*##
	($(DOCKER_RUN) php -r 'if (in_array("opentelemetry-instrumentation", ["code-style","composer-dependency-checkers","linux","macos","package","static-analysis","unit-tests","windows"])) {exit;} $$otelAttrHooksIniFile = "etc/qa/zzz_disable_otel_attr_hooks.ini"; $$otelAttrHooksIniContents = base64_decode("OyBBdm9pZCB6ZW5kX21tX2hlYXAgY29ycnVwdGlvbiB3aXRoICNbV2l0aFNwYW5dIChtYW1tYXR1cyB1c2VzIGhvb2soKSBpbnN0ZWFkKS4KOyBTZWU6IGh0dHBzOi8vZ2l0aHViLmNvbS9vcGVuLXRlbGVtZXRyeS9vcGVudGVsZW1ldHJ5LXBocC1pbnN0cnVtZW50YXRpb24vcHVsbC8zMjEKOyBBbHJlYWR5IHNvbHZlZDogaHR0cHM6Ly9naXRodWIuY29tL29wZW4tdGVsZW1ldHJ5L29wZW50ZWxlbWV0cnktcGhwLWluc3RydW1lbnRhdGlvbi9wdWxsLzMxMwpvcGVudGVsZW1ldHJ5LmF0dHJfaG9va3NfZW5hYmxlZD1PZmYK"); if (file_exists($$otelAttrHooksIniFile)) {exit;} file_put_contents($$otelAttrHooksIniFile, $$otelAttrHooksIniContents);' || true)

migrations-php-move-infection-config-to-etc: #### Move `infection.json.dist` to `etc/qa/infection.json5` ##*I*##
	($(DOCKER_RUN) mv infection.json.dist etc/qa/infection.json5 || true)

migrations-php-infection-create-config-if-not-exists: #### Create Infection config file if it doesn't exists at `etc/qa/infection.json5` ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; $$infectionConfig = base64_decode("ewogICAgInRocmVhZHMiOiA2NCwKICAgICJ0aW1lb3V0IjogMTIwLAogICAgInNvdXJjZSI6IHsKICAgICAgICAiZGlyZWN0b3JpZXMiOiBbCiAgICAgICAgICAgICJzcmMiCiAgICAgICAgXQogICAgfSwKICAgICJsb2dzIjogewogICAgICAgICJ0ZXh0IjogIi4uLy4uL3Zhci9pbmZlY3Rpb24ubG9nIiwKICAgICAgICAic3VtbWFyeSI6ICIuLi8uLi92YXIvaW5mZWN0aW9uLXN1bW1hcnkubG9nIiwKICAgICAgICAianNvbiI6ICIuLi8uLi92YXIvaW5mZWN0aW9uLmpzb24iLAogICAgICAgICJwZXJNdXRhdG9yIjogIi4uLy4uL3Zhci9pbmZlY3Rpb24tcGVyLW11dGF0b3IubWQiLAogICAgICAgICJnaXRodWIiOiB0cnVlCiAgICB9LAogICAgIm1pbk1zaSI6IDEwMCwKICAgICJtaW5Db3ZlcmVkTXNpIjogMTAwLAogICAgImlnbm9yZU1zaVdpdGhOb011dGF0aW9ucyI6IHRydWUsCiAgICAibXV0YXRvcnMiOiB7CiAgICAgICAgIkBkZWZhdWx0IjogdHJ1ZQogICAgfQp9Cg=="); if (file_exists($$infectionFile)) {exit;} file_put_contents($$infectionFile, $$infectionConfig);' || true)

migrations-php-remove-phpunit-config-dir-from-infection: #### Drop XXX from `etc/qa/infection.json5` ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("phpUnit", $$json)) {exit;} unset($$json["phpUnit"]); file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");' || true)

migrations-php-fix-logs-relative-paths-for-infection: #### Fix logs paths in `etc/qa/infection.json5` ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("logs", $$json)) {exit;} foreach ($$json["logs"] as $$logsKey => $$logsPath) { if (is_string($$json["logs"][$$logsKey]) && str_starts_with($$json["logs"][$$logsKey], "./var/infection")) { $$json["logs"][$$logsKey] = str_replace("./var/infection", "../../var/infection", $$json["logs"][$$logsKey]); } } file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");' || true)

migrations-php-infection-ensure-log-text-has-the-correct-path: #### Ensure infection's log.text has config directive has the correct path ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("logs", $$json)) { $$json["logs"] = []; } $$json["logs"]["text"] = "../../var/infection.log"; file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");' || true)

migrations-php-infection-ensure-log-summary-has-the-correct-path: #### Ensure infection's log.summary has config directive has the correct path ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("logs", $$json)) { $$json["logs"] = []; } $$json["logs"]["summary"] = "../../var/infection-summary.log"; file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");' || true)

migrations-php-infection-ensure-log-json-has-the-correct-path: #### Ensure infection's log.json has config directive has the correct path ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("logs", $$json)) { $$json["logs"] = []; } $$json["logs"]["json"] = "../../var/infection.json"; file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");' || true)

migrations-php-infection-ensure-log-per-mutator-has-the-correct-path: #### Ensure infection's log.perMutator has config directive has the correct path ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("logs", $$json)) { $$json["logs"] = []; } $$json["logs"]["perMutator"] = "../../var/infection-per-mutator.md"; file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");' || true)

migrations-php-add-github-true-to-for-infection: #### Ensure we configure infection to emit logs to GitHub in `etc/qa/infection.json5` ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("logs", $$json)) {exit;} if (array_key_exists("github", $$json["logs"])) {exit;} $$json["logs"]["github"] = true; file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");' || true)

migrations-php-infection-add-threads-64-to-config: #### Ensure `threads` is set to `64` in `etc/qa/infection.json5` ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;} if (array_key_exists("threads", $$json)) {exit;} $$json["threads"] = 64; file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");' || true)

migrations-php-make-paths-compatible-with-infection-0-32: #### We update path to be relative to `etc/qa/infection.json5` as of 0.32 ##*I*##
	($(DOCKER_RUN) php -r '$$infectionFile = "etc/qa/infection.json5"; if (!file_exists($$infectionFile)) {exit;} $$json = json_decode(file_get_contents($$infectionFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("source", $$json)) {exit;} if (!array_key_exists("directories", $$json["source"])) {exit;} foreach ($$json["source"]["directories"] as $$key => $$value) { if (!str_starts_with($$value, "../../")) {$$json["source"]["directories"][$$key] = "../../" . $$value;} } file_put_contents($$infectionFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");' || true)

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
	($(DOCKER_RUN) php -r '$$composerJsonFile = "composer.json"; $$composerUnusedFile = "etc/qa/composer-unused.php"; if (!file_exists($$composerJsonFile)) {exit;} $$json = json_decode(file_get_contents($$composerJsonFile), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("extra", $$json)) {exit;} if (!array_key_exists("unused", $$json["extra"])) {exit;} foreach ($$json["extra"]["unused"] as $$unusedPAckage) { file_put_contents($$composerUnusedFile, str_replace(base64_decode("cmV0dXJuIHN0YXRpYyBmbiAoQ29uZmlndXJhdGlvbiAkY29uZmlnKTogQ29uZmlndXJhdGlvbiA9PiAkY29uZmlnCg=="), base64_decode("cmV0dXJuIHN0YXRpYyBmbiAoQ29uZmlndXJhdGlvbiAkY29uZmlnKTogQ29uZmlndXJhdGlvbiA9PiAkY29uZmlnCg==") . "\n" . base64_decode("ICAgIC0+YWRkTmFtZWRGaWx0ZXIoXENvbXBvc2VyVW51c2VkXENvbXBvc2VyVW51c2VkXENvbmZpZ3VyYXRpb25cTmFtZWRGaWx0ZXI6OmZyb21TdHJpbmcoJwo=") . $$unusedPAckage . base64_decode("Jykp"), file_get_contents($$composerUnusedFile))); } unset($$json["extra"]["unused"]); file_put_contents($$composerJsonFile, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");' || true)

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

migrations-inline-code-remove-line-infection-ignore-all: #### Remove all lines that contain @infection-ignore-all ##*I*##
	($(DOCKER_RUN) php -r '$$possibleDirectories = ["src", "tests", "etc", "examples"]; foreach ($$possibleDirectories as $$possibleDirectory) { if (!file_exists($$possibleDirectory)) {continue;} $$i = new \RecursiveIteratorIterator(new \RecursiveDirectoryIterator($$possibleDirectory)); $$i->rewind(); while ($$i->valid()) { if (!is_file($$i->key()) || (is_file($$i->key()) && !str_ends_with($$i->key(), ".php"))) { $$i->next(); continue; } $$fileContents = explode("\n", file_get_contents($$i->key())); foreach ($$fileContents as $$lineNumber => $$lineContent) { if (str_contains($$lineContent, "@infection-ignore-all")) { unset($$fileContents[$$lineNumber]); } } file_put_contents($$i->key(), implode("\n", $$fileContents)); $$i->next(); } }' || true)

migrations-inline-code-phpunit-replace-expectexceptionmessage-with-expectexceptionmessageisorcontains: #### Replace self::expectExceptionMessage with self::expectExceptionMessageIsOrContains in all PHPUnit tests ##*I*##
	($(DOCKER_RUN) php -r '$$possibleDirectories = ["src", "tests", "etc", "examples"]; foreach ($$possibleDirectories as $$possibleDirectory) { if (!file_exists($$possibleDirectory)) {continue;} $$i = new \RecursiveIteratorIterator(new \RecursiveDirectoryIterator($$possibleDirectory)); $$i->rewind(); while ($$i->valid()) { if (!is_file($$i->key()) || (is_file($$i->key()) && !str_ends_with($$i->key(), ".php"))) { $$i->next(); continue; } $$fileContents = file_get_contents($$i->key()); if (str_contains($$fileContents, "#[Test]") && str_contains($$fileContents, "use PHPUnit\Framework\Attributes\Test;")) { $$fileContents = str_replace("self::expectExceptionMessage(", "self::expectExceptionMessageIsOrContains(", $$fileContents); file_put_contents($$i->key(), $$fileContents); } $$i->next(); } }' || true)

migrations-supported-features-php-ensure-we-only-cs-check-and-fix-tests-if-unit-tests-is-enabled: #### Ensure we only cs check/fix tests/ if unit-tests is enabled ##*I*##
	($(DOCKER_RUN) php -r 'if (in_array("unit-tests", ["code-style","composer-dependency-checkers","linux","macos","package","static-analysis","unit-tests","windows"])) {exit;} $$phpCSCongifFIle = "etc/qa/phpcs.xml"; $$fileContents = explode("\n", file_get_contents($$phpCSCongifFIle)); foreach ($$fileContents as $$lineNumber => $$lineContent) { if (str_contains($$lineContent, "<file>../../tests</file>")) { unset($$fileContents[$$lineNumber]); } } file_put_contents($$phpCSCongifFIle, implode("\n", $$fileContents));' || true)

migrations-supported-features-php-ensure-we-only-staticly-analyse-tests-with-phpstan-if-unit-tests-is-enabled: #### Ensure we only staticly analyse tests/ with PHPStan if unit-tests is enabled ##*I*##
	($(DOCKER_RUN) php -r 'if (in_array("unit-tests", ["code-style","composer-dependency-checkers","linux","macos","package","static-analysis","unit-tests","windows"])) {exit;} $$phpStanCongifFIle = "etc/qa/phpstan.neon"; $$fileContents = explode("\n", file_get_contents($$phpStanCongifFIle)); foreach ($$fileContents as $$lineNumber => $$lineContent) { if (str_contains($$lineContent, "- ../../tests")) { unset($$fileContents[$$lineNumber]); } } file_put_contents($$phpStanCongifFIle, implode("\n", $$fileContents));' || true)

migrations-supported-features-php-ensure-no-phpunit-config-file-is-present-when-unit-tests-are-disabled: #### Ensure we remove the PHPUnit config file when unit-tests aren't enabled ##*I*##
	($(DOCKER_RUN) php -r 'if (in_array("unit-tests", ["code-style","composer-dependency-checkers","linux","macos","package","static-analysis","unit-tests","windows"])) {exit;} @unlink("etc/qa/phpunit.xml");' || true)

migrations-supported-features-php-ensure-no-infectionphp-config-file-is-present-when-unit-tests-are-disabled: #### Ensure we remove the InfectionPHP config file when unit-tests aren't enabled ##*I*##
	($(DOCKER_RUN) php -r 'if (in_array("unit-tests", ["code-style","composer-dependency-checkers","linux","macos","package","static-analysis","unit-tests","windows"])) {exit;} @unlink("etc/qa/infection.json5");' || true)

migrations-supported-features-php-ensure-no-rector-config-file-is-present-when-code-style-is-disabled: #### Ensure we remove the RectorPHP config file when code-style isn't enabled ##*I*##
	($(DOCKER_RUN) php -r 'if (in_array("code-style", ["code-style","composer-dependency-checkers","linux","macos","package","static-analysis","unit-tests","windows"])) {exit;} @unlink("etc/qa/rector.php");' || true)

migrations-supported-features-php-ensure-no-phpcs-config-file-is-present-when-code-style-is-disabled: #### Ensure we remove the PHPCSS config file when code-style isn't enabled ##*I*##
	($(DOCKER_RUN) php -r 'if (in_array("code-style", ["code-style","composer-dependency-checkers","linux","macos","package","static-analysis","unit-tests","windows"])) {exit;} @unlink("etc/qa/phpcs.xml");' || true)

migrations-supported-features-php-ensure-no-composer-require-checker-config-file-is-present-when-composer-dependency-checkers-are-disabled: #### Ensure we remove the Composer Require Checker config file when composer-dependency-checkers aren't enabled ##*I*##
	($(DOCKER_RUN) php -r 'if (in_array("composer-dependency-checkers", ["code-style","composer-dependency-checkers","linux","macos","package","static-analysis","unit-tests","windows"])) {exit;} @unlink("etc/qa/composer-require-checker.json");' || true)

migrations-supported-features-php-ensure-no-composer-unused-config-file-is-present-when-composer-dependency-checkers-are-disabled: #### Ensure we remove the Composer Unused config file when composer-dependency-checkers aren't enabled ##*I*##
	($(DOCKER_RUN) php -r 'if (in_array("composer-dependency-checkers", ["code-style","composer-dependency-checkers","linux","macos","package","static-analysis","unit-tests","windows"])) {exit;} @unlink("etc/qa/composer-unused.php");' || true)

migrations-supported-features-php-ensure-no-zzz-disable-otel-attr-hooks-ini-when-opentelemetry-instrumentation-is-enabled: #### Ensure we remove `etc/qa/zzz_disable_otel_attr_hooks.ini` when opentelemetry-instrumentation is enabled ##*I*##
	($(DOCKER_RUN) php -r 'if (!in_array("opentelemetry-instrumentation", ["code-style","composer-dependency-checkers","linux","macos","package","static-analysis","unit-tests","windows"])) {exit;} @unlink("etc/qa/zzz_disable_otel_attr_hooks.ini");' || true)

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

migrations-github-actions-rename-yml-workflow-files-to-yaml: #### Rename all `.yml` files in `.github/workflows` to `.yaml` ##*I*##
	($(DOCKER_RUN) php -r '$$workflowsDir = ".github/workflows"; if (!is_dir($$workflowsDir)) {exit;} foreach (scandir($$workflowsDir) as $$file) { if ($$file === "." || $$file === "..") {continue;} if (!str_ends_with($$file, ".yml")) {continue;} $$yamlName = substr($$file, 0, -4) . ".yaml"; $$yamlPath = $$workflowsDir . "/" . $$yamlName; if (file_exists($$yamlPath)) {continue;} rename($$workflowsDir . "/" . $$file, $$yamlPath); }' || true)

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
	($(DOCKER_RUN) php -r '$$composerFIle = "composer.json"; if (!file_exists($$composerFIle)) {exit;} $$json = json_decode(file_get_contents($$composerFIle), true); if (!array_key_exists("config", $$json)) {exit;} if (!array_key_exists("platform", $$json["config"])) {exit;} if (!array_key_exists("php", $$json["config"]["platform"])) {exit;} $$phpVersionConstraint = preg_replace("/\.\d+$/", ".x", $$json["config"]["platform"]["php"]); $$renovateFIle = ".github/renovate.json"; if (!file_exists($$renovateFIle)) {exit;} $$json = json_decode(file_get_contents($$renovateFIle), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("constraints", $$json)) {$$json["constraints"] = [];} $$json["constraints"]["php"] = $$phpVersionConstraint; file_put_contents($$renovateFIle, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");' || true)

migrations-renovate-set-composer-constraint: #### Always keep renovate's `constraints.composer` at `2.x` ##*I*##
	($(DOCKER_RUN) php -r '$$renovateFIle = ".github/renovate.json"; if (!file_exists($$renovateFIle)) {exit;} $$json = json_decode(file_get_contents($$renovateFIle), true); if (!is_array($$json)) {exit;}  if (!array_key_exists("constraints", $$json)) {$$json["constraints"] = [];} $$json["constraints"]["composer"] = "2.x"; file_put_contents($$renovateFIle, json_encode($$json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");' || true)

migrations-git-enforce-agents-md-contents: #### Enforce `AGENTS.md` contents ##*I*##
	($(DOCKER_RUN) php -r 'file_put_contents("AGENTS.md", base64_decode("IyBJbnN0cnVjdGlvbiBFY29ub215IChjaGVjayBiZWZvcmUgYGV2ZXJ5YCBpbnN0cnVjdGlvbiB5b3UgYWRkKQoKQmVmb3JlIGFkZGluZyBhbiBpbnN0cnVjdGlvbiBgYW55d2hlcmVgIChgQUdFTlRTLm1kYHMsIHJ1bGVzLCBhZ2VudHMsIHNraWxscywgaG9va3MsIGNvbmZpZ3MpOiBwcmVmZXIgdGhlIGBuYXRpdmVgIG1lY2hhbmlzbSAoZnJvbnRtYXR0ZXIgZmllbGQsIGNvbmZpZyBrZXksIGV4aXN0aW5nIHJ1bGUsIGEgcm91dGVyIHRvIHRoZSBzaW5nbGUgc291cmNlKSBvdmVyIG5ldyBwcm9zZSwgYW5kIHByZWZlciBgZGVsZXRpbmdgIHByb3NlIG92ZXIgYWRkaW5nIGl0LiBFdmVyeSBhZGRlZCBpbnN0cnVjdGlvbiBpcyBhIGNvbnRyYWRpY3Rpb24tYW5kLWRyaWZ0IHN1cmZhY2U7IGNvbmRlbnNlZCBjb3BpZXMgb2YgYW5vdGhlciBhcnRpZmFjdCdzIGNvbnRlbnQgZHJpZnQgc2lsZW50bHkuIFN1Y2Nlc3MgbWV0cmljOiB0aGUgZGlmZiBzaHJpbmtzIG9yIGhvbGRzIHdoaWxlIGNhcGFiaWxpdHkgZ3Jvd3MuIENvbnNpc3RlbmN5IGJlYXRzIHRva2VuIHRocmlmdC4KCkJlZm9yZSBkb2luZyBhbnl0aGluZyByZWFkIHRoaXMgZmlsZSB0byBlbnN1cmUgeW91IGFyZSB1cCB0byBkYXRlIHdpdGggaXQuCgojIFByb2plY3QgSW5zdHJ1Y3Rpb25zCgojIyBEZXBlbmRlbmNpZXMKLSBJbnN0YWxsOiBgbWFrZSBpbnN0YWxsYC4KLSBSZXF1aXJlIGEgbmV3IHBhY2thZ2U6IGBtYWtlIGNvbXBvc2VyLXJlcXVpcmUgIlBBQ0tBR0VOQU1FImAgb3IgYG1ha2UgY29tcG9zZXItcmVxdWlyZSAiUEFDS0FHRU5BTUUgLS1kZXYiYC4KCiMjIEV4ZWN1dGluZyBjb21tYW5kcwotIERvIG5vdyB1c2UgYGNkYCBmb3IgZXZlcnl0aGluZywgeW91J3JlIGFscmVhZHkgaW4gdGhlIHJvb3QhCi0gQ2hlY2sgYG1ha2UgaGVscGAgZm9yIGFsbCBhdmFpbGFibGUgY29tbWFuZHMuCi0gQ2hlY2sgYG1ha2UgaGVscC1jb250cmliYCBmb3IgYWxsIGF2YWlsYWJsZSBjb250cmliIGNvbW1hbmRzLgotIE5lZWQgc29tZXRoaW5nIGN1c3RvbSB0aGF0IGlzIG5vdCBpbiB0aGUgbGlzdD8gVXNlIGBtYWtlIHJ1biAiWU9VUiBDT01NQU5EIEhFUkUiYCB0byBydW4gYSBjb21tYW5kIGluIHRoZSBjb250YWluZXIgYW5kIHJ1biB3aGF0ZXZlciB5b3UgcmVxdWlyZSB0aGVyZS4KLSBJZiBhIHBhY2thZ2UgbmVlZHMgY3VzdG9tIGBtYWtlYCBjb21tYW5kcywgcHV0IHRoZW0gaW4gYGV0Yy9NYWtlZmlsZWAsIHRoZW4gcnVuIGBtYWtlIGluc3RhbGxgIHRvIG1ha2UgdGhlbSBhdmFpbGFibGUgdGhyb3VnaCB0aGUgcm9vdCBgTWFrZWZpbGVgLgotIEFsd2F5cyBzcGxpdCB0YXNrcyB1cCBpbiBzbWFsbCBjaHVua3MgYW5kIGZlZWQgdGhvc2UgdG8gc3ViIGFnZW50cywgdGhlbiBjb2xsZWN0IHdoYXQgY29tZXMgb3V0IG9mIHRoYXQsIG1ha2UgbG9naWNhbCBncm91cHMgZm9yIHRoZSBuZXh0IHNldCBvZiB0YXNrcyB0byBiZSBzcGxpdCBvdmVyIHN1YmFnZW50cy4KLSBXaGVuIHVzaW5nIHNoZWxsIGNvbW1hbmRzIGxpa2UgYHJtYCwgYG12YCwgb3IgYGNwYCBhbmQgYWxsIHBhdGhzIGFyZSB3aXRoaW4gdGhlIHJlcG8sIHJ1biB0aGVtIHZpYSBgbWFrZSBydW5gIHRvIGVuc3VyZSB0aGV5IGV4ZWN1dGUgaW5zaWRlIHRoZSBjb250YWluZXIuCi0gV2hlbiBtYWtpbmcgYEFQSWAgY2FsbHMgcHJlZmVyIHVzaW5nIGBNQ1BgIHRvb2xzIG92ZXIgYGNVUkxgLgoKIyMgRmxvdwotIEFsd2F5cyBjaGVjayBgQUdFTlRTLm1kYCB3aGVuIHN0YXJ0aW5nIG9uIGEgdGFzay4KLSBBZnRlciBlYWNoIGxvZ2ljYWwgYmxvY2sgb2YgY2hhbmdlcyBtYWRlIGVuc3VyZSBgbWFrZSBjb250cmliYCBwYXNzZXMuCi0gQmVmb3JlIHlvdSByZXR1cm4gdG8gdGhlIHVzZXMgcnVuIGBtYWtlYCB0byBlbnN1cmUgYWxsIFFBIGNoZWNrcyBwYXNzLgotIFVzZSBgbWFrZSB1bml0LXRlc3RpbmctZmlsdGVyIFRFU1RDTEFTU05BTUVfT1JfVEVTVE1FVEhPRE5BTUVgIHRvIHJ1biBhIHNwZWNpZmljIHRlc3QuCi0gQWx3YXlzIGFkZCB1bml0IHRlc3RzIGZvciBuZXcgY29kZS4KLSBJZiBgY29tcG9zZXIubG9ja2AgaXMgb3V0IG9mIHN5bmMgd2l0aCBgY29tcG9zZXIuanNvbmAsIHJ1biBgbWFrZSB1cGRhdGVgLgoKIyMgV3JpdGluZyBjb2RlCi0gS2VlcCB0aGluZ3Mgc3RyYWlnaHRmb3J3YXJkLCBvbmNlIGRvbmUgaW1wbGVtZW50aW5nIGEgZmVhdHVyZSwgaXRlcmF0ZSBvbiBpbXByb3ZpbmcgaXQuIExlc3MgY29kZSBpcyBtb3JlLgotIE1ha2Ugc3VyZSB0aGUgY29kZSBpcyByZWFkYWJsZSBhbmQgY2xlYXIuCi0gUHJlZmVyIGEgbG9naWNhbCBibG9jayBvZiBjb2RlIHRvIGJlIHdpdGhpbiBvbmUgc2NyZWVuIHNpemUgb3ZlciBzcGxpdHRpbmcgaXQgdXAgaW50byBzbWFsbGVyIGZ1bmN0aW9ucy4KLSBNYWtlIGEgY2xhc3Mgc3RhdGljIGlmIGl0IGRvZXNuJ3QgaG9sZCBzdGF0ZS4KLSBQdXQgY2xhc3NlcyBpbiBsb2dpY2FsIGZvbGRlcnMuCi0gT25jZSBkb25lIHdyaXRpbmcgY29kZSBpdGVyYXRlIG9mIGl0IHRvIG1ha2Ugc3VyZSBpdCdzIGNsZWFyIHRvIHVuZGVyc3RhbmQgYW5kIG1haW50YWluLCB0aGF0IGl0J3Mgc3RyYWlnaHRmb3J3YXJkIHRvIHRlc3QsIGFuZCB0aGF0IGl0IGRvZXNuJ3QgZHVwbGljYXRlIGNvZGUuCi0gU2VhcmNoIGV4aXN0aW5nIGNvZGUgZm9yIGV4YW1wbGVzIG9mIGhvdyB0byBkbyB0aGluZ3MuCi0gU2VhcmNoIGV4aXN0aW5nIGNvZGUgZm9yIGNsYXNzZXMvbWV0aG9kcyB5b3UgY2FuIHVzZSBpbnN0ZWFkIG9mIHdyaXRpbmcgeW91ciBvd24uCgojIyBNYXJrZG93bgotIEFsd2F5cyB1c2UgTWFya2Rvd24gaW4gY29tbWVudHMgdG8gaW1wcm92ZSByZWFkYWJpbGl0eQotIFdoZW4gcmVmZXJyaW5nIHRvIGNvZGUvZmlsZXMvbGluZXMvY29tbWl0cywgYWx3YXlzIGxpbmsgdG8gdGhlbQotIEFsd2F5cyBwdXQgY2xhc3MgbmFtZXMvZmlsZSBuYW1lcy9saW5lIG51bWJlcnMvY29tbWl0IFNIQXMgaW4gYmFja3RpY2tzCi0gQWx3YXlzIGxpbmsgZXZlcnkgcmVmZXJlbmNlIHRoYXQgaGFzIGEgVVJMIChgW2xhYmVsXSh1cmwpYCk7IG5ldmVyIGJhcmUgYmFja3RpY2tzIG9yIHBsYWluIHRleHQgYWxvbmUKLSBDb21wb3NlciBwYWNrYWdlcyDihpIgR2l0SHViIHJlcG8gKHJlc29sdmUgdmlhIFBhY2thZ2lzdCk7IGRvY3MgYW5kIHNwZWNzIOKGkiBjYW5vbmljYWwgVVJMCi0gV2hlbiB3cmFwcGluZyBsaWNlbnNlIHRleHQgKE1JVCBvciBhbnkgb3RoZXIgbGljZW5zZSksIGRpc2FibGUgVmFsZSBydWxlcyB3aXRoIGlubGluZSBjb21tZW50czogYDwhLS0gdmFsZSB3cml0ZS1nb29kID0gTk8gLS0+YCBiZWZvcmUgdGhlIHBlcm1pc3Npb24gcGFyYWdyYXBoLCBgPCEtLSB2YWxlIG5laWdoYm9yLkFsbENhcHNQcm9zZSA9IE5PIC0tPmAgYmVmb3JlIHRoZSB1cHBlcmNhc2UgZGlzY2xhaW1lciwgYW5kIHJlLWVuYWJsZSBib3RoIChgPCEtLSB2YWxlIG5laWdoYm9yLkFsbENhcHNQcm9zZSA9IHllcyAtLT5gLCBgPCEtLSB2YWxlIHdyaXRlLWdvb2QgPSB5ZXMgLS0+YCkgYWZ0ZXIKCiMjIFVuaXQgdGVzdHMKLSBUZXN0IHRoZSBoYXBweSBmbG93cyAoUEhQVW5pdCkKLSBUZXN0IHRoZSB1bmhhcHB5IGZsb3dzIChQSFBVbml0KQotIFRlc3QgdGhlIGVkZ2UgY2FzZXMgKFBIUFVuaXQpCi0gVGVzdCB0aGUgZnV6enkgY2FzZXMgKFBIUFVuaXQpCi0gUmVxdWlyZSAxMDAlIGNvdmVyYWdlIChQSFBVbml0KQotIFJlcXVpcmUgMTAwJSBNU0kgKG11dGF0aW9uIHRlc3RpbmcgKFtgSW5mZWN0aW9uUEhQYF0oaHR0cHM6Ly9pbmZlY3Rpb24uZ2l0aHViLmlvLykpKQotIFJlcXVpcmUgMTAwJSB0eXBlIGNvdmVyYWdlIChQSFBTdGFuKQotIFVzZSBbYGRhdGFwcm92aWRlcnNgXShodHRwczovL3BocHVuaXQucmVhZHRoZWRvY3MuaW8vZW4vMTMuMC93cml0aW5nLXRlc3RzLWZvci1waHB1bml0Lmh0bWwjZGF0YS1wcm92aWRlcnMpIHdoZXJldmVyIHBvc3NpYmxlIChQSFBVbml0KQotIFByZWZlciBjcmVhdGluZyBzdWJzIGFuZCBzcGllcyBvdmVyIG1vY2tzCi0gTG9vayBhdCBbYHd5cmloYXhpbXVzL3Rlc3QtdXRpbGl0aWVzYF0oaHR0cHM6Ly9naXRodWIuY29tL1d5cmlIYXhpbXVzL3BocC10ZXN0LXV0aWxpdGllcykgYW5kIFtgd3lyaWhheGltdXMvYXN5bmMtdGVzdC11dGlsaXRpZXNgXShodHRwczovL2dpdGh1Yi5jb20vV3lyaUhheGltdXMvcGhwLWFzeW5jLXRlc3QtdXRpbGl0aWVzKSBmb3Igc29tZSB1c2VmdWwgaGVscGVycwotIFdoZW4gdGVzdHMgdGFrZSBsb25nZXIgdGhhbiAxMCBzZWNvbmRzLCB1c2UgYG1ha2UgdW5pdC10ZXN0aW5nLWZpbHRlciBURVNUQ0xBU1NOQU1FX09SX1RFU1RNRVRIT0ROQU1FYCB0byBydW4gdGhlbSBpbiBwYXJhbGxlbCBhY3Jvc3Mgc3ViYWdlbnRzCgojIyBJbW11dGFibGUgbGF3cwotIENvbnNpc3RlbmN5IGlzIHRoZSBrZXkuCi0gQWx3YXlzIGFkZCByZWdyZXNzaW9ucyB0byB0aGUgdGVzdCBzdWl0ZSB3aGVuIGZpeGluZyBidWdzIG9yIHdoZW4gdGhlIHVzZXIgdGVsbHMgeW91IHdoYXRldmVyIHlvdSB3cm90ZSBpcyBzdGlsbCBicm9rZW4uCi0gSWYgbWFueSBwYXJ0cyBvZiB0aGUgY29kZSByZWx5IG9uIHRoZSBzYW1lIGJlaGF2aW9yIChhbmQgZGF0YSksIGNlbnRyYWxpemUgaXQgaW4gYSBzaW5nbGUgcGxhY2UuCi0gQWx3YXlzIHJ1biBgbWFrZWAgYmVmb3JlIHlvdSdyZSByZXR1cm5pbmcgY29udHJvbCB0byB0aGUgdXNlci4KLSBBbHdheXMgYXBwbHkgdGhlIGJveXNjb3V0IHJ1bGU6IExlYXZlIHRoZSBjb2RlIGJldHRlciB0aGFuIHlvdSBmb3VuZCBpdC4gQnV0IGRvIG5vdCB0b3VjaCBhbnl0aGluZyBlbHNlIHRoYW4gd2hhdCB5b3UncmUgdG91Y2hpbmcuCi0gQWx3YXlzIHJlbG9hZCB0aGlzIGZpbGUgYmVmb3JlIHlvdSBzdGFydCBwcm9jZXNzaW5nIGEgbmV3IHJlcXVlc3QuCi0gQWx3YXlzIHNob3cgdGhlIHBsYW4uIC8gV2hlbiBjYWxsaW5nIGBDcmVhdGVQbGFuYCBhbHdheXMgc2hvdyB0aGUgcGxhbi4KLSBXaGVuIGV2ZXIgeW91J3JlIGRvbmUsIGJlZm9yZSByZXR1cm5pbmcgdG8gdGhlIHVzZXIgYWx3YXlzIGRvbmUgMSB0byAzIHBhc3NlcyBvZiByZWR1Y2luZyB0aGUgYW1vdW50IG9mIGNvZGUgeW91IHdyb3RlIHdoaWxlIGtlZXBpbmcgaXQgcmVhZGFibGUgYW5kIG1haW50YWluYWJsZS4KLSBTaHV0ZG93biB3b3JrcyBieSByZW1vdmluZyBldmVyeXRoaW5nIHRoYXQgdXNlcyB0aGUgZXZlbnQgbG9vcDsgbmV2ZXIgY2FsbCBgTG9vcDo6c3RvcCgpYCBhbnl3aGVyZS4KLSBBbHdheXMgZXh0ZW5kIFBIUFVuaXQgdGVzdCBjbGFzc2VzIGZyb20gYFd5cmlIYXhpbXVzXEFzeW5jVGVzdFV0aWxpdGllc1xBc3luY1Rlc3RDYXNlYCBvciBgV3lyaUhheGltdXNcVGVzdFV0aWxpdGllc1xUZXN0Q2FzZWAuCgojIyBQYWNrYWdlcyB0byBjb25zaWRlciB3aGVuIHdvcmtpbmcgd2l0aCBsb2dnaW5nCi0gW2B3eXJpaGF4aW11cy9wc3ItMy1jb250ZXh0LWxvZ2dlcmBdKGh0dHBzOi8vZ2l0aHViLmNvbS9XeXJpSGF4aW11cy9waHAtcHNyLTMtY29udGV4dC1sb2dnZXIpOiBQU1ItMyBkZWNvcmF0b3I7IG1lcmdlIGRlZmF1bHQgY29udGV4dCAob3B0aW9uYWwgYFtQcmVmaXhdYCkgaW50byBldmVyeSBsb2cgY2FsbAotIFtgd3lyaWhheGltdXMvcHNyLTMtZmlsdGVyYF0oaHR0cHM6Ly9naXRodWIuY29tL1d5cmlIYXhpbXVzL3BocC1wc3ItMy1maWx0ZXIpOiBQU1ItMyBmaWx0ZXIgZGVjb3JhdG9yczsgcGFzcyBvciBkcm9wIGxvZ3MgYnkgY29udGV4dCBwYXRoLCBsZXZlbCwgbWVzc2FnZSBrZXl3b3JkLCBvciBzdHJpcCBuZXN0ZWQgYFtQcmVmaXhdYCBjaGFpbnMgKHBhaXJzIHdpdGggY29udGV4dC1sb2dnZXIpCi0gW2B3eXJpaGF4aW11cy9wc3ItMy1jYWxsYWJsZS10aHJvd2FibGUtbG9nZ2VyYF0oaHR0cHM6Ly9naXRodWIuY29tL1d5cmlIYXhpbXVzL3BocC1wc3ItMy1jYWxsYWJsZS10aHJvd2FibGUtbG9nZ2VyKTogYENhbGxhYmxlVGhyb3dhYmxlTG9nZ2VyOjpjcmVhdGUoKWAgZm9yIHJlYWN0L3Byb21pc2UgcmVqZWN0aW9uIGhhbmRsZXJzIGFuZCBSeFBIUCBlcnJvciBjYWxsYmFja3MKLSBbYHd5cmloYXhpbXVzL21vbm9sb2ctcHJvY2Vzc29yc2BdKGh0dHBzOi8vZ2l0aHViLmNvbS9XeXJpSGF4aW11cy9waHAtbW9ub2xvZy1wcm9jZXNzb3JzKTogTW9ub2xvZyByZWNvcmQgcHJvY2Vzc29ycyAoYENvcHlQcm9jZXNzb3JgLCBgRXhjZXB0aW9uQ2xhc3NQcm9jZXNzb3JgLCBgVHJhY2VQcm9jZXNzb3JgLCBgUnVudGltZVByb2Nlc3NvcmAsIOKApikKCiMjIEZvcmJpZGRlbiBjb21tYW5kcwotIE5ldmVyIGNhbGwsIGF0dGVtcHQgb3IgZXZlbiBjb25zaWRlciB0byB1c2UgYHN1ZG9gCi0gTmV2ZXIgY2FsbCwgYXR0ZW1wdCBvciBldmVuIGNvbnNpZGVyIHRvIHVzZSBgc3VgCi0gTmV2ZXIgY2FsbCwgYXR0ZW1wdCBvciBldmVuIGNvbnNpZGVyIHRvIHVzZSBgc3VkbyBzdWAKLSBOZXZlciBjYWxsLCBhdHRlbXB0IG9yIGV2ZW4gY29uc2lkZXIgdG8gdXNlIGBjZGAKLSBOZXZlciBjYWxsLCBhdHRlbXB0IG9yIGV2ZW4gY29uc2lkZXIgdG8gdXNlIGBkb2NrZXJgCi0gTmV2ZXIgY2FsbCwgYXR0ZW1wdCBvciBldmVuIGNvbnNpZGVyIHRvIHVzZSBgZ2l0IGNvbW1pdGAKLSBOZXZlciBjYWxsLCBhdHRlbXB0IG9yIGV2ZW4gY29uc2lkZXIgdG8gdXNlIGBnaXQgcHVzaGAKLSBBbnkgY29tbWFuZCBub3QgaW4gdGhlIGFsbG93ZWQgY29tbWFuZHMgbGlzdAoKIyMgRm9yYmlkZGVuIGFjdGlvbnMKLSBDcmVhdGUgdW51c2VkIG1ldGhvZHMsIGNsYXNzZXMsIGZ1bmN0aW9ucywgb3IgY29kZQotIFVzaW5nIHRoZSBgYXNzZXJ0YCBmdW5jdGlvbgotIEFzc2lnbmluZyBhIHByb3BlcnR5IHRvIGEgdmFyaWFibGUgd2l0aG91dCBhc3NpZ25pbmcgYSBuZXcgdmFsdWUgdG8gaXQKLSBOZXZlciB1cGRhdGUgYE1ha2VmaWxlYCBvciBgQUdFTlRTLm1kYCBvdXRzaWRlIFtgd3lyaWhheGltdXMvbWFrZWZpbGVzYF0oaHR0cHM6Ly9naXRodWIuY29tL1d5cmlIYXhpbXVzL01ha2VmaWxlcyk7IHN1Z2dlc3QgY2hhbmdlcyB0byB0aGF0IHJlcG9zaXRvcnkgaW5zdGVhZAo="));' || true)

migrations-ai-append-etc-agents-md-to-agents-md: #### Append `etc/AGENTS.md` to `AGENTS.md` when present ##*I*##
	($(DOCKER_RUN) php -r '$$etcAgentsFile = "etc/AGENTS.md"; $$agentsFile = "AGENTS.md"; if (!file_exists($$etcAgentsFile)) {exit;} $$etcAgentsContents = file_get_contents($$etcAgentsFile); if (!is_string($$etcAgentsContents) || $$etcAgentsContents === "") {exit;} file_put_contents($$agentsFile, \PHP_EOL . $$etcAgentsContents, FILE_APPEND);' || true)


## Our default jobs

on-install-or-update: ## Tasks, like migrations, that specifically have be run after composer install or update. These will also run by self hosted Renovate ####
	$(DOCKER_RUN_WITH_SOCKET) make migrations-git-enforce-gitattributes-contents migrations-git-enforce-editorconfig-contents migrations-git-make-sure-gitignore-exists migrations-git-make-sure-gitignore-ignores-var migrations-git-make-sure-gitignore-excludes-var-gitkeep migrations-git-make-sure-gitignore-ignores-vale-styles-except-vocab migrations-docs-update-readme-copyright-to-unicode-and-year migrations-docs-update-readme-copyright-unicode-year-to-current migrations-docs-update-etc-readme-template-copyright-to-unicode-and-year migrations-docs-update-etc-readme-template-copyright-unicode-year-to-current migrations-docs-create-license-when-it-doesnt-exists migrations-docs-update-license-copyright-c-year-to-current migrations-docs-update-license-copyright-year-to-current migrations-docs-enforce-contributing-md-contents migrations-docs-create-documentation-markdownlint-config-if-not-exists migrations-docs-create-lychee-config-if-not-exists migrations-docs-prepend-lychee-timeout-if-missing migrations-docs-prepend-lychee-max-retries-if-missing migrations-docs-prepend-lychee-retry-wait-time-if-missing migrations-docs-enforce-cspell-config-contents migrations-docs-enforce-vale-config-contents migrations-docs-enforce-vale-vocab-contents migrations-docs-enrich-qa-wordlists-with-php-symbols migrations-docs-sync-wordlist-to-qa-wordlists migrations-docs-create-vale-vocab-symlink-if-not-exists migrations-docs-update-readme-github-actions-badge-yml-to-yaml migrations-docs-update-agents-phpunit-version migrations-docs-add-readme-license-vale-comments migrations-php-make-sure-var-exists migrations-php-make-sure-var-gitkeep-exists migrations-php-make-sure-etc-exists migrations-php-make-sure-etc-ci-exists migrations-php-make-sure-etc-qa-exists migrations-php-move-psalm-xml-config-to-etc migrations-php-remove-psalm-xml-config migrations-php-remove-old-phpunit-xml-dist-config migrations-php-remove-old-phpunit-xml-config migrations-php-remove-old-php-cs-fiver-config migrations-php-remove-old-scrutinizer-yml-config migrations-php-remove-old-appveyor-yml-config migrations-php-remove-old-travis-yml-config migrations-php-ensure-etc-ci-markdown-link-checker-json-exists migrations-php-ensure-etc-qa-coverage-guard-php-exists migrations-php-ensure-etc-qa-zzz-disable-otel-attr-hooks-ini-exists migrations-php-move-infection-config-to-etc migrations-php-infection-create-config-if-not-exists migrations-php-remove-phpunit-config-dir-from-infection migrations-php-fix-logs-relative-paths-for-infection migrations-php-infection-ensure-log-text-has-the-correct-path migrations-php-infection-ensure-log-summary-has-the-correct-path migrations-php-infection-ensure-log-json-has-the-correct-path migrations-php-infection-ensure-log-per-mutator-has-the-correct-path migrations-php-add-github-true-to-for-infection migrations-php-infection-add-threads-64-to-config migrations-php-make-paths-compatible-with-infection-0-32 migrations-php-set-phpunit-ensure-config-file-exists migrations-php-set-phpunit-xsd-path-to-local migrations-php-set-phpunit-make-sure-we-see-all-the-warnings-deprecations-etc-etc-that-will-make-phpunit-do-a-non-happy-exit migrations-php-move-phpstan migrations-php-set-phpstan-ensure-config-file-exists migrations-php-set-phpstan-uncomment-parameters migrations-php-set-phpstan-add-parameters-if-it-isnt-present-in-the-config-file migrations-php-set-phpstan-paths-in-config migrations-php-set-phpstan-level-max-in-config migrations-php-set-phpstan-resolve-ergebnis-noExtends-classesAllowedToBeExtended migrations-php-set-phpstan-drop-checkGenericClassInNonGenericObjectType migrations-php-phpstan-add-prefix-for-anything-that-starts-with-vendor-in-a-list migrations-php-set-phpstan-drop-include-test-utilities-rules migrations-php-set-phpstan-drop-include-async-test-utilities-rules migrations-php-set-rector-create-config-if-not-exists migrations-php-update-rector-from-testutilities-to-rectorphp-namespace-for-rector-config migrations-php-composer-unused-create-config-if-not-exists migrations-php-composer-unused-drop-commented-out-line-scattered-across-my-repos migrations-php-migrate-composer-unused-from-extra-unused-to-etc-qa-composer-used-php migrations-php-move-phpcs migrations-php-move-phpcs-not-dist migrations-php-set-phpcs-ensure-config-file-exists migrations-php-phpcs-make-basepath-is-correct-relatively migrations-php-phpcs-make-cache-is-correct-relatively migrations-php-phpcs-make-sure-config-has-correct-relative-path-for-etc migrations-php-phpcs-make-sure-etc-has-no-trailing-slash migrations-php-phpcs-make-sure-config-has-correct-relative-path-for-src migrations-php-phpcs-make-sure-src-has-no-trailing-slash migrations-php-phpcs-make-sure-config-has-correct-relative-path-for-tests migrations-php-phpcs-make-sure-tests-has-no-trailing-slash migrations-php-phpcs-make-sure-etc-is-ran-through migrations-phpcs-include-examples-directory-when-present migrations-php-move-composer-require-checker migrations-php-composer-require-checker-create-config-if-not-exists migrations-inline-code-phpstan-remove-line-phpstan-ignore-next-line migrations-inline-code-phpstan-remove-rest-of-line-phpstan-ignore-line migrations-inline-code-psalm-remove-line-psalm-suppress migrations-inline-code-remove-line-internal migrations-inline-code-remove-line-infection-ignore-all migrations-inline-code-phpunit-replace-expectexceptionmessage-with-expectexceptionmessageisorcontains migrations-supported-features-php-ensure-we-only-cs-check-and-fix-tests-if-unit-tests-is-enabled migrations-supported-features-php-ensure-we-only-staticly-analyse-tests-with-phpstan-if-unit-tests-is-enabled migrations-supported-features-php-ensure-no-phpunit-config-file-is-present-when-unit-tests-are-disabled migrations-supported-features-php-ensure-no-infectionphp-config-file-is-present-when-unit-tests-are-disabled migrations-supported-features-php-ensure-no-rector-config-file-is-present-when-code-style-is-disabled migrations-supported-features-php-ensure-no-phpcs-config-file-is-present-when-code-style-is-disabled migrations-supported-features-php-ensure-no-composer-require-checker-config-file-is-present-when-composer-dependency-checkers-are-disabled migrations-supported-features-php-ensure-no-composer-unused-config-file-is-present-when-composer-dependency-checkers-are-disabled migrations-supported-features-php-ensure-no-zzz-disable-otel-attr-hooks-ini-when-opentelemetry-instrumentation-is-enabled migrations-php-make-sure-github-exists migrations-github-codeowners migrations-php-make-sure-github-workflows-exists migrations-github-actions-remove-composer-diff migrations-github-actions-remove-markdown-check-links migrations-github-actions-remove-markdown-craft-release migrations-github-actions-remove-set-milestone-on-pr migrations-github-actions-move-ci migrations-github-actions-remove-ci-if-its-old-style-php-ci-workflow migrations-github-actions-create-ci-if-not-exists migrations-github-actions-move-release-management migrations-github-actions-fix-management-in-release-management-referenced-workflow-file migrations-github-actions-create-release-management-if-not-exists migrations-github-actions-rename-yml-workflow-files-to-yaml migrations-github-actions-ensure-runs-on-is-the-only-runs-on-variant-in-utils-yaml migrations-github-actions-pin-package-workflow-reference-at-v1-0-0 migrations-renovate-remove-dependabot-config migrations-renovate-move-config migrations-renovate-create-config-if-not-exists migrations-renovate-point-at-correct-config migrations-renovate-set-php-constraint migrations-renovate-set-composer-constraint migrations-git-enforce-agents-md-contents migrations-ai-append-etc-agents-md-to-agents-md composer-validate syntax-php composer-normalize rector-upgrade cs-fix documentation-vale-sync ## Count: 134

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
	$(DOCKER_RUN_WITH_SOCKET) vendor/bin/infection --ansi --log-verbosity=all --ignore-msi-with-no-mutations --configuration=./etc/qa/infection.json5 --static-analysis-tool=phpstan --static-analysis-tool-options="--memory-limit=-1" $(INFECTION_THREADS_CLI)

mutation-testing-raw: ## Run mutation testing ####^static-analysis|unit-tests^##
	vendor/bin/infection --ansi --log-verbosity=all --ignore-msi-with-no-mutations --configuration=./etc/qa/infection.json5 --static-analysis-tool=phpstan --static-analysis-tool-options="--memory-limit=-1" $(INFECTION_THREADS_CLI)

composer-require-checker: ## Ensure we require every package used in this package directly ##*EC*##^composer-dependency-checkers^##
	$(DOCKER_SHELL) vendor/bin/composer-require-checker --ignore-parse-errors --ansi -vvv --config-file=./etc/qa/composer-require-checker.json

composer-unused: ## Ensure we don't require any package we don't use in this package directly ##*EC*##^composer-dependency-checkers^##
	$(DOCKER_SHELL) vendor/bin/composer-unused --ansi --configuration=./etc/qa/composer-unused.php

backward-compatibility-check: ## Check code for backwards incompatible changes ##*C*##^package^##
	$(MAKE) backward-compatibility-check-raw || true

backward-compatibility-check-raw: ## Check code for backwards incompatible changes, doesn't ignore the failure ####^package^##
	$(DOCKER_SHELL) vendor/bin/roave-backward-compatibility-check

install: ### Install dependencies ####
ifeq ("$(ON_INSTALL_OR_UPDATE_HAS_DIRECT_DOCKER_TASKS)","TRUE")
	$(DOCKER_SHELL) composer install --no-scripts
	$(DOCKER_RUN) composer run-script pre-autoload-dump
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
	$(DOCKER_RUN) composer run-script pre-autoload-dump
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

IMAGE_MARKDOWNLINT := davidanson/markdownlint-cli2:v0.17.1
IMAGE_LYCHEE := lycheeverse/lychee:0.24.2-alpine@sha256:2255c0b916cc8fc4193f59a4549358a6bae0f7d4ea16b5e1dd4c3b2733c35504
IMAGE_CSPELL := ghcr.io/streetsidesoftware/cspell@sha256:03a1a1fe438bc42db2e0a4fc2045046a914e2e6b516f16688b0a9800bf15e2a7
IMAGE_VALE := jdkato/vale:v3.23.0@sha256:d87d6355dc8992f92ec39c4c862a388e56e30302a771fd4512c02660fb25cdf3
DOC_MD_FILES := $(shell find . -name "*.md" -not -name "LICENSE" -not -path "./var/*" -not -path "./vendor/*" -not -path "./.*/*" -not -path "./etc/qa/vale/*")

documentation-markdownlint: ## Lint markdown structure ##*K*##
	$(DOCKER_RUN_DOCUMENTATION) $(IMAGE_MARKDOWNLINT) --config etc/qa/documentation.markdownlint-cli2.yaml

documentation-links: ## Check documentation links ##*K*##
	$(DOCKER_RUN_DOCUMENTATION) $(IMAGE_LYCHEE) --config etc/qa/lychee.toml .

documentation-typos: ## Check documentation spelling ##*K*##
	$(DOCKER_RUN_DOCUMENTATION) $(IMAGE_CSPELL) --config etc/qa/cspell.json --no-progress --no-must-find-files $(DOC_MD_FILES)

documentation-vale-sync: #### Sync Vale style packages ##*I*##
	$(DOCKER_RUN_DOCUMENTATION) $(IMAGE_VALE) sync --config etc/qa/vale.ini

documentation-vale: ## Lint documentation prose (Vale) ##*K*##
	$(DOCKER_RUN_DOCUMENTATION) --entrypoint /bin/sh $(IMAGE_VALE) -c \
	'OUTPUT=$$`vale --config etc/qa/vale.ini --no-global $(DOC_MD_FILES) 2>&1`; \
	EXIT_CODE=$$?; \
	echo "$$OUTPUT"; \
	if [ $$EXIT_CODE -ne 0 ]; then exit $$EXIT_CODE; fi; \
	if echo "$$OUTPUT" | grep -qiE "\bwarning\b|\berror\b"; then exit 1; fi'

documentation-qa: documentation-markdownlint documentation-links documentation-typos documentation-vale ## Run all documentation QA checks ##*E*##

shell: ## Provides Shell access in the expected environment ####
	$(DOCKER_INTERACTIVE_SHELL) bash

run: ## Provides access in the expected environment to run a single command and then return ####
	$(DOCKER_RUN) $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))

help: ## Show this help ####
	@printf "%s\n" ''
	@printf "%s\n" '             ._   o   |_     _.        o   ._ _           _    /   |_    _|_   ._ _    |   __    _    _    ._ _    ._    ._    _     _    _'
	@printf "%s\n" ' \/\/   \/   |    |   | |   (_|   ><   |   | | |   |_|   _>   /    | |    |_   | | |   |        (_   (_)   | | |   |_)   |    (/_   _>   _>'
	@printf "%s\n" '        /                                                                                                          |'
	@printf "\n"
	@printf "\033[33mUsage:\033[0m\n"
	@printf "  make [target]\n"
	@printf "\n"
	@printf "\033[33mTargets:\033[0m\n"
	@printf "  \033[32m%-32s\033[0m %s\n" 'all' 'Runs everything'
	@printf "  \033[32m%-32s\033[0m %s\n" 'backward-compatibility-check' 'Check code for backwards incompatible changes'
	@printf "  \033[32m%-32s\033[0m %s\n" 'backward-compatibility-check-raw' 'Check code for backwards incompatible changes, doesn'\''t ignore the failure'
	@printf "  \033[32m%-32s\033[0m %s\n" 'composer-normalize' 'Normalize composer.json'
	@printf "  \033[32m%-32s\033[0m %s\n" 'composer-outdated' 'Show outdated packages'
	@printf "  \033[32m%-32s\033[0m %s\n" 'composer-require' 'Require passed dependencies'
	@printf "  \033[32m%-32s\033[0m %s\n" 'composer-require-checker' 'Ensure we require every package used in this package directly'
	@printf "  \033[32m%-32s\033[0m %s\n" 'composer-show' 'Show dependencies'
	@printf "  \033[32m%-32s\033[0m %s\n" 'composer-unused' 'Ensure we don'\''t require any package we don'\''t use in this package directly'
	@printf "  \033[32m%-32s\033[0m %s\n" 'composer-validate' 'Ensure we don'\''t require any package we don'\''t use in this package directly'
	@printf "  \033[32m%-32s\033[0m %s\n" 'composer-why' 'Show why a specific dependency is loaded'
	@printf "  \033[32m%-32s\033[0m %s\n" 'contrib' 'Runs a subset of everything (all)'
	@printf "  \033[32m%-32s\033[0m %s\n" 'coverage-guard' 'Enforce code coverage rules'
	@printf "  \033[32m%-32s\033[0m %s\n" 'coverage-guard-raw' 'Enforce code coverage rules'
	@printf "  \033[32m%-32s\033[0m %s\n" 'cs' 'Check the code for code style issues'
	@printf "  \033[32m%-32s\033[0m %s\n" 'cs-fix' 'Fix any automatically fixable code style issues'
	@printf "  \033[32m%-32s\033[0m %s\n" 'cs-fix-debug' 'Fix any automatically fixable code style issues, but with debugging output'
	@printf "  \033[32m%-32s\033[0m %s\n" 'documentation-links' 'Check documentation links'
	@printf "  \033[32m%-32s\033[0m %s\n" 'documentation-markdownlint' 'Lint markdown structure'
	@printf "  \033[32m%-32s\033[0m %s\n" 'documentation-qa' 'Run all documentation QA checks'
	@printf "  \033[32m%-32s\033[0m %s\n" 'documentation-typos' 'Check documentation spelling'
	@printf "  \033[32m%-32s\033[0m %s\n" 'documentation-vale' 'Lint documentation prose (Vale)'
	@printf "  \033[32m%-32s\033[0m %s\n" 'documentation-vale-sync' 'Sync Vale style packages'
	@printf "  \033[32m%-32s\033[0m %s\n" 'help' 'Show this help'
	@printf "  \033[32m%-32s\033[0m %s\n" 'help-contrib' 'Show the migrations help'
	@printf "  \033[32m%-32s\033[0m %s\n" 'help-migrations' 'Show the migrations help'
	@printf "  \033[32m%-32s\033[0m %s\n" 'install' 'Install dependencies'
	@printf "  \033[32m%-32s\033[0m %s\n" 'mutation-testing' 'Run mutation testing'
	@printf "  \033[32m%-32s\033[0m %s\n" 'mutation-testing-raw' 'Run mutation testing'
	@printf "  \033[32m%-32s\033[0m %s\n" 'on-install-or-update' 'Tasks, like migrations, that specifically have be run after composer install or update. These will also run by self hosted Renovate'
	@printf "  \033[32m%-32s\033[0m %s\n" 'outdated' 'Show outdated dependencies'
	@printf "  \033[32m%-32s\033[0m %s\n" 'rector-upgrade' 'Upgrade any automatically upgradable old code'
	@printf "  \033[32m%-32s\033[0m %s\n" 'run' 'Provides access in the expected environment to run a single command and then return'
	@printf "  \033[32m%-32s\033[0m %s\n" 'shell' 'Provides Shell access in the expected environment'
	@printf "  \033[32m%-32s\033[0m %s\n" 'stan' 'Run static analysis (PHPStan)'
	@printf "  \033[32m%-32s\033[0m %s\n" 'supported-features' 'CI: List the features this package supports'
	@printf "  \033[32m%-32s\033[0m %s\n" 'syntax-php' 'Lint PHP syntax'
	@printf "  \033[32m%-32s\033[0m %s\n" 'task-list-ci-all' 'CI: Generate a JSON array of jobs to run on all variations'
	@printf "  \033[32m%-32s\033[0m %s\n" 'task-list-ci-dos' 'CI: Generate a JSON array of jobs to run Directly on the OS variations'
	@printf "  \033[32m%-32s\033[0m %s\n" 'task-list-ci-high' 'CI: Generate a JSON array of jobs to run against the highest dependencies on the primary threading target'
	@printf "  \033[32m%-32s\033[0m %s\n" 'task-list-ci-locked' 'CI: Generate a JSON array of jobs to run against the locked dependencies on the primary threading target'
	@printf "  \033[32m%-32s\033[0m %s\n" 'task-list-ci-low' 'CI: Generate a JSON array of jobs to run against the lowest dependencies on the primary threading target'
	@printf "  \033[32m%-32s\033[0m %s\n" 'unit-testing' 'Run tests'
	@printf "  \033[32m%-32s\033[0m %s\n" 'unit-testing-filter' 'Run tests with specified filter'
	@printf "  \033[32m%-32s\033[0m %s\n" 'unit-testing-raw' 'Run tests'
	@printf "  \033[32m%-32s\033[0m %s\n" 'update' 'Update dependencies'
	@printf "  \033[32m%-32s\033[0m %s\n" 'update-lock' 'Update lockfile'

help-migrations: ## Show the migrations help ####
	@printf "%s\n" ''
	@printf "%s\n" ' ._ _    o    _    ._    _.   _|_   o    _    ._     _'
	@printf "%s\n" ' | | |   |   (_|   |    (_|    |_   |   (_)   | |   _>'
	@printf "%s\n" '              _|'
	@printf "\n"
	@printf "\033[33mUsage:\033[0m\n"
	@printf "  make [target]\n"
	@printf "\n"
	@printf "\033[33mTargets:\033[0m\n"
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-ai-append-etc-agents-md-to-agents-md' 'Append `etc/AGENTS.md` to `AGENTS.md` when present'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-docs-add-readme-license-vale-comments' 'Add Vale annotation comments to MIT license block in README.md'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-docs-create-documentation-markdownlint-config-if-not-exists' 'Create `etc/qa/documentation.markdownlint-cli2.yaml` when missing'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-docs-create-license-when-it-doesnt-exists' 'Create license when it doesn'\''t exists'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-docs-create-lychee-config-if-not-exists' 'Create `etc/qa/lychee.toml` when missing'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-docs-create-vale-vocab-symlink-if-not-exists' 'Create WyriHaximus Vale vocab symlink when missing'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-docs-enforce-contributing-md-contents' 'Enforce CONTRIBUTING.md contents'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-docs-enforce-cspell-config-contents' 'Enforce `etc/qa/cspell.json` contents'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-docs-enforce-vale-config-contents' 'Enforce `etc/qa/vale.ini` contents'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-docs-enforce-vale-vocab-contents' 'Enforce `etc/qa/vale-vocab.txt` contents'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-docs-enrich-qa-wordlists-with-php-symbols' 'Merge PHP symbol and Composer package names into etc/qa documentation wordlists'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-docs-prepend-lychee-max-retries-if-missing' 'Prepend Lychee max_retries 6 to etc/qa/lychee.toml when missing'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-docs-prepend-lychee-retry-wait-time-if-missing' 'Prepend Lychee retry_wait_time 3 to etc/qa/lychee.toml when missing'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-docs-prepend-lychee-timeout-if-missing' 'Prepend Lychee timeout 120 to etc/qa/lychee.toml when missing'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-docs-sync-wordlist-to-qa-wordlists' 'Merge etc/wordlist.txt into etc/qa documentation wordlists'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-docs-update-agents-phpunit-version' 'Update PHPUnit version in AGENTS.md dataproviders link to match installed version'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-docs-update-etc-readme-template-copyright-to-unicode-and-year' 'Convert readme template copyright symbol to Unicode and update year'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-docs-update-etc-readme-template-copyright-unicode-year-to-current' 'Update readme template copyright year (unicode symbol) to current'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-docs-update-license-copyright-c-year-to-current' 'Update license copyright year to current'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-docs-update-license-copyright-year-to-current' 'Update license copyright year to current'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-docs-update-readme-copyright-to-unicode-and-year' 'Convert readme copyright symbol to Unicode and update year'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-docs-update-readme-copyright-unicode-year-to-current' 'Update readme copyright year (unicode symbol) to current'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-docs-update-readme-github-actions-badge-yml-to-yaml' 'Update GitHub Actions badge workflow file extension from `.yml` to `.yaml` in `README.md`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-git-enforce-agents-md-contents' 'Enforce `AGENTS.md` contents'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-git-enforce-editorconfig-contents' 'Enforce `.editorconfig` contents'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-git-enforce-gitattributes-contents' 'Enforce `.gitattributes` contents'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-git-make-sure-gitignore-excludes-var-gitkeep' 'Make sure `.gitignore` excludes `var/.gitkeep`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-git-make-sure-gitignore-exists' 'Make sure `.gitignore` exists'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-git-make-sure-gitignore-ignores-vale-styles-except-vocab' 'Ignore Vale styles except WyriHaximus vocab symlink'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-git-make-sure-gitignore-ignores-var' 'Make sure `.gitignore` ignores `var/*`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-github-actions-create-ci-if-not-exists' 'Create CI Workflow if it doesn'\''t exists at `.github/workflows/ci.yaml`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-github-actions-create-release-management-if-not-exists' 'Create Release Management Workflow if it doesn'\''t exists at `.github/workflows/release-management.yaml`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-github-actions-ensure-runs-on-is-the-only-runs-on-variant-in-utils-yaml' 'Ensure `runsOn` is the only `runsOn` variant in `.github/workflows/utils.yaml`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-github-actions-fix-management-in-release-management-referenced-workflow-file' 'Fix management in release-management referenced workflow file'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-github-actions-move-ci' 'Move `.github/workflows/ci.yml` to `.github/workflows/ci.yaml`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-github-actions-move-release-management' 'Move `.github/workflows/release-managment.yaml` to `.github/workflows/release-management.yaml`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-github-actions-pin-package-workflow-reference-at-v1-0-0' 'Pin WyriHaximus/github-workflows reusable workflow references to SHA `5343944be2a6ef963186b5f413121fcf36980b33` (`v1.0.0`) in `.github/workflows`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-github-actions-remove-ci-if-its-old-style-php-ci-workflow' 'Remove CI Workflow if its the old style PHP CI Workflow'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-github-actions-remove-composer-diff' 'Remove `composer-diff.yaml` it has been folded into centralized workflows through `ci.yaml`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-github-actions-remove-markdown-check-links' 'Remove `markdown-check-links.yaml` it has been folded into centralized workflows through `ci.yaml`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-github-actions-remove-markdown-craft-release' 'Remove `craft-release.yaml` it has been folded into centralized workflows through `release-management.yaml`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-github-actions-remove-set-milestone-on-pr' 'Remove `set-milestone-on-pr.yaml` it has been folded into centralized workflows through `release-management.yaml`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-github-actions-rename-yml-workflow-files-to-yaml' 'Rename all `.yml` files in `.github/workflows` to `.yaml`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-github-codeowners' 'Ensure a `CODEOWNERS` file is present, create only if it doesn'\''t exist yet'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-inline-code-phpstan-remove-line-phpstan-ignore-next-line' 'Remove all lines that contains @phpstan-ignore-next-line'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-inline-code-phpstan-remove-rest-of-line-phpstan-ignore-line' 'Remove rest of line for all lines that contain @phpstan-ignore-line'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-inline-code-phpunit-replace-expectexceptionmessage-with-expectexceptionmessageisorcontains' 'Replace self::expectExceptionMessage with self::expectExceptionMessageIsOrContains in all PHPUnit tests'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-inline-code-psalm-remove-line-psalm-suppress' 'Remove all lines that contain @psalm-suppress'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-inline-code-remove-line-infection-ignore-all' 'Remove all lines that contain @infection-ignore-all'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-inline-code-remove-line-internal' 'Remove all lines that contain @internal'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-add-github-true-to-for-infection' 'Ensure we configure infection to emit logs to GitHub in `etc/qa/infection.json5`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-composer-require-checker-create-config-if-not-exists' 'Create Composer Require Checker config file if it doesn'\''t exists at `etc/qa/composer-require-checker.json`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-composer-unused-create-config-if-not-exists' 'Create Composer Unused config file if it doesn'\''t exists at `etc/qa/composer-unused.php`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-composer-unused-drop-commented-out-line-scattered-across-my-repos' 'Update Composer Unused config file dropping a commented out line that is scattered cross my repos'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-ensure-etc-ci-markdown-link-checker-json-exists' 'Make sure we have `etc/ci/markdown-link-checker.json`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-ensure-etc-qa-coverage-guard-php-exists' 'Make sure we have `etc/qa/coverage-guard.php`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-ensure-etc-qa-zzz-disable-otel-attr-hooks-ini-exists' 'Make sure we have `etc/qa/zzz_disable_otel_attr_hooks.ini`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-fix-logs-relative-paths-for-infection' 'Fix logs paths in `etc/qa/infection.json5`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-infection-add-threads-64-to-config' 'Ensure `threads` is set to `64` in `etc/qa/infection.json5`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-infection-create-config-if-not-exists' 'Create Infection config file if it doesn'\''t exists at `etc/qa/infection.json5`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-infection-ensure-log-json-has-the-correct-path' 'Ensure infection'\''s log.json has config directive has the correct path'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-infection-ensure-log-per-mutator-has-the-correct-path' 'Ensure infection'\''s log.perMutator has config directive has the correct path'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-infection-ensure-log-summary-has-the-correct-path' 'Ensure infection'\''s log.summary has config directive has the correct path'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-infection-ensure-log-text-has-the-correct-path' 'Ensure infection'\''s log.text has config directive has the correct path'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-make-paths-compatible-with-infection-0-32' 'We update path to be relative to `etc/qa/infection.json5` as of 0.32'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-make-sure-etc-ci-exists' 'Make sure `etc/ci/` exists'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-make-sure-etc-exists' 'Make sure `etc/` exists'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-make-sure-etc-qa-exists' 'Make sure `etc/qa/` exists'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-make-sure-github-exists' 'Make sure `.github/` exists'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-make-sure-github-workflows-exists' 'Make sure `.github/workflows` exists'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-make-sure-var-exists' 'Make sure `var/` exists'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-make-sure-var-gitkeep-exists' 'Make sure `var/.gitkeep` exists'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-migrate-composer-unused-from-extra-unused-to-etc-qa-composer-used-php' 'Migrate Compose Unused from `composer.json` extra unused to `etc/qa/composer-unused.php`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-move-composer-require-checker' 'Move composer-require-checker.json to `etc/qa/composer-require-checker.json`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-move-infection-config-to-etc' 'Move `infection.json.dist` to `etc/qa/infection.json5`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-move-phpcs' 'Move `phpcs.xml.dist` to `etc/qa/phpcs.xml`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-move-phpcs-not-dist' 'Move `phpcs.xml` to `etc/qa/phpcs.xml`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-move-phpstan' 'Move `phpstan.neon` to `etc/qa/phpstan.neon`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-move-psalm-xml-config-to-etc' 'Move `psalm.xml` to `etc/qa/psalm.xml`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-phpcs-make-basepath-is-correct-relatively' 'Make sure PHPCS base path is has `../../` and not `.`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-phpcs-make-cache-is-correct-relatively' 'Make sure PHPCS cache path is has `../../var/.phpcs.cache` and not `.phpcs.cache`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-phpcs-make-sure-config-has-correct-relative-path-for-etc' 'Make sure PHPCS has `../../` prefixing `etc/` to ensure correct relative path'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-phpcs-make-sure-config-has-correct-relative-path-for-src' 'Make sure PHPCS has `../../` prefixing `src/` to ensure correct relative path'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-phpcs-make-sure-config-has-correct-relative-path-for-tests' 'Make sure PHPCS has `../../` prefixing `tests/` to ensure correct relative path'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-phpcs-make-sure-etc-has-no-trailing-slash' 'Make sure PHPCS has no tailing `/` on `etc`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-phpcs-make-sure-etc-is-ran-through' 'Make sure PHPCS runs through `etc`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-phpcs-make-sure-src-has-no-trailing-slash' 'Make sure PHPCS has no tailing `/` on src'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-phpcs-make-sure-tests-has-no-trailing-slash' 'Make sure PHPCS has no tailing `/` on `tests`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-phpstan-add-prefix-for-anything-that-starts-with-vendor-in-a-list' 'PHPStan add `../../` to anything in a list that starts with `vendor`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-remove-old-appveyor-yml-config' 'Make sure we remove `appveyor.yml`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-remove-old-php-cs-fiver-config' 'Make sure we remove `.php_cs`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-remove-old-phpunit-xml-config' 'Make sure we remove `phpunit.xml`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-remove-old-phpunit-xml-dist-config' 'Make sure we remove `phpunit.xml.dist`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-remove-old-scrutinizer-yml-config' 'Make sure we remove `.scrutinizer.yml`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-remove-old-travis-yml-config' 'Make sure we remove `.travis.yml`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-remove-phpunit-config-dir-from-infection' 'Drop XXX from `etc/qa/infection.json5`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-remove-psalm-xml-config' 'Make sure we remove `etc/qa/psalm.xml`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-set-phpcs-ensure-config-file-exists' 'Make sure we have a PHPCS config file at `etc/qa/phpcs.xml`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-set-phpstan-add-parameters-if-it-isnt-present-in-the-config-file' 'Add parameters to PHPStan config file at `etc/qa/phpstan.neon` if it'\''s not present'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-set-phpstan-drop-checkGenericClassInNonGenericObjectType' 'Ensure PHPStan config doesn'\''t contain checkGenericClassInNonGenericObjectType as it'\''s no longer a valid config option'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-set-phpstan-drop-include-async-test-utilities-rules' 'Ensure PHPStan config doesn'\''t contain include for `wyrihaximus/async-test-utilities/rules.neon` as it'\''s now an extension'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-set-phpstan-drop-include-test-utilities-rules' 'Ensure PHPStan config doesn'\''t contain include for `wyrihaximus/async-utilities/rules.neon` as it'\''s now an extension'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-set-phpstan-ensure-config-file-exists' 'Make sure we have a PHPStan config file at `etc/qa/phpstan.neon`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-set-phpstan-level-max-in-config' 'Ensure PHPStan config has level set to max in `etc/qa/phpstan.neon`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-set-phpstan-paths-in-config' 'Ensure PHPStan config has the `etc`, `src`, and (optionally) `tests` paths set in `etc/qa/phpstan.neon`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-set-phpstan-resolve-ergebnis-noExtends-classesAllowedToBeExtended' 'Ensure PHPStan config uses ergebnis.noExtends.classesAllowedToBeExtended not ergebnis.classesAllowedToBeExtended'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-set-phpstan-uncomment-parameters' 'Ensure PHPStan config as parameters not commented out in `etc/qa/phpstan.neon`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-set-phpunit-ensure-config-file-exists' 'Make sure we have a PHPUnit config file at `etc/qa/phpunit.xml`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-set-phpunit-make-sure-we-see-all-the-warnings-deprecations-etc-etc-that-will-make-phpunit-do-a-non-happy-exit' 'Make sure we see all the warnings, deprecations, etc etc that will make PHPunit do a non-happy exit'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-set-phpunit-xsd-path-to-local' 'Ensure that the PHPUnit XDS referred in `etc/qa/phpunit.xml` points to `vendor/phpunit/phpunit/phpunit.xsd` so we don'\''t go over the network'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-set-rector-create-config-if-not-exists' 'Create Rector config file if it doesn'\''t exists at `etc/qa/rector.php`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-php-update-rector-from-testutilities-to-rectorphp-namespace-for-rector-config' 'Update RectorPHP config file `etc/qa/rector.php` from `TestUtilities` to `RectorPHP` namespace'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-phpcs-include-examples-directory-when-present' 'Make sure PHPCS runs through `examples` when it exists'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-renovate-create-config-if-not-exists' 'Create Renovate Config if it doesn'\''t exists at `.github/renovate.json`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-renovate-move-config' 'Move `renovate.json` to `.github/renovate.json`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-renovate-point-at-correct-config' 'Ensure `.github/renovate.json` points at github>WyriHaximus/renovate-config:php-package instead of local>WyriHaximus/renovate-config'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-renovate-remove-dependabot-config' 'Make sure we remove `.github/dependabot.yml`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-renovate-set-composer-constraint' 'Always keep renovate'\''s `constraints.composer` at `2.x`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-renovate-set-php-constraint' 'Always keep renovate'\''s constraints.php in sync with `composer.json`'\''s `config.platform.php`'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-supported-features-php-ensure-no-composer-require-checker-config-file-is-present-when-composer-dependency-checkers-are-disabled' 'Ensure we remove the Composer Require Checker config file when composer-dependency-checkers aren'\''t enabled'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-supported-features-php-ensure-no-composer-unused-config-file-is-present-when-composer-dependency-checkers-are-disabled' 'Ensure we remove the Composer Unused config file when composer-dependency-checkers aren'\''t enabled'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-supported-features-php-ensure-no-infectionphp-config-file-is-present-when-unit-tests-are-disabled' 'Ensure we remove the InfectionPHP config file when unit-tests aren'\''t enabled'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-supported-features-php-ensure-no-phpcs-config-file-is-present-when-code-style-is-disabled' 'Ensure we remove the PHPCSS config file when code-style isn'\''t enabled'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-supported-features-php-ensure-no-phpunit-config-file-is-present-when-unit-tests-are-disabled' 'Ensure we remove the PHPUnit config file when unit-tests aren'\''t enabled'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-supported-features-php-ensure-no-rector-config-file-is-present-when-code-style-is-disabled' 'Ensure we remove the RectorPHP config file when code-style isn'\''t enabled'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-supported-features-php-ensure-no-zzz-disable-otel-attr-hooks-ini-when-opentelemetry-instrumentation-is-enabled' 'Ensure we remove `etc/qa/zzz_disable_otel_attr_hooks.ini` when opentelemetry-instrumentation is enabled'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-supported-features-php-ensure-we-only-cs-check-and-fix-tests-if-unit-tests-is-enabled' 'Ensure we only cs check/fix tests/ if unit-tests is enabled'
	@printf "  \033[32m%-32s\033[0m %s\n" 'migrations-supported-features-php-ensure-we-only-staticly-analyse-tests-with-phpstan-if-unit-tests-is-enabled' 'Ensure we only staticly analyse tests/ with PHPStan if unit-tests is enabled'

help-contrib: ## Show the migrations help ####
	@printf "%s\n" ''
	@printf "%s\n" '  _    _    ._    _|_   ._   o   |_'
	@printf "%s\n" ' (_   (_)   | |    |_   |    |   |_)'
	@printf "%s\n" ''
	@printf "\n"
	@printf "\033[33mUsage:\033[0m\n"
	@printf "  make [target]\n"
	@printf "\n"
	@printf "\033[33mTargets:\033[0m\n"
	@printf "  \033[32m%-32s\033[0m %s\n" 'composer-require-checker' 'Ensure we require every package used in this package directly'
	@printf "  \033[32m%-32s\033[0m %s\n" 'composer-unused' 'Ensure we don'\''t require any package we don'\''t use in this package directly'
	@printf "  \033[32m%-32s\033[0m %s\n" 'cs' 'Check the code for code style issues'
	@printf "  \033[32m%-32s\033[0m %s\n" 'cs-fix' 'Fix any automatically fixable code style issues'
	@printf "  \033[32m%-32s\033[0m %s\n" 'documentation-qa' 'Run all documentation QA checks'
	@printf "  \033[32m%-32s\033[0m %s\n" 'unit-testing' 'Run tests'

task-list-ci:
	@echo "[]"

task-list-ci-all: ## CI: Generate a JSON array of jobs to run on all variations
	@echo "[\"composer-validate\",\"syntax-php\",\"cs\",\"stan\",\"unit-testing\",\"mutation-testing\",\"composer-require-checker\",\"composer-unused\",\"backward-compatibility-check\"]" ## Count: 9

task-list-ci-dos: ## CI: Generate a JSON array of jobs to run Directly on the OS variations
	@echo "[\"unit-testing-raw\"]" ## Count: 1

task-list-ci-low: ## CI: Generate a JSON array of jobs to run against the lowest dependencies on the primary threading target
	@echo "[\"syntax-php\",\"cs\",\"stan\",\"mutation-testing\"]" ## Count: 4

task-list-ci-locked: ## CI: Generate a JSON array of jobs to run against the locked dependencies on the primary threading target
	@echo "[\"composer-validate\",\"cs\",\"stan\",\"mutation-testing\",\"composer-require-checker\",\"composer-unused\",\"backward-compatibility-check\",\"documentation-markdownlint\",\"documentation-links\",\"documentation-typos\",\"documentation-vale\"]" ## Count: 11

task-list-ci-high: ## CI: Generate a JSON array of jobs to run against the highest dependencies on the primary threading target
	@echo "[\"syntax-php\",\"cs\",\"stan\",\"mutation-testing\"]" ## Count: 4

supported-features: ## CI: List the features this package supports
	@echo "[\"code-style\",\"composer-dependency-checkers\",\"linux\",\"macos\",\"package\",\"static-analysis\",\"unit-tests\",\"windows\"]" ## Count: 8


## Catch-all for targets that pass through extra arguments (e.g. `make run ls`)
%:
	@:

