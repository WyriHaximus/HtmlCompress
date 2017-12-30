<?php // @codeCoverageIgnoreStart

/*
 * This file is part of HtmlCompress.
 *
 ** (c) 2014 Cees-Jan Kiewiet
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */
namespace WyriHaximus\HtmlCompress;

/**
 * Class Patterns
 *
 * @package WyriHaximus\HtmlCompress
 */
class Patterns
{
    const MATCH_PRE          = '!(<pre>|<pre[^>]*>?)(.*?)(</pre>)!is';
    const MATCH_TEXTAREA     = '!(<textarea>|<textarea[^>]*>?)(.*?)(</textarea>)!is';
    const MATCH_STYLE        = '!(<style>|<style[^>]*>?)(.*?)(</style>)!is';
    const MATCH_STYLE_INLINE = '!(<[^>]* style=")(.*?)(")!is';
    // @codingStandardsIgnoreStart
    const MATCH_JSCRIPT      = '!(<script>|<script[^>]*type="text/javascript"[^>]*>|<script[^>]*type=\'text/javascript\'[^>]*>)(.*?)(</script>)!is';
    const MATCH_LD_JSON      = '!(<script[^>]*type="application/ld\+json"[^>]*>|<script[^>]*type=\'application/ld\+json\'[^>]*>)(.*?)(</script>)!is';
    // @codingStandardsIgnoreEnd
    const MATCH_SCRIPT       = '!(<script[^>]*>?)(.*?)(</script>)!is';
    const MATCH_NOCOMPRESS   = '!(<nocompress>)(.*?)(</nocompress>)!is';
}
