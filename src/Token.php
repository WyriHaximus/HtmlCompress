<?php declare(strict_types=1);
/*
 * This file is part of HtmlCompress.
 *
 ** (c) 2014 Cees-Jan Kiewiet
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

namespace WyriHaximus\HtmlCompress;

use WyriHaximus\HtmlCompress\Compressor\CompressorInterface;

/**
 * Class Token.
 *
 * @package WyriHaximus\HtmlCompress
 */
final class Token
{
    protected $prefix;
    protected $suffix;
    protected $html;
    protected $compressor;

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
