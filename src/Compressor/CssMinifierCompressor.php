<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

use WebSharks\CssMinifier\Core;

/**
 * CssMinifierCompressor.
 *
 * @author Marcel Voigt <mv@noch.so>
 */
class CssMinifierCompressor extends Compressor
{
    protected function execute($string)
    {
        return Core::compress($string);
    }
}
