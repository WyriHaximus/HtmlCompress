<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

use voku\helper\HtmlMin;
use WyriHaximus\Compress\CompressorInterface;
use WyriHaximus\HtmlCompress\HtmlMinObserver;
use WyriHaximus\HtmlCompress\Patterns;

final class HtmlCompressor implements CompressorInterface
{
    /** @var HtmlMin */
    private $htmlMin;

    public function __construct(Patterns $patterns)
    {
        $this->htmlMin = new HtmlMin();
        $this->htmlMin->attachObserverToTheDomLoop(new HtmlMinObserver($patterns));
    }

    public function compress(string $string): string
    {
        return $this->htmlMin->minify($string);
    }
}
