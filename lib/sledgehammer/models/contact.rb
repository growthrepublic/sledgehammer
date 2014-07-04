class Sledgehammer::Contact < ActiveRecord::Base
  has_many :page_contacts
  has_many :pages, through: :page_contacts

  validates :email, uniqueness: true
end
