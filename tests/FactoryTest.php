<?php

namespace WyriHaximus\HtmlCompress\Tests;

class FactoryTest extends \PHPUnit_Framework_TestCase {

    public function testConstruct() {
        $parser = \WyriHaximus\HtmlCompress\Factory::construct('<html><p> <span>foo bar</span> </p></html>html>');
        $this->assertInstanceOf('WyriHaximus\HtmlCompress\Parser', $parser);
        $this->assertSame('<html><p><span>foo bar</span></p></html>html>', $parser->compress());
    }

}