class Product < ActiveRecord::Base
	belongs_to :product_type

	validates_presence_of :name
end
