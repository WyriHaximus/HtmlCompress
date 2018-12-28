<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

use voku\helper\HtmlMin;
use voku\helper\HtmlMinDomObserverInterface;
use voku\helper\SimpleHtmlDom;
use WyriHaximus\HtmlCompress\Compressor\Compressor;

final class HtmlMinObserver implements HtmlMinDomObserverInterface
{
    /**
     * @var array
     */
    private $options;

    public function __construct(array $options)
    {
        $this->options = $options;
    }

    /**
     * Receive dom elements before the minification.
     *
     * @param SimpleHtmlDom $element
     * @param HtmlMin       $htmlMin
     */
    public function domElementBeforeMinification(SimpleHtmlDom $element, HtmlMin $htmlMin)
    {
        if (isset($this->options['compressors'])) {
            foreach ($this->options['compressors'] as $compressorTmp) {
                /** @var Compressor $compressor */
                $compressor = $compressorTmp['compressor'];

                switch ($compressorTmp['patterns'][0]) {

                    case Patterns::MATCH_LD_JSON:
                        if (
                            $element->tag === Patterns::MATCH_LD_JSON[0]
                            &&
                            isset(Patterns::MATCH_LD_JSON[1])
                            &&
                            $element->hasAttribute(\array_keys(Patterns::MATCH_LD_JSON[1])[0]) === true
                            &&
                            $element->getAttribute(\array_keys(Patterns::MATCH_LD_JSON[1])[0]) === \array_values(Patterns::MATCH_LD_JSON[1])[0]
                        ) {
                            $notCompressed = $element->innerHtml;
                            $compressed = $compressor->compress($notCompressed);
                            if ($compressed != $notCompressed) {
                                $element->innerHtml = $compressed;
                            }

                            break 2;
                        }

                        // no break
                    case Patterns::MATCH_JSCRIPT:
                        if (
                            $element->tag === Patterns::MATCH_JSCRIPT[0]
                            &&
                            isset(Patterns::MATCH_JSCRIPT[1])
                            &&
                            (
                                $element->hasAttribute(\array_keys(Patterns::MATCH_JSCRIPT[1])[0]) === false
                                ||
                                (
                                    $element->hasAttribute(\array_keys(Patterns::MATCH_JSCRIPT[1])[0]) === true
                                    &&
                                    $element->getAttribute(\array_keys(Patterns::MATCH_JSCRIPT[1])[0]) === \array_values(Patterns::MATCH_JSCRIPT[1])[0]
                                )
                            )
                        ) {
                            $notCompressed = $element->innerHtml;
                            $compressed = $compressor->compress($notCompressed);
                            if ($compressed != $notCompressed) {
                                $element->outerHtml = '<script>' . $compressed . '</script>';
                            }

                            continue 2;
                        }

                        // no break
                    case Patterns::MATCH_SCRIPT:
                        if (
                            $element->tag === Patterns::MATCH_SCRIPT[0]
                            &&
                            !isset(Patterns::MATCH_SCRIPT[1])
                        ) {
                            $notCompressed = $element->innerHtml;
                            $compressed = $compressor->compress($notCompressed);
                            if ($compressed != $notCompressed) {
                                $element->outerHtml = '<script>' . $compressed . '</script>';
                            }

                            break 2;
                        }

                        // no break
                    case Patterns::MATCH_STYLE:
                        if (
                            $element->tag === Patterns::MATCH_STYLE[0]
                            &&
                            !isset(Patterns::MATCH_STYLE[1])
                        ) {
                            $notCompressed = $element->innerHtml;
                            $compressed = $compressor->compress($notCompressed);
                            if ($compressed != $notCompressed) {
                                $element->innerHtml = $compressed;
                            }

                            break 2;
                        }

                        // no break
                    case Patterns::MATCH_STYLE_INLINE:
                        if (
                            $element->tag
                            &&
                            isset(Patterns::MATCH_STYLE_INLINE[1][0])
                            &&
                            $element->hasAttribute(Patterns::MATCH_STYLE_INLINE[1][0])
                        ) {
                            $notCompressed = $element->getAttribute(Patterns::MATCH_STYLE_INLINE[1][0]);
                            $compressed = $compressor->compress($notCompressed);
                            if ($compressed != $notCompressed) {
                                /** @noinspection UnusedFunctionResultInspection */
                                $element->setAttribute(Patterns::MATCH_STYLE_INLINE[1][0], $compressed);
                            }

                            break 2;
                        }

                }
            }
        }
    }

    /**
     * Receive dom elements after the minification.
     *
     * @param SimpleHtmlDom $element
     * @param HtmlMin       $htmlMin
     */
    public function domElementAfterMinification(SimpleHtmlDom $element, HtmlMin $htmlMin)
    {
    }
}
