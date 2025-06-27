<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests;

use PHPUnit\Framework\Attributes\Test;
use RuntimeException;
use voku\helper\HtmlMin;
use WyriHaximus\HtmlCompress\Factory;
use WyriHaximus\HtmlCompress\HtmlCompressor;
use WyriHaximus\TestUtilities\TestCase;

use function file_get_contents;
use function is_string;

use const DIRECTORY_SEPARATOR;

final class FactoryTest extends TestCase
{
    #[Test]
    public function constructFastest(): void
    {
        $compressor = Factory::constructFastest()->withHtmlMin(new HtmlMin());
        self::assertInstanceOf(HtmlCompressor::class, $compressor);

        $in = file_get_contents(__DIR__ . DIRECTORY_SEPARATOR . 'Factory' . DIRECTORY_SEPARATOR . 'fastest' . DIRECTORY_SEPARATOR . 'in.html');
        if (! is_string($in)) {
            throw new RuntimeException('Could not read compress test input');
        }

        $out = file_get_contents(__DIR__ . DIRECTORY_SEPARATOR . 'Factory' . DIRECTORY_SEPARATOR . 'fastest' . DIRECTORY_SEPARATOR . 'out.html');
        if (! is_string($out)) {
            throw new RuntimeException('Could not read compress expected test output');
        }

        self::assertSame($out, $compressor->compress($in));
    }

    #[Test]
    public function construct(): void
    {
        $compressor = Factory::construct()->withHtmlMin(new HtmlMin());
        self::assertInstanceOf(HtmlCompressor::class, $compressor);

        $in = file_get_contents(__DIR__ . DIRECTORY_SEPARATOR . 'Factory' . DIRECTORY_SEPARATOR . 'normal' . DIRECTORY_SEPARATOR . 'in.html');
        if (! is_string($in)) {
            throw new RuntimeException('Could not read compress test input');
        }

        $out = file_get_contents(__DIR__ . DIRECTORY_SEPARATOR . 'Factory' . DIRECTORY_SEPARATOR . 'normal' . DIRECTORY_SEPARATOR . 'out.html');
        if (! is_string($out)) {
            throw new RuntimeException('Could not read compress expected test output');
        }

        self::assertSame($out, $compressor->compress($in));
    }

    #[Test]
    public function constructSmallest(): void
    {
        $compressor = Factory::constructSmallest()->withHtmlMin(new HtmlMin());
        self::assertInstanceOf(HtmlCompressor::class, $compressor);

        $in = file_get_contents(__DIR__ . DIRECTORY_SEPARATOR . 'Factory' . DIRECTORY_SEPARATOR . 'smallest' . DIRECTORY_SEPARATOR . 'in.html');
        if (! is_string($in)) {
            throw new RuntimeException('Could not read compress test input');
        }

        $out = file_get_contents(__DIR__ . DIRECTORY_SEPARATOR . 'Factory' . DIRECTORY_SEPARATOR . 'smallest' . DIRECTORY_SEPARATOR . 'out.html');
        if (! is_string($out)) {
            throw new RuntimeException('Could not read compress expected test output');
        }

        self::assertSame($out, $compressor->compress($in));
    }
}
