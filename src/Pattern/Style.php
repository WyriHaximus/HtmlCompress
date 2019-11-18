<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Pattern;

use voku\helper\SimpleHtmlDomInterface;
use WyriHaximus\Compress\CompressorInterface;
use WyriHaximus\HtmlCompress\PatternInterface;

final class Style implements PatternInterface
{
    private const ZERO = 0;
    private const CSS_COMMENT_OPEN = '<!--';
    private const CSS_COMMENT_OPEN_LENGTH = 4;
    private const CSS_COMMENT_CLOSE = '-->';

    /** @var CompressorInterface */
    private $compressor;

    public function __construct(CompressorInterface $compressor)
    {
        $this->compressor = $compressor;
    }

    public function matches(SimpleHtmlDomInterface $element): bool
    {
        return $element->tag === 'style';
    }

    public function compress(SimpleHtmlDomInterface $element): void
    {
        /** @var string $innerHtml */
        $innerHtml = $element->innerhtml;
        $innerHtml = $this->stripComments($innerHtml);
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

        $element->outerhtml = '<style ' . $attributes . '>' . $compressedInnerHtml . '</style>';
    }

    private function stripComments(string $contents): string
    {
        if (\strpos($contents, self::CSS_COMMENT_OPEN) === self::ZERO) {
            $contents = \substr($contents, self::CSS_COMMENT_OPEN_LENGTH);
        }

        $pos = \strpos($contents, self::CSS_COMMENT_CLOSE);
        if ($pos !== false) {
            $contents = \substr($contents, self::ZERO, $pos);
        }

        return $contents;
    }
}
