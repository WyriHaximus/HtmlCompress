<?php declare(strict_types=1);

use WyriHaximus\HtmlCompress\Compressor\MMMJSCompressor;
use WyriHaximus\HtmlCompress\HtmlCompressor;
use WyriHaximus\HtmlCompress\Pattern\Script;
use WyriHaximus\HtmlCompress\Patterns;

return new HtmlCompressor(
    new Patterns(
        new Script(
            new MMMJSCompressor()
        )
    )
);
