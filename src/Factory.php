<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

use WyriHaximus\HtmlCompress\Compressor\CssMinCompressor;
use WyriHaximus\HtmlCompress\Compressor\CssMinifierCompressor;
use WyriHaximus\HtmlCompress\Compressor\JavaScriptPackerCompressor;
use WyriHaximus\HtmlCompress\Compressor\JShrinkCompressor;
use WyriHaximus\HtmlCompress\Compressor\JSMinCompressor;
use WyriHaximus\HtmlCompress\Compressor\JSqueezeCompressor;
use WyriHaximus\HtmlCompress\Compressor\MMMCSSCompressor;
use WyriHaximus\HtmlCompress\Compressor\MMMJSCompressor;
use WyriHaximus\HtmlCompress\Compressor\ReturnCompressor;
use WyriHaximus\HtmlCompress\Compressor\SmallestResultCompressor;
use WyriHaximus\HtmlCompress\Compressor\YUICSSCompressor;
use WyriHaximus\HtmlCompress\Compressor\YUIJSCompressor;
use WyriHaximus\HtmlCompress\Pattern\JavaScript;
use WyriHaximus\HtmlCompress\Pattern\LdJson;
use WyriHaximus\HtmlCompress\Pattern\Script;
use WyriHaximus\HtmlCompress\Pattern\Style;
use WyriHaximus\HtmlCompress\Pattern\StyleAttribute;

final class Factory
{
    public static function constructFastest(): HtmlCompressorInterface
    {
        return new HtmlCompressor(new Patterns());
    }

    public static function construct(): HtmlCompressorInterface
    {
        $styleCompressor = new CssMinCompressor();

        return new HtmlCompressor(
            new Patterns(
                new LdJson(
                    new MMMJSCompressor()
                ),
                new JavaScript(
                    new MMMJSCompressor()
                ),
                new Script(
                    new ReturnCompressor()
                ),
                new Style(
                    $styleCompressor
                ),
                new StyleAttribute(
                    $styleCompressor
                )
            )
        );
    }

    /**
     * @param  bool                    $externalCompressors When set to false only use pure PHP compressors.
     * @return HtmlCompressorInterface
     */
    public static function constructSmallest(bool $externalCompressors = true): HtmlCompressorInterface
    {
        $styleCompressor = new SmallestResultCompressor(
            new MMMCSSCompressor(),
            new CssMinCompressor(),
            new CssMinifierCompressor(),
            $externalCompressors ? new YUICSSCompressor() : new ReturnCompressor(),
            new ReturnCompressor()
        );

        return new HtmlCompressor(
            new Patterns(
                new LdJson(
                    new MMMJSCompressor()
                ),
                new JavaScript(
                    new SmallestResultCompressor(
                        new MMMJSCompressor(),
                        new JSqueezeCompressor(),
                        new JSMinCompressor(),
                        new JavaScriptPackerCompressor(),
                        new JShrinkCompressor(),
                        $externalCompressors ? new YUIJSCompressor() : new ReturnCompressor(),
                        new ReturnCompressor() // Sometimes no compression can already be the smallest
                    )
                ),
                new Script(
                    new ReturnCompressor()
                ),
                new Style(
                    $styleCompressor
                ),
                new StyleAttribute(
                    $styleCompressor
                )
            )
        );
    }
}
