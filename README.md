# Spree BestPrice

This is a BestPrice extension for [Spree Commerce](https://spreecommerce.org), an open‑source e-commerce platform built with Ruby on Rails. It adds the ability to provide products listings to BestPrice Martketplace.

[![Gem Version](https://badge.fury.io/rb/spree_bestprice.svg)](https://badge.fury.io/rb/spree_bestprice)

## Installation

1. Add this extension to your Gemfile with this line:

   ```bash
   bundle add spree_bestprice
   ```

2. Restart your server

## Usage

1. **Deploy your endpoint**
   Once the extension is installed and enabled for your store, the feed is publicly served at:
   `https://yoursite.com/bestprice/products.xml`

2. **Whitelist BestPrice's bot IPs**
   BestPrice's crawler needs access to the feed URL. Make sure these IPs aren't blocked by a firewall, WAF, or bot-protection layer:

- `139.91.201.40`
- `139.91.200.222`
- `62.103.124.6`
- `62.103.124.3`

3. **Register the feed with BestPrice**
   Share your feed URL with BestPrice (via your Partner Platform contact) to have it added as a data source. New products are typically ingested within 3 business days of the first successful fetch; this isn't something you configure — BestPrice controls the fetch schedule on their end. If a fetch fails, they retry and will email you if the problem persists.

## Developing

1. Create a dummy app

   ```bash
   bundle update
   bundle exec rake test_app
   ```

2. Add your new code

3. Run tests

   ```bash
   bundle exec rspec
   ```

When testing your applications integration with this extension you may use it's factories.
Simply add this require statement to your spec_helper:

```ruby
require 'spree_bestprice/factories'
```

## Releasing a new version

```bash
bundle exec gem bump -p -t
bundle exec gem release
```

For more options please see [gem-release README](https://github.com/svenfuchs/gem-release)

## Contributing

If you'd like to contribute, please take a look at the
[instructions](CONTRIBUTING.md) for installing dependencies and crafting a good
pull request.

Copyright (c) 2026 OlympusOne, released under the MIT License.
