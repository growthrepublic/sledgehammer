require 'sidekiq'
require 'typhoeus'
require 'sledgehammer/version'
require 'sledgehammer/models/contact.rb'
require 'sledgehammer/models/page.rb'
require 'sledgehammer/models/website.rb'
require 'sledgehammer/workers/crawl_worker.rb'

module Sledgehammer
end
