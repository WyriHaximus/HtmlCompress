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
 * Class HtmlCompressor
 *
 * @package WyriHaximus\HtmlCompress\Compressor
 */
class HtmlCompressor extends Compressor
{
    /**
     * {@inheritdoc}
     */
    protected function execute($string)
    {
        // Replace newlines, returns and tabs with spaces
        $string = str_replace(["\r", "\n", "\t"], ' ', $string);
        // Replace multiple spaces with a single space
        $string = preg_replace('/(\s+)/mu', ' ', $string);

        // Remove spaces that are followed by either > or <
        $string = preg_replace('/ (>)/', '$1', $string);
        // Remove spaces that are preceded by either > or <
        $string = preg_replace('/(<) /', '$1', $string);
        // Remove spaces that are between > and <
        $string = preg_replace('/(>) (<)/', '>$2', $string);

        return trim($string);
    }
}
