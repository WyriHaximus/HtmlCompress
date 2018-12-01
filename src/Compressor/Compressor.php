<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

abstract class Compressor implements CompressorInterface
{
    public function compress(string $source): string
    {
        $result = $this->execute($source);

        if (\strlen($source) >= \strlen($result)) {
            return $result;
        }

        return $source;
    }

    abstract protected function execute(string $string): string;
}
