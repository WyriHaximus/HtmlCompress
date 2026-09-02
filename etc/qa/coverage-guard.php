<?php

declare(strict_types=1);

use ShipMonk\CoverageGuard\Config;
use ShipMonk\CoverageGuard\Excluder\IgnoreThrowNewExceptionLineExcluder;
use ShipMonk\CoverageGuard\Rule\EnforceCoverageForMethodsRule;

return (static function (): Config {
    $config = new Config();

    $config->addRule(new EnforceCoverageForMethodsRule(
        requiredCoveragePercentage: 100,
        minExecutableLines: 1,
    ));

    $config->addExecutableLineExcluder(new IgnoreThrowNewExceptionLineExcluder([
        RuntimeException::class,
    ]));

    return $config;
})();
