<?php

namespace WyriHaximus\HtmlCompress\Tests\Compressor;

use WyriHaximus\HtmlCompress\Compressor\CssMinCompressor;

class CssMinCompressorTest extends AbstractVendorCompressorTest {

    const COMPRESSOR = 'WyriHaximus\HtmlCompress\Compressor\CssMinCompressor';

    public function providerReturn() {
        return [
            [
                'p { background-color: #ffffff; font-size: 1px; }',
                'p{background-color:#ffffff;font-size:1px}',
            ],
            [
                '/* comments */
                p { background-color: #ffffff; font-size: 1px; }',
                'p{background-color:#ffffff;font-size:1px}',
            ],
        ];
    }

    /**
     * @dataProvider providerReturn
     */
    public function testReturn($input, $expected) {
        $actual = $this->compressor->compress($input);
        $this->assertSame($expected, $actual);
    }
}