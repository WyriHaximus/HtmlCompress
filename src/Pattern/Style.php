<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Pattern;

use voku\helper\SimpleHtmlDomInterface;
use WyriHaximus\Compress\CompressorInterface;
use WyriHaximus\HtmlCompress\PatternInterface;

use function str_starts_with;
use function strlen;
use function strpos;
use function substr;

final readonly class Style implements PatternInterface
{
    private const int ZERO                    = 0;
    private const string CSS_COMMENT_OPEN     = '<!--';
    private const int CSS_COMMENT_OPEN_LENGTH = 4;
    private const string CSS_COMMENT_CLOSE    = '-->';

    public function __construct(private CompressorInterface $compressor)
    {
    }

    public function matches(SimpleHtmlDomInterface $element): bool
    {
        /** @psalm-suppress NoInterfaceProperties */
        return $element->tag === 'style';
    }

    public function compress(SimpleHtmlDomInterface $element): void
    {
        /** @psalm-suppress NoInterfaceProperties */
        $innerHtml           = $element->innerhtml;
        $innerHtml           = $this->stripComments($innerHtml);
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
        $element->outerhtml = '<style ' . $attributes . '>' . $compressedInnerHtml . '</style>';
    }

    private function stripComments(string $contents): string
    {
        if (str_starts_with($contents, self::CSS_COMMENT_OPEN)) {
            $contents = substr($contents, self::CSS_COMMENT_OPEN_LENGTH);
        }

        $pos = strpos($contents, self::CSS_COMMENT_CLOSE);
        if ($pos !== false) {
            $contents = substr($contents, self::ZERO, $pos);
        }

        return $contents;
    }
}
