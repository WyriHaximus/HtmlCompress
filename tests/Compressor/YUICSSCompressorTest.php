<?php declare(strict_types=1);
/**
 * Created by PhpStorm.
 * User: wyrihaximus
 * Date: 6/25/14
 * Time: 5:32 PM.
 */

namespace WyriHaximus\HtmlCompress\Tests\Compressor;

use WyriHaximus\HtmlCompress\Compressor\YUICSSCompressor;
use YUI\Compressor as YUICompressor;

/**
 * @internal
 */
final class YUICSSCompressorTest extends AbstractVendorCompressorTest
{
    const COMPRESSOR = YUICSSCompressor::class;

    public function testSetCorrectType(): void
    {
        $yui = (new \ReflectionClass($this->compressor))->getProperty('yui');
        $yui->setAccessible(true);
        $yuiInstance = $yui->getValue($this->compressor);
        $options = (new \ReflectionClass(
            $yuiInstance
        ))->getProperty('_options');
        $options->setAccessible(true);

        self::assertSame(YUICompressor::TYPE_CSS, $options->getValue($yuiInstance)['type']);
    }
}
