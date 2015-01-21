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

use WyriHaximus\HtmlCompress\Factory;

/**
 * Class FactoryTest
 *
 * @package WyriHaximus\HtmlCompress\Tests
 */
class EdgeCasesTest extends \PHPUnit_Framework_TestCase
{
    public function providerEdgeCase()
    {
        $baseDir = __DIR__ . DIRECTORY_SEPARATOR . 'EdgeCases' . DIRECTORY_SEPARATOR;
        $dirs = [];

        foreach (glob($baseDir . '*', GLOB_ONLYDIR) as $item) {
            $dirs[] = [$item . DIRECTORY_SEPARATOR];
        }

        return $dirs;
    }

    /**
     * @dataProvider providerEdgeCase
     */
    public function testEdgeCase($dir)
    {
        $this->assertSame(file_get_contents($dir . 'out.html'), Factory::constructSmallest()->compress(file_get_contents($dir . 'in.html')));
    }
}