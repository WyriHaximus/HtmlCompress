<?php

namespace WyriHaximus\HtmlCompress;

class Factory {

    public static function construct($html) {
        return new Parser($html);
    }

}