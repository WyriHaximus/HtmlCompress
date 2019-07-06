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
        /** @psalm-suppress TooManyArguments */
        return (new CSS($string))->minify();
    }
}
