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

use PHPUnit\Framework\TestCase;
use WyriHaximus\HtmlCompress\Patterns;

/**
 * Class PatternsTest
 *
 * @package WyriHaximus\HtmlCompress\Tests
 */
class PatternsTest extends TestCase {

    /**
     * Nasty long method, but this is the best way (I can think of) to do this
     *
     * @return array
     */
    public function patternProvider() {
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
                '<pre>awkef8227h9r8r23</pre><pre>awkef8227q2yegf829f2h9r8r23</pre>',
                [
                    '',
                    '',
                    '',
                ],
                [
                    [
                        '<pre>awkef8227h9r8r23</pre>',
                        '<pre>awkef8227q2yegf829f2h9r8r23</pre>',
                    ],
                    [
                        '<pre>',
                        '<pre>',
                    ],
                    [
                        'awkef8227h9r8r23',
                        'awkef8227q2yegf829f2h9r8r23',
                    ],
                    [
                        '</pre>',
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
                'o <pre>awkef8227h9r8r23</pre> 0o <pre>awkef8227h9r8r23wuiehfoquhe9hf2</pre> 0',
                [
                    'o ',
                    ' 0o ',
                    ' 0',
                ],
                [
                    [
                        '<pre>awkef8227h9r8r23</pre>',
                        '<pre>awkef8227h9r8r23wuiehfoquhe9hf2</pre>',
                    ],
                    [
                        '<pre>',
                        '<pre>',
                    ],
                    [
                        'awkef8227h9r8r23',
                        'awkef8227h9r8r23wuiehfoquhe9hf2',
                    ],
                    [
                        '</pre>',
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
                Patterns::MATCH_PRE,
                'o <pre attribute="bar">awkef8227h9r8r23</pre> 0o <pre attribute="foo">awkef8227h9r8reopiirghuoer23</pre> 0',
                [
                    'o ',
                    ' 0o ',
                    ' 0',
                ],
                [
                    [
                        '<pre attribute="bar">awkef8227h9r8r23</pre>',
                        '<pre attribute="foo">awkef8227h9r8reopiirghuoer23</pre>',
                    ],
                    [
                        '<pre attribute="bar">',
                        '<pre attribute="foo">',
                    ],
                    [
                        'awkef8227h9r8r23',
                        'awkef8227h9r8reopiirghuoer23',
                    ],
                    [
                        '</pre>',
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
                '<textarea>awkef8227h9r8r23</textarea><textarea>esorhtn9437yt9783434jt933hok</textarea>',
                [
                    '',
                    '',
                    '',
                ],
                [
                    [
                        '<textarea>awkef8227h9r8r23</textarea>',
                        '<textarea>esorhtn9437yt9783434jt933hok</textarea>',
                    ],
                    [
                        '<textarea>',
                        '<textarea>',
                    ],
                    [
                        'awkef8227h9r8r23',
                        'esorhtn9437yt9783434jt933hok',
                    ],
                    [
                        '</textarea>',
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
                'o <textarea>awkef8227h9r8r23</textarea> 0o <textarea>esorhtn9437yt9783434jt933hok</textarea> 0',
                [
                    'o ',
                    ' 0o ',
                    ' 0',
                ],
                [
                    [
                        '<textarea>awkef8227h9r8r23</textarea>',
                        '<textarea>esorhtn9437yt9783434jt933hok</textarea>',
                    ],
                    [
                        '<textarea>',
                        '<textarea>',
                    ],
                    [
                        'awkef8227h9r8r23',
                        'esorhtn9437yt9783434jt933hok',
                    ],
                    [
                        '</textarea>',
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
                Patterns::MATCH_TEXTAREA,
                'o <textarea attribute="bar">awkef8227h9r8r23</textarea> 0o <textarea attribute="foo">awkef8227h9r8r23o3tbnt783cm5t834</textarea> 0',
                [
                    'o ',
                    ' 0o ',
                    ' 0',
                ],
                [
                    [
                        '<textarea attribute="bar">awkef8227h9r8r23</textarea>',
                        '<textarea attribute="foo">awkef8227h9r8r23o3tbnt783cm5t834</textarea>',
                    ],
                    [
                        '<textarea attribute="bar">',
                        '<textarea attribute="foo">',
                    ],
                    [
                        'awkef8227h9r8r23',
                        'awkef8227h9r8r23o3tbnt783cm5t834',
                    ],
                    [
                        '</textarea>',
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
                '<style>awkef8227h9r8r23</style><style>awkef8227h9r8rou3ny4v73423</style>',
                [
                    '',
                    '',
                    '',
                ],
                [
                    [
                        '<style>awkef8227h9r8r23</style>',
                        '<style>awkef8227h9r8rou3ny4v73423</style>',
                    ],
                    [
                        '<style>',
                        '<style>',
                    ],
                    [
                        'awkef8227h9r8r23',
                        'awkef8227h9r8rou3ny4v73423',
                    ],
                    [
                        '</style>',
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
                'o <style>awkef8227h9r8r23</style> 0o <style>awkefsiogy8379238227h9r8r23</style> 0',
                [
                    'o ',
                    ' 0o ',
                    ' 0',
                ],
                [
                    [
                        '<style>awkef8227h9r8r23</style>',
                        '<style>awkefsiogy8379238227h9r8r23</style>',
                    ],
                    [
                        '<style>',
                        '<style>',
                    ],
                    [
                        'awkef8227h9r8r23',
                        'awkefsiogy8379238227h9r8r23',
                    ],
                    [
                        '</style>',
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
                Patterns::MATCH_STYLE,
                'o <style attribute="bar">awkef8227h9r8r23</style> 0o <style attribute="bar">awkef8227h9r8r2KH$^I%3</style> 0',
                [
                    'o ',
                    ' 0o ',
                    ' 0',
                ],
                [
                    [
                        '<style attribute="bar">awkef8227h9r8r23</style>',
                        '<style attribute="bar">awkef8227h9r8r2KH$^I%3</style>',
                    ],
                    [
                        '<style attribute="bar">',
                        '<style attribute="bar">',
                    ],
                    [
                        'awkef8227h9r8r23',
                        'awkef8227h9r8r2KH$^I%3',
                    ],
                    [
                        '</style>',
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
                '<script>awkef8227h9r8r23</script><script>awsepirg poeurkef8227h9r8r23</script>',
                [
                    '',
                    '',
                    '',
                ],
                [
                    [
                        '<script>awkef8227h9r8r23</script>',
                        '<script>awsepirg poeurkef8227h9r8r23</script>',
                    ],
                    [
                        '<script>',
                        '<script>',
                    ],
                    [
                        'awkef8227h9r8r23',
                        'awsepirg poeurkef8227h9r8r23',
                    ],
                    [
                        '</script>',
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
                'o <script>awkef8227h9r8r23</script> 0o <script>awkef8227h9r8p9e8ynv09wv35r23</script> 0',
                [
                    'o ',
                    ' 0o ',
                    ' 0',
                ],
                [
                    [
                        '<script>awkef8227h9r8r23</script>',
                        '<script>awkef8227h9r8p9e8ynv09wv35r23</script>',
                    ],
                    [
                        '<script>',
                        '<script>',
                    ],
                    [
                        'awkef8227h9r8r23',
                        'awkef8227h9r8p9e8ynv09wv35r23',
                    ],
                    [
                        '</script>',
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
                'o <script type="text/javascript">awkef8227h9r8r23</script> 0o <script type="text/javascript">awksoeuirtnv7w3ef8227h9r8r23</script> 0',
                [
                    'o ',
                    ' 0o ',
                    ' 0',
                ],
                [
                    [
                        '<script type="text/javascript">awkef8227h9r8r23</script>',
                        '<script type="text/javascript">awksoeuirtnv7w3ef8227h9r8r23</script>',
                    ],
                    [
                        '<script type="text/javascript">',
                        '<script type="text/javascript">',
                    ],
                    [
                        'awkef8227h9r8r23',
                        'awksoeuirtnv7w3ef8227h9r8r23',
                    ],
                    [
                        '</script>',
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
                'o <script type="text/JavaScript">awkef8227h9r8r23</script> 0o <script type="text/JavaScript">awkowiuynt09349ef8227h9r8r23</script> 0',
                [
                    'o ',
                    ' 0o ',
                    ' 0',
                ],
                [
                    [
                        '<script type="text/JavaScript">awkef8227h9r8r23</script>',
                        '<script type="text/JavaScript">awkowiuynt09349ef8227h9r8r23</script>',
                    ],
                    [
                        '<script type="text/JavaScript">',
                        '<script type="text/JavaScript">',
                    ],
                    [
                        'awkef8227h9r8r23',
                        'awkowiuynt09349ef8227h9r8r23',
                    ],
                    [
                        '</script>',
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
                'o <script type="text/JavaScript" attribute="bar">awkef8227h9r8r23</script> 0o <script type="text/JavaScript" attribute="foo">awkef8227h9r8rew980rytv09m38423</script> 0',
                [
                    'o ',
                    ' 0o ',
                    ' 0',
                ],
                [
                    [
                        '<script type="text/JavaScript" attribute="bar">awkef8227h9r8r23</script>',
                        '<script type="text/JavaScript" attribute="foo">awkef8227h9r8rew980rytv09m38423</script>',
                    ],
                    [
                        '<script type="text/JavaScript" attribute="bar">',
                        '<script type="text/JavaScript" attribute="foo">',
                    ],
                    [
                        'awkef8227h9r8r23',
                        'awkef8227h9r8rew980rytv09m38423',
                    ],
                    [
                        '</script>',
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
                'o <script attribute="bar" type="text/JavaScript" attribute="bar">awkef8227h9r8r23</script> 0o <script attribute="foo" type="text/JavaScript" attribute="foo">awkef8227h9r8oserynt0w7yn0t59r23</script> 0',
                [
                    'o ',
                    ' 0o ',
                    ' 0',
                ],
                [
                    [
                        '<script attribute="bar" type="text/JavaScript" attribute="bar">awkef8227h9r8r23</script>',
                        '<script attribute="foo" type="text/JavaScript" attribute="foo">awkef8227h9r8oserynt0w7yn0t59r23</script>',
                    ],
                    [
                        '<script attribute="bar" type="text/JavaScript" attribute="bar">',
                        '<script attribute="foo" type="text/JavaScript" attribute="foo">',
                    ],
                    [
                        'awkef8227h9r8r23',
                        'awkef8227h9r8oserynt0w7yn0t59r23',
                    ],
                    [
                        '</script>',
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
                'o <script attribute="bar" type="text/JavaScript">awkef8227h9r8r23</script> 0o <script attribute="foo" type="text/JavaScript">awpoeumyt0v494kef8227h9r8r23</script> 0',
                [
                    'o ',
                    ' 0o ',
                    ' 0',
                ],
                [
                    [
                        '<script attribute="bar" type="text/JavaScript">awkef8227h9r8r23</script>',
                        '<script attribute="foo" type="text/JavaScript">awpoeumyt0v494kef8227h9r8r23</script>',
                    ],
                    [
                        '<script attribute="bar" type="text/JavaScript">',
                        '<script attribute="foo" type="text/JavaScript">',
                    ],
                    [
                        'awkef8227h9r8r23',
                        'awpoeumyt0v494kef8227h9r8r23',
                    ],
                    [
                        '</script>',
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
                'o <script type=\'text/JavaScript\' attribute=\'bar\'>awkef8227h9r8r23</script> 0o <script type=\'text/JavaScript\' attribute=\'foo\'>awkef8227poutb9968t709mh9r8r23</script> 0',
                [
                    'o ',
                    ' 0o ',
                    ' 0',
                ],
                [
                    [
                        '<script type=\'text/JavaScript\' attribute=\'bar\'>awkef8227h9r8r23</script>',
                        '<script type=\'text/JavaScript\' attribute=\'foo\'>awkef8227poutb9968t709mh9r8r23</script>',
                    ],
                    [
                        '<script type=\'text/JavaScript\' attribute=\'bar\'>',
                        '<script type=\'text/JavaScript\' attribute=\'foo\'>',
                    ],
                    [
                        'awkef8227h9r8r23',
                        'awkef8227poutb9968t709mh9r8r23',
                    ],
                    [
                        '</script>',
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
                'o <script attribute=\'bar\' type=\'text/JavaScript\' attribute=\'bar\'>awkef8227h9r8r23</script> 0o <script attribute=\'foo\' type=\'text/JavaScript\' attribute=\'foo\'>awkef82ee7v89tn987t87rvb727h9r8r23</script> 0',
                [
                    'o ',
                    ' 0o ',
                    ' 0',
                ],
                [
                    [
                        '<script attribute=\'bar\' type=\'text/JavaScript\' attribute=\'bar\'>awkef8227h9r8r23</script>',
                        '<script attribute=\'foo\' type=\'text/JavaScript\' attribute=\'foo\'>awkef82ee7v89tn987t87rvb727h9r8r23</script>',
                    ],
                    [
                        '<script attribute=\'bar\' type=\'text/JavaScript\' attribute=\'bar\'>',
                        '<script attribute=\'foo\' type=\'text/JavaScript\' attribute=\'foo\'>',
                    ],
                    [
                        'awkef8227h9r8r23',
                        'awkef82ee7v89tn987t87rvb727h9r8r23',
                    ],
                    [
                        '</script>',
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
            [
                Patterns::MATCH_JSCRIPT,
                'o <script attribute=\'bar\' type=\'text/JavaScript\'>awkef8227h9r8r23</script> 0o <script attribute=\'foo\' type=\'text/JavaScript\'>uytrvb8ytnmuawkef8227h9r8r23</script> 0',
                [
                    'o ',
                    ' 0o ',
                    ' 0',
                ],
                [
                    [
                        '<script attribute=\'bar\' type=\'text/JavaScript\'>awkef8227h9r8r23</script>',
                        '<script attribute=\'foo\' type=\'text/JavaScript\'>uytrvb8ytnmuawkef8227h9r8r23</script>',
                    ],
                    [
                        '<script attribute=\'bar\' type=\'text/JavaScript\'>',
                        '<script attribute=\'foo\' type=\'text/JavaScript\'>',
                    ],
                    [
                        'awkef8227h9r8r23',
                        'uytrvb8ytnmuawkef8227h9r8r23',
                    ],
                    [
                        '</script>',
                        '</script>',
                    ],
                ],
            ],
            [
                Patterns::MATCH_SCRIPT,
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
                Patterns::MATCH_SCRIPT,
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
                Patterns::MATCH_SCRIPT,
                'o <script>awkef8227h9r8r23</script> 0o <script>awkef8227h9reo475yt9734yc0c97yn9ct73y9t7b3&%*%(&8r23</script> 0',
                [
                    'o ',
                    ' 0o ',
                    ' 0',
                ],
                [
                    [
                        '<script>awkef8227h9r8r23</script>',
                        '<script>awkef8227h9reo475yt9734yc0c97yn9ct73y9t7b3&%*%(&8r23</script>',
                    ],
                    [
                        '<script>',
                        '<script>',
                    ],
                    [
                        'awkef8227h9r8r23',
                        'awkef8227h9reo475yt9734yc0c97yn9ct73y9t7b3&%*%(&8r23',
                    ],
                    [
                        '</script>',
                        '</script>',
                    ],
                ],
            ],
            [
                Patterns::MATCH_SCRIPT,
                'o <script attribute="bar">awkef8227h9r8r23</script> 0',
                [
                    'o ',
                    ' 0',
                ],
                [
                    [
                        '<script attribute="bar">awkef8227h9r8r23</script>',
                    ],
                    [
                        '<script attribute="bar">',
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
                Patterns::MATCH_SCRIPT,
                'o <script attribute="bar">awkef8227h9r8r23</script> 0o <script attribute="foo">ouerycntyw45u094y5awkef8227h9r8r23</script> 0',
                [
                    'o ',
                    ' 0o ',
                    ' 0',
                ],
                [
                    [
                        '<script attribute="bar">awkef8227h9r8r23</script>',
                        '<script attribute="foo">ouerycntyw45u094y5awkef8227h9r8r23</script>',
                    ],
                    [
                        '<script attribute="bar">',
                        '<script attribute="foo">',
                    ],
                    [
                        'awkef8227h9r8r23',
                        'ouerycntyw45u094y5awkef8227h9r8r23',
                    ],
                    [
                        '</script>',
                        '</script>',
                    ],
                ],
            ],
            [
                Patterns::MATCH_SCRIPT,
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
                Patterns::MATCH_SCRIPT,
                'o <script type="text/javascript">awkef8227h9r8r23</script> 0o <script type="text/javascript">awkef8227h9r8a,sdfkjahjfwer23</script> 0',
                [
                    'o ',
                    ' 0o ',
                    ' 0',
                ],
                [
                    [
                        '<script type="text/javascript">awkef8227h9r8r23</script>',
                        '<script type="text/javascript">awkef8227h9r8a,sdfkjahjfwer23</script>',
                    ],
                    [
                        '<script type="text/javascript">',
                        '<script type="text/javascript">',
                    ],
                    [
                        'awkef8227h9r8r23',
                        'awkef8227h9r8a,sdfkjahjfwer23',
                    ],
                    [
                        '</script>',
                        '</script>',
                    ],
                ],
            ],
            [
                Patterns::MATCH_NOCOMPRESS,
                '<nocompress>awkef8227h9r8r23</nocompress>',
                [
                    '',
                    '',
                ],
                [
                    [
                        '<nocompress>awkef8227h9r8r23</nocompress>',
                    ],
                    [
                        '<nocompress>',
                    ],
                    [
                        'awkef8227h9r8r23',
                    ],
                    [
                        '</nocompress>',
                    ],
                ],
            ],
            [
                Patterns::MATCH_STYLE,
                '<style>awkef8227h9r8r23</style><script>alert(\'bla\');</script>',
                [
                    '',
                    '<script>alert(\'bla\');</script>',
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
                Patterns::MATCH_SCRIPT,
                '<style>awkef8227h9r8r23</style><script>alert(\'bla\');</script>',
                [
                    '<style>awkef8227h9r8r23</style>',
                    '',
                ],
                [
                    [
                        '<script>alert(\'bla\');</script>',
                    ],
                    [
                        '<script>',
                    ],
                    [
                        'alert(\'bla\');',
                    ],
                    [
                        '</script>',
                    ],
                ],
            ],
            [
                Patterns::MATCH_JSCRIPT,
                '<pre>b;aejdhjd d2</pre><script type="text/javascript" src="https://asciinema.org/a/18487.js" id="asciicast-18487" async></script><pre>wohef oqh2uhif2q</pre>',
                [
                    '<pre>b;aejdhjd d2</pre>',
                    '<pre>wohef oqh2uhif2q</pre>',
                ],
                [
                    [
                        '<script type="text/javascript" src="https://asciinema.org/a/18487.js" id="asciicast-18487" async></script>',
                    ],
                    [
                        '<script type="text/javascript" src="https://asciinema.org/a/18487.js" id="asciicast-18487" async>',
                    ],
                    [
                        '',
                    ],
                    [
                        '</script>',
                    ],
                ],
            ],
            [
                Patterns::MATCH_SCRIPT,
                '<pre>b;aejdhjd d2</pre><script type="text/javascript" src="https://asciinema.org/a/18487.js" id="asciicast-18487" async></script><pre>wohef oqh2uhif2q</pre>',
                [
                    '<pre>b;aejdhjd d2</pre>',
                    '<pre>wohef oqh2uhif2q</pre>',
                ],
                [
                    [
                        '<script type="text/javascript" src="https://asciinema.org/a/18487.js" id="asciicast-18487" async></script>',
                    ],
                    [
                        '<script type="text/javascript" src="https://asciinema.org/a/18487.js" id="asciicast-18487" async>',
                    ],
                    [
                        '',
                    ],
                    [
                        '</script>',
                    ],
                ],
            ],
        ];
    }

    /**
     * @dataProvider patternProvider
     */
    public function testPattern($pattern, $input, $expectedHtml, $expectedBits) {
        $html = preg_split($pattern, $input);
        preg_match_all($pattern, $input, $bits);
        $this->assertSame($expectedHtml, $html);
        $this->assertSame($expectedBits, $bits);
    }

}