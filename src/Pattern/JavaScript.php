<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Pattern;

use voku\helper\SimpleHtmlDomInterface;
use WyriHaximus\Compress\CompressorInterface;
use WyriHaximus\HtmlCompress\PatternInterface;

use function strlen;

final class JavaScript implements PatternInterface
{
    private CompressorInterface $compressor;

    public function __construct(CompressorInterface $compressor)
    {
        $this->compressor = $compressor;
    }

    public function matches(SimpleHtmlDomInterface $element): bool
    {
        /** @psalm-suppress NoInterfaceProperties */
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
        /** @psalm-suppress NoInterfaceProperties */
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

        /** @psalm-suppress NoInterfaceProperties */
        $element->outerhtml = '<script ' . $attributes . '>' . $compressedInnerHtml . '</script>';
    }
}
