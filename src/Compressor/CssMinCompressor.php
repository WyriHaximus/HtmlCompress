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
        // If there's no selector, this must be an inline CSS attribute
        if (strlen($string) > 0 && strpos($string, '{') === false) {
            return $this->minifyInline($string);
        }

        return $this->cssMin->minify($string);
    }

    /**
     * Minifies inline CSS attributes.
     *
     * @param string $string
     *
     * @return string
     */
    private function minifyInline($string)
    {
        // Get CssMin to compress inline CSS by adding and stripping a selector
        $mock = 'body{' . $string . '}';
        $minified = $this->execute($mock);

        return substr($minified, 5, -1);
    }
}
