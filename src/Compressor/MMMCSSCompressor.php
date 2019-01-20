<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

use MatthiasMullie\Minify\CSS;

final class MMMCSSCompressor extends Compressor
{
    /**
     * {@inheritdoc}
     */
    protected function execute(string $string): string
    {
        $result = (new CSS($string))->minify();
        if (\is_string($result)) {
            return $result;
        }

        return $string;
    }
}
