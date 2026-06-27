<?php

declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

use voku\helper\HtmlMin;
use WyriHaximus\Compress\CompressorInterface;

/** @api */
interface HtmlCompressorInterface extends CompressorInterface
{
    public function withHtmlMin(HtmlMin $htmlMin): self;
}
