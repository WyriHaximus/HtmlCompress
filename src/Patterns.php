<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

final class Patterns
{
    const MATCH_STYLE = [
        'tag' => 'style'
    ];

    const MATCH_STYLE_INLINE = [
        'attributes' => ['style']
    ];

    const MATCH_JSCRIPT = [
        'tag' => 'script',
        'attributes' => ['type' => 'text/javascript']
    ];

    const MATCH_LD_JSON = [
        'tag' => 'script',
        'attributes' => ['type' => 'application/ld+json']
    ];

    const MATCH_SCRIPT = [
        'tag' => 'script'
    ];
}
