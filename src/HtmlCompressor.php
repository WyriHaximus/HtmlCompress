<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

use WyriHaximus\HtmlCompress\Compressor\CompressorInterface;
use WyriHaximus\HtmlCompress\Compressor\HtmlCompressor as DefaultCompressor;

final class HtmlCompressor implements HtmlCompressorInterface
{
    /** @var CompressorInterface */
    private $defaultCompressor;

    /** @var Tokenizer */
    private $tokenizer;

    public function __construct(array $options)
    {
        $this->defaultCompressor = new DefaultCompressor();
        $this->tokenizer = new Tokenizer($options['compressors'], $this->defaultCompressor);
    }

    public function compress(string $html): string
    {
        $tokens = $this->tokenizer->parse($html)->getTokens();

        $compressedHtml = '';
        $useHtmlCompressor = false;
        do {
            $token = \array_shift($tokens);
            $compressor = $token->getCompressor();
            if ($compressor instanceof DefaultCompressor) {
                $useHtmlCompressor = true;
                $compressedHtml .= $token->getCombinedHtml();
            } else {
                $compressedHtml .= $compressor->compress($token->getCombinedHtml());
            }
        } while (\count($tokens) > 0);

        if ($useHtmlCompressor === true) {
            $compressedHtml = $this->defaultCompressor->compress($compressedHtml);
        }

        return $compressedHtml;
    }
}
