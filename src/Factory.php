<?php

/*
 * This file is part of HtmlCompress.
 *
 ** (c) 2014 Cees-Jan Kiewiet
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */
namespace WyriHaximus\HtmlCompress;

use WyriHaximus\HtmlCompress\Compressor\BestResultCompressor;
use WyriHaximus\HtmlCompress\Compressor\CssMinCompressor;
use WyriHaximus\HtmlCompress\Compressor\CssMinifierCompressor;
use WyriHaximus\HtmlCompress\Compressor\JShrinkCompressor;
use WyriHaximus\HtmlCompress\Compressor\JSqueezeCompressor;
use WyriHaximus\HtmlCompress\Compressor\JSMinCompressor;
use WyriHaximus\HtmlCompress\Compressor\JavaScriptPackerCompressor;
use WyriHaximus\HtmlCompress\Compressor\MMMCSSCompressor;
use WyriHaximus\HtmlCompress\Compressor\MMMJSCompressor;
use WyriHaximus\HtmlCompress\Compressor\ReturnCompressor;
use WyriHaximus\HtmlCompress\Compressor\YUICSSCompressor;
use WyriHaximus\HtmlCompress\Compressor\YUIJSCompressor;

/**
 * Class Factory
 *
 * @package WyriHaximus\HtmlCompress
 */
class Factory
{
    /**
     * @return Parser
     */
    public static function constructFastest()
    {
        return new Parser(
            [
                'compressors' => [
                    [
                        'patterns' => [
                            Patterns::MATCH_NOCOMPRESS,
                            Patterns::MATCH_STYLE,
                            Patterns::MATCH_LD_JSON,
                            Patterns::MATCH_JSCRIPT,
                            Patterns::MATCH_SCRIPT,
                            Patterns::MATCH_PRE,
                            Patterns::MATCH_TEXTAREA,
                        ],
                        'compressor' => new ReturnCompressor(),
                    ],
                ],
            ]
        );
    }

    /**
     * @return Parser
     */
    public static function construct()
    {
        return new Parser(
            [
                'compressors' => [
                    [
                        'patterns' => [
                            Patterns::MATCH_NOCOMPRESS,
                        ],
                        'compressor' => new ReturnCompressor(),
                    ],
                    [
                        'patterns' => [
                            Patterns::MATCH_LD_JSON,
                        ],
                        'compressor' => new JSMinCompressor(),
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
                            Patterns::MATCH_PRE,
                            Patterns::MATCH_TEXTAREA,
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
     * @param bool $externalCompressors When set to false only use pure PHP compressors.
     * @return Parser
     */
    public static function constructSmallest($externalCompressors = true)
    {
        return new Parser(
            [
                'compressors' => [
                    [
                        'patterns' => [
                            Patterns::MATCH_NOCOMPRESS,
                        ],
                        'compressor' => new ReturnCompressor(),
                    ],
                    [
                        'patterns' => [
                            Patterns::MATCH_LD_JSON,
                        ],
                        'compressor' => new BestResultCompressor(
                            [
                                new MMMJSCompressor(),
                                new JSMinCompressor(),
                                new JavaScriptPackerCompressor(),
                                new JShrinkCompressor(),
                                new YUIJSCompressor(),
                                new ReturnCompressor(), // Sometimes no compression can already be the smallest
                            ]
                        ),
                    ],
                    [
                        'patterns' => [
                            Patterns::MATCH_JSCRIPT,
                        ],
                        'compressor' => new BestResultCompressor(
                            [
                                new MMMJSCompressor(),
                                new JSqueezeCompressor(),
                                new JSMinCompressor(),
                                new JavaScriptPackerCompressor(),
                                new JShrinkCompressor(),
                                $externalCompressors ? new YUICSSCompressor() : new ReturnCompressor(),
                                new ReturnCompressor(), // Sometimes no compression can already be the smallest
                            ]
                        ),
                    ],
                    [
                        'patterns' => [
                            Patterns::MATCH_SCRIPT,
                            Patterns::MATCH_PRE,
                            Patterns::MATCH_TEXTAREA,
                        ],
                        'compressor' => new ReturnCompressor(),
                    ],
                    [
                        'patterns' => [
                            Patterns::MATCH_STYLE,
                            Patterns::MATCH_STYLE_INLINE,
                        ],
                        'compressor' => new BestResultCompressor(
                            [
                                new MMMCSSCompressor(),
                                new CssMinCompressor(),
                                new CssMinifierCompressor(),
                                $externalCompressors ? new YUICSSCompressor() : new ReturnCompressor(),
                                new ReturnCompressor(),
                            ]
                        ),
                    ],
                ],
            ]
        );
    }
}
