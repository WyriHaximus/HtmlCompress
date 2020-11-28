<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

use voku\helper\HtmlMinDomObserverInterface;
use voku\helper\HtmlMinInterface;
use voku\helper\SimpleHtmlDomInterface;

final class Patterns implements HtmlMinDomObserverInterface
{
    /** @var array<PatternInterface> */
    private array $patterns = [];

    public function __construct(PatternInterface ...$patterns)
    {
        $this->patterns = $patterns;
    }

    public function add(PatternInterface $pattern): void
    {
        $this->patterns[] = $pattern;
    }

    public function compress(SimpleHtmlDomInterface $element): void
    {
        foreach ($this->patterns as $pattern) {
            if ($pattern->matches($element) === true) {
                $pattern->compress($element);

                return;
            }
        }
    }

    /**
     * Receive dom elements before the minification.
     */
    public function domElementBeforeMinification(SimpleHtmlDomInterface $element, HtmlMinInterface $htmlMin): void
    {
        $this->compress($element);
    }

    /**
     * Receive dom elements after the minification.
     */
    public function domElementAfterMinification(SimpleHtmlDomInterface $element, HtmlMinInterface $htmlMin): void
    {
    }
}
