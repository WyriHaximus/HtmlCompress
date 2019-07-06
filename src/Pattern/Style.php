<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Pattern;

use voku\helper\SimpleHtmlDomInterface;
use WyriHaximus\HtmlCompress\Compressor\CompressorInterface;
use WyriHaximus\HtmlCompress\PatternInterface;

final class Style implements PatternInterface
{
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
        $compressedInnerHtml = $this->compressor->compress($innerHtml);

        if ($compressedInnerHtml === '') {
            return;
        }

        if (\strlen($compressedInnerHtml) >= \strlen($innerHtml)) {
            return;
        }

        $element->innerhtml = $compressedInnerHtml;
    }
}
