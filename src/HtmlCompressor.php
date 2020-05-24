<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

use voku\helper\HtmlMin;
use WyriHaximus\HtmlCompress\Compressor\HtmlCompressor as DefaultCompressor;

final class HtmlCompressor implements HtmlCompressorInterface
{
    /**
     * @var Patterns
     */
    private $patterns;

    /**
     * @var DefaultCompressor
     */
    private $defaultCompressor;

    public function __construct(Patterns $patterns)
    {
        $this->patterns = $patterns;
        $this->defaultCompressor = new DefaultCompressor($patterns);
    }

    public function compress(string $html): string
    {
        return $this->defaultCompressor->compress($html);
    }

    public function withHtmlMin(HtmlMin $htmlMin): HtmlCompressorInterface
    {
        $clone          = clone $this;
        $clone->defaultCompressor = $clone->defaultCompressor->withHtmlMin($htmlMin);

        return $clone;
    }
}
