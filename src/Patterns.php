<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

use voku\helper\SimpleHtmlDomInterface;

final class Patterns
{
    /** @var PatternInterface[] */
    private $patterns = [];

    /**
     * @param PatternInterface ...$patterns
     */
    public function __construct(PatternInterface ...$patterns)
    {
        $this->patterns = $patterns;
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
}
