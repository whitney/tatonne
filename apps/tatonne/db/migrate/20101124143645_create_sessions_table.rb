class CreateSessionsTable < ActiveRecord::Migration

	def self.up
		sql  = "CREATE TABLE sessions ("
		sql += "id int(11) NOT NULL AUTO_INCREMENT, "
		sql += "session_id varchar(255) NOT NULL, "
		sql += "data text DEFAULT NULL, "
		sql += "created_at timestamp NOT NULL DEFAULT '0000-00-00 00:00:00', "
		sql += "updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, "
		sql += "PRIMARY KEY (id), "
		sql += "UNIQUE KEY uk_sessions_session_id (session_id)"
		sql += ") ENGINE=InnoDB DEFAULT CHARSET=utf8"
		ActiveRecord::Base.connection.execute(sql)

		# created_at trigger
		sql  = "CREATE TRIGGER trg_insert_sessions "
		sql += "BEFORE INSERT ON sessions "
		sql += "FOR EACH ROW "
		sql += "BEGIN "
		sql += "SET NEW.created_at = NOW();"
		sql += "SET NEW.updated_at = NOW();"
		sql += "END"
		ActiveRecord::Base.connection.execute(sql)
	end

	def self.down
		sql = "DROP TRIGGER trg_insert_sessions"
		ActiveRecord::Base.connection.execute(sql)

		sql = "DROP TABLE sessions"
		ActiveRecord::Base.connection.execute(sql)
	end
end
