<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Pattern;

use voku\helper\SimpleHtmlDomInterface;
use WyriHaximus\Compress\CompressorInterface;
use WyriHaximus\HtmlCompress\PatternInterface;

final class LdJson implements PatternInterface
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

        foreach (['type' => 'application/ld+json'] as $name => $value) {
            if ($element->hasAttribute($name) === false) {
                return false;
            }

            if ($element->getAttribute($name) !== $value) {
                return false;
            }
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

        $element->innerhtml = $compressedInnerHtml;
    }
}
