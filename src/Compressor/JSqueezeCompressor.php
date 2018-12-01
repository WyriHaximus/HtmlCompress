<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

final class JSqueezeCompressor extends Compressor
{
    protected function execute(string $string): string
    {
        // rry version 2.0 namespace first
        $class = '\Patchwork\JSqueeze';
        if (!class_exists($class)) {
            // otherwise use 1.0
            $class = '\JSqueeze';
        }
        /** @var \Patchwork\JSqueeze|\JSqueeze $parser */
        $parser = new $class();

        return $parser->squeeze($string);
    }
}
