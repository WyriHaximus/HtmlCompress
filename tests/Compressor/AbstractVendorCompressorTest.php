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

use PHPUnit\Framework\TestCase;
use WyriHaximus\HtmlCompress\Compressor\CompressorInterface;

abstract class AbstractVendorCompressorTest extends TestCase {

    /**
     * @var CompressorInterface
     */
    protected $compressor;

    /**
     * Compressor class to instantiate $compressor
     */
    const COMPRESSOR = '';

    protected function setUp()
    {
        $compressor = static::COMPRESSOR;
        $this->compressor = new $compressor();
    }

    protected function tearDown()
    {
        $this->compressor = null;
    }

    public function testCompress() {
        $this->assertTrue(is_string($this->compressor->compress('foo ')));
    }
}