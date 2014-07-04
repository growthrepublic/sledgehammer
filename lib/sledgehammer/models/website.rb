class Sledgehammer::Website < ActiveRecord::Base
  has_many :pages
  has_many :contacts, through: :pages
end
