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

use JShrink\Minifier;

/**
 * Class JShrinkCompressor
 *
 * @package WyriHaximus\HtmlCompress\Compressor
 */
class JShrinkCompressor extends Compressor
{
    /**
     * {@inheritdoc}
     */
    protected function execute($string)
    {
        try {
            return Minifier::minify($string);
        } catch (\Exception $exception) {
            return $string;
        }
    }
}
