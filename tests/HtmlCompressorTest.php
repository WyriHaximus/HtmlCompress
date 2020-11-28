<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests;

use voku\helper\HtmlMin;
use WyriHaximus\HtmlCompress\Factory;
use WyriHaximus\TestUtilities\TestCase;

/**
 * @internal
 */
final class HtmlCompressorTest extends TestCase
{
    /**
     * @test
     */
    public function withHtmlMin(): void
    {
        $compressor = Factory::constructFastest();
        $clone      = $compressor->withHtmlMin(new HtmlMin());

        self::assertNotSame($compressor, $clone);
    }
}
