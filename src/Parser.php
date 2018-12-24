<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

use WyriHaximus\HtmlCompress\Compressor\CompressorInterface;
use WyriHaximus\HtmlCompress\Compressor\HtmlCompressor;

final class Parser implements ParserInterface
{
    /**
     * @var Compressor\CompressorInterface|Compressor\HtmlCompressor
     */
    private $defaultCompressor;

    /**
     * @var array
     */
    private $options;

    public function __construct(array $options, CompressorInterface $defaultCompressor = null)
    {
        $this->options = $options;

        if ($defaultCompressor === null) {
            $defaultCompressor = new HtmlCompressor();
        }
        $this->defaultCompressor = $defaultCompressor;
    }

    public function compress(string $html): string
    {
        $tokens = $this->tokenize($html);

        $compressedHtml = '';
        $useHtmlCompressor = false;
        do {
            $token = \array_shift($tokens);
            $compressor = $token->getCompressor();
            if ($compressor instanceof HtmlCompressor) {
                $useHtmlCompressor = true;
                $compressedHtml .= $token->getCombinedHtml();
            } else {
                $compressedHtml .= $compressor->compress($token->getCombinedHtml());
            }
        } while (\count($tokens) > 0);

        if ($useHtmlCompressor === true) {
            $compressedHtml = (new HtmlCompressor())->compress($compressedHtml);
        }

        return $compressedHtml;
    }

    /**
     * @param  string        $html
     * @return array|Token[]
     */
    public function tokenize(string $html): array
    {
        return Tokenizer::tokenize($html, $this->getCompressors(), $this->getDefaultCompressor());
    }

    public function getDefaultCompressor(): CompressorInterface
    {
        return $this->defaultCompressor;
    }

    public function getCompressors(): array
    {
        return $this->options['compressors'];
    }
}
