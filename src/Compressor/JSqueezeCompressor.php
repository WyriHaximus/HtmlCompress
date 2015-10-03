<?php

/*
 * This file is part of HtmlCompress.
 *
 ** (c) 2014 Cees-Jan Kiewiet
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */
namespace WyriHaximus\HtmlCompress\Compressor;

/**
 * Class JSqueezeCompressor
 *
 * @package WyriHaximus\HtmlCompress\Compressor
 */
class JSqueezeCompressor extends Compressor
{
    /**
     * {@inheritdoc}
     */
    protected function execute($string)
    {
        // Try version 2.0 namespace first
        $class = '\Patchwork\JSqueeze';
        if (!class_exists($class)) {
            // Otherwise use 1.0
            $class = '\JSqueeze';
        }
        /** @var \Patchwork\JSqueeze|\JSqueeze $parser */
        $parser = new $class();
        return $parser->squeeze($string);
    }
}
