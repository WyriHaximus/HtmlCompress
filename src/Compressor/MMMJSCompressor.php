<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

use MatthiasMullie\Minify\JS;

final class MMMJSCompressor extends Compressor
{
    protected function execute(string $string): string
    {
        $result = (new JS())->add($string)->minify();
        if (\is_string($result)) {
            return $result;
        }

        return $string;
    }
}
