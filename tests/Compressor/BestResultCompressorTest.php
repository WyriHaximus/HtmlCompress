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

use PHPUnit\Framework\TestCase;
use WyriHaximus\HtmlCompress\Compressor\BestResultCompressor;
use WyriHaximus\HtmlCompress\Compressor\CompressorInterface;

/**
 * Class BestResultCompressor.
 *
 * @package WyriHaximus\HtmlCompress\Tests\Compressor
 */
final class BestResultCompressorTest extends TestCase
{
    public function testCompress()
    {
        $input = 'abc';
        $compressorA = new class() implements CompressorInterface {
            public $called = false;

            public function compress(string $string): string
            {
                $this->called = true;

                return 'ab';
            }
        };
        $compressorB = new class() implements CompressorInterface {
            public $called = false;

            public function compress(string $string): string
            {
                $this->called = true;

                return 'abcd';
            }
        };

        $compressor = new BestResultCompressor([
            $compressorA,
            $compressorB,
        ]);
        $actual = $compressor->compress($input);

        self::assertTrue($compressorA->called);
        self::assertTrue($compressorB->called);

        $this->assertSame('ab', $actual);
    }
}
