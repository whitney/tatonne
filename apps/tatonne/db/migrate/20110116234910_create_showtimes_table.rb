class CreateShowtimesTable < ActiveRecord::Migration

	def self.up
		sql  = "CREATE TABLE showtimes ("
		sql += "id int(11) NOT NULL AUTO_INCREMENT, "
		sql += "movie_theater_location_id int(11) NOT NULL, "
		sql += "movie_id int(11) NOT NULL, "
		sql += "showtime DATETIME NOT NULL,"
		sql += "created_at timestamp NOT NULL DEFAULT '0000-00-00 00:00:00', "
		sql += "updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, "
		sql += "creator_id int(11) DEFAULT NULL, "
		sql += "updater_id int(11) DEFAULT NULL, "
		sql += "PRIMARY KEY (id), "
		sql += "CONSTRAINT `fk_showtimes_movie_theater_location_id` FOREIGN KEY (movie_theater_location_id) REFERENCES movie_theater_locations (id) ON DELETE CASCADE, "
		sql += "CONSTRAINT `fk_showtimes_movie_id` FOREIGN KEY (movie_id) REFERENCES movies (id) ON DELETE CASCADE "
		#sql += ", UNIQUE KEY `theater_movie_showtime` (movie_theater_location_id, movie_id, showtime)"
		sql += ") ENGINE=InnoDB DEFAULT CHARSET=utf8"
		ActiveRecord::Base.connection.execute(sql)

		sql  = "CREATE TRIGGER trg_insert_showtimes "
		sql += "BEFORE INSERT ON showtimes "
		sql += "FOR EACH ROW "
		sql += "SET NEW.created_at = CURRENT_TIMESTAMP"
		ActiveRecord::Base.connection.execute(sql)

	end

	def self.down
		sql = "DROP TRIGGER trg_insert_showtimes"
		ActiveRecord::Base.connection.execute(sql)

		sql = "DROP TABLE showtimes"
		ActiveRecord::Base.connection.execute(sql)
	end

end
