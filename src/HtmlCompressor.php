<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

use voku\helper\HtmlMin;

use function trim;

final class HtmlCompressor implements HtmlCompressorInterface
{
    public function __construct(private HtmlMin $htmlMin, private Patterns $patterns)
    {
        $this->htmlMin->attachObserverToTheDomLoop($this->patterns);
    }

    public function compress(string $string): string
    {
        return trim($this->htmlMin->minify($string));
    }

    public function withHtmlMin(HtmlMin $htmlMin): HtmlCompressorInterface
    {
        $clone          = clone $this;
        $clone->htmlMin = $htmlMin;
        $clone->htmlMin->attachObserverToTheDomLoop($clone->patterns);

        return $clone;
    }
}
