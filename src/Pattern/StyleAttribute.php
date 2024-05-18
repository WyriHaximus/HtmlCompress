<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Pattern;

use voku\helper\SimpleHtmlDomInterface;
use WyriHaximus\Compress\CompressorInterface;
use WyriHaximus\HtmlCompress\PatternInterface;

use function strlen;

final class StyleAttribute implements PatternInterface
{
    public function __construct(private CompressorInterface $compressor)
    {
    }

    public function matches(SimpleHtmlDomInterface $element): bool
    {
        return $element->hasAttribute('style');
    }

    public function compress(SimpleHtmlDomInterface $element): void
    {
        $uncompressedStyleAttribute = $element->getAttribute('style');
        $compressedStyleAttribute   = $this->compressor->compress($uncompressedStyleAttribute);

        if ($compressedStyleAttribute === '') {
            return;
        }

        if (strlen($compressedStyleAttribute) >= strlen($uncompressedStyleAttribute)) {
            return;
        }

        $element->setAttribute('style', $compressedStyleAttribute);
    }
}
