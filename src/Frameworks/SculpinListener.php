<?php

/*
 * This file is part of HtmlCompress.
 *
 ** (c) 2014 Cees-Jan Kiewiet
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */
namespace WyriHaximus\HtmlCompress\Frameworks;

use WyriHaximus\HtmlCompress\Factory;
use Sculpin\Core\Event\SourceSetEvent;

class SymfonyListener {

    public function onKernelResponse(SourceSetEvent $event) {
        $parser = Factory::construct();
        foreach ($event->allSources() as $source) {
            $source->setFormattedContent($parser->compress($source->formattedContent()));
        }
    }

}