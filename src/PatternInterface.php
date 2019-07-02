<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

use voku\helper\SimpleHtmlDomInterface;

interface PatternInterface
{
    public function matches(SimpleHtmlDomInterface $element): bool;

    public function compress(SimpleHtmlDomInterface $element): void;
}
