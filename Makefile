all: phpcs dunit phpunit
travis: phpcs phpunit-travis

init:
	if [ ! -d vendor ]; then composer install; fi;

phpcs: init
	./vendor/bin/phpcs --standard=PSR2 src/

phpunit: init
	./vendor/bin/phpunit --coverage-text --coverage-html covHtml

phpunit-travis: init
	./vendor/bin/phpunit --coverage-text --coverage-clover ./build/logs/clover.xml

dunit: init
	./vendor/bin/dunit
