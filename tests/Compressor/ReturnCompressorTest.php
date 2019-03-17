<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests\Compressor;

use WyriHaximus\HtmlCompress\Compressor\ReturnCompressor;
use WyriHaximus\TestUtilities\TestCase;

/**
 * @internal
 */
final class ReturnCompressorTest extends TestCase
{
    /**
     * @var ReturnCompressor
     */
    private $compressor;

    protected function setUp(): void
    {
        parent::setUp();

        $this->compressor = new ReturnCompressor();
    }

    protected function tearDown(): void
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
    public function testReturn($input, $expected): void
    {
        $actual = $this->compressor->compress($input);
        self::assertSame($expected, $actual);
    }
}
