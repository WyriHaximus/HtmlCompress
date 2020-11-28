<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests;

use Generator;
use WyriHaximus\TestUtilities\TestCase;

use function array_pop;
use function explode;
use function Safe\file_get_contents;
use function Safe\glob;

use const DIRECTORY_SEPARATOR;
use const GLOB_ONLYDIR;

/**
 * @internal
 */
final class HtmlMinObserverTest extends TestCase
{
    /**
     * @return Generator<array<int, string>>
     */
    public function providerEdgeCase(): Generator
    {
        $items = glob(__DIR__ . DIRECTORY_SEPARATOR . 'HtmlMinObserver' . DIRECTORY_SEPARATOR . '*', GLOB_ONLYDIR);

        foreach ($items as $item) {
            $itemName = explode(DIRECTORY_SEPARATOR, $item);
            $itemName = array_pop($itemName);

            yield $itemName => [$item . DIRECTORY_SEPARATOR];
        }
    }

    /**
     * @param mixed $dir
     *
     * @dataProvider providerEdgeCase
     */
    public function testEdgeCase($dir): void
    {
        $in  = file_get_contents($dir . 'in.html');
        $out = file_get_contents($dir . 'out.html');

        $compressor = require $dir . 'compressor.php';
        $result     = $compressor->compress($in);

        self::assertSame($out, $result);
    }
}
