<?php declare(strict_types=1);

use WyriHaximus\HtmlCompress\HtmlCompressor;
use WyriHaximus\HtmlCompress\Pattern\LdJson;
use WyriHaximus\HtmlCompress\Patterns;
use WyriHaximus\JsCompress\Compressor\MMMJSCompressor;

return new HtmlCompressor(
    new Patterns(
        new LdJson(
            new MMMJSCompressor()
        )
    )
);
