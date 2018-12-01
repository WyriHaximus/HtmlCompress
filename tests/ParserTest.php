<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests;

use PHPUnit\Framework\TestCase;
use WyriHaximus\HtmlCompress\Compressor\CompressorInterface;
use WyriHaximus\HtmlCompress\Compressor\HtmlCompressor;
use WyriHaximus\HtmlCompress\Compressor\JSqueezeCompressor;
use WyriHaximus\HtmlCompress\Compressor\ReturnCompressor;
use WyriHaximus\HtmlCompress\Parser;
use WyriHaximus\HtmlCompress\Patterns;

final class ParserTest extends TestCase
{
    public function testConstruct()
    {
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

    public function testConstructNonDefaultDefaultCompressor()
    {
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

    public function testCompress()
    {
        $html = 'foo';
        $compressedHtml = 'bar';
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
        $parser = new Parser($options, new class($compressedHtml) implements CompressorInterface {
            private $compressedHtml;

            public function __construct($compressedHtml)
            {
                $this->compressedHtml = $compressedHtml;
            }

            public function compress(string $string): string
            {
                return $this->compressedHtml;
            }
        });
        $this->assertSame($compressedHtml, $parser->compress($html));
    }
}
