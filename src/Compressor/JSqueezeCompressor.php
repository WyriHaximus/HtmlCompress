<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

use Patchwork\JSqueeze;

final class JSqueezeCompressor extends Compressor
{
    protected function execute(string $string): string
    {
        return (new JSqueeze())->squeeze($string);
    }
}
