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

/**
 * Class ParserTest
 *
 * @package WyriHaximus\HtmlCompress\Tests
 */
class ParserTest extends \PHPUnit_Framework_TestCase {

    public function testConstruct() {
        $options = [
            'compressors' => [
                [
                    'patterns' => [
                        \WyriHaximus\HtmlCompress\Patterns::MATCH_JSCRIPT,
                    ],
                    'compressor' => new \WyriHaximus\HtmlCompress\Compressor\JSqueezeCompressor(),
                ],
            ],
        ];
        $parser = new \WyriHaximus\HtmlCompress\Parser($options);

        $this->assertSame($options['compressors'], $parser->getCompressors());
        $this->assertInstanceOf('\WyriHaximus\HtmlCompress\Compressor\HtmlCompressor', $parser->getDefaultCompressor());
    }
    public function testConstructNonDefaultDefaultCompressor() {
        $defaultCompressor = new \WyriHaximus\HtmlCompress\Compressor\ReturnCompressor();
        $options = [
            'compressors' => [
                [
                    'patterns' => [
                        \WyriHaximus\HtmlCompress\Patterns::MATCH_JSCRIPT,
                    ],
                    'compressor' => new \WyriHaximus\HtmlCompress\Compressor\JSqueezeCompressor(),
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
        $compressor = Phake::partialMock('\WyriHaximus\HtmlCompress\Compressor\ReturnCompressor');
        Phake::when($compressor)->compress($html)->thenReturn($compressedHtml);

        $parser = Phake::partialMock('\WyriHaximus\HtmlCompress\Parser', [
            'compressors' => [
                [
                    'patterns' => [
                        \WyriHaximus\HtmlCompress\Patterns::MATCH_JSCRIPT,
                    ],
                    'compressor' => new \WyriHaximus\HtmlCompress\Compressor\JSqueezeCompressor(),
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