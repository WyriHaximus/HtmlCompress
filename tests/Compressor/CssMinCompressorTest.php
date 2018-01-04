<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\tests\Compressor;

use WyriHaximus\HtmlCompress\Compressor\CssMinCompressor;

/**
 * CssMinCompressorTest.
 *
 * @author Marcel Voigt <mv@noch.so>
 */
class CssMinCompressorTest extends AbstractVendorCompressorTest
{
    const COMPRESSOR = CssMinCompressor::class;

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
     * @param mixed $input
     * @param mixed $expected
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
