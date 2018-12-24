<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

final class JSMinCompressor extends Compressor
{
    protected function execute(string $string): string
    {
        try {
            return \JSMin::minify($string);
        } catch (\JSMinException $exception) {
            return $string;
        }
    }
}
