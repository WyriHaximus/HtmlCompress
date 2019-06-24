<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

use voku\helper\SimpleHtmlDom;

interface PatternInterface
{
    public function matches(SimpleHtmlDom $element): bool;

    public function compress(SimpleHtmlDom $element): void;
}
