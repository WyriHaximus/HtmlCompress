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
 * Class ParserTest
 *
 * @package WyriHaximus\HtmlCompress\Tests
 */
class ParserTest extends \PHPUnit_Framework_TestCase {

    public function testConstruct() {
        $parser = new \WyriHaximus\HtmlCompress\Parser('<html><p> <span>foo bar</span> </p></html>html>');
        $this->assertSame('<html><p><span>foo bar</span></p></html>html>', $parser->compress());
    }

}