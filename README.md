HtmlCompress
============

[![Build Status](https://travis-ci.org/WyriHaximus/HtmlCompress.png)](https://travis-ci.org/WyriHaximus/HtmlCompress)
[![Latest Stable Version](https://poser.pugx.org/WyriHaximus/html-compress/v/stable.png)](https://packagist.org/packages/WyriHaximus/html-compress)
[![Total Downloads](https://poser.pugx.org/WyriHaximus/html-compress/downloads.png)](https://packagist.org/packages/WyriHaximus/html-compress)
[![Coverage Status](https://coveralls.io/repos/WyriHaximus/HtmlCompress/badge.png)](https://coveralls.io/r/WyriHaximus/HtmlCompress)
[![License](https://poser.pugx.org/wyrihaximus/html-compress/license.png)](https://packagist.org/packages/wyrihaximus/html-compress)

## Installation ##

Installation is easy with composer just add HtmlCompress to your composer.json.

```json
{
	"require": {
		"wyrihaximus/html-compress": "dev-master"
	}
}
```

Or use composer it self to add it:

```bash
composer require "wyrihaximus/html-compress:dev-master"
```

## Basic Usage ##

```php
<?php

require dirname(__DIR__) . '/vendor/autoload.php';

$parser = \WyriHaximus\HtmlCompress\Factory::construct();
$compressedHtml = $parser->compress($sourceHtml);


```


## License ##

Copyright 2014 [Cees-Jan Kiewiet](http://wyrihaximus.net/)

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
