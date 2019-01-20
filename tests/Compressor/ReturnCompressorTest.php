<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests\Compressor;

use ApiClients\Tools\TestUtilities\TestCase;
use WyriHaximus\HtmlCompress\Compressor\ReturnCompressor;

/**
 * @internal
 */
final class ReturnCompressorTest extends TestCase
{
    /**
     * @var ReturnCompressor
     */
    private $compressor;

    protected function setUp()
    {
        parent::setUp();

        $this->compressor = new ReturnCompressor();
    }

    protected function tearDown()
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
