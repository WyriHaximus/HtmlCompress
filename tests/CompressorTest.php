<?php

/*
 * This file is part of HtmlCompress.
 *
 ** (c) 2014 Cees-Jan Kiewiet
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */
namespace WyriHaximus\HtmlCompress\Tests;

use Phake;

/**
 * Class CompressorTest
 *
 * @package WyriHaximus\HtmlCompress\Tests
 */
class CompressorTest extends \PHPUnit_Framework_TestCase {

    public function testCompress() {
        $compressor = Phake::partialMock('\WyriHaximus\HtmlCompress\Compressor\ReturnCompressor');
        Phake::when($compressor)->execute('foo ')->thenReturn('foo');
        $this->assertSame('foo', $compressor->compress('foo '));
    }

    public function testCompressLargerResult() {
        $compressor = Phake::partialMock('\WyriHaximus\HtmlCompress\Compressor\ReturnCompressor');
        Phake::when($compressor)->execute('foo ')->thenReturn(' foo ');
        $this->assertSame('foo ', $compressor->compress('foo '));
    }

}