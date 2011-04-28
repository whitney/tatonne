class AddActiveAndPerishableTokenToUsers < ActiveRecord::Migration

	def self.up
		sql  = "ALTER TABLE users "
		sql += "ADD COLUMN active tinyint(1) DEFAULT 0 "
		sql += "AFTER last_name"
		ActiveRecord::Base.connection.execute(sql)

		sql  = "ALTER TABLE users "
		sql += "ADD COLUMN perishable_token varchar(255) DEFAULT NULL "
		sql += "AFTER persistence_token"
		ActiveRecord::Base.connection.execute(sql)

		sql  = "ALTER TABLE users "
		sql += "ADD INDEX idx_users_perishable_token (perishable_token)"
		ActiveRecord::Base.connection.execute(sql)
	end

	def self.down
		sql  = "ALTER TABLE users "
		sql += "DROP COLUMN active"
		ActiveRecord::Base.connection.execute(sql)

		sql  = "ALTER TABLE users "
		sql += "DROP INDEX idx_users_perishable_token"
		ActiveRecord::Base.connection.execute(sql)

		sql  = "ALTER TABLE users "
		sql += "DROP COLUMN perishable_token"
		ActiveRecord::Base.connection.execute(sql)
	end

end
