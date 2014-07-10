# Sledgehammer

Sledgehammer is a gem which allows to crawl websites in search of email addresses.
It uses Typhoeus and Sidekiq to spawn ultra-fast workers which gathers data in no-time.

## Installation

Include the gem in your Gemfile

```ruby
gem "sledgehammer"
```

Bundle the Gemfile

```ruby
bundle install
```

Run the install script which will create a migration file and a config file.

```ruby
bundle exec rails generate sledgehammer:install
```

Migrate your database

```ruby
bundle exec rake db:migrate
```

## Setup

You should be aware of using this gem with application with sqlite3 database.
Due to multi threaded nature of gem you will be greeted with "SQLite3::BusyException: database is locked" errors.
PostgreSQL, MySQL or MongoDB should be just fine.

## Usage

Run sidekiq worker form your code:


```ruby
Sledgehammer::CrawlWorker.perform_async ARRAY_OF_URLS, [OPTIONS]
```

Here is sample usage:

```ruby
Sledgehammer::CrawlWorker.perform_async ['http://example.com'], { depth_limit: 3 }
```

## Contributors

[d4rky-pl] (https://github.com/d4rky-pl)

[rabsztok](https://github.com/rabsztok)

## License

Sledgehammer is Copyright © 2014 Growth Republic. It is free software, and may be redistributed under the terms specified in the LICENSE file.
