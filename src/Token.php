<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

use WyriHaximus\HtmlCompress\Compressor\CompressorInterface;

final class Token
{
    private $prefix;
    private $suffix;
    private $html;
    private $compressor;

    public function __construct(string $prefix, string $html, string $suffix, CompressorInterface $compressor)
    {
        $this->prefix = $prefix;
        $this->html = $html;
        $this->suffix = $suffix;
        $this->compressor = $compressor;
    }

    public function getPrefix(): string
    {
        return $this->prefix;
    }

    public function getSuffix(): string
    {
        return $this->suffix;
    }

    public function getHtml(): string
    {
        return $this->html;
    }

    public function getCombinedHtml(): string
    {
        return $this->getPrefix() . $this->getHtml() . $this->getSuffix();
    }

    public function getCompressor(): CompressorInterface
    {
        return $this->compressor;
    }
}
