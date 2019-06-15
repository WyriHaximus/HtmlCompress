<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests\Compressor;

use WyriHaximus\HtmlCompress\Compressor\CompressorInterface;
use WyriHaximus\TestUtilities\TestCase;

abstract class AbstractVendorCompressorTest extends TestCase
{
    /**
     * Compressor class to instantiate $compressor.
     */
    const COMPRESSOR = '';

    /**
     * @var CompressorInterface
     */
    protected $compressor;

    protected function setUp(): void
    {
        parent::setUp();

        $compressor = static::COMPRESSOR;
        $this->compressor = new $compressor();
    }

    public function testCompress(): void
    {
        self::assertStringContainsString('foo', $this->compressor->compress('foo '));
    }
}
