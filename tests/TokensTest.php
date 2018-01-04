<?php

namespace WyriHaximus\HtmlCompress\Tests;

use PHPUnit\Framework\TestCase;
use WyriHaximus\HtmlCompress\Compressor\ReturnCompressor;
use WyriHaximus\HtmlCompress\Token;
use WyriHaximus\HtmlCompress\Tokens;

class TokensTest extends TestCase
{
    public function testReplace()
    {
        $tokens = new Tokens([
            new Token('a', 'b', 'c', new ReturnCompressor()),
            new Token('d', 'e', 'f', new ReturnCompressor()),
            new Token('g', 'h', 'i', new ReturnCompressor()),
        ]);

        $tokens->replace(1, new Tokens([
            new Token('j', 'k', 'l', new ReturnCompressor()),
            new Token('m', 'n', 'o', new ReturnCompressor()),
            new Token('p', 'q', 'r', new ReturnCompressor()),
        ]));

        $this->assertSame('abcjklmnopqrghi', $tokens->getHtml());
    }
}
