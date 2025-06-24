<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests\Pattern;

use Mockery;
use Override;
use PHPUnit\Framework\Attributes\Test;
use voku\helper\HtmlDomParser;
use voku\helper\SimpleHtmlDomInterface;
use WyriHaximus\Compress\CompressorInterface;
use WyriHaximus\HtmlCompress\Pattern\LdJson;
use WyriHaximus\TestUtilities\TestCase;

final class LdJsonTest extends TestCase
{
    private SimpleHtmlDomInterface $simpleHtmlDom;

    private Mockery\MockInterface&CompressorInterface $compressor;

    private LdJson $ldJson;

    #[Override]
    protected function setUp(): void
    {
        parent::setUp();

        $this->simpleHtmlDom = HtmlDomParser::str_get_html('<span>innerHtml</span>')->getElementByTagName('span');

        $this->compressor = Mockery::mock(CompressorInterface::class);

        $this->ldJson = new LdJson($this->compressor);
    }

    #[Test]
    public function emptyCompressResultIsIgnored(): void
    {
        $this->compressor->expects('compress')->with('innerHtml')->andReturn('');

        $this->ldJson->compress($this->simpleHtmlDom);

        self::assertSame('innerHtml', $this->simpleHtmlDom->innerhtml);
    }

    #[Test]
    public function biggerOutputThenInputCompressResultIsIgnored(): void
    {
        $this->compressor->expects('compress')->with('innerHtml')->andReturn('aaaaaaaaaaaaaaaaaaaaaaa');

        $this->ldJson->compress($this->simpleHtmlDom);

        self::assertSame('innerHtml', $this->simpleHtmlDom->innerhtml);
    }

    #[Test]
    public function sameSizedOutputThenInputCompressResultIsIgnored(): void
    {
        $this->compressor->expects('compress')->with('innerHtml')->andReturn('htmlInner');

        $this->ldJson->compress($this->simpleHtmlDom);

        self::assertSame('innerHtml', $this->simpleHtmlDom->innerhtml);
    }
}
