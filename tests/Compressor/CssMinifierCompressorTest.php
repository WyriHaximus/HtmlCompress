<?php

namespace WyriHaximus\HtmlCompress\Tests\Compressor;

/**
 * CssMinifierCompressorTest
 *
 * @author Marcel Voigt <mv@noch.so>
 */
class CssMinifierCompressorTest extends AbstractVendorCompressorTest
{
    const COMPRESSOR = 'WyriHaximus\HtmlCompress\Compressor\CssMinifierCompressor';

    public function providerReturn()
    {
        return [
            [
                'p { background-color: #ffffff; font-size: 1px; }',
                'p{background-color: #FFF;font-size: 1px}',
            ],
            [
                '/* comments */
                p { background-color: #ffffff; font-size: 1px; }',
                'p{background-color: #FFF;font-size: 1px}',
            ],
            [
                'background-color: #FFFFFF ; ',
                'background-color: #FFF;',
            ],
            [
                'background-color: #FFFFFF; font-size: 14px
                ;
                ',
                'background-color: #FFF;font-size: 14px;',
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
}
