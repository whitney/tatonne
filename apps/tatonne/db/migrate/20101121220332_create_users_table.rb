class CreateUsersTable < ActiveRecord::Migration

	def self.up
		sql  = "CREATE TABLE users ("
		sql += "id int(11) NOT NULL AUTO_INCREMENT, "
		sql += "email varchar(255) DEFAULT NULL, "
		sql += "crypted_password varchar(255) DEFAULT NULL, "
		sql += "password_salt varchar(255) DEFAULT NULL, "
		sql += "persistence_token VARCHAR(255) NOT NULL, "
		sql += "first_name varchar(255) DEFAULT NULL, "
		sql += "last_name varchar(255) DEFAULT NULL, "
		sql += "created_at timestamp NOT NULL DEFAULT '0000-00-00 00:00:00', "
		sql += "updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, "
		sql += "creator_id int(11) DEFAULT NULL, "
		sql += "updater_id int(11) DEFAULT NULL, "
		sql += "PRIMARY KEY (id), "
		sql += "UNIQUE KEY uk_users_email (email)"
		sql += ") ENGINE=InnoDB DEFAULT CHARSET=utf8"
		ActiveRecord::Base.connection.execute(sql)

		sql  = "ALTER TABLE users "
		sql += "ADD INDEX idx_users_persistence_token (persistence_token)"
		ActiveRecord::Base.connection.execute(sql)

		# created_at trigger
		sql  = "CREATE TRIGGER trg_insert_users "
		sql += "BEFORE INSERT ON users "
		sql += "FOR EACH ROW "
		sql += "BEGIN "
		sql += "SET NEW.created_at = NOW();"
		sql += "SET NEW.updated_at = NOW();"
		sql += "END"
		ActiveRecord::Base.connection.execute(sql)
	end

	def self.down
		sql = "DROP TRIGGER trg_insert_users"
		ActiveRecord::Base.connection.execute(sql)

		sql = "DROP TABLE users"
		ActiveRecord::Base.connection.execute(sql)
	end

end
