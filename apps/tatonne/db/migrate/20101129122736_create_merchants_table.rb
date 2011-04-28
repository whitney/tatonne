class CreateMerchantsTable < ActiveRecord::Migration

	def self.up
		sql  = "CREATE TABLE merchants ("
		sql += "id int(11) NOT NULL AUTO_INCREMENT, "
		sql += "admin_id int(11) NOT NULL, "
		sql += "name varchar(255) DEFAULT NULL, "
		sql += "description text DEFAULT NULL, "
		sql += "domain_url varchar(255) DEFAULT NULL, "
		sql += "merchant_type_id int(11) NOT NULL, "
		sql += "created_at timestamp NOT NULL DEFAULT '0000-00-00 00:00:00', "
		sql += "updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, "
		sql += "creator_id int(11) DEFAULT NULL, "
		sql += "updater_id int(11) DEFAULT NULL, "
		sql += "PRIMARY KEY (id), "
		sql += "CONSTRAINT `fk_merchants_admin_id` FOREIGN KEY (admin_id) REFERENCES users (id) ON DELETE CASCADE, "
		sql += "CONSTRAINT `fk_merchants_merchant_type_id` FOREIGN KEY (merchant_type_id) REFERENCES merchant_types (id) ON DELETE CASCADE, "
		sql += "INDEX idx_merchants_admin_id_merchant_type_id (admin_id, merchant_type_id)"
		sql += ") ENGINE=InnoDB DEFAULT CHARSET=utf8"
		ActiveRecord::Base.connection.execute(sql)

		# created_at trigger
		sql  = "CREATE TRIGGER trg_insert_merchants "
		sql += "BEFORE INSERT ON merchants "
		sql += "FOR EACH ROW "
		sql += "BEGIN "
		sql += "SET NEW.created_at = NOW();"
		sql += "SET NEW.updated_at = NOW();"
		sql += "END"
		ActiveRecord::Base.connection.execute(sql)
	end

	def self.down
		sql = "DROP TRIGGER trg_insert_merchants"
		ActiveRecord::Base.connection.execute(sql)

		sql = "DROP TABLE merchants"
		ActiveRecord::Base.connection.execute(sql)
	end

end
