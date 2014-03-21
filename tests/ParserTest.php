<?php

namespace WyriHaximus\HtmlCompress\Tests;

class ParserTest extends \PHPUnit_Framework_TestCase {

    public function testConstruct() {
        $parser = new \WyriHaximus\HtmlCompress\Parser('<html><p> <span>foo bar</span> </p></html>html>');
        $this->assertSame('<html><p><span>foo bar</span></p></html>html>', $parser->compress());
    }

}