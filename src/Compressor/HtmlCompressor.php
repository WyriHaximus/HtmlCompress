<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

use voku\helper\HtmlMin;
use WyriHaximus\HtmlCompress\HtmlMinObserver;

final class HtmlCompressor extends Compressor
{
    /** @var HtmlMin */
    private $htmlMin;

    public function __construct(array $options)
    {
        $this->htmlMin = new HtmlMin();
        $this->htmlMin->attachObserverToTheDomLoop(new HtmlMinObserver($options));
    }

    public function getHtmlMin(): HtmlMin
    {
        return $this->htmlMin;
    }

    protected function execute(string $string): string
    {
        return $this->htmlMin->minify($string);
    }
}
