<?php declare(strict_types=1);

use WyriHaximus\HtmlCompress\HtmlCompressor;
use WyriHaximus\HtmlCompress\Pattern\Script;
use WyriHaximus\HtmlCompress\Patterns;
use WyriHaximus\JsCompress\Compressor\MMMJSCompressor;

return new HtmlCompressor(
    new Patterns(
        new Script(
            new MMMJSCompressor()
        )
    )
);
