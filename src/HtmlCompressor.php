<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

use voku\helper\HtmlMin as DefaultCompressor;

final class HtmlCompressor implements HtmlCompressorInterface
{
    private DefaultCompressor $defaultCompressor;

    private Patterns $patterns;

    public function __construct(Patterns $patterns)
    {
        $this->defaultCompressor = new DefaultCompressor();
        $this->patterns          = $patterns;
        $this->compressor()->attachObserverToTheDomLoop($this->patterns); // Patterns $patters IS already a voku\helper\HtmlMinDomObserverInterface;
    }

    public function compress(string $html): string
    {
        return $this->compressor()->minify($html);
    }

    public function compressor(): DefaultCompressor
    {
        return $this->defaultCompressor;
    }

    public function patterns(): Patterns
    {
        return $this->patterns;
    }
}
