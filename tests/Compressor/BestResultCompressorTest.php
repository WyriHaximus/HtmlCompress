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

use Phake;

/**
 * Class BestResultCompressor
 *
 * @package WyriHaximus\HtmlCompress\Tests\Compressor
 */
class BestResultCompressor extends \PHPUnit_Framework_TestCase {

    public function testCompress() {
        $input = 'abc';
        $compressorA = Phake::partialMock('\WyriHaximus\HtmlCompress\Compressor\ReturnCompressor');
        Phake::when($compressorA)->compress($input)->thenReturn('ab');
        $compressorB = Phake::partialMock('\WyriHaximus\HtmlCompress\Compressor\ReturnCompressor');
        Phake::when($compressorB)->compress($input)->thenReturn('abcd');

        $compressor = new \WyriHaximus\HtmlCompress\Compressor\BestResultCompressor([
            $compressorA,
            $compressorB,
        ]);
        $actual = $compressor->compress($input);

        Phake::verify($compressorA)->compress('abc');
        Phake::verify($compressorB)->compress('abc');

        $this->assertSame('ab', $actual);
    }

}