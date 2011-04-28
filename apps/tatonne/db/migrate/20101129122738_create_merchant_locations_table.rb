class CreateMerchantLocationsTable < ActiveRecord::Migration

	def self.up
		sql  = "CREATE TABLE merchant_locations ("
		sql += "id int(11) NOT NULL AUTO_INCREMENT, "
		sql += "merchant_id int(11) NOT NULL, "
		sql += "address_1 varchar(255) DEFAULT NULL, "
		sql += "address_2 varchar(255) DEFAULT NULL, "
		sql += "city varchar(255) DEFAULT NULL, "
		sql += "state varchar(255) DEFAULT NULL, "
		sql += "postal_code varchar(255) DEFAULT NULL, "
		sql += "country varchar(255) DEFAULT NULL, "
		sql += "latitude float DEFAULT NULL, "
		sql += "longitude float DEFAULT NULL, "
		sql += "created_at timestamp NOT NULL DEFAULT '0000-00-00 00:00:00', "
		sql += "updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, "
		sql += "creator_id int(11) DEFAULT NULL, "
		sql += "updater_id int(11) DEFAULT NULL, "
		sql += "PRIMARY KEY (id), "
		sql += "CONSTRAINT `fk_merchant_locations_merchant_id` FOREIGN KEY (merchant_id) REFERENCES merchants (id) ON DELETE CASCADE "
		sql += ") ENGINE=InnoDB DEFAULT CHARSET=utf8"
		ActiveRecord::Base.connection.execute(sql)

		# created_at trigger
		sql  = "CREATE TRIGGER trg_insert_merchant_locations "
		sql += "BEFORE INSERT ON merchant_locations "
		sql += "FOR EACH ROW "
		sql += "BEGIN "
		sql += "SET NEW.created_at = NOW();"
		sql += "SET NEW.updated_at = NOW();"
		sql += "END"
		ActiveRecord::Base.connection.execute(sql)
	end

	def self.down
		sql = "DROP TRIGGER trg_insert_merchant_locations"
		ActiveRecord::Base.connection.execute(sql)

		sql = "DROP TABLE merchant_locations"
		ActiveRecord::Base.connection.execute(sql)
	end

end
