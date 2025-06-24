<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests;

use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Test;
use RuntimeException;
use WyriHaximus\HtmlCompress\Factory;
use WyriHaximus\TestUtilities\TestCase;

use function array_pop;
use function explode;
use function file_get_contents;
use function glob;
use function is_array;
use function is_string;
use function trim;

use const DIRECTORY_SEPARATOR;
use const GLOB_ONLYDIR;

final class EdgeCasesTest extends TestCase
{
    /** @return iterable<array<int, string>> */
    public static function providerEdgeCase(): iterable
    {
        /** @var list<string>|false $items */
        $items = glob(__DIR__ . DIRECTORY_SEPARATOR . 'EdgeCases' . DIRECTORY_SEPARATOR . '*', GLOB_ONLYDIR);

        if (! is_array($items)) {
            /** @phpstan-ignore shipmonk.checkedExceptionInYieldingMethod */
            throw new RuntimeException('Could not read test set directories');
        }

        foreach ($items as $item) {
            $itemName = explode(DIRECTORY_SEPARATOR, $item);
            $itemKey  = array_pop($itemName);

            yield $itemKey => [$item . DIRECTORY_SEPARATOR];
        }
    }

    #[DataProvider('providerEdgeCase')]
    #[Test]
    public function edgeCase(string $dir): void
    {
        $in = file_get_contents($dir . 'in.html');
        if (! is_string($in)) {
            throw new RuntimeException('Could not read compress test input');
        }

        $out = file_get_contents($dir . 'out.html');
        if (! is_string($out)) {
            throw new RuntimeException('Could not read compress expected test output');
        }

        $result = Factory::constructSmallest()->compress($in);

        /** Trimming both the expected output and the results because IDE's might add a new line at the end of files */
        self::assertSame(trim($out), trim($result));
    }
}
