<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests\SpecialFormats;

use WyriHaximus\Compress\CompressorInterface;
use WyriHaximus\Compress\ReturnCompressor;
use WyriHaximus\JsCompress\Compressor as JsCompressor;
use WyriHaximus\TestUtilities\TestCase;

use function Safe\file_get_contents;
use function Safe\json_decode;
use function strpos;
use function strrpos;
use function substr;

use const DIRECTORY_SEPARATOR;

/** @internal */
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

    /** @dataProvider javascriptCompressorProvider */
    public function testLdJson(CompressorInterface $compressor): void
    {
        $input = file_get_contents(__DIR__ . DIRECTORY_SEPARATOR . 'input' . DIRECTORY_SEPARATOR . 'ld.json.input');

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
