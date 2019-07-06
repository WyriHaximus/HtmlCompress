<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

use WebSharks\CssMinifier\Core;

final class CssMinifierCompressor extends Compressor
{
    protected function execute(string $string): string
    {
        return (string)Core::compress($string);
    }
}
