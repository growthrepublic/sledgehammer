require 'rails/generators/base'

module Sledgehammer
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../../../../', __FILE__)

      def generate_migrations
        copy_file "db/migrate/20140626075744_create_pages.rb"
        copy_file "db/migrate/20140626080142_create_contacts.rb"
        copy_file "db/migrate/20140626105612_create_websites.rb"
        copy_file "db/migrate/20140704070249_create_page_contacts.rb"
      end
    end
  end
end
