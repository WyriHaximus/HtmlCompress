<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Tests;

use ApiClients\Tools\TestUtilities\TestCase;
use WyriHaximus\HtmlCompress\Factory;
use WyriHaximus\HtmlCompress\HtmlCompressor;

/**
 * @internal
 */
final class FactoryTest extends TestCase
{
    public function testConstructFastest(): void
    {
        $parser = Factory::constructFastest();
        self::assertInstanceOf(HtmlCompressor::class, $parser);
    }

    public function testConstruct(): void
    {
        $parser = Factory::construct();
        self::assertInstanceOf(HtmlCompressor::class, $parser);
    }

    public function testConstructSmallestDefault(): void
    {
        $parser = Factory::constructSmallest();
        self::assertInstanceOf(HtmlCompressor::class, $parser);
    }

    public function testConstructSmallestNoExternal(): void
    {
        $parser = Factory::constructSmallest(false);
        self::assertInstanceOf(HtmlCompressor::class, $parser);
    }

    public function testConstructSmallestExternal(): void
    {
        $parser = Factory::constructSmallest(true);
        self::assertInstanceOf(HtmlCompressor::class, $parser);
    }
}
