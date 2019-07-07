<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Pattern;

use voku\helper\SimpleHtmlDomInterface;
use WyriHaximus\Compress\CompressorInterface;
use WyriHaximus\HtmlCompress\PatternInterface;

final class JavaScript implements PatternInterface
{
    /** @var CompressorInterface */
    private $compressor;

    public function __construct(CompressorInterface $compressor)
    {
        $this->compressor = $compressor;
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

        if ($element->getAttribute('type') !== 'text/javascript') {
            return false;
        }

        return true;
    }

    public function compress(SimpleHtmlDomInterface $element): void
    {
        /** @var string $innerHtml */
        $innerHtml = $element->innerhtml;
        $compressedInnerHtml = $this->compressor->compress($innerHtml);

        if ($compressedInnerHtml === '') {
            return;
        }

        if (\strlen($compressedInnerHtml) >= \strlen($innerHtml)) {
            return;
        }

        $attributes = '';
        $elementAttributes = $element->getAllAttributes();
        if ($elementAttributes !== null) {
            /**
             * @var string $attributeName
             * @var string $attributeValue
             */
            foreach ($elementAttributes as $attributeName => $attributeValue) {
                $attributes .= $attributeName . '="' . $attributeValue . '"';
            }
        }

        $element->outerHtml = '<script ' . $attributes . '>' . $compressedInnerHtml . '</script>';
    }
}
