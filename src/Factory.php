<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

use WyriHaximus\Compress\ReturnCompressor;
use WyriHaximus\CssCompress\Factory as CssFactory;
use WyriHaximus\HtmlCompress\Pattern\JavaScript;
use WyriHaximus\HtmlCompress\Pattern\LdJson;
use WyriHaximus\HtmlCompress\Pattern\Script;
use WyriHaximus\HtmlCompress\Pattern\Style;
use WyriHaximus\HtmlCompress\Pattern\StyleAttribute;
use WyriHaximus\JsCompress\Compressor\MMMJSCompressor;
use WyriHaximus\JsCompress\Factory as JsFactory;

final class Factory
{
    public static function constructFastest(): HtmlCompressorInterface
    {
        return new HtmlCompressor(new Patterns());
    }

    public static function construct(): HtmlCompressorInterface
    {
        $styleCompressor = CssFactory::construct();

        return new HtmlCompressor(
            new Patterns(
                new LdJson(
                    new MMMJSCompressor()
                ),
                new JavaScript(
                    JsFactory::construct()
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
        $styleCompressor = CssFactory::constructSmallest($externalCompressors);

        return new HtmlCompressor(
            new Patterns(
                new LdJson(
                    new MMMJSCompressor()
                ),
                new JavaScript(
                    JsFactory::constructSmallest($externalCompressors)
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
