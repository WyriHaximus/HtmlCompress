<?php declare(strict_types=1);
/*
 * This file is part of HtmlCompress.
 *
 ** (c) 2014 Cees-Jan Kiewiet
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

namespace WyriHaximus\HtmlCompress\Tests;

use PHPUnit\Framework\TestCase;
use WyriHaximus\HtmlCompress\Parser;

/**
 * Class FactoryTest.
 *
 * @package WyriHaximus\HtmlCompress\Tests
 */
final class FactoryTest extends TestCase
{
    public function testConstructFastest()
    {
        $parser = \WyriHaximus\HtmlCompress\Factory::constructFastest();
        $this->assertInstanceOf(Parser::class, $parser);
    }

    public function testConstruct()
    {
        $parser = \WyriHaximus\HtmlCompress\Factory::construct();
        $this->assertInstanceOf(Parser::class, $parser);
    }

    public function testConstructSmallestDefault()
    {
        $parser = \WyriHaximus\HtmlCompress\Factory::constructSmallest();
        $this->assertInstanceOf(Parser::class, $parser);
    }

    public function testConstructSmallestNoExternal()
    {
        $parser = \WyriHaximus\HtmlCompress\Factory::constructSmallest(false);
        $this->assertInstanceOf(Parser::class, $parser);
    }

    public function testConstructSmallestExternal()
    {
        $parser = \WyriHaximus\HtmlCompress\Factory::constructSmallest(true);
        $this->assertInstanceOf(Parser::class, $parser);
    }
}
