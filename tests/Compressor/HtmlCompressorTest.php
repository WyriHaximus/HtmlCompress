<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests\Compressor;

use PHPUnit\Framework\TestCase;
use WyriHaximus\HtmlCompress\Compressor\HtmlCompressor;

final class HtmlCompressorTest extends TestCase
{
    /**
     * @var HtmlCompressor
     */
    private $compressor;

    public function setUp()
    {
        parent::setUp();

        $this->compressor = new HtmlCompressor();
    }

    public function tearDown()
    {
        unset($this->compressor);
    }

    public function providerNewLinesTabsReturns()
    {
        return [
            [
              "<html>\r\t<body>\n\t\t<h1>hoi</h1>\r\n\t</body>\r\n</html>",
              '<html><body><h1>hoi</h1>',
            ],
            [
              "<html>\r\t<h1>hoi</h1>\r\n\t\r\n</html>",
              '<html><h1>hoi</h1>',
            ],
            [
              "<html><p>abc\r\ndef</p></html>",
              '<html><p>abc def',
            ],
        ];
    }

    /**
     * @dataProvider providerNewLinesTabsReturns
     * @param mixed $input
     * @param mixed $expected
     */
    public function testNewLinesTabsReturns($input, $expected)
    {
        $actual = $this->compressor->compress($input);
        $this->assertSame($expected, $actual);
    }

    public function providerMultipleSpaces()
    {
        return [
          [
            '<html>  <body>          <h1>h  oi</h1>                         </body></html>',
            '<html><body><h1>h oi</h1>',
          ],
          [
            '<html>   </html>',
            '<html>',
          ],
          [
            "<html><body>  pre \r\n  suf\r\n  </body>",
            '<html><body> pre suf',
          ],
          [
              '<span class="foo"><span title="bar"></span><span title="baz"></span><span title="bat"></span></span>',
              '<span class=foo><span title=bar></span><span title=baz></span><span title=bat></span></span>',
          ],
          [
              "<html>\n    <head>     </head>\n    <body>\n      <p id=\"text\" class=\"foo\">\n        foo\n      </p>  <br />  <ul > <li> <p class=\"foo\">lall</p> </li></ul>\n    </body>\n    </html>",
              '<html><head> <body><p class=foo id=text> foo </p> <br><ul><li><p class=foo>lall </ul>',
          ],
        ];
    }

    /**
     * @dataProvider providerMultipleSpaces
     * @param mixed $input
     * @param mixed $expected
     */
    public function testMultipleSpaces($input, $expected)
    {
        $actual = $this->compressor->compress($input);
        $this->assertSame($expected, $actual);
    }

    public function providerSpaceAfterGt()
    {
        return [
          [
            '<html> <body> <h1>hoi</h1>   </body> </html>',
            '<html><body><h1>hoi</h1>',
          ],
          [
            '<html>  a',
            '<html>  a',
          ],
        ];
    }

    /**
     * @dataProvider providerSpaceAfterGt
     * @param mixed $input
     * @param mixed $expected
     */
    public function testSpaceAfterGt($input, $expected)
    {
        $actual = $this->compressor->compress($input);
        $this->assertSame($expected, $actual);
    }

    public function providerSpaceBeforeLt()
    {
        return [
          [
            '<html> <body>   <h1>hoi</h1></body> </html> ',
            '<html><body><h1>hoi</h1>',
          ],
          [
            'a     <html>',
            'a     <html>',
          ],
        ];
    }

    /**
     * @dataProvider providerSpaceBeforeLt
     * @param mixed $input
     * @param mixed $expected
     */
    public function testSpaceBeforeLt($input, $expected)
    {
        $actual = $this->compressor->compress($input);
        $this->assertSame($expected, $actual);
    }

    public function providerTrim()
    {
        return [
          [
            '              ',
            '',
          ],
          [
            ' ',
            '',
          ],
        ];
    }

    /**
     * @dataProvider providerTrim
     * @param mixed $input
     * @param mixed $expected
     */
    public function testTrim($input, $expected)
    {
        $actual = $this->compressor->compress($input);
        $this->assertSame($expected, $actual);
    }

    public function providerSpecialCharacterEncoding()
    {
        return [
            [
                "<html>\r\n\t<body>\xc3\xa0</body>\r\n\t</html>",
                '<html><body>à',
            ],
        ];
    }

    /**
     * @dataProvider providerSpecialCharacterEncoding
     * @param mixed $input
     * @param mixed $expected
     */
    public function testSpecialCharacterEncoding($input, $expected)
    {
        $actual = $this->compressor->compress($input);
        $this->assertSame($expected, $actual);
    }

    public function providerComments()
    {
        return [
            [
                '<html><body><!-- HTML comment --></body></html>',
                '<html><body>',
            ],
        ];
    }

    /**
     * @dataProvider providerComments
     * @param mixed $input
     * @param mixed $expected
     */
    public function testComments($input, $expected)
    {
        $actual = $this->compressor->compress($input);
        $this->assertSame($expected, $actual);
    }
}
