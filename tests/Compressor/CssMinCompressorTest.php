<?php

namespace WyriHaximus\HtmlCompress\tests\Compressor;

/**
 * CssMinCompressorTest
 *
 * @author Marcel Voigt <mv@noch.so>
 */
class CssMinCompressorTest extends AbstractVendorCompressorTest
{
    const COMPRESSOR = 'WyriHaximus\HtmlCompress\Compressor\CssMinCompressor';

    public function providerReturn()
    {
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
            [
                'background-color: #FFFFFF ; ',
                'background-color:#FFFFFF',
            ],
            [
                'background-color: #FFFFFF; font-size: 14px
                ;
                ',
                'background-color:#FFFFFF;font-size:14px',
            ],
        ];
    }

    /**
     * @dataProvider providerReturn
     */
    public function testReturn($input, $expected)
    {
        $actual = $this->compressor->compress($input);
        $this->assertSame($expected, $actual);
    }

    public function testCompress()
    {
        $this->assertTrue(is_string($this->compressor->compress('background-color: red;')));
    }
}
