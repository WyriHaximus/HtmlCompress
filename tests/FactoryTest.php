<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests;

use voku\helper\HtmlMin;
use WyriHaximus\HtmlCompress\Factory;
use WyriHaximus\HtmlCompress\HtmlCompressor;
use WyriHaximus\TestUtilities\TestCase;

use function Safe\file_get_contents as safeFileGetContents;

use const DIRECTORY_SEPARATOR;

/**
 * @internal
 */
final class FactoryTest extends TestCase
{
    public function testConstructFastest(): void
    {
        $compressor = Factory::constructFastest()->withHtmlMin(new HtmlMin());
        self::assertInstanceOf(HtmlCompressor::class, $compressor);

        self::assertSame(
            safeFileGetContents(__DIR__ . DIRECTORY_SEPARATOR . 'Factory' . DIRECTORY_SEPARATOR . 'fastest' . DIRECTORY_SEPARATOR . 'out.html'),
            $compressor->compress(
                safeFileGetContents(__DIR__ . DIRECTORY_SEPARATOR . 'Factory' . DIRECTORY_SEPARATOR . 'fastest' . DIRECTORY_SEPARATOR . 'in.html')
            )
        );
    }

    public function testConstruct(): void
    {
        $compressor = Factory::construct()->withHtmlMin(new HtmlMin());
        self::assertInstanceOf(HtmlCompressor::class, $compressor);

        self::assertSame(
            safeFileGetContents(__DIR__ . DIRECTORY_SEPARATOR . 'Factory' . DIRECTORY_SEPARATOR . 'normal' . DIRECTORY_SEPARATOR . 'out.html'),
            $compressor->compress(
                safeFileGetContents(__DIR__ . DIRECTORY_SEPARATOR . 'Factory' . DIRECTORY_SEPARATOR . 'normal' . DIRECTORY_SEPARATOR . 'in.html')
            )
        );
    }

    public function testConstructSmallest(): void
    {
        $compressor = Factory::constructSmallest()->withHtmlMin(new HtmlMin());
        self::assertInstanceOf(HtmlCompressor::class, $compressor);

        self::assertSame(
            safeFileGetContents(__DIR__ . DIRECTORY_SEPARATOR . 'Factory' . DIRECTORY_SEPARATOR . 'smallest' . DIRECTORY_SEPARATOR . 'out.html'),
            $compressor->compress(
                safeFileGetContents(__DIR__ . DIRECTORY_SEPARATOR . 'Factory' . DIRECTORY_SEPARATOR . 'smallest' . DIRECTORY_SEPARATOR . 'in.html')
            )
        );
    }
}
