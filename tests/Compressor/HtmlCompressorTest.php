<?php declare(strict_types=1);
/*
 * This file is part of HtmlCompress.
 *
 ** (c) 2014 Cees-Jan Kiewiet
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

namespace WyriHaximus\HtmlCompress\Tests\Compressor;

use PHPUnit\Framework\TestCase;
use WyriHaximus\HtmlCompress\Compressor\HtmlCompressor;

/**
 * Class HtmlCompressorTest.
 *
 * @package WyriHaximus\HtmlCompress\Tests\Compressor
 */
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
              '<html><body><h1>hoi</h1></body></html>',
            ],
            [
              "<html>\r\t<h1>hoi</h1>\r\n\t\r\n</html>",
              '<html><h1>hoi</h1></html>',
            ],
            [
              "<html><p>abc\r\ndef</p></html>",
              '<html><p>abc def</p></html>',
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
            '<html><body><h1>h oi</h1></body></html>',
          ],
          [
            '<html>   </html>',
            '<html></html>',
          ],
          [
            "<html><body>  pre \r\n  suf\r\n  </body>",
            '<html><body> pre suf </body>',
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
            '<html><body><h1>hoi</h1></body></html>',
          ],
          [
            '<html>  a',
            '<html> a',
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
            '<html><body><h1>hoi</h1></body></html>',
          ],
          [
            'a     <html>',
            'a <html>',
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
                '<html><body>à</body></html>',
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
                "<html><body><!-- HTML comment --></body></html>",
                '<html><body></body></html>',
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
