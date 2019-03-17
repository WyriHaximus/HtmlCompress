<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests\Compressor;

use ApiClients\Tools\TestUtilities\TestCase;
use WyriHaximus\HtmlCompress\Compressor\CompressorInterface;

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
        $compressor = static::COMPRESSOR;
        $this->compressor = new $compressor();
    }

    protected function tearDown(): void
    {
        $this->compressor = null;
    }

    public function testCompress(): void
    {
        self::assertIsString($this->compressor->compress('foo '));
    }
}
