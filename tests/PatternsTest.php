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

use WyriHaximus\HtmlCompress\Patterns;

/**
 * Class PatternsTest
 *
 * @package WyriHaximus\HtmlCompress\Tests
 */
class PatternsTest extends \PHPUnit_Framework_TestCase {

    public function testPreProvider() {
        return array(
            array(
                Patterns::MATCH_PRE,
                '<pre>awkef8227h9r8r23</pre>',
                array(
                    '',
                    '',
                ),
                array(
                    array(
                        '<pre>awkef8227h9r8r23</pre>',
                    ),
                    array(
                        '<pre>',
                    ),
                    array(
                        'awkef8227h9r8r23',
                    ),
                    array(
                        '</pre>',
                    ),
                ),
            ),
            array(
                Patterns::MATCH_PRE,
                'o <pre>awkef8227h9r8r23</pre> 0',
                array(
                    'o ',
                    ' 0',
                ),
                array(
                    array(
                        '<pre>awkef8227h9r8r23</pre>',
                    ),
                    array(
                        '<pre>',
                    ),
                    array(
                        'awkef8227h9r8r23',
                    ),
                    array(
                        '</pre>',
                    ),
                ),
            ),
            array(
                Patterns::MATCH_PRE,
                'o <pre attribute="bar">awkef8227h9r8r23</pre> 0',
                array(
                    'o ',
                    ' 0',
                ),
                array(
                    array(
                        '<pre attribute="bar">awkef8227h9r8r23</pre>',
                    ),
                    array(
                        '<pre attribute="bar">',
                    ),
                    array(
                        'awkef8227h9r8r23',
                    ),
                    array(
                        '</pre>',
                    ),
                ),
            ),
        );
    }

    /**
     * @dataProvider testPreProvider
     */
    public function testPattern($pattern, $input, $expectedHtml, $expectedBits) {
        $html = preg_split($pattern, $input);
        preg_match_all($pattern, $input, $bits);
        $this->assertSame($expectedHtml, $html);
        $this->assertSame($expectedBits, $bits);
    }

}