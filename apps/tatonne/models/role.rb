class Role < ActiveRecord::Base
	has_and_belongs_to_many :acls
	has_and_belongs_to_many :users
end
