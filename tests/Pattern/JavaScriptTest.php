<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests\Pattern;

use Prophecy\Prophecy\ObjectProphecy;
use voku\helper\HtmlDomParser;
use voku\helper\SimpleHtmlDomInterface;
use WyriHaximus\Compress\CompressorInterface;
use WyriHaximus\HtmlCompress\Pattern\JavaScript;
use WyriHaximus\TestUtilities\TestCase;

/** @internal */
final class JavaScriptTest extends TestCase
{
    private SimpleHtmlDomInterface $simpleHtmlDom;

    /** @var ObjectProphecy|CompressorInterface */
    private $compressor;

    private JavaScript $javaScript;

    protected function setUp(): void
    {
        parent::setUp();

        $this->simpleHtmlDom = HtmlDomParser::str_get_html('<span>innerHtml</span>')->getElementByTagName('span');

        $this->compressor = $this->prophesize(CompressorInterface::class);

        $this->javaScript = new JavaScript($this->compressor->reveal());
    }

    /**
     * @test
     */
    public function emptyCompressResultIsIgnored(): void
    {
        $this->compressor->compress('innerHtml')->shouldBeCalled()->willReturn('');

        $this->javaScript->compress($this->simpleHtmlDom);

        self::assertSame('innerHtml', $this->simpleHtmlDom->innerhtml);
    }

    /**
     * @test
     */
    public function biggerOutputThenInputCompressResultIsIgnored(): void
    {
        $this->compressor->compress('innerHtml')->shouldBeCalled()->willReturn('aaaaaaaaaaaaaaaaaaaaaaa');

        $this->javaScript->compress($this->simpleHtmlDom);

        self::assertSame('innerHtml', $this->simpleHtmlDom->innerhtml);
    }

    /**
     * @test
     */
    public function sameSizedOutputThenInputCompressResultIsIgnored(): void
    {
        $this->compressor->compress('innerHtml')->shouldBeCalled()->willReturn('htmlInner');

        $this->javaScript->compress($this->simpleHtmlDom);

        self::assertSame('innerHtml', $this->simpleHtmlDom->innerhtml);
    }
}
