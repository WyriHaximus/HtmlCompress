<?php

namespace WyriHaximus\HtmlCompress\Compressor;

/**
 * CssMinCompressor
 *
 * @author Marcel Voigt <mv@noch.so>
 */
class CssMinCompressor extends Compressor
{
    private $cssMin;

    public function __construct()
    {
        $this->cssMin = new \CssMin();
    }

    protected function execute($string)
    {
        return $this->cssMin->minify($string);
    }
}
