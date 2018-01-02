<?php

/*
 * This file is part of HtmlCompress.
 *
 ** (c) 2014 Cees-Jan Kiewiet
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */
namespace WyriHaximus\HtmlCompress\Compressor;

use YUI\Compressor as YUICompressor;

/**
 * Class YUIJSCompressor
 *
 * @package WyriHaximus\HtmlCompress\Compressor
 */
class YUIJSCompressor extends Compressor
{
    /**
     * {@inheritdoc}
     */
    protected function execute($string)
    {
        try {
            $yui = new YUICompressor();
            $yui->setType(YUICompressor::TYPE_JS);
            return $yui->compress($string);
        } catch (\Exception $exception) {
            return $string;
        }
    }
}
