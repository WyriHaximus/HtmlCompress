<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

use JShrink\Minifier;

final class JShrinkCompressor extends Compressor
{
    protected function execute(string $string): string
    {
        try {
            $return = Minifier::minify($string);
            if (\is_string($return)) {
                return $return;
            }

            return $string;
        } catch (\Exception $exception) {
            return $string;
        }
    }
}
