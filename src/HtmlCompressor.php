<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

use voku\helper\HtmlMin;

final class HtmlCompressor implements HtmlCompressorInterface
{
    private HtmlMin $htmlMin;

    private Patterns $patterns;

    public function __construct(HtmlMin $htmlMin, Patterns $patterns)
    {
        $this->htmlMin  = $htmlMin;
        $this->patterns = $patterns;
        $this->htmlMin->attachObserverToTheDomLoop($this->patterns);
    }

    public function compress(string $string): string
    {
        return $this->htmlMin->minify($string);
    }

    public function withHtmlMin(HtmlMin $htmlMin): HtmlCompressorInterface
    {
        $clone          = clone $this;
        $clone->htmlMin = $htmlMin;
        $clone->htmlMin->attachObserverToTheDomLoop($clone->patterns);

        return $clone;
    }
}
