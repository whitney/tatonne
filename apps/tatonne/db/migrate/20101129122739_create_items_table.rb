class CreateItemsTable < ActiveRecord::Migration

	def self.up
		sql  = "CREATE TABLE items ("
		sql += "id int(11) NOT NULL AUTO_INCREMENT, "
		sql += "merchant_id int(11) NOT NULL, "
		sql += "product_id int(11) NOT NULL, "
		sql += "merchant_location_id int(11) DEFAULT NULL, "
		sql += "current_count int(11) DEFAULT NULL, "
		sql += "max_count int(11) DEFAULT NULL, "
		sql += "created_at timestamp NOT NULL DEFAULT '0000-00-00 00:00:00', "
		sql += "updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, "
		sql += "creator_id int(11) DEFAULT NULL, "
		sql += "updater_id int(11) DEFAULT NULL, "
		sql += "PRIMARY KEY (id), "
		# a merchant can only have one item record per product per location (hence the aggregated count columns)
		sql += "UNIQUE KEY `uk_items_merchant_product_merchant_location` (merchant_id, product_id, merchant_location_id), "
		sql += "CONSTRAINT `fk_items_merchant_id` FOREIGN KEY (merchant_id) REFERENCES merchants (id) ON DELETE CASCADE, "
		sql += "CONSTRAINT `fk_items_product_id` FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE, "
		sql += "CONSTRAINT `fk_items_merchant_location_id` FOREIGN KEY (merchant_location_id) REFERENCES merchant_locations (id) ON DELETE CASCADE "
		sql += ") ENGINE=InnoDB DEFAULT CHARSET=utf8"
		ActiveRecord::Base.connection.execute(sql)

		# created_at trigger
		sql  = "CREATE TRIGGER trg_insert_items "
		sql += "BEFORE INSERT ON items "
		sql += "FOR EACH ROW "
		sql += "BEGIN "
		sql += "SET NEW.created_at = NOW();"
		sql += "SET NEW.updated_at = NOW();"
		sql += "END"
		ActiveRecord::Base.connection.execute(sql)
	end

	def self.down
		sql = "DROP TRIGGER trg_insert_items"
		ActiveRecord::Base.connection.execute(sql)

		sql = "DROP TABLE items"
		ActiveRecord::Base.connection.execute(sql)
	end

end
