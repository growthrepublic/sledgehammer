require File.expand_path('../support/active_record_helper', __FILE__)
require File.expand_path('../../lib/sledgehammer.rb', __FILE__)

RSpec.configure do |config|
  config.before :each do
    Typhoeus::Expectation.clear
  end
end
