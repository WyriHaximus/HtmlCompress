<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

use voku\helper\HtmlMin;
use WyriHaximus\HtmlCompress\HtmlMinObserver;
use WyriHaximus\HtmlCompress\Patterns;

final class HtmlCompressor extends Compressor
{
    /** @var HtmlMin */
    private $htmlMin;

    public function __construct(Patterns $patterns)
    {
        $this->htmlMin = new HtmlMin();
        $this->htmlMin->attachObserverToTheDomLoop(new HtmlMinObserver($patterns));
    }

    protected function execute(string $string): string
    {
        return $this->htmlMin->minify($string);
    }
}
