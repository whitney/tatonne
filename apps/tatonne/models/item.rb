class Item < ActiveRecord::Base
	belongs_to :merchant
	belongs_to :product
	belongs_to :merchant_location
end
