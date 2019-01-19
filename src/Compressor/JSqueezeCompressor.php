<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

final class JSqueezeCompressor extends Compressor
{
    protected function execute(string $string): string
    {
        // Try version 2.0 namespace first
        $class = '\Patchwork\JSqueeze';
        if (!class_exists($class)) {
            // otherwise use 1.0
            $class = '\JSqueeze';
        }
        /** @var \JSqueeze|\Patchwork\JSqueeze $parser */
        /** @psalm-suppress UndefinedClass */
        $parser = new $class();

        return $parser->squeeze($string);
    }
}
