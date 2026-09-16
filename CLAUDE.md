# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

`spree_bestprice` is a Spree Commerce extension (gem) that exposes a product feed for [BestPrice Merchants](https://merchants.bestprice.gr/). It registers a `Spree::Integrations::BestPrice` integration that store owners enable per-store, and when enabled exposes an XML feed at `/bestprice/products.xml` (also available gzipped at `/bestprice/products.xml.gz`).

## Commands

### Setup (first time or after gem changes)

```bash
bundle update
bundle exec rake test_app   # generates spec/dummy app
```

### Running tests

```bash
bundle exec rspec                              # all specs
bundle exec rspec spec/feature/home_page_spec.rb  # single spec file
```

### Releasing a new version

```bash
bundle exec gem bump -p -t   # bump patch version + tag
bundle exec gem release      # push gem to RubyGems
```

## Architecture

This is a standard Spree extension. Key files:

- **`lib/spree_bestprice/engine.rb`** — Rails engine; loads decorators, registers assets and importmap
- **`config/initializers/spree.rb`** — appends `Spree::Integrations::Bestprice` to `Spree.integrations` after init
- **`app/models/spree/integrations/bestprice.rb`** — integration model (inherits `Spree::Integration`), grouped under `'marketing'`. Class is `Spree::Integrations::Bestprice` (lowercase `p`), not `BestPrice` — this is deliberate: Rails autoloading (Zeitwerk) and Spree's `integration_key` (`name.demodulize.underscore`) both derive names from the filename via plain `camelize`/`underscore`, which can't reproduce a mid-word capital like the "P" in "BestPrice" without special-casing. Using `Bestprice` everywhere (class name, `integration_key` → `'bestprice'`, admin partial filename, `store_integration('bestprice')` calls) keeps every layer in sync with zero custom inflection config
- **`app/controllers/spree/bestprice_controller.rb`** — inherits `Spree::StoreController`; defines `Spree::BestpriceController` (lowercase `p`, same reasoning as above — the route's `to: 'bestprice#products'` resolves via `"bestprice".camelize`); checks `store_integration('bestprice')` before serving the feed; responds to `.xml` and `.xml.gz` formats
- **`app/views/spree_bestprice/products.xml.builder`** — XML builder template; iterates `storefront_products_scope` with fragment caching keyed on `[storefront_products_scope, current_currency]`. Products with a `color` option type are split into one `<product>` entry per color (id: `"#{product.id}-#{color_value.id}"`), per BestPrice's requirement that color variants be separate listings; sizes stay aggregated as a comma list within each entry. Root structure (`<store><date>...<products><product>...`) and tag names mirror BestPrice's own "Υπόδειγμα XML" sample as closely as possible
- **`app/views/spree/admin/integrations/forms/_bestprice.html.erb`** — admin UI partial shown when configuring the integration (filename must match `Spree::Integrations::Bestprice`'s `integration_key`)
- **`config/routes.rb`** — mounts routes inside `Spree::Core::Engine.add_routes`
- **`lib/spree_bestprice/configuration.rb`** — `SpreeBestPrice::Config` preferences object (currently no preferences defined)
- **`lib/spree_bestprice/factories.rb`** — FactoryBot factory `bestprice_integration` for use in test suites of host apps

## XML Feed Fields

The feed (`products.xml.builder`) maps Spree product attributes to BestPrice's required schema. Each `<product>` corresponds to one "entry" — either the whole product, or one color group of variants if the product has a `color` option type (see Architecture above):

| XML tag                      | Source                                                                                                                                                                                                                                                                                                           |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `productId`                  | `product.id`, or `"#{product.id}-#{color_value.id}"` for a color entry                                                                                                                                                                                                                                           |
| `title`                      | `product.name`, or `"#{product.name} - #{color}"` for a color entry — suffix is skipped if `product.name` already contains the color name (case-insensitive), to avoid duplication for stores that bake color into the product name                                                                              |
| `productURL`                 | `spree_storefront_resource_url(product)`                                                                                                                                                                                                                                                                         |
| `image` / `additional_image` | images from the entry's variants, falling back to `product.default_image`; `image` is always rendered (empty if the entry has no images at all), since it's a required BestPrice field                                                                                                                           |
| `category_id`                | id of the leaf taxon from `product_breadcrumb_taxons(product)`, omitted if the product has no taxons (optional field)                                                                                                                                                                                            |
| `category_name`              | `product_breadcrumb_taxons(product).map(&:name).join('->')` (spec-mandated separator)                                                                                                                                                                                                                            |
| `price`                      | `display_price.to_d` of the entry's representative variant (first in-stock, else first) — VAT-inclusive, there is no separate `vat` field in the BestPrice spec                                                                                                                                                  |
| `availability`               | `product.bestprice_availability` override always wins if set; otherwise in stock → `Σε απόθεμα`/`Παράδοση σε 1-3 ημέρες` (per `preferred_physical_pickup`), out of stock → store's `preferred_default_availability`, falling back to `Εξαντλήθηκε` if unset so a product is never silently dropped from the feed |
| `stock`                      | `Y`/`N` based on whether any of the entry's variants are in stock                                                                                                                                                                                                                                                |
| `manufacturer`               | `product.brand_taxon&.name` — always rendered (empty if absent), it's a required BestPrice field                                                                                                                                                                                                                 |
| `ean`                        | representative variant's `barcode`, falling back to `product.barcode` — always rendered, required field (BestPrice's EAN/Barcode/MPN/SKU field; named `ean` since the underlying data is a barcode/EAN, not a true manufacturer part number — tag names for this field are configurable per BestPrice's spec)    |
| `size` / `color`             | option values of the entry's variants, filtered by option type name (`'size'` / `'color'`)                                                                                                                                                                                                                       |
| `weight`                     | `product.weight` + `product.weight_unit`                                                                                                                                                                                                                                                                         |
| `description`                | `product.storefront_description` (truncated to 10 000 chars) — not part of the BestPrice spec, kept as a harmless custom field                                                                                                                                                                                   |
| `quantity`                   | sum of `total_on_hand` across the entry's variants — not part of the BestPrice spec, kept as a harmless custom field                                                                                                                                                                                             |

## Spree Extension Conventions

- All classes under `Spree::` namespace
- Decorator files follow the pattern `app/**/*_decorator*.rb` and are loaded by the engine
- Use `Spree.t` for all translations; locale files live in `config/locales/`
- The integration is per-store: `store_integration('bestprice')` returns nil when not configured, which gates the feed endpoint
- Avoid mid-word capitals in class/file names that need to round-trip through Rails' `camelize`/`underscore` (Zeitwerk autoloading, Spree's `integration_key`, route `to:` controller resolution) — `BestPrice` breaks this, `Bestprice` doesn't
- Tests use `spec/dummy` (generated by `rake test_app`); require `spree_bestprice/factories` in `spec_helper` for the `bestprice_integration` factory
