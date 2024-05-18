<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests\Compressor;

use voku\helper\HtmlMin;
use WyriHaximus\HtmlCompress\HtmlCompressor;
use WyriHaximus\HtmlCompress\Patterns;
use WyriHaximus\TestUtilities\TestCase;

/** @internal */
final class HtmlCompressorTest extends TestCase
{
    /** @return iterable<array<string>> */
    public static function providerNewLinesTabsReturns(): iterable
    {
        yield [
            "<html>\r\t<body>\n\t\t<h1>hoi</h1>\r\n\t</body>\r\n</html>",
            '<html><body><h1>hoi</h1>',
        ];

        yield [
            "<html>\r\t<h1>hoi</h1>\r\n\t\r\n</html>",
            '<html><h1>hoi</h1>',
        ];

        yield [
            "<html><p>abc\r\ndef</p></html>",
            '<html><p>abc def',
        ];
    }

    /** @dataProvider providerNewLinesTabsReturns */
    public function testNewLinesTabsReturns(string $input, string $expected): void
    {
        $actual = (new HtmlCompressor(new HtmlMin(), new Patterns()))->compress($input);
        self::assertSame($expected, $actual);
    }

    /** @return iterable<array<string>> */
    public static function providerMultipleSpaces(): iterable
    {
        yield [
            '<html>  <body>          <h1>h  oi</h1>                         </body></html>',
            '<html><body><h1>h oi</h1>',
        ];

        yield [
            '<html>   </html>',
            '<html>',
        ];

        yield [
            "<html><body>  pre \r\n  suf\r\n  </body>",
            '<html><body> pre suf',
        ];

        yield [
            '<span class="foo"><span title="bar"></span><span title="baz"></span><span title="bat"></span></span>',
            '<span class=foo><span title=bar></span><span title=baz></span><span title=bat></span></span>',
        ];

        yield [
            "<html>\n    <head>     </head>\n    <body>\n      <p id=\"text\" class=\"foo\">\n        foo\n      </p>  <br />  <ul > <li> <p class=\"foo\">lall</p> </li></ul>\n    </body>\n    </html>",
            '<html><head> <body><p class=foo id=text> foo </p> <br> <ul><li><p class=foo>lall </ul>',
        ];
    }

    /** @dataProvider providerMultipleSpaces */
    public function testMultipleSpaces(string $input, string $expected): void
    {
        $actual = (new HtmlCompressor(new HtmlMin(), new Patterns()))->compress($input);
        self::assertSame($expected, $actual);
    }

    /** @return iterable<array<string>> */
    public static function providerSpaceAfterGt(): iterable
    {
        yield [
            '<html> <body> <h1>hoi</h1>   </body> </html>',
            '<html><body><h1>hoi</h1>',
        ];

        yield [
            '<html>  a',
            '<html> a',
        ];
    }

    /** @dataProvider providerSpaceAfterGt */
    public function testSpaceAfterGt(string $input, string $expected): void
    {
        $actual = (new HtmlCompressor(new HtmlMin(), new Patterns()))->compress($input);
        self::assertSame($expected, $actual);
    }

    /** @return iterable<array<string>> */
    public static function providerSpaceBeforeLt(): iterable
    {
        yield [
            '<html> <body>   <h1>hoi</h1></body> </html> ',
            '<html><body><h1>hoi</h1>',
        ];

        yield [
            '<html>  a',
            '<html> a',
        ];
    }

    /** @dataProvider providerSpaceBeforeLt */
    public function testSpaceBeforeLt(string $input, string $expected): void
    {
        $actual = (new HtmlCompressor(new HtmlMin(), new Patterns()))->compress($input);
        self::assertSame($expected, $actual);
    }

    /** @return iterable<array<string>> */
    public static function providerTrim(): iterable
    {
        yield [
            '              ',
            '',
        ];

        yield [
            ' ',
            '',
        ];
    }

    /** @dataProvider providerTrim */
    public function testTrim(string $input, string $expected): void
    {
        $actual = (new HtmlCompressor(new HtmlMin(), new Patterns()))->compress($input);
        self::assertSame($expected, $actual);
    }

    /** @return iterable<array<string>> */
    public static function providerSpecialCharacterEncoding(): iterable
    {
        yield [
            "<html>\r\n\t<body>\xc3\xa0</body>\r\n\t</html>",
            '<html><body>à',
        ];
    }

    /** @dataProvider providerSpecialCharacterEncoding */
    public function testSpecialCharacterEncoding(string $input, string $expected): void
    {
        $actual = (new HtmlCompressor(new HtmlMin(), new Patterns()))->compress($input);
        self::assertSame($expected, $actual);
    }

    /** @return iterable<array<string>> */
    public static function providerComments(): iterable
    {
        yield [
            '<html><body><!-- HTML comment --></body></html>',
            '<html><body>',
        ];
    }

    /** @dataProvider providerComments */
    public function testComments(string $input, string $expected): void
    {
        $actual = (new HtmlCompressor(new HtmlMin(), new Patterns()))->compress($input);
        self::assertSame($expected, $actual);
    }
}
