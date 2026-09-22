# Instruction Economy (check before EVERY instruction you add)

Before adding an instruction ANYWHERE — AGENTS.mds, rules, agents, skills, hooks, configs: prefer the NATIVE mechanism (frontmatter field, config key, existing rule, a router to the single source) over new prose, and prefer DELETING prose over adding it. Every added instruction is a contradiction-and-drift surface; condensed copies of another artifact's content drift silently. Success metric: the diff shrinks or holds while capability grows. Consistency beats token thrift.

# Project Instructions

## Dependencies
- Install: `make install`.
- Require a new package: `make composer-require "PACKAGENAME"` or `make composer-require "PACKAGENAME --dev"`.

## Executing commands
- Do now use `cd` for everything, you're already in the root!
- Check `make help` for all available commands.
- Check `make help-contrib` for all available contrib commands.
- Need something custom that is not in the list? Use `make run "YOUR COMMAND HERE"` to run a command in the container and run whatever you require there.
- If a package needs custom `make` commands, put them in `etc/Makefile`, then run `make install` to make them available through the root `Makefile`.

## Flow
- After each logical block of changes made ensure `make contrib` passes.
- Before you return to the uses run `make` to ensure all QA checks pass.
- Use `make unit-testing-filter TESTCLASSNAME_OR_TESTMETHODNAME` to run a specific test.
- Always add unit tests for new code.
- If `composer.lock` is out of sync with `composer.json`, run `make update`.

## Writing code
- Keep things simple, once done implementing a feature, iterate on improving it. Less code is more.
- Make sure the code is readable and easy to understand.
- Prefer a logical block of code to be within one screen size over splitting it up in multiple smaller functions.
- Make a class static if it doesn't hold state.
- Put classes in logical folders.
- Once done writing code iterate of it to make sure it's easy to understand and maintain, that it's easy to test, and that it doesn't duplicate code.
- Search existing code for examples of how to do things.
- Search existing code for classes/methods you can use instead of writing your own.

## Markdown
- Always link every reference that has a URL (`[label](url)`); never bare backticks or plain text alone
- Composer packages → GitHub repo (resolve via Packagist); docs and specs → canonical URL

## Unit tests
- Test the happy flows (PHPUnit)
- Test the unhappy flows (PHPUnit)
- Test the edge cases (PHPUnit)
- Test the fuzzy cases (PHPUnit)
- 100% coverage is required (PHPUnit)
- 100% MSI is required (mutation testing (InfectionPHP))
- 100% type coverage is required (PHPStan)
- Use dataproviders wherever possible (PHPUnit)
- Prefer creating subs and spies over mocks
- Look at [`wyrihaximus/test-utilities`](https://github.com/WyriHaximus/php-test-utilities) and [`wyrihaximus/async-test-utilities`](https://github.com/WyriHaximus/php-async-test-utilities) for some useful helpers
- When tests are known to take longer than 10 seconds, when possible use `make unit-testing-filter TESTCLASSNAME_OR_TESTMETHODNAME` to run them in parallel across subagents

## Immutable laws
- Consistency is the key.
- Always add regressions to the test suite when fixing bugs or when the user tells you whatever you wrote is still broken.
- If several parts of the code rely on the same behavior (and data), centralize it in a single place.
- Always run `make` before you're returning control to the user.
- Always apply the boyscout rule: Leave the code better than you found it. But do not touch anything else than what you're touching.
- Always reload this file before you start processing a new request.
- Always show the plan. / When calling `CreatePlan` always show the plan.
- When ever you're done, before returning to the user always done 1 to 3 passes of reducing the amount of code you wrote while keeping it readable and maintainable.
- Shutdown works by removing everything that uses the event loop; never call `Loop::stop()` anywhere.
- Always extend PHPUnit test classes from `WyriHaximus\AsyncTestUtilities\AsyncTestCase` or `WyriHaximus\TestUtilities\TestCase`.

## Packages to consider when working with logging
- [`wyrihaximus/psr-3-context-logger`](https://github.com/WyriHaximus/php-psr-3-context-logger) — PSR-3 decorator; merge default context (optional `[Prefix]`) into every log call
- [`wyrihaximus/psr-3-filter`](https://github.com/WyriHaximus/php-psr-3-filter) — PSR-3 filter decorators; pass or drop logs by context path, level, message keyword, or strip nested `[Prefix]` chains (pairs with context-logger)
- [`wyrihaximus/psr-3-callable-throwable-logger`](https://github.com/WyriHaximus/php-psr-3-callable-throwable-logger) — `CallableThrowableLogger::create()` for react/promise rejection handlers and RxPHP error callbacks
- [`wyrihaximus/monolog-processors`](https://github.com/WyriHaximus/php-monolog-processors) — Monolog record processors (`CopyProcessor`, `ExceptionClassProcessor`, `TraceProcessor`, `RuntimeProcessor`, …)

## Forbidden commands
- Never call, attempt or even consider to use `sudo`
- Never call, attempt or even consider to use `su`
- Never call, attempt or even consider to use `sudo su`
- Never call, attempt or even consider to use `cd`
- Never call, attempt or even consider to use `docker`
- Any command not in the allowed commands list
- Never, ever, ever use ` — ` in documentation!!!!!

## Forbidden actions
- Create dead/unused methods/classes/functions/code
- Using the `assert` function
- Assigning a property to a variable without assigning a new value to it
- Never update `Makefile` or `AGENTS.md` outside [`wyrihaximus/makefiles`](https://github.com/WyriHaximus/Makefiles); suggest changes to that repository instead

## Recovery
- When you get `Error: RetriableError: [canceled] http/2 stream closed with error code CANCEL (0x8)` retry the request
