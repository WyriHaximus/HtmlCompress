<?php // @codeCoverageIgnoreStart

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
 * Interface CompressorInterface
 * @package WyriHaximus\HtmlCompress\Compressor
 */
interface CompressorInterface
{
    /**
     * @param $string
     *
     * @return string
     */
    public function compress($string);
}
