class AddDefaultToMovieTheaterLocationsTable < ActiveRecord::Migration

	def self.up
		sql  = "ALTER TABLE movie_theater_locations "
		sql += "ADD COLUMN `default` tinyint(1) DEFAULT NULL "
		sql += "AFTER longitude"
		ActiveRecord::Base.connection.execute(sql)
	end

	def self.down
		sql  = "ALTER TABLE movie_theater_locations "
		sql += "DROP COLUMN `default`"
		ActiveRecord::Base.connection.execute(sql)
	end

end
