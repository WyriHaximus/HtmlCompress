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

/**
 * Class JSMinCompressor
 *
 * @package WyriHaximus\HtmlCompress\Compressor
 */
class JSMinCompressor extends Compressor
{
    /**
     * {@inheritdoc}
     */
    protected function execute($string)
    {
        try {
            return \JSMin::minify($string);
        } catch (\JSMinException $exception) {
            return $string;
        }
    }
}
