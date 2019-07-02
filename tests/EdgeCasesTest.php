<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests;

use WyriHaximus\HtmlCompress\Factory;
use WyriHaximus\TestUtilities\TestCase;

/**
 * @internal
 */
final class EdgeCasesTest extends TestCase
{
    public function providerEdgeCase(): array
    {
        $dirs = [];

        $items = \glob(__DIR__ . \DIRECTORY_SEPARATOR . 'EdgeCases' . \DIRECTORY_SEPARATOR . '*', \GLOB_ONLYDIR);
        if ($items !== false) {
            foreach ($items as $item) {
                $item = $item;
                $itemName = \explode(\DIRECTORY_SEPARATOR, $item);
                $itemName = \array_pop($itemName);
                $dirs[$itemName] = [$item . \DIRECTORY_SEPARATOR];
            }
        }

        return $dirs;
    }

    /**
     * @dataProvider providerEdgeCase
     * @param mixed $dir
     */
    public function testEdgeCase($dir): void
    {
        /** @var string $in */
        $in = \file_get_contents($dir . 'in.html');
        /** @var string $out */
        $out = \file_get_contents($dir . 'out.html');

        $result = Factory::constructSmallest()->compress($in);

        self::assertSame(\strlen($out), \strlen($result));
        self::assertSame($out, $result);
    }
}
