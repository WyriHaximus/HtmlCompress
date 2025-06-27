<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests\Pattern;

use Mockery;
use Override;
use PHPUnit\Framework\Attributes\Test;
use voku\helper\HtmlDomParser;
use voku\helper\SimpleHtmlDomInterface;
use WyriHaximus\Compress\CompressorInterface;
use WyriHaximus\HtmlCompress\Pattern\Script;
use WyriHaximus\TestUtilities\TestCase;

final class ScriptTest extends TestCase
{
    private SimpleHtmlDomInterface $simpleHtmlDom;

    private Mockery\MockInterface&CompressorInterface $compressor;

    private Script $script;

    #[Override]
    protected function setUp(): void
    {
        parent::setUp();

        $this->simpleHtmlDom = HtmlDomParser::str_get_html(
            '<script>innerHtml</script>',
        )->getElementByTagName('script');

        $this->compressor = Mockery::mock(CompressorInterface::class);

        $this->script = new Script($this->compressor);
    }

    #[Test]
    public function emptyCompressResultIsIgnored(): void
    {
        $this->compressor->expects('compress')->with('innerHtml')->andReturn('');

        $this->script->compress($this->simpleHtmlDom);

        self::assertSame('innerHtml', $this->simpleHtmlDom->innerhtml);
    }

    #[Test]
    public function biggerOutputThenInputCompressResultIsIgnored(): void
    {
        $this->compressor->expects('compress')->with('innerHtml')->andReturn('aaaaaaaaaaaaaaaaaaaaaaa');

        $this->script->compress($this->simpleHtmlDom);

        self::assertSame('innerHtml', $this->simpleHtmlDom->innerhtml);
    }

    #[Test]
    public function sameSizedOutputThenInputCompressResultIsIgnored(): void
    {
        $this->compressor->expects('compress')->with('innerHtml')->andReturn('htmlInner');

        $this->script->compress($this->simpleHtmlDom);

        self::assertSame('innerHtml', $this->simpleHtmlDom->innerhtml);
    }

    #[Test]
    public function compress(): void
    {
        $this->compressor->expects('compress')->with('innerHtml')->andReturn('bla');

        $this->script->compress($this->simpleHtmlDom);

        self::assertSame('bla', $this->simpleHtmlDom->innerhtml);
        self::assertSame(
            '<script>bla</script>',
            $this->simpleHtmlDom->outerHtml(),
        );
    }
}
