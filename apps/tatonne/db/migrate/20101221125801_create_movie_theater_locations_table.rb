class CreateMovieTheaterLocationsTable < ActiveRecord::Migration

	def self.up
		sql  = "CREATE TABLE movie_theater_locations ("
		sql += "id int(11) NOT NULL AUTO_INCREMENT, "
		sql += "movie_theater_id int(11) NOT NULL, "
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
		sql += "CONSTRAINT `fk_movie_theater_locations_movie_theater_id` FOREIGN KEY (movie_theater_id) REFERENCES movie_theaters (id) ON DELETE CASCADE "
		sql += ") ENGINE=InnoDB DEFAULT CHARSET=utf8"
		ActiveRecord::Base.connection.execute(sql)

		sql  = "CREATE TRIGGER trg_insert_movie_theater_locations "
		sql += "BEFORE INSERT ON movie_theater_locations "
		sql += "FOR EACH ROW "
		sql += "SET NEW.created_at = CURRENT_TIMESTAMP"
		ActiveRecord::Base.connection.execute(sql)
	end

	def self.down
		sql = "DROP TRIGGER trg_insert_movie_theater_locations"
		ActiveRecord::Base.connection.execute(sql)

		sql = "DROP TABLE movie_theater_locations"
		ActiveRecord::Base.connection.execute(sql)
	end

end
