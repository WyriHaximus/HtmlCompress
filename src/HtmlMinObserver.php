<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

use voku\helper\HtmlMin;
use voku\helper\HtmlMinDomObserverInterface;
use voku\helper\SimpleHtmlDom;

final class HtmlMinObserver implements HtmlMinDomObserverInterface
{
    /** @var Patterns */
    private $patterns;

    public function __construct(Patterns $patterns)
    {
        $this->patterns = $patterns;
    }

    /**
     * Receive dom elements before the minification.
     *
     * @param SimpleHtmlDom $element
     * @param HtmlMin       $htmlMin
     */
    public function domElementBeforeMinification(SimpleHtmlDom $element, HtmlMin $htmlMin): void
    {
        $this->patterns->compress($element);
    }

    /**
     * Receive dom elements after the minification.
     *
     * @param SimpleHtmlDom $element
     * @param HtmlMin       $htmlMin
     */
    public function domElementAfterMinification(SimpleHtmlDom $element, HtmlMin $htmlMin): void
    {
    }
}
