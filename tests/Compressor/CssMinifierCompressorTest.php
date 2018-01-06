<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests\Compressor;

use WyriHaximus\HtmlCompress\Compressor\CssMinifierCompressor;

/**
 * CssMinifierCompressorTest.
 *
 * @author Marcel Voigt <mv@noch.so>
 */
final class CssMinifierCompressorTest extends AbstractVendorCompressorTest
{
    const COMPRESSOR = CssMinifierCompressor::class;

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
     * @param mixed $input
     * @param mixed $expected
     */
    public function testReturn($input, $expected)
    {
        $actual = $this->compressor->compress($input);
        $this->assertSame($expected, $actual);
    }
}
