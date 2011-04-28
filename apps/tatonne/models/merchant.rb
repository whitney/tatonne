class Merchant < ActiveRecord::Base
	belongs_to :merchant_type
	has_many :merchant_locations

	validates_presence_of :name
end
