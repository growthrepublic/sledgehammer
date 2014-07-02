class Sledgehammer::Page < ActiveRecord::Base
  belongs_to :website
  has_many :contacts
  before_create :create_website!

  protected
  def create_website!
    hostname = URI.parse(url).host
    self.website = Sledgehammer::Website.find_or_create_by(hostname: hostname)
  end
end
