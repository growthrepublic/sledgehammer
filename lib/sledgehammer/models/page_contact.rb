class Sledgehammer::PageContact < ActiveRecord::Base
  belongs_to :page
  belongs_to :contact
end
