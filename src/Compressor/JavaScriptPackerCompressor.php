<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

final class JavaScriptPackerCompressor extends Compressor
{
    protected function execute(string $string): string
    {
        return (new \JavaScriptPacker($string))->pack();
    }
}
