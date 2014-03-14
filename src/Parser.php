<?php

namespace WyriHaximus\HtmlCompress;

class Parser {

    protected $html = '';

    public function __construct($html) {
        $this->html = $html;
    }

    public function compress() {
        return str_replace('> <', '><', $this->html);
    }

}