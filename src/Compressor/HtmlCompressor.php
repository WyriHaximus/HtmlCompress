<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

use voku\helper\HtmlMin;

final class HtmlCompressor extends Compressor
{
    /** @var HtmlMin */
    private $htmlMin;

    public function __construct()
    {
        $this->htmlMin = new HtmlMin();
    }

    protected function execute(string $string): string
    {
        return $this->htmlMin->minify($string);
    }

    public function getHtmlMin(): HtmlMin
    {
        return $this->htmlMin;
    }
}
