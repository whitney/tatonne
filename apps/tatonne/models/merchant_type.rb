class MerchantType < ActiveRecord::Base
	has_many :merchants

	validates_presence_of :name
	validates_presence_of :code
end
