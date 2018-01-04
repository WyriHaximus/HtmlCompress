<?php

/*
 * This file is part of HtmlCompress.
 *
 ** (c) 2014 Cees-Jan Kiewiet
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */
namespace WyriHaximus\HtmlCompress\Tests;

use Phake;
use PHPUnit\Framework\TestCase;
use WyriHaximus\HtmlCompress\Compressor\HtmlCompressor;
use WyriHaximus\HtmlCompress\Compressor\JSqueezeCompressor;
use WyriHaximus\HtmlCompress\Compressor\ReturnCompressor;
use WyriHaximus\HtmlCompress\Parser;
use WyriHaximus\HtmlCompress\Patterns;

/**
 * Class ParserTest
 *
 * @package WyriHaximus\HtmlCompress\Tests
 */
class ParserTest extends TestCase {

    public function testConstruct() {
        $options = [
            'compressors' => [
                [
                    'patterns' => [
                        Patterns::MATCH_JSCRIPT,
                    ],
                    'compressor' => new JSqueezeCompressor(),
                ],
            ],
        ];
        $parser = new \WyriHaximus\HtmlCompress\Parser($options);

        $this->assertSame($options['compressors'], $parser->getCompressors());
        $this->assertInstanceOf(HtmlCompressor::class, $parser->getDefaultCompressor());
    }
    public function testConstructNonDefaultDefaultCompressor() {
        $defaultCompressor = new ReturnCompressor();
        $options = [
            'compressors' => [
                [
                    'patterns' => [
                        Patterns::MATCH_JSCRIPT,
                    ],
                    'compressor' => new JSqueezeCompressor(),
                ],
            ],
        ];
        $parser = new \WyriHaximus\HtmlCompress\Parser($options, $defaultCompressor);

        $this->assertSame($options['compressors'], $parser->getCompressors());
        $this->assertSame($defaultCompressor, $parser->getDefaultCompressor());
    }

    public function testCompress() {
        $html = 'foo';
        $compressedHtml = 'bar';
        $compressor = Phake::partialMock(ReturnCompressor::class);
        Phake::when($compressor)->compress($html)->thenReturn($compressedHtml);

        $parser = Phake::partialMock(Parser::class, [
            'compressors' => [
                [
                    'patterns' => [
                        Patterns::MATCH_JSCRIPT,
                    ],
                    'compressor' => new JSqueezeCompressor(),
                ],
            ],
        ]);
        Phake::when($parser)->tokenize($html)->thenReturn([
            [
                'compressor' => $compressor,
                'html' => $html,
            ],
        ]);
        $this->assertSame($compressedHtml, $parser->compress($compressedHtml));
    }
}
