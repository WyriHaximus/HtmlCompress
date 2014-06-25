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

abstract class AbstractVendorCompressorTest extends \PHPUnit_Framework_TestCase {

    public function testCompress() {
        $compressor = static::COMPRESSOR;
        $this->assertTrue(is_string((new $compressor)->compress('foo ')));
    }
}