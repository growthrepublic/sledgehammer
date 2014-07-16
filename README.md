# Sledgehammer [![Gem Version](https://badge.fury.io/rb/sledgehammer.svg)](http://badge.fury.io/rb/sledgehammer) [![Build Status](https://travis-ci.org/growthrepublic/sledgehammer.svg?branch=master)](https://travis-ci.org/growthrepublic/sledgehammer) [![Code Climate](https://codeclimate.com/github/growthrepublic/sledgehammer.png)](https://codeclimate.com/github/growthrepublic/sledgehammer)

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

Run sidekiq worker from your code:


```ruby
Sledgehammer::CrawlWorker.perform_async ARRAY_OF_URLS, [OPTIONS]
```

Here is sample usage:

```ruby
Sledgehammer::CrawlWorker.perform_async ['http://example.com'], { depth_limit: 3 }
```

Available options are:

- `depth_limit` - limit how far into the website the crawler should go; **1** means only the first page will be crawled.
- `depth` - this is used internally to know the depth level of crawling and should never be set by hand except in tests

## Extending Sledgehammer in your application

Sledgehammer is pretty rudimentary and does not allow much functionality at this point. 
That's why we've created a set of simple callbacks that you can overwrite in your application,
for example when you plan to group found pages into groups or filter the URL list.

There are many ways to override the behaviour of a callback. The simplest one is to create a file
in your `lib/` directory and create a module that will be mixed into `Sledgehammer::CrawlWorker`:

```ruby
module OnlyPolishWebsites
  extend ActiveSupport::Concern

  included do
    def on_queue(url)
      url ~= /\.pl$/
    end
  end
end

Sledgehammer::CrawlWorker.include OnlyPolishWebsites
```

There are 3 methods you should ever need to overwrite, and one that should rather be chained than overwritten:

- `before_queue(LIST_OF_URLS)`
- `on_queue(ONE_URL)`
- `after_queue(LIST_OF_URLS)`
- `on_complete(TYPHOEUS_RESPONSE_OBJECT)` - this method executes further crawling, email parsing and saving a new `Sledgehammer::Page` model so be careful if you decide to overwrite it!

You can also access options that were passed to `Sledgehammer::CrawlWorker` with `@options` ivar.

If the need arises in the future, we will add more robust way of adding callbacks and modyfing 
Sledgehammer behaviour (#4), but for now this was more than enough for our needs. 

## Contributors

- [Michał Matyas] (https://github.com/d4rky-pl)
- [rabsztok](https://github.com/rabsztok)

## License

Sledgehammer is Copyright © 2014 Growth Republic. It is free software, and may be redistributed under the terms specified in the LICENSE file.
