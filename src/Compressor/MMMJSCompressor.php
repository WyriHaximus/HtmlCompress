<?php declare(strict_types=1);
/*
 * This file is part of HtmlCompress.
 *
 ** (c) 2014 Cees-Jan Kiewiet
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

namespace WyriHaximus\HtmlCompress\Compressor;

use MatthiasMullie\Minify\JS;

/**
 * Class MMMJSCompressor.
 *
 * @package WyriHaximus\HtmlCompress\Compressor
 */
final class MMMJSCompressor extends Compressor
{
    /**
     * {@inheritdoc}
     */
    protected function execute(string $string): string
    {
        $result = (new JS($string))->minify();
        if (is_string($result)) {
            return $result;
        }

        return $string;
    }
}
