<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests\Pattern;

use Prophecy\Prophecy\ObjectProphecy;
use voku\helper\HtmlDomParser;
use voku\helper\SimpleHtmlDomInterface;
use WyriHaximus\Compress\CompressorInterface;
use WyriHaximus\HtmlCompress\Pattern\StyleAttribute;
use WyriHaximus\TestUtilities\TestCase;

/** @internal */
final class StyleAttributeTest extends TestCase
{
    private SimpleHtmlDomInterface $simpleHtmlDom;

    /** @var ObjectProphecy|CompressorInterface */
    private $compressor;

    private StyleAttribute $styleAttribute;

    protected function setUp(): void
    {
        parent::setUp();

        $this->simpleHtmlDom = HtmlDomParser::str_get_html('<span style="innerHtml">blaatg</span>')->getElementByTagName('span');

        $this->compressor = $this->prophesize(CompressorInterface::class);

        $this->styleAttribute = new StyleAttribute($this->compressor->reveal());
    }

    /**
     * @test
     */
    public function emptyCompressResultIsIgnored(): void
    {
        $this->compressor->compress('innerHtml')->shouldBeCalled()->willReturn('');

        $this->styleAttribute->compress($this->simpleHtmlDom);

        self::assertSame('innerHtml', $this->simpleHtmlDom->getAttribute('style'));
    }

    /**
     * @test
     */
    public function biggerOutputThenInputCompressResultIsIgnored(): void
    {
        $this->compressor->compress('innerHtml')->shouldBeCalled()->willReturn('aaaaaaaaaaaaaaaaaaaaaaa');

        $this->styleAttribute->compress($this->simpleHtmlDom);

        self::assertSame('innerHtml', $this->simpleHtmlDom->getAttribute('style'));
    }

    /**
     * @test
     */
    public function sameSizedOutputThenInputCompressResultIsIgnored(): void
    {
        $this->compressor->compress('innerHtml')->shouldBeCalled()->willReturn('htmlInner');

        $this->styleAttribute->compress($this->simpleHtmlDom);

        self::assertSame('innerHtml', $this->simpleHtmlDom->getAttribute('style'));
    }
}
