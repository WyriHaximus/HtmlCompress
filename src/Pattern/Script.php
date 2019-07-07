<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Pattern;

use voku\helper\SimpleHtmlDomInterface;
use WyriHaximus\Compress\CompressorInterface;
use WyriHaximus\HtmlCompress\PatternInterface;

final class Script implements PatternInterface
{
    /** @var CompressorInterface */
    private $compressor;

    public function __construct(CompressorInterface $compressor)
    {
        $this->compressor = $compressor;
    }

    public function matches(SimpleHtmlDomInterface $element): bool
    {
        return $element->tag === 'script';
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
