<?php declare(strict_types=1);
require \dirname(__DIR__) . '/vendor/autoload.php';

$parser = \WyriHaximus\HtmlCompress\Factory::constructSmallest();
$sites = [
    'Example.com' => 'http://example.com/',
    'Google.nl' => 'http://google.nl/',
    'Google.co.uk' => 'http://google.co.uk/',
    'Google.com' => 'http://google.com/',
    'Tweakers' => 'http://tweakers.net/',
    'Amazon UK' => 'http://www.amazon.co.uk/',
    'Amazon US' => 'http://www.amazon.com/',
    'Apple' => 'http://www.apple.com/',
    'Facebook' => 'http://www.facebook.com/',
    'Twitter' => 'http://www.twitter.com/',
    'LinkedIn' => 'http://www.linkedin.com/',
    'NOS' => 'http://www.nos.nl/',
    'BBC' => 'http://www.bbc.co.uk/',
    'Github' => 'https://github.com/',
    'Reddit' => 'https://reddit.com/',
    'Imgur' => 'https://imgur.com/',
    'BF4 Battlelog' => 'http://battlelog.battlefield.com/bf4/',
    'BF3 Battlelog' => 'http://battlelog.battlefield.com/bf3/',
    'EU BattleNet' => 'http://eu.battle.net/',
    'US BattleNet' => 'http://us.battle.net/',
    'WyriMaps' => 'http://wyrimaps.net/',
    'WyriMaps Map' => 'http://wyrimaps.net/wow',
    'WyriHaximus' => 'http://wyrihaximus.net/',
];
$line = \str_pad('', 83, '-');

echo $line;
echo \PHP_EOL;
echo '| ';
echo \str_pad('Site Name', 13, ' ');
echo ' | ';
echo \str_pad('Original', 10, ' ', \STR_PAD_LEFT);
echo ' | ';
echo \str_pad('Compressed', 10, ' ', \STR_PAD_LEFT);
echo ' | ';
echo \str_pad('Saved', 10, ' ', \STR_PAD_LEFT);
echo ' | ';
echo \str_pad('% Original', 10, ' ', \STR_PAD_LEFT);
echo ' | ';
echo \str_pad('Time Taken', 11, ' ', \STR_PAD_LEFT);
echo ' |';
echo \PHP_EOL;
echo $line;
echo \PHP_EOL;
foreach ($sites as $siteName => $siteUrl) {
    echo '| ';
    echo \str_pad($siteName, 13, ' ');
    echo ' | ';
    $source = \file_get_contents($siteUrl);
    $sourceLen = \strlen($source);
    echo \str_pad(\number_format($sourceLen), 10, ' ', \STR_PAD_LEFT);
    echo ' | ';
    $start = \microtime(true);
    $compressed = $parser->compress($source);
    $end = \microtime(true);
    $compressedLen = \strlen($compressed);
    echo \str_pad(\number_format($compressedLen), 10, ' ', \STR_PAD_LEFT);
    echo ' | ';
    echo \str_pad(\number_format($sourceLen - $compressedLen), 10, ' ', \STR_PAD_LEFT);
    echo ' | ';
    echo \str_pad(\round(($compressedLen / $sourceLen) * 100, 3) . '%', 10, ' ', \STR_PAD_LEFT);
    echo ' | ';
    echo \str_pad(\str_pad(\round($end - $start, 5), 7, ' ') . ' sec', 11, ' ', \STR_PAD_LEFT);
    echo ' |';
    echo \PHP_EOL;
    echo $line;
    echo \PHP_EOL;
}
