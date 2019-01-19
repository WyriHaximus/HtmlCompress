<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

final class Patterns
{
    const MATCH_STYLE        = ['style'];
    const MATCH_STYLE_INLINE = ['*', ['style']];
    const MATCH_JSCRIPT      = ['script', ['type' => 'text/javascript']];
    const MATCH_LD_JSON      = ['script', ['type' => 'application/ld+json']];
    const MATCH_SCRIPT       = ['script'];
}
