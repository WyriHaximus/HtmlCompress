<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests\SpecialFormats;

use WyriHaximus\Compress\CompressorInterface;
use WyriHaximus\Compress\ReturnCompressor;
use WyriHaximus\JsCompress\Compressor as JsCompressor;
use WyriHaximus\TestUtilities\TestCase;

/**
 * @internal
 */
final class LdJsonTest extends TestCase
{
    public function javascriptCompressorProvider(): iterable
    {
        yield 'jsmin' => [
            new JsCompressor\JSMinCompressor(),
        ];

        /*yield 'javascript-packer' => [ // This compressor results in invalid JSON
            new JsCompressor\JavaScriptPackerCompressor(),
        ];*/

        /*[ // This compressor results in invalid JSON
            new JsCompressor\JSqueezeCompressor(),
        ],*/
        yield 'mmjs' => [
            new JsCompressor\MMMJSCompressor(),
        ];

        yield 'jshrink' => [
            new JsCompressor\JShrinkCompressor(),
        ];

        yield 'yuijs' => [
            new JsCompressor\YUIJSCompressor(),
        ];

        yield 'return' => [
            new ReturnCompressor(),
        ];
    }

    /**
     * @dataProvider javascriptCompressorProvider
     */
    public function testLdJson(CompressorInterface $compressor): void
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
