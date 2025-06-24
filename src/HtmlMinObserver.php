<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

use voku\helper\HtmlMinDomObserverInterface;
use voku\helper\HtmlMinInterface;
use voku\helper\SimpleHtmlDomInterface;

final readonly class HtmlMinObserver implements HtmlMinDomObserverInterface
{
    /** @phpstan-ignore shipmonk.deadMethod */
    public function __construct(private Patterns $patterns)
    {
    }

    /**
     * Receive dom elements before the minification.
     */
    public function domElementBeforeMinification(SimpleHtmlDomInterface $element, HtmlMinInterface $htmlMin): void
    {
        $this->patterns->compress($element);
    }

    /**
     * Receive dom elements after the minification.
     */
    public function domElementAfterMinification(SimpleHtmlDomInterface $element, HtmlMinInterface $htmlMin): void
    {
    }
}
