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
    public function testConstructFastest()
    {
        $parser = Factory::constructFastest();
        self::assertInstanceOf(HtmlCompressor::class, $parser);
    }

    public function testConstruct()
    {
        $parser = Factory::construct();
        self::assertInstanceOf(HtmlCompressor::class, $parser);
    }

    public function testConstructSmallestDefault()
    {
        $parser = Factory::constructSmallest();
        self::assertInstanceOf(HtmlCompressor::class, $parser);
    }

    public function testConstructSmallestNoExternal()
    {
        $parser = Factory::constructSmallest(false);
        self::assertInstanceOf(HtmlCompressor::class, $parser);
    }

    public function testConstructSmallestExternal()
    {
        $parser = Factory::constructSmallest(true);
        self::assertInstanceOf(HtmlCompressor::class, $parser);
    }
}
