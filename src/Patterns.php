<?php declare(strict_types=1);

namespace WyriHaximus\HtmlCompress;

final class Patterns
{
    const MATCH_PRE          = '!(<pre>|<pre[^>]*>?)(.*?)(</pre>)!is';
    const MATCH_TEXTAREA     = '!(<textarea>|<textarea[^>]*>?)(.*?)(</textarea>)!is';
    const MATCH_STYLE        = '!(<style>|<style[^>]*>?)(.*?)(</style>)!is';
    const MATCH_STYLE_INLINE = '!(<[^>]* style=")(.*?)(")!is';
    const MATCH_JSCRIPT      = '!(<script>|<script[^>]*type="text/javascript"[^>]*>|<script[^>]*type=\'text/javascript\'[^>]*>)(.*?)(</script>)!is';
    const MATCH_LD_JSON      = '!(<script[^>]*type="application/ld\+json"[^>]*>|<script[^>]*type=\'application/ld\+json\'[^>]*>)(.*?)(</script>)!is';
    const MATCH_SCRIPT       = '!(<script[^>]*>?)(.*?)(</script>)!is';
    const MATCH_NOCOMPRESS   = '!(<nocompress>)(.*?)(</nocompress>)!is';
}
