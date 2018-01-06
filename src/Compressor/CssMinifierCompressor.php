<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

use WebSharks\CssMinifier\Core;

/**
 * CssMinifierCompressor.
 *
 * @author Marcel Voigt <mv@noch.so>
 */
final class CssMinifierCompressor extends Compressor
{
    protected function execute(string $string): string
    {
        return Core::compress($string);
    }
}
