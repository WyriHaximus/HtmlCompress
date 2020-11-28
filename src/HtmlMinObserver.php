<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

use voku\helper\HtmlMinDomObserverInterface;
use voku\helper\HtmlMinInterface;
use voku\helper\SimpleHtmlDomInterface;

final class HtmlMinObserver implements HtmlMinDomObserverInterface
{
    private Patterns $patterns;

    public function __construct(Patterns $patterns)
    {
        $this->patterns = $patterns;
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
