<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

use YUI\Compressor as YUICompressor;

final class YUICSSCompressor extends Compressor
{
    protected function execute(string $string): string
    {
        try {
            $yui = new YUICompressor();
            $yui->setType(YUICompressor::TYPE_CSS);

            return $yui->compress($string);
        } catch (\Exception $exception) {
            return $string;
        }
    }
}
