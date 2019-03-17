<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests\Compressor;

use ApiClients\Tools\TestUtilities\TestCase;
use WyriHaximus\HtmlCompress\Compressor\JavaScriptPackerCompressor;
use WyriHaximus\HtmlCompress\Factory;

/**
 * @internal
 */
final class CompressorSmallestTest extends TestCase
{
    /**
     * @var JavaScriptPackerCompressor
     */
    protected $compressor;

    protected function setUp(): void
    {
        parent::setUp();

        $this->compressor = Factory::constructSmallest();
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
                '<html><script>;var i,x=0,y=i+x;console.log(y)</script>',
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
