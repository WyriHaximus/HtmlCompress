<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests\Pattern;

use Prophecy\Prophecy\ObjectProphecy;
use voku\helper\HtmlDomParser;
use voku\helper\SimpleHtmlDomInterface;
use WyriHaximus\Compress\CompressorInterface;
use WyriHaximus\HtmlCompress\Pattern\Style;
use WyriHaximus\TestUtilities\TestCase;

/** @internal */
final class StyleTest extends TestCase
{
    private SimpleHtmlDomInterface $simpleHtmlDom;

    /** @var ObjectProphecy|CompressorInterface */
    private $compressor;

    private Style $style;

    protected function setUp(): void
    {
        parent::setUp();

        $this->simpleHtmlDom = HtmlDomParser::str_get_html('<span>innerHtml</span>')->getElementByTagName('span');

        $this->compressor = $this->prophesize(CompressorInterface::class);

        $this->style = new Style($this->compressor->reveal());
    }

    /**
     * @test
     */
    public function emptyCompressResultIsIgnored(): void
    {
        $this->compressor->compress('innerHtml')->shouldBeCalled()->willReturn('');

        $this->style->compress($this->simpleHtmlDom);

        self::assertSame('innerHtml', $this->simpleHtmlDom->innerhtml);
    }

    /**
     * @test
     */
    public function biggerOutputThenInputCompressResultIsIgnored(): void
    {
        $this->compressor->compress('innerHtml')->shouldBeCalled()->willReturn('aaaaaaaaaaaaaaaaaaaaaaa');

        $this->style->compress($this->simpleHtmlDom);

        self::assertSame('innerHtml', $this->simpleHtmlDom->innerhtml);
    }

    /**
     * @test
     */
    public function sameSizedOutputThenInputCompressResultIsIgnored(): void
    {
        $this->compressor->compress('innerHtml')->shouldBeCalled()->willReturn('htmlInner');

        $this->style->compress($this->simpleHtmlDom);

        self::assertSame('innerHtml', $this->simpleHtmlDom->innerhtml);
    }
}
