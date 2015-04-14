<?php

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
 * Class Token
 *
 * @package WyriHaximus\HtmlCompress
 */
class Token
{
    protected $prefix;
    protected $suffix;
    protected $html;
    protected $compressor;

    public function __construct($prefix, $html, $suffix, CompressorInterface $compressor)
    {
        $this->prefix = $prefix;
        $this->html = $html;
        $this->suffix = $suffix;
        $this->compressor = $compressor;
    }

    public function getPrefix()
    {
        return $this->prefix;
    }

    public function getSuffix()
    {
        return $this->suffix;
    }

    public function getHtml()
    {
        return $this->html;
    }

    public function getCombinedHtml()
    {
        return $this->getPrefix() . $this->getHtml() . $this->getSuffix();
    }

    public function getCompressor()
    {
        return $this->compressor;
    }
}
