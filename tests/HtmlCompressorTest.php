<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests;

use PHPUnit\Framework\Attributes\Test;
use voku\helper\HtmlMin;
use WyriHaximus\HtmlCompress\Factory;
use WyriHaximus\TestUtilities\TestCase;

final class HtmlCompressorTest extends TestCase
{
    #[Test]
    public function withHtmlMin(): void
    {
        $compressor = Factory::constructFastest();
        $clone      = $compressor->withHtmlMin(new HtmlMin());

        self::assertNotSame($compressor, $clone);
    }
}
