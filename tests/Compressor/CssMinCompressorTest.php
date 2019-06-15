<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests\Compressor;

use WyriHaximus\HtmlCompress\Compressor\CssMinCompressor;

/**
 * CssMinCompressorTest.
 *
 * @author Marcel Voigt <mv@noch.so>
 *
 * @internal
 */
final class CssMinCompressorTest extends AbstractVendorCompressorTest
{
    const COMPRESSOR = CssMinCompressor::class;

    public function providerReturn(): iterable
    {
        yield [
            'p { background-color: #ffffff; font-size: 1px; }',
            'p{background-color:#ffffff;font-size:1px}',
        ];
        yield [
            '/* comments */
            p { background-color: #ffffff; font-size: 1px; }',
            'p{background-color:#ffffff;font-size:1px}',
        ];
        yield [
            'background-color: #FFFFFF ; ',
            'background-color:#FFFFFF',
        ];
        yield [
            'background-color: #FFFFFF; font-size: 14px
            ;
            ',
            'background-color:#FFFFFF;font-size:14px',
        ];
    }

    /**
     * @dataProvider providerReturn
     * @param mixed $input
     * @param mixed $expected
     */
    public function testCssMinCompress($input, $expected): void
    {
        $actual = $this->compressor->compress($input);
        self::assertSame($expected, $actual);
    }
}
