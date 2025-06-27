<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests\SpecialFormats;

use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Test;
use RuntimeException;
use WyriHaximus\Compress\CompressorInterface;
use WyriHaximus\Compress\ReturnCompressor;
use WyriHaximus\JsCompress\Compressor as JsCompressor;
use WyriHaximus\TestUtilities\TestCase;

use function file_get_contents;
use function is_string;
use function json_decode;
use function strpos;
use function strrpos;
use function substr;

use const DIRECTORY_SEPARATOR;

final class LdJsonTest extends TestCase
{
    /** @return iterable<array<int, CompressorInterface>> */
    public static function javascriptCompressorProvider(): iterable
    {
        yield 'mmjs' => [
            new JsCompressor\MMMJSCompressor(),
        ];

        yield 'return' => [
            new ReturnCompressor(),
        ];
    }

    #[DataProvider('javascriptCompressorProvider')]
    #[Test]
    public function ldJson(CompressorInterface $compressor): void
    {
        $input = file_get_contents(__DIR__ . DIRECTORY_SEPARATOR . 'input' . DIRECTORY_SEPARATOR . 'ld.json.input');

        if (! is_string($input)) {
            throw new RuntimeException('Could not read test input file');
        }

        $inputJson       = $this->getJson($input);
        $compressedInput = $compressor->compress($input);
        $compressedJson  = $this->getJson($compressedInput);

        self::assertSame($inputJson, $compressedJson, $compressedInput);
    }

    /** @return array<mixed> */
    private function getJson(string $string): array
    {
        $start  = (int) strpos($string, '{');
        $end    = (int) strrpos($string, '}') + 1;
        $string = substr($string, $start, $end - $start);

        /** @phpstan-ignore-next-line */
        return json_decode($string, true);
    }
}
