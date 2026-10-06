# widget_list

`widget_list` renders sortable, searchable Rails data grids with Ajax paging and CSV export. Version 2.0.0 has been exercised with **Rails 8.1.4**, **Ruby 3.4.11**, **Sequel 5.109.0**, **Ransack 5.0.2**, and SQLite. Rails 8.1 requires Ruby 3.2 or newer. The Rails 3 era guide remains in [docs/legacy-readme.md](docs/legacy-readme.md) for reference.

The runnable [widget_list_example_rails8](https://github.com/davidrenne/widget_list_example_rails8/) contains both a Sequel SQL list and a Ransack/Active Record list. Its README and single commit diff show every caller change needed in a fresh Rails 8 app.

## Video demo

[![Play the original widget_list demo](docs/widget-list-demo-thumbnail.png)](https://www.youtube.com/watch?v=A6mZa8Ge2Rk)

This video shows the original 1.x interface. For the Rails 8 integration, use the current example app below.

## Add it to a Rails 8 app

`widget_list` uses jQuery and Sprockets assets. In your Gemfile:

```ruby
gem 'sprockets-rails'
gem 'jquery-rails'
gem 'widget_list', '~> 2.0'
```

Run `bundle install`. Add `app/assets/config/manifest.js`:

```javascript
//= link_tree ../images
//= link_directory ../stylesheets .css
//= link_directory ../javascripts .js
//= link widget_list.css
//= link widgets.css
//= link widget_list.js
```

Add `app/assets/javascripts/application.js`:

```javascript
//= require jquery
//= require jquery_ujs
//= require widget_list
```

Load the assets in the application layout's `<head>`:

```erb
<%= csrf_meta_tags %>
<%= stylesheet_link_tag 'application', 'widget_list', 'widgets' %>
<%= javascript_include_tag 'application', defer: true %>
```

The gem resolves its image URLs through Sprockets when compiling CSS. No manual image copy or static middleware is needed. An app using the default Rails 8 Propshaft pipeline should replace `propshaft` with `sprockets-rails` for this integration. Run `bin/rails assets:precompile` to check production assets.

## Choose a database source

**Active Record only:** `config/widget-list.yml` is optional. The gem uses the current Rails environment's Active Record connection as its primary source. Pass an `ActiveRecord::Relation` as `list['view']`.

**Sequel SQL and Active Record together:** create `config/widget-list.yml` with the Sequel URI as `primary` and the Rails database environment name as `secondary`:

```yaml
development:
  :primary: sqlite://<%= Rails.root.join('storage/development.sqlite3') %>
  :secondary: development
  :api_mode: false
test:
  :primary: sqlite://<%= Rails.root.join('storage/test.sqlite3') %>
  :secondary: test
  :api_mode: false
```

Set `list['database']` to `'primary'` for a SQL table or view name, or `'secondary'` for an Active Record relation. Use the corresponding database file from your app's `config/database.yml`. Only SQLite was exercised during this upgrade; the older examples for PostgreSQL, Oracle, and MongoDB have not been reverified.

## Render a list

The controller must answer GET for the first page and POST for the gem's Ajax controls. For example:

```ruby
# config/routes.rb
match '/items', to: 'items#index', via: [:get, :post]

# app/controllers/items_controller.rb
class ItemsController < ApplicationController
  def index
    list = WidgetList::List.init_config
    list['name'] = 'items'
    list['database'] = 'primary' # omit for the default Active Record source
    list['view'] = 'items'       # use Item.all for Active Record
    list['fields'] = { 'id' => 'ID', 'name' => 'Name', 'sku' => 'SKU' }
    list['searchIdCol'] = ['id', 'sku']
    list['rowLimit'] = 10

    type, output = WidgetList::List.build_list(list)
    case type
    when 'html'   then @output = output
    when 'json'   then render json: JSON.parse(output)
    when 'export' then send_data output, filename: 'items.csv', type: 'text/csv'
    end
  end
end
```

In `app/views/items/index.html.erb`, render `<%= raw @output %>`. Only use trusted values in custom HTML fields and SQL fragments. The gem builds markup and SQL from list configuration.

For Ransack filtering, allowlist searchable model columns and pass both the search object and its relation:

```ruby
class Item < ApplicationRecord
  def self.ransackable_attributes(_auth_object = nil)
    %w[id name sku]
  end
end

search = Item.ransack(params[:q])
list['database'] = 'secondary' # omit if Active Record is primary
list['ransackSearch'] = search
list['view'] = search.result
```

A standard GET URL such as `/items?q[name_cont]=Apple` applies the filter. The gem also renders its advanced Ransack form from `ransackSearch`.

## Try the example

The example installs the published 2.0.0 gem from RubyGems. Clone and run it anywhere:

```sh
git clone https://github.com/davidrenne/widget_list_example_rails8.git
cd widget_list_example_rails8
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails test
bin/rails server
```

Open `http://127.0.0.1:3000/` for Sequel or `/ransack` for Active Record. Search SKU `1001`, change pages, export CSV, or open the filter arrow and set **Name contains Apple**.

## Release

Version 2.0.0 is published. The RubyGems page takes its short summary and longer description from `gem.summary` and `gem.description` in [widget_list.gemspec](widget_list.gemspec). To change them in a future release, bump `WidgetList::VERSION` in `lib/widget_list/version.rb` and publish a new version; published versions cannot be overwritten.

`./checkin_gem.sh` validates and builds the gem, and runs the sibling local-source Rails 8 example tests when present. Review and commit your changes on `main`. Sign in to the command-line publisher with `gem signin` if needed, using an API key with the `push_rubygem` scope. A RubyGems website session does not sign in the `gem` command. Then run `./publish_gem.sh`; it checks that the tree is clean, builds the package, and pushes it to RubyGems.org. RubyGems may prompt for MFA in the terminal or open a browser for WebAuthn. No credential is stored in these scripts. Publishing is a separate, intentional step from committing.

See [RubyGems publishing](https://guides.rubygems.org/publishing/) and [MFA setup](https://guides.rubygems.org/setting-up-otp-mfa/) for account setup.

## Upgrade notes

The migration replaced Rails 3 callbacks and asset middleware, Ruby's removed `URI.decode`, unsafe SQL `eval`, and process-wide request globals. Ransack 5 requires explicit `ransackable_attributes` in each searchable model. The original 2013 administration builder and non-SQLite adapters are still historical code paths; the Rails 8 example verifies the list, Ajax search, pagination, advanced Ransack filtering, CSV export, and asset compilation.
