<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

use voku\helper\HtmlMin;
use WyriHaximus\Compress\CompressorInterface;
use WyriHaximus\HtmlCompress\HtmlMinObserver;
use WyriHaximus\HtmlCompress\Patterns;

final class HtmlCompressor implements CompressorInterface
{
    /** @var Patterns */
    private $patterns;

    /** @var HtmlMin */
    private $htmlMin;

    public function __construct(Patterns $patterns)
    {
        $this->patterns = $patterns;
        $this->htmlMin = new HtmlMin();
        $this->htmlMin->attachObserverToTheDomLoop(new HtmlMinObserver($patterns));
    }

    public function compress(string $string): string
    {
        return $this->htmlMin->minify($string);
    }

    public function withHtmlMin(HtmlMin $htmlMin): HtmlCompressor
    {
        $clone          = clone $this;
        $clone->htmlMin = $htmlMin;
        $clone->htmlMin->attachObserverToTheDomLoop(new HtmlMinObserver($clone->patterns));

        return $clone;
    }
}
