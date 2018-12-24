<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

interface HtmlCompressorInterface
{
    public function compress(string $html): string;
}
