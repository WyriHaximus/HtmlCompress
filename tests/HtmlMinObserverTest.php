<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests;

use WyriHaximus\TestUtilities\TestCase;

/**
 * @internal
 */
final class HtmlMinObserverTest extends TestCase
{
    /**
     * @return array[]
     */
    public function providerEdgeCase(): array
    {
        $dirs = [];

        $items = \glob(__DIR__ . \DIRECTORY_SEPARATOR . 'HtmlMinObserver' . \DIRECTORY_SEPARATOR . '*', \GLOB_ONLYDIR);
        if ($items !== false) {
            foreach ($items as $item) {
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

        $result = (require $dir . 'compressor.php')->compress($in);

        self::assertSame($out, $result);
        self::assertSame(\strlen($out), \strlen($result));
    }
}
