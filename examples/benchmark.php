<?php declare(strict_types=1);

use WyriHaximus\HtmlCompress\Factory;

require \dirname(__DIR__) . '/vendor/autoload.php';

$rawHtml = \file_get_contents(__DIR__ . \DIRECTORY_SEPARATOR . 'benchmark.html');

echo \date('r'), \PHP_EOL;

for ($i = 0; $i < 13; $i++) {
    Factory::constructSmallest(false)->compress($rawHtml);
}

echo \date('r'), \PHP_EOL;
