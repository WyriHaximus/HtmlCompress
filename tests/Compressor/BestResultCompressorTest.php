<?php declare(strict_types=1);
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
use PHPUnit\Framework\TestCase;
use WyriHaximus\HtmlCompress\Compressor\BestResultCompressor;
use WyriHaximus\HtmlCompress\Compressor\ReturnCompressor;

/**
 * Class BestResultCompressor.
 *
 * @package WyriHaximus\HtmlCompress\Tests\Compressor
 */
class BestResultCompressorTest extends TestCase
{
    public function testCompress()
    {
        $input = 'abc';
        $compressorA = Phake::partialMock(ReturnCompressor::class);
        Phake::when($compressorA)->compress($input)->thenReturn('ab');
        $compressorB = Phake::partialMock(ReturnCompressor::class);
        Phake::when($compressorB)->compress($input)->thenReturn('abcd');

        $compressor = new BestResultCompressor([
            $compressorA,
            $compressorB,
        ]);
        $actual = $compressor->compress($input);

        Phake::verify($compressorA)->compress('abc');
        Phake::verify($compressorB)->compress('abc');

        $this->assertSame('ab', $actual);
    }
}
