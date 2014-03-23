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
 * Class Parser
 *
 * @package WyriHaximus\HtmlCompress
 */
class Parser {

    protected $html = '';

    public function __construct($html) {
        $this->html = $html;
    }

    public function compress() {
        return str_replace('> <', '><', $this->html);
    }

}