<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests\Compressor;

use WyriHaximus\HtmlCompress\Compressor\JavaScriptPackerCompressor;
use WyriHaximus\HtmlCompress\Factory;
use WyriHaximus\TestUtilities\TestCase;

/**
 * @internal
 */
final class CompressorFastesTest extends TestCase
{
    /**
     * @var JavaScriptPackerCompressor
     */
    protected $compressor;

    protected function setUp(): void
    {
        parent::setUp();

        $this->compressor = Factory::constructFastest();
    }

    protected function tearDown(): void
    {
        unset($this->compressor);
    }

    public function providerJavaScript()
    {
        return [
            [
                '<html><script>
                    var i;
                    var x = 0;
                    
                    var y = i + x;
                    console.log(y);
                </script></html>',
                '<html><script>var i;
                    var x = 0;
                    
                    var y = i + x;
                    console.log(y);</script>',
            ],
        ];
    }

    /**
     * @dataProvider providerJavaScript
     * @param mixed $input
     * @param mixed $expected
     */
    public function testJavaScript($input, $expected): void
    {
        $actual = $this->compressor->compress($input);
        self::assertSame($expected, $actual);
    }
}
