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

    public function testPatternProvider() {
        return [
            [
                Patterns::MATCH_PRE,
                '<pre>awkef8227h9r8r23</pre>',
                [
                    '',
                    '',
                ],
                [
                    [
                        '<pre>awkef8227h9r8r23</pre>',
                    ],
                    [
                        '<pre>',
                    ],
                    [
                        'awkef8227h9r8r23',
                    ],
                    [
                        '</pre>',
                    ],
                ],
            ],
            [
                Patterns::MATCH_PRE,
                'o <pre>awkef8227h9r8r23</pre> 0',
                [
                    'o ',
                    ' 0',
                ],
                [
                    [
                        '<pre>awkef8227h9r8r23</pre>',
                    ],
                    [
                        '<pre>',
                    ],
                    [
                        'awkef8227h9r8r23',
                    ],
                    [
                        '</pre>',
                    ],
                ],
            ],
            [
                Patterns::MATCH_PRE,
                'o <pre attribute="bar">awkef8227h9r8r23</pre> 0',
                [
                    'o ',
                    ' 0',
                ],
                [
                    [
                        '<pre attribute="bar">awkef8227h9r8r23</pre>',
                    ],
                    [
                        '<pre attribute="bar">',
                    ],
                    [
                        'awkef8227h9r8r23',
                    ],
                    [
                        '</pre>',
                    ],
                ],
            ],
            [
                Patterns::MATCH_TEXTAREA,
                '<textarea>awkef8227h9r8r23</textarea>',
                [
                    '',
                    '',
                ],
                [
                    [
                        '<textarea>awkef8227h9r8r23</textarea>',
                    ],
                    [
                        '<textarea>',
                    ],
                    [
                        'awkef8227h9r8r23',
                    ],
                    [
                        '</textarea>',
                    ],
                ],
            ],
            [
                Patterns::MATCH_TEXTAREA,
                'o <textarea>awkef8227h9r8r23</textarea> 0',
                [
                    'o ',
                    ' 0',
                ],
                [
                    [
                        '<textarea>awkef8227h9r8r23</textarea>',
                    ],
                    [
                        '<textarea>',
                    ],
                    [
                        'awkef8227h9r8r23',
                    ],
                    [
                        '</textarea>',
                    ],
                ],
            ],
            [
                Patterns::MATCH_TEXTAREA,
                'o <textarea attribute="bar">awkef8227h9r8r23</textarea> 0',
                [
                    'o ',
                    ' 0',
                ],
                [
                    [
                        '<textarea attribute="bar">awkef8227h9r8r23</textarea>',
                    ],
                    [
                        '<textarea attribute="bar">',
                    ],
                    [
                        'awkef8227h9r8r23',
                    ],
                    [
                        '</textarea>',
                    ],
                ],
            ],
            [
                Patterns::MATCH_STYLE,
                '<style>awkef8227h9r8r23</style>',
                [
                    '',
                    '',
                ],
                [
                    [
                        '<style>awkef8227h9r8r23</style>',
                    ],
                    [
                        '<style>',
                    ],
                    [
                        'awkef8227h9r8r23',
                    ],
                    [
                        '</style>',
                    ],
                ],
            ],
            [
                Patterns::MATCH_STYLE,
                'o <style>awkef8227h9r8r23</style> 0',
                [
                    'o ',
                    ' 0',
                ],
                [
                    [
                        '<style>awkef8227h9r8r23</style>',
                    ],
                    [
                        '<style>',
                    ],
                    [
                        'awkef8227h9r8r23',
                    ],
                    [
                        '</style>',
                    ],
                ],
            ],
            [
                Patterns::MATCH_STYLE,
                'o <style attribute="bar">awkef8227h9r8r23</style> 0',
                [
                    'o ',
                    ' 0',
                ],
                [
                    [
                        '<style attribute="bar">awkef8227h9r8r23</style>',
                    ],
                    [
                        '<style attribute="bar">',
                    ],
                    [
                        'awkef8227h9r8r23',
                    ],
                    [
                        '</style>',
                    ],
                ],
            ],
            [
                Patterns::MATCH_JSCRIPT,
                '<script>awkef8227h9r8r23</script>',
                [
                    '',
                    '',
                ],
                [
                    [
                        '<script>awkef8227h9r8r23</script>',
                    ],
                    [
                        '<script>',
                    ],
                    [
                        'awkef8227h9r8r23',
                    ],
                    [
                        '</script>',
                    ],
                ],
            ],
            [
                Patterns::MATCH_JSCRIPT,
                'o <script>awkef8227h9r8r23</script> 0',
                [
                    'o ',
                    ' 0',
                ],
                [
                    [
                        '<script>awkef8227h9r8r23</script>',
                    ],
                    [
                        '<script>',
                    ],
                    [
                        'awkef8227h9r8r23',
                    ],
                    [
                        '</script>',
                    ],
                ],
            ],
            [
                Patterns::MATCH_JSCRIPT,
                'o <script attribute="bar">awkef8227h9r8r23</script> 0',
                [
                    'o <script attribute="bar">awkef8227h9r8r23</script> 0',
                ],
                [
                    [],
                    [],
                    [],
                    [],
                ],
            ],
            [
                Patterns::MATCH_JSCRIPT,
                'o <script type="text/javascript">awkef8227h9r8r23</script> 0',
                [
                    'o ',
                    ' 0',
                ],
                [
                    [
                        '<script type="text/javascript">awkef8227h9r8r23</script>',
                    ],
                    [
                        '<script type="text/javascript">',
                    ],
                    [
                        'awkef8227h9r8r23',
                    ],
                    [
                        '</script>',
                    ],
                ],
            ],
            [
                Patterns::MATCH_JSCRIPT,
                'o <script type="text/JavaScript">awkef8227h9r8r23</script> 0',
                [
                    'o ',
                    ' 0',
                ],
                [
                    [
                        '<script type="text/JavaScript">awkef8227h9r8r23</script>',
                    ],
                    [
                        '<script type="text/JavaScript">',
                    ],
                    [
                        'awkef8227h9r8r23',
                    ],
                    [
                        '</script>',
                    ],
                ],
            ],
            [
                Patterns::MATCH_JSCRIPT,
                'o <script type="text/JavaScript" attribute="bar">awkef8227h9r8r23</script> 0',
                [
                    'o ',
                    ' 0',
                ],
                [
                    [
                        '<script type="text/JavaScript" attribute="bar">awkef8227h9r8r23</script>',
                    ],
                    [
                        '<script type="text/JavaScript" attribute="bar">',
                    ],
                    [
                        'awkef8227h9r8r23',
                    ],
                    [
                        '</script>',
                    ],
                ],
            ],
            [
                Patterns::MATCH_JSCRIPT,
                'o <script attribute="bar" type="text/JavaScript" attribute="bar">awkef8227h9r8r23</script> 0',
                [
                    'o ',
                    ' 0',
                ],
                [
                    [
                        '<script attribute="bar" type="text/JavaScript" attribute="bar">awkef8227h9r8r23</script>',
                    ],
                    [
                        '<script attribute="bar" type="text/JavaScript" attribute="bar">',
                    ],
                    [
                        'awkef8227h9r8r23',
                    ],
                    [
                        '</script>',
                    ],
                ],
            ],
            [
                Patterns::MATCH_JSCRIPT,
                'o <script attribute="bar" type="text/JavaScript">awkef8227h9r8r23</script> 0',
                [
                    'o ',
                    ' 0',
                ],
                [
                    [
                        '<script attribute="bar" type="text/JavaScript">awkef8227h9r8r23</script>',
                    ],
                    [
                        '<script attribute="bar" type="text/JavaScript">',
                    ],
                    [
                        'awkef8227h9r8r23',
                    ],
                    [
                        '</script>',
                    ],
                ],
            ],
            [
                Patterns::MATCH_JSCRIPT,
                'o <script type=\'text/JavaScript\' attribute=\'bar\'>awkef8227h9r8r23</script> 0',
                [
                    'o ',
                    ' 0',
                ],
                [
                    [
                        '<script type=\'text/JavaScript\' attribute=\'bar\'>awkef8227h9r8r23</script>',
                    ],
                    [
                        '<script type=\'text/JavaScript\' attribute=\'bar\'>',
                    ],
                    [
                        'awkef8227h9r8r23',
                    ],
                    [
                        '</script>',
                    ],
                ],
            ],
            [
                Patterns::MATCH_JSCRIPT,
                'o <script attribute=\'bar\' type=\'text/JavaScript\' attribute=\'bar\'>awkef8227h9r8r23</script> 0',
                [
                    'o ',
                    ' 0',
                ],
                [
                    [
                        '<script attribute=\'bar\' type=\'text/JavaScript\' attribute=\'bar\'>awkef8227h9r8r23</script>',
                    ],
                    [
                        '<script attribute=\'bar\' type=\'text/JavaScript\' attribute=\'bar\'>',
                    ],
                    [
                        'awkef8227h9r8r23',
                    ],
                    [
                        '</script>',
                    ],
                ],
            ],
            [
                Patterns::MATCH_JSCRIPT,
                'o <script attribute=\'bar\' type=\'text/JavaScript\'>awkef8227h9r8r23</script> 0',
                [
                    'o ',
                    ' 0',
                ],
                [
                    [
                        '<script attribute=\'bar\' type=\'text/JavaScript\'>awkef8227h9r8r23</script>',
                    ],
                    [
                        '<script attribute=\'bar\' type=\'text/JavaScript\'>',
                    ],
                    [
                        'awkef8227h9r8r23',
                    ],
                    [
                        '</script>',
                    ],
                ],
            ],
        ];
    }

    /**
     * @dataProvider testPatternProvider
     */
    public function testPattern($pattern, $input, $expectedHtml, $expectedBits) {
        $html = preg_split($pattern, $input);
        preg_match_all($pattern, $input, $bits);
        $this->assertSame($expectedHtml, $html);
        $this->assertSame($expectedBits, $bits);
    }

}