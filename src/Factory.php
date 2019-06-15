<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

use WyriHaximus\HtmlCompress\Compressor\BestResultCompressor;
use WyriHaximus\HtmlCompress\Compressor\CssMinCompressor;
use WyriHaximus\HtmlCompress\Compressor\CssMinifierCompressor;
use WyriHaximus\HtmlCompress\Compressor\JavaScriptPackerCompressor;
use WyriHaximus\HtmlCompress\Compressor\JShrinkCompressor;
use WyriHaximus\HtmlCompress\Compressor\JSMinCompressor;
use WyriHaximus\HtmlCompress\Compressor\JSqueezeCompressor;
use WyriHaximus\HtmlCompress\Compressor\MMMCSSCompressor;
use WyriHaximus\HtmlCompress\Compressor\MMMJSCompressor;
use WyriHaximus\HtmlCompress\Compressor\ReturnCompressor;
use WyriHaximus\HtmlCompress\Compressor\YUICSSCompressor;
use WyriHaximus\HtmlCompress\Compressor\YUIJSCompressor;

final class Factory
{
    public static function constructFastest(): HtmlCompressorInterface
    {
        return new HtmlCompressor(
            [
                'compressors' => [
                    [
                        'patterns' => [
                            Patterns::MATCH_STYLE,
                            Patterns::MATCH_LD_JSON,
                            Patterns::MATCH_JSCRIPT,
                            Patterns::MATCH_SCRIPT,
                        ],
                        'compressor' => new ReturnCompressor(),
                    ],
                ],
            ]
        );
    }

    public static function construct(): HtmlCompressorInterface
    {
        return new HtmlCompressor(
            [
                'compressors' => [
                    [
                        'patterns' => [
                            Patterns::MATCH_LD_JSON,
                        ],
                        'compressor' => new MMMJSCompressor(),
                    ],
                    [
                        'patterns' => [
                            Patterns::MATCH_JSCRIPT,
                        ],
                        'compressor' => new JSqueezeCompressor(),
                    ],
                    [
                        'patterns' => [
                            Patterns::MATCH_SCRIPT,
                        ],
                        'compressor' => new ReturnCompressor(),
                    ],
                    [
                        'patterns' => [
                            Patterns::MATCH_STYLE,
                            Patterns::MATCH_STYLE_INLINE,
                        ],
                        'compressor' => new CssMinCompressor(),
                    ],
                ],
            ]
        );
    }

    /**
     * @param  bool                    $externalCompressors When set to false only use pure PHP compressors.
     * @return HtmlCompressorInterface
     */
    public static function constructSmallest(bool $externalCompressors = true): HtmlCompressorInterface
    {
        return new HtmlCompressor(
            [
                'compressors' => [
                    [
                        'patterns' => [
                            Patterns::MATCH_LD_JSON,
                        ],
                        'compressor' => new MMMJSCompressor(),
                    ],
                    [
                        'patterns' => [
                            Patterns::MATCH_JSCRIPT,
                        ],
                        'compressor' => new BestResultCompressor(
                            new MMMJSCompressor(),
                            new JSqueezeCompressor(),
                            new JSMinCompressor(),
                            new JavaScriptPackerCompressor(),
                            new JShrinkCompressor(),
                            $externalCompressors ? new YUIJSCompressor() : new ReturnCompressor(),
                            new ReturnCompressor() // Sometimes no compression can already be the smallest
                        ),
                    ],
                    [
                        'patterns' => [
                            Patterns::MATCH_SCRIPT,
                        ],
                        'compressor' => new ReturnCompressor(),
                    ],
                    [
                        'patterns' => [
                            Patterns::MATCH_STYLE,
                            Patterns::MATCH_STYLE_INLINE,
                        ],
                        'compressor' => new BestResultCompressor(
                            new MMMCSSCompressor(),
                            new CssMinCompressor(),
                            new CssMinifierCompressor(),
                            $externalCompressors ? new YUICSSCompressor() : new ReturnCompressor(),
                            new ReturnCompressor(),
                            ),
                    ],
                ],
            ]
        );
    }
}
