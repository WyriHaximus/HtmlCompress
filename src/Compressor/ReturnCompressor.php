<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

final class ReturnCompressor extends Compressor
{
    protected function execute(string $string): string
    {
        return $string;
    }
}
