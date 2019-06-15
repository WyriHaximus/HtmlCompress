<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests\Compressor;

use WyriHaximus\HtmlCompress\Compressor\BestResultCompressor;
use WyriHaximus\HtmlCompress\Compressor\CompressorInterface;
use WyriHaximus\TestUtilities\TestCase;

/**
 * @internal
 */
final class BestResultCompressorTest extends TestCase
{
    public function testCompress(): void
    {
        $input = 'abc';
        $compressorA = new class() implements CompressorInterface {
            /** @var bool */
            public $called = false;

            public function compress(string $string): string
            {
                $this->called = true;

                return 'ab';
            }
        };
        $compressorB = new class() implements CompressorInterface {
            /** @var bool */
            public $called = false;

            public function compress(string $string): string
            {
                $this->called = true;

                return 'abcd';
            }
        };

        $compressor = new BestResultCompressor($compressorA, $compressorB);
        $actual = $compressor->compress($input);

        self::assertTrue($compressorA->called);
        self::assertTrue($compressorB->called);

        self::assertSame('ab', $actual);
    }
}
