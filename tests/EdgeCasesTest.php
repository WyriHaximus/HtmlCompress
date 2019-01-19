<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests;

use ApiClients\Tools\TestUtilities\TestCase;
use WyriHaximus\HtmlCompress\Factory;

/**
 * @internal
 */
final class EdgeCasesTest extends TestCase
{
    public function providerEdgeCase(): array
    {
        $baseDir = __DIR__ . \DIRECTORY_SEPARATOR . 'EdgeCases' . \DIRECTORY_SEPARATOR;
        $dirs = [];

        foreach (\glob($baseDir . '*', \GLOB_ONLYDIR) as $item) {
            $dirs[] = [$item . \DIRECTORY_SEPARATOR];
        }

        return $dirs;
    }

    /**
     * @dataProvider providerEdgeCase
     * @param mixed $dir
     */
    public function testEdgeCase($dir)
    {
        $in = \file_get_contents($dir . 'in.html');
        $out = \file_get_contents($dir . 'out.html');

        $result = Factory::constructSmallest()->compress($in);

        self::assertSame($out, $result);
    }
}
