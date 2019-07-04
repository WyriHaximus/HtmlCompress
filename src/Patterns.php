<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

use voku\helper\SimpleHtmlDom;

final class Patterns
{
    /** @var PatternInterface[] */
    private $patterns = [];

    public function __construct(PatternInterface ...$patterns)
    {
        $this->patterns = $patterns;
    }

    public function compress(SimpleHtmlDom $element): void
    {
        foreach ($this->patterns as $pattern) {
            if ($pattern->matches($element) === true) {
                $pattern->compress($element);

                return;
            }
        }
    }
}
