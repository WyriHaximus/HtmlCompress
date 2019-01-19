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

    protected function setUp()
    {
        $compressor = static::COMPRESSOR;
        $this->compressor = new $compressor();
    }

    protected function tearDown()
    {
        $this->compressor = null;
    }

    public function testCompress()
    {
        $this->assertTrue(\is_string($this->compressor->compress('foo ')));
    }
}
