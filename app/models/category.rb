class Category < ActiveRecord::Base
  has_many :products, primary_key: 'ecwid_id', foreign_key: 'ecwid_catrgory_id'
end
