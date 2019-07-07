<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

use WyriHaximus\Compress\CompressorInterface;
use WyriHaximus\HtmlCompress\Compressor\HtmlCompressor as DefaultCompressor;

final class HtmlCompressor implements HtmlCompressorInterface
{
    /**
     * @var CompressorInterface
     */
    private $defaultCompressor;

    public function __construct(Patterns $patterns)
    {
        $this->defaultCompressor = new DefaultCompressor($patterns);
    }

    public function compress(string $html): string
    {
        return $this->defaultCompressor->compress($html);
    }
}
