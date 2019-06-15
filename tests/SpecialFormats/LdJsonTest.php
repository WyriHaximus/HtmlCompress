<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests\SpecialFormats;

use WyriHaximus\HtmlCompress\Compressor;
use WyriHaximus\TestUtilities\TestCase;

/**
 * @internal
 */
final class LdJsonTest extends TestCase
{
    public function javascriptCompressorProvider(): iterable
    {
        yield 'jsmin' => [
            new Compressor\JSMinCompressor(),
        ];

        yield 'javascript-package' => [
            new Compressor\JavaScriptPackerCompressor(),
        ];

        /*[ // This compressor results in invalid JSON
            new Compressor\JSqueezeCompressor(),
        ],*/
        yield 'mmjs' => [
            new Compressor\MMMJSCompressor(),
        ];

        yield 'jshrink' => [
            new Compressor\JShrinkCompressor(),
        ];

        yield 'yuijs' => [
            new Compressor\YUIJSCompressor(),
        ];

        yield 'return' => [
            new Compressor\ReturnCompressor(),
        ];
    }

    /**
     * @dataProvider javascriptCompressorProvider
     */
    public function testLdJson(Compressor\CompressorInterface $compressor): void
    {
        /** @var string $input */
        $input = \file_get_contents(__DIR__ . \DIRECTORY_SEPARATOR . 'input' . \DIRECTORY_SEPARATOR . 'ld.json.input');
        $inputJson = $this->getJson($input);
        $compressedInput = $compressor->compress($input);
        $compressedJson = $this->getJson($compressedInput);

        self::assertSame($inputJson, $compressedJson, $compressedInput);
    }

    private function getJson(string $string): array
    {
        /** @var int $start */
        $start = \strpos($string, '{');
        /** @var int $end */
        $end = (int)\strrpos($string, '}') + 1;
        /** @var string $string */
        $string = \substr($string, $start, $end - $start);

        return \json_decode($string, true);
    }
}
