class CreateRolesUsersTable < ActiveRecord::Migration

	def self.up
		sql  = "CREATE TABLE roles_users ("
		sql += "user_id int(11) NOT NULL, "
		sql += "role_id int(11) NOT NULL, "
		sql += "created_at timestamp NOT NULL DEFAULT '0000-00-00 00:00:00', "
		sql += "updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, "
		sql += "PRIMARY KEY (user_id, role_id), "
		sql += "CONSTRAINT `fk_roles_users_user_id` FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE, "
		sql += "CONSTRAINT `fk_roles_users_role_id` FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE CASCADE "
		sql += ") ENGINE=InnoDB DEFAULT CHARSET=utf8"
		ActiveRecord::Base.connection.execute(sql)

		# created_at trigger
		sql  = "CREATE TRIGGER trg_insert_roles_users "
		sql += "BEFORE INSERT ON roles_users "
		sql += "FOR EACH ROW "
		sql += "BEGIN "
		sql += "SET NEW.created_at = NOW();"
		sql += "SET NEW.updated_at = NOW();"
		sql += "END"
		ActiveRecord::Base.connection.execute(sql)
	end

	def self.down
		sql = "DROP TRIGGER trg_insert_roles_users"
		ActiveRecord::Base.connection.execute(sql)

		sql = "DROP TABLE roles_users"
		ActiveRecord::Base.connection.execute(sql)
	end

end
