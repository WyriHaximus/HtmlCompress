<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

use WyriHaximus\HtmlCompress\Compressor\CompressorInterface;
use WyriHaximus\HtmlCompress\Compressor\HtmlCompressor as DefaultCompressor;

final class HtmlCompressor implements HtmlCompressorInterface
{
    /**
     * @var CompressorInterface
     */
    private $defaultCompressor;

    public function __construct(array $options)
    {
        $this->defaultCompressor = new DefaultCompressor($options);
    }

    public function compress(string $html): string
    {
        return $this->defaultCompressor->compress($html);
    }
}
