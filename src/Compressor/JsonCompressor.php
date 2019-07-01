<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

use t1st3\JSONMin\JSONMin;

final class JsonCompressor extends Compressor
{
    protected function execute(string $string): string
    {
        return JSONMin::minify($string);
    }
}
