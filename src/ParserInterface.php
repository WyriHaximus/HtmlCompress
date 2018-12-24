<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

use WyriHaximus\HtmlCompress\Compressor\CompressorInterface;

interface ParserInterface
{
    public function compress(string $html): string;

    public function tokenize(string $html): array;

    public function getDefaultCompressor(): CompressorInterface;

    public function getCompressors(): array;
}
