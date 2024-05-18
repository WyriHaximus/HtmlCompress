<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests\Pattern;

use Mockery;
use voku\helper\HtmlDomParser;
use voku\helper\SimpleHtmlDomInterface;
use WyriHaximus\Compress\CompressorInterface;
use WyriHaximus\HtmlCompress\Pattern\Style;
use WyriHaximus\TestUtilities\TestCase;

/** @internal */
final class StyleTest extends TestCase
{
    private SimpleHtmlDomInterface $simpleHtmlDom;

    private Mockery\MockInterface&CompressorInterface $compressor;

    private Style $style;

    protected function setUp(): void
    {
        parent::setUp();

        $this->simpleHtmlDom = HtmlDomParser::str_get_html('<span>innerHtml</span>')->getElementByTagName('span');

        $this->compressor = Mockery::mock(CompressorInterface::class);

        $this->style = new Style($this->compressor);
    }

    /** @test */
    public function emptyCompressResultIsIgnored(): void
    {
        $this->compressor->expects('compress')->with('innerHtml')->andReturn('');

        $this->style->compress($this->simpleHtmlDom);

        self::assertSame('innerHtml', $this->simpleHtmlDom->innerhtml);
    }

    /** @test */
    public function biggerOutputThenInputCompressResultIsIgnored(): void
    {
        $this->compressor->expects('compress')->with('innerHtml')->andReturn('aaaaaaaaaaaaaaaaaaaaaaa');

        $this->style->compress($this->simpleHtmlDom);

        self::assertSame('innerHtml', $this->simpleHtmlDom->innerhtml);
    }

    /** @test */
    public function sameSizedOutputThenInputCompressResultIsIgnored(): void
    {
        $this->compressor->expects('compress')->with('innerHtml')->andReturn('htmlInner');

        $this->style->compress($this->simpleHtmlDom);

        self::assertSame('innerHtml', $this->simpleHtmlDom->innerhtml);
    }
}
