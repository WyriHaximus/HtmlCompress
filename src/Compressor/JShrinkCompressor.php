<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

use JShrink\Minifier;

final class JShrinkCompressor extends Compressor
{
    protected function execute(string $string): string
    {
        try {
            /** @var string $string */
            $string = Minifier::minify($string);

            return $string;
        } catch (\Exception $exception) {
            return $string;
        }
    }
}
