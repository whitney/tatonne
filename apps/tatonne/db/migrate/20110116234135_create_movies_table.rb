class CreateMoviesTable < ActiveRecord::Migration

	def self.up
		sql  = "CREATE TABLE movies ("
		sql += "id int(11) NOT NULL AUTO_INCREMENT, "
		sql += "name varchar(255) DEFAULT NULL, "
		sql += "created_at timestamp NOT NULL DEFAULT '0000-00-00 00:00:00', "
		sql += "updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, "
		sql += "creator_id int(11) DEFAULT NULL, "
		sql += "updater_id int(11) DEFAULT NULL, "
		sql += "PRIMARY KEY (id) "
		sql += ") ENGINE=InnoDB DEFAULT CHARSET=utf8"
		ActiveRecord::Base.connection.execute(sql)

		sql  = "CREATE TRIGGER trg_insert_movies "
		sql += "BEFORE INSERT ON movies "
		sql += "FOR EACH ROW "
		sql += "BEGIN "
		sql += "SET NEW.created_at = NOW();"
		sql += "END"
		ActiveRecord::Base.connection.execute(sql)
	end

	def self.down
		sql = "DROP TRIGGER trg_insert_movies"
		ActiveRecord::Base.connection.execute(sql)

		sql = "DROP TABLE movies"
		ActiveRecord::Base.connection.execute(sql)
	end

end
