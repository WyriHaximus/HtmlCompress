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
use WyriHaximus\HtmlCompress\Compressor\ReturnCompressor;

/**
 * Class HtmlCompressorTest.
 *
 * @package WyriHaximus\HtmlCompress\Tests\Compressor
 */
final class ReturnCompressorTest extends TestCase
{

    /**
     * @var ReturnCompressor
     */
    private $compressor;

    public function setUp()
    {
        parent::setUp();

        $this->compressor = new ReturnCompressor();
    }

    public function tearDown()
    {
        unset($this->compressor);
    }

    public function providerReturn()
    {
        return [
            [
              " <html>\r\t<body>\n\t\t<h1>hoi</h1>\r\n\t</body>\r\n</html>",
              " <html>\r\t<body>\n\t\t<h1>hoi</h1>\r\n\t</body>\r\n</html>",
            ],
            [
              "<html>\r\t<h1>h            oi</h1>\r\n\t\r\n</html>",
              "<html>\r\t<h1>h            oi</h1>\r\n\t\r\n</html>",
            ],
        ];
    }

    /**
     * @dataProvider providerReturn
     * @param mixed $input
     * @param mixed $expected
     */
    public function testReturn($input, $expected)
    {
        $actual = $this->compressor->compress($input);
        $this->assertSame($expected, $actual);
    }
}
