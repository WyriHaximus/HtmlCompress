<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

interface CompressorInterface
{
    public function compress(string $string): string;
}
