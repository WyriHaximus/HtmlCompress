<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests\Compressor;

use WyriHaximus\HtmlCompress\Compressor\CssMinifierCompressor;

/**
 * CssMinifierCompressorTest.
 *
 * @author Marcel Voigt <mv@noch.so>
 *
 * @internal
 */
final class CssMinifierCompressorTest extends AbstractVendorCompressorTest
{
    const COMPRESSOR = CssMinifierCompressor::class;

    public function providerReturn(): iterable
    {
        yield [
            'p { background-color: #ffffff; font-size: 1px; }',
            'p{background-color: #FFF;font-size: 1px}',
        ];
        yield [
            '/* comments */
            p { background-color: #ffffff; font-size: 1px; }',
            'p{background-color: #FFF;font-size: 1px}',
        ];
        yield [
            'background-color: #FFFFFF ; ',
            'background-color: #FFF;',
        ];
        yield [
            'background-color: #FFFFFF; font-size: 14px
            ;
            ',
            'background-color: #FFF;font-size: 14px;',
        ];
    }

    /**
     * @dataProvider providerReturn
     * @param mixed $input
     * @param mixed $expected
     */
    public function testReturn($input, $expected): void
    {
        $actual = $this->compressor->compress($input);
        self::assertSame($expected, $actual);
    }
}
