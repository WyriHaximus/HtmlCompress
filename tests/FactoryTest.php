<?php

/*
 * This file is part of HtmlCompress.
 *
 ** (c) 2014 Cees-Jan Kiewiet
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */
namespace WyriHaximus\HtmlCompress\Tests;

/**
 * Class FactoryTest
 *
 * @package WyriHaximus\HtmlCompress\Tests
 */
class FactoryTest extends \PHPUnit_Framework_TestCase {

    public function testConstructFastest() {
        $parser = \WyriHaximus\HtmlCompress\Factory::constructFastest();
        $this->assertInstanceOf('WyriHaximus\HtmlCompress\Parser', $parser);
    }

    public function testConstruct() {
        $parser = \WyriHaximus\HtmlCompress\Factory::construct();
        $this->assertInstanceOf('WyriHaximus\HtmlCompress\Parser', $parser);
    }

    public function testConstructSmallestDefault() {
        $parser = \WyriHaximus\HtmlCompress\Factory::constructSmallest();
        $this->assertInstanceOf('WyriHaximus\HtmlCompress\Parser', $parser);
    }

    public function testConstructSmallestNoExternal() {
        $parser = \WyriHaximus\HtmlCompress\Factory::constructSmallest(false);
        $this->assertInstanceOf('WyriHaximus\HtmlCompress\Parser', $parser);
    }

    public function testConstructSmallestExternal() {
        $parser = \WyriHaximus\HtmlCompress\Factory::constructSmallest(true);
        $this->assertInstanceOf('WyriHaximus\HtmlCompress\Parser', $parser);
    }

}