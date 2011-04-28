class CreateAclsTable < ActiveRecord::Migration

	def self.up
		sql  = "CREATE TABLE acls ("
		sql += "id int(11) NOT NULL AUTO_INCREMENT, "
		sql += "name varchar(255) NOT NULL, "
		sql += "created_at timestamp NOT NULL DEFAULT '0000-00-00 00:00:00', "
		sql += "updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, "
		sql += "creator_id int(11) DEFAULT NULL, "
		sql += "updater_id int(11) DEFAULT NULL, "
		sql += "PRIMARY KEY (id), "
		sql += "UNIQUE KEY `uk_acls_name` (name) "
		sql += ") ENGINE=InnoDB DEFAULT CHARSET=utf8"
		ActiveRecord::Base.connection.execute(sql)

		# created_at trigger
		sql  = "CREATE TRIGGER trg_insert_acls "
		sql += "BEFORE INSERT ON acls "
		sql += "FOR EACH ROW "
		sql += "BEGIN "
		sql += "SET NEW.created_at = NOW();"
		sql += "SET NEW.updated_at = NOW();"
		sql += "END"
		ActiveRecord::Base.connection.execute(sql)
	end

	def self.down
		sql = "DROP TRIGGER trg_insert_acls"
		ActiveRecord::Base.connection.execute(sql)

		sql = "DROP TABLE acls"
		ActiveRecord::Base.connection.execute(sql)
	end

end
