<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Pattern;

use voku\helper\SimpleHtmlDomInterface;
use WyriHaximus\Compress\CompressorInterface;
use WyriHaximus\HtmlCompress\PatternInterface;

use function strlen;

final readonly class JavaScript implements PatternInterface
{
    public function __construct(private CompressorInterface $compressor)
    {
    }

    public function matches(SimpleHtmlDomInterface $element): bool
    {
        if ($element->tag !== 'script') {
            return false;
        }

        if ($element->getAllAttributes() === null) {
            return true;
        }

        if ($element->hasAttribute('type')  === false) {
            return true;
        }

        return $element->getAttribute('type') === 'text/javascript';
    }

    public function compress(SimpleHtmlDomInterface $element): void
    {
        $innerHtml           = $element->innerhtml;
        $compressedInnerHtml = $this->compressor->compress($innerHtml);

        if ($compressedInnerHtml === '') {
            return;
        }

        if (strlen($compressedInnerHtml) >= strlen($innerHtml)) {
            return;
        }

        $attributes        = '';
        $elementAttributes = $element->getAllAttributes();
        if ($elementAttributes !== null) {
            foreach ($elementAttributes as $attributeName => $attributeValue) {
                $attributes .= $attributeName . '="' . $attributeValue . '"';
            }
        }

        $element->outerhtml = '<script ' . $attributes . '>' . $compressedInnerHtml . '</script>';
    }
}
