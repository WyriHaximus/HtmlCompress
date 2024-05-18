<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests\Pattern;

use Mockery;
use voku\helper\HtmlDomParser;
use voku\helper\SimpleHtmlDomInterface;
use WyriHaximus\Compress\CompressorInterface;
use WyriHaximus\HtmlCompress\Pattern\StyleAttribute;
use WyriHaximus\TestUtilities\TestCase;

/** @internal */
final class StyleAttributeTest extends TestCase
{
    private SimpleHtmlDomInterface $simpleHtmlDom;

    private Mockery\MockInterface&CompressorInterface $compressor;

    private StyleAttribute $styleAttribute;

    protected function setUp(): void
    {
        parent::setUp();

        $this->simpleHtmlDom = HtmlDomParser::str_get_html('<span style="innerHtml">blaatg</span>')->getElementByTagName('span');

        $this->compressor = Mockery::mock(CompressorInterface::class);

        $this->styleAttribute = new StyleAttribute($this->compressor);
    }

    /** @test */
    public function emptyCompressResultIsIgnored(): void
    {
        $this->compressor->expects('compress')->with('innerHtml')->andReturn('');

        $this->styleAttribute->compress($this->simpleHtmlDom);

        self::assertSame('innerHtml', $this->simpleHtmlDom->getAttribute('style'));
    }

    /** @test */
    public function biggerOutputThenInputCompressResultIsIgnored(): void
    {
        $this->compressor->expects('compress')->with('innerHtml')->andReturn('aaaaaaaaaaaaaaaaaaaaaaa');

        $this->styleAttribute->compress($this->simpleHtmlDom);

        self::assertSame('innerHtml', $this->simpleHtmlDom->getAttribute('style'));
    }

    /** @test */
    public function sameSizedOutputThenInputCompressResultIsIgnored(): void
    {
        $this->compressor->expects('compress')->with('innerHtml')->andReturn('htmlInner');

        $this->styleAttribute->compress($this->simpleHtmlDom);

        self::assertSame('innerHtml', $this->simpleHtmlDom->getAttribute('style'));
    }
}
