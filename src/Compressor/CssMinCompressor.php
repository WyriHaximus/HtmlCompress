<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress\Compressor;

final class CssMinCompressor extends Compressor
{
    /**
     * @var \CssMin
     */
    private $cssMin;

    public function __construct()
    {
        $this->cssMin = new \CssMin();
    }

    protected function execute(string $string): string
    {
        // If there's no selector, this must be an inline CSS attribute.
        if (
            \strlen($string) > 0
            &&
            \strpos($string, '{') === false
        ) {
            return $this->minifyInline($string);
        }

        return $this->cssMin::minify($string);
    }

    private function minifyInline(string $string): string
    {
        // Get CssMin to compress inline CSS by adding and stripping a selector.
        $mock = 'body{' . $string . '}';
        $minified = $this->execute($mock);

        return \substr($minified, 5, -1);
    }
}
