# Contributing

Pull requests are highly appreciated. Here's a quick guide.

Fork, then clone the repo:

    git clone git@github.com:your-username/HtmlCompress.git

Install dependencies:

    make install

Work on the contribution and check if it passes all QA checks with:

    make

If some of the PHPStan or other checks are to strict or intimidating that is fine, finish what you want to contribute and I'll help you with those, but please make the following command passes. It runs a subset of everything:

    make contrib

You can list all the contrib commands with:

    make help-contrib

Push to your fork and [submit a pull request][pr].

[pr]: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request
