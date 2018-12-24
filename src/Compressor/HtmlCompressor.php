<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

use voku\helper\HtmlMin;

final class HtmlCompressor extends Compressor
{
    protected function execute(string $string): string
    {
        return (new HtmlMin())->minify($string);
    }
}
