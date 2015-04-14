<?php

/*
 * This file is part of HtmlCompress.
 *
 ** (c) 2014 Cees-Jan Kiewiet
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */
namespace WyriHaximus\HtmlCompress\Tests\Compressor;

/**
 * Class HtmlCompressorTest
 *
 * @package WyriHaximus\HtmlCompress\Tests\Compressor
 */
class HtmlCompressorTest extends \PHPUnit_Framework_TestCase {

    public function setUp() {
        parent::setUp();

        $this->compressor = new \WyriHaximus\HtmlCompress\Compressor\HtmlCompressor();
    }

    public function tearDown() {
        unset($this->compressor);
    }

    public function providerNewLinesTabsReturns() {
        return [
            [
              "<html>\r\t<body>\n\t\t<h1>hoi</h1>\r\n\t</body>\r\n</html>",
              '<html><body><h1>hoi</h1></body></html>',
            ],
            [
              "<html>\r\t<h1>hoi</h1>\r\n\t\r\n</html>",
              '<html><h1>hoi</h1></html>',
            ],
        ];
    }

    /**
     * @dataProvider providerNewLinesTabsReturns
     */
    public function testNewLinesTabsReturns($input, $expected) {
        $actual = $this->compressor->compress($input);
        $this->assertSame($expected, $actual);
    }

    public function providerMultipleSpaces() {
        return [
          [
            '<html>  <body>          <h1>h  oi</h1>                         </body></html>',
            '<html><body><h1>h oi</h1></body></html>',
          ],
          [
            '<html>   </html>',
            '<html></html>',
          ],
        ];
    }

    /**
     * @dataProvider providerMultipleSpaces
     */
    public function testMultipleSpaces($input, $expected) {
        $actual = $this->compressor->compress($input);
        $this->assertSame($expected, $actual);
    }

    public function providerSpaceAfterGt() {
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
     */
    public function testSpaceAfterGt($input, $expected) {
        $actual = $this->compressor->compress($input);
        $this->assertSame($expected, $actual);
    }

    public function providerSpaceBeforeLt() {
        return [
          [
            "<html> <body>   <h1>hoi</h1></body> </html> ",
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
     */
    public function testSpaceBeforeLt($input, $expected) {
        $actual = $this->compressor->compress($input);
        $this->assertSame($expected, $actual);
    }

    public function providerTrim() {
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
     */
    public function testTrim($input, $expected) {
        $actual = $this->compressor->compress($input);
        $this->assertSame($expected, $actual);
    }

}