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
    public function provideCompressors(): iterable
    {
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

                return 'efgh';
            }
        };
        $compressorC = new class() implements CompressorInterface {
            /** @var bool */
            public $called = false;

            public function compress(string $string): string
            {
                $this->called = true;

                return 'abcd';
            }
        };

        $compressorD = new class() implements CompressorInterface {
            /** @var bool */
            public $called = false;

            public function compress(string $string): string
            {
                $this->called = true;

                return '';
            }
        };

        yield ['ab', $compressorA, $compressorC, $compressorB];
        yield ['ab', $compressorC, $compressorB, $compressorA];
        yield ['ab', $compressorC, $compressorD, $compressorA];
        yield ['abcd', $compressorC, $compressorB, $compressorB];
    }

    /**
     * @dataProvider provideCompressors
     */
    public function testCompress(string $expectedOutput, CompressorInterface ...$compressors): void
    {
        $input = 'abcdefgh';
        $compressor = new BestResultCompressor(...$compressors);
        $actual = $compressor->compress($input);

        foreach ($compressors as $compressorX) {
            self::assertTrue($compressorX->called);
        }

        self::assertSame($expectedOutput, $actual);
    }
}
