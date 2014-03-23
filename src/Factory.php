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

/**
 * Class Factory
 *
 * @package WyriHaximus\HtmlCompress
 */
class Factory {

    public static function construct($html) {
        return new Parser($html);
    }

}