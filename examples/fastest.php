<?php

require dirname(__DIR__) . '/vendor/autoload.php';

$parser = \WyriHaximus\HtmlCompress\Factory::constructFastest();
echo $parser->compress("<html>\r\n\t<body>\r\n\t\t<h1>Title</h1>\r\n\t</body>\r\n</html>\r\n"), PHP_EOL;
