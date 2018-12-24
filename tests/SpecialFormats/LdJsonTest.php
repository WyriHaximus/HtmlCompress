<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests\SpecialFormats;

use PHPUnit\Framework\TestCase;
use WyriHaximus\HtmlCompress\Compressor;

final class LdJsonTest extends TestCase
{
    public function javascriptCompressorProvider()
    {
        return [
            [
                new Compressor\JSMinCompressor(),
            ],
            [
                new Compressor\JavaScriptPackerCompressor(),
            ],
            /*[ // This compressor results in invalid JSON
                new Compressor\JSqueezeCompressor(),
            ],*/
            [
                new Compressor\MMMJSCompressor(),
            ],
            [
                new Compressor\JShrinkCompressor(),
            ],
            [
                new Compressor\YUIJSCompressor(),
            ],
            [
                new Compressor\ReturnCompressor(),
            ],
        ];
    }

    /**
     * @dataProvider javascriptCompressorProvider
     */
    public function testLdJson(Compressor\CompressorInterface $compressor)
    {
        $input = file_get_contents(__DIR__ . DIRECTORY_SEPARATOR . 'input' . DIRECTORY_SEPARATOR . 'ld.json.input');
        $inputJson = $this->getJson($input);
        $compressedInput = $compressor->compress($input);
        $compressedJson = $this->getJson($compressedInput);

        self::assertSame($inputJson, $compressedJson, $compressedInput);
    }

    private function getJson($string)
    {
        $start = strpos($string, '{');
        $end = strrpos($string, '}') + 1;
        $string = substr($string, $start, $end - $start);

        return json_decode($string, true);
    }
}
