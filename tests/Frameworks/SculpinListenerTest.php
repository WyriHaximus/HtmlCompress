<?php

/*
 * This file is part of HtmlCompress.
 *
 ** (c) 2014 Cees-Jan Kiewiet
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */
namespace WyriHaximus\HtmlCompress\Tests\Frameworks;

use Phake;
use PHPUnit\Framework\TestCase;
use WyriHaximus\HtmlCompress\Frameworks\SculpinListener;
use WyriHaximus\HtmlCompress\Parser;

class SculpinListenerTest extends TestCase {

    public function testOnAfterFormatFastest() {
        $this->markTestSkipped('Deprecated');
        $event = Phake::mock('Sculpin\Core\Event\SourceSetEvent');
        $listener = Phake::mock(SculpinListener::class);
        Phake::when($listener)->compress($this->isInstanceOf(Parser::class), $event);
        Phake::when($listener)->onAfterFormatFastest($event)->thenCallParent();
        $listener->onAfterFormatFastest($event);
        Phake::verify($listener)->compress($this->isInstanceOf(Parser::class), $event);
    }

    public function testOnAfterFormat() {
        $this->markTestSkipped('Deprecated');
        $event = Phake::mock('Sculpin\Core\Event\SourceSetEvent');
        $listener = Phake::mock(SculpinListener::class);
        Phake::when($listener)->compress($this->isInstanceOf(Parser::class), $event);
        Phake::when($listener)->onAfterFormat($event)->thenCallParent();
        $listener->onAfterFormat($event);
        Phake::verify($listener)->compress($this->isInstanceOf(Parser::class), $event);
    }

    public function testOnAfterFormatSmallest() {
        $this->markTestSkipped('Deprecated');
        $event = Phake::mock('Sculpin\Core\Event\SourceSetEvent');
        $listener = Phake::mock(SculpinListener::class);
        Phake::when($listener)->compress($this->isInstanceOf(Parser::class), $event);
        Phake::when($listener)->onAfterFormatSmallest($event)->thenCallParent();
        $listener->onAfterFormatSmallest($event);
        Phake::verify($listener)->compress($this->isInstanceOf(Parser::class), $event);
    }

    public function testCompress() {
        $this->markTestSkipped('Deprecated');
        $sourceA = Phake::mock('Sculpin\Core\Source\SourceInterface');
        Phake::when($sourceA)->filename()->thenReturn('index.html');
        Phake::when($sourceA)->formattedContent()->thenReturn('foo');

        $sourceB = Phake::mock('Sculpin\Core\Source\SourceInterface');
        Phake::when($sourceB)->filename()->thenReturn('robots.txt');

        $event = Phake::mock('Sculpin\Core\Event\SourceSetEvent');
        Phake::when($event)->allSources()->thenReturn(array(
            $sourceA,
            $sourceB
        ));

        $listener = new \WyriHaximus\HtmlCompress\Frameworks\SculpinListener();
        $listener->onAfterFormatSmallest($event);

        Phake::inOrder(
            Phake::verify($event)->allSources(),
            Phake::verify($sourceA)->filename(),
            Phake::verify($sourceA)->formattedContent(),
            Phake::verify($sourceB)->filename()
        );

        Phake::verify($sourceB, Phake::never())->formattedContent();
    }

}
