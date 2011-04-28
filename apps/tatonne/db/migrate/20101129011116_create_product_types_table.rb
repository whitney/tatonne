class CreateProductTypesTable < ActiveRecord::Migration

	def self.up
		sql  = "CREATE TABLE product_types ("
		sql += "id int(11) NOT NULL AUTO_INCREMENT, "
		sql += "name varchar(32) DEFAULT NULL, "
		sql += "code varchar(8) DEFAULT NULL, "
		sql += "description varchar(255) DEFAULT NULL, "
		sql += "created_at timestamp NOT NULL DEFAULT '0000-00-00 00:00:00', "
		sql += "updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, "
		sql += "PRIMARY KEY (id), "
		sql += "UNIQUE KEY uk_product_types_name (name), "
		sql += "UNIQUE KEY uk_product_types_code (code) "
		sql += ") ENGINE=InnoDB DEFAULT CHARSET=utf8"
		ActiveRecord::Base.connection.execute(sql)

		# created_at trigger
		sql  = "CREATE TRIGGER trg_insert_product_types "
		sql += "BEFORE INSERT ON product_types "
		sql += "FOR EACH ROW "
		sql += "BEGIN "
		sql += "SET NEW.created_at = NOW();"
		sql += "SET NEW.updated_at = NOW();"
		sql += "END"
		ActiveRecord::Base.connection.execute(sql)
	end

	def self.down
		sql = "DROP TRIGGER trg_insert_product_types"
		ActiveRecord::Base.connection.execute(sql)

		sql = "DROP TABLE product_types"
		ActiveRecord::Base.connection.execute(sql)
	end

end
