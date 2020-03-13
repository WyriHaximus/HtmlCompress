<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;


use voku\helper\HtmlMinDomObserverInterface;
use voku\helper\SimpleHtmlDomInterface;
use voku\helper\HtmlMinInterface;

final class Patterns implements HtmlMinDomObserverInterface
{
    /** @var PatternInterface[] */
    private $patterns = [];
	
	/** @var HtmlMinInterface */
    private $htmlMin;

    /**
     * @param PatternInterface ...$patterns
     */
    public function __construct(PatternInterface ...$patterns)
    {
        $this->patterns = $patterns;
	}
	

	/**
     * @param PatternInterface $pattern
     */
	public function add(PatternInterface $pattern){
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
     *
     * @param SimpleHtmlDomInterface $element
     * @param HtmlMinInterface       $htmlMin
     */
	public function domElementBeforeMinification(SimpleHtmlDomInterface $element, HtmlMinInterface $htmlMin): void
    {
		$this->htmlMin = $htmlMin;

        $this->compress($element);
    }

    /**
     * Receive dom elements after the minification.
     *
     * @param SimpleHtmlDomInterface $element
     * @param HtmlMinInterface       $htmlMin
     */
    public function domElementAfterMinification(SimpleHtmlDomInterface $element, HtmlMinInterface $htmlMin): void
    {
	}
	
	
}
