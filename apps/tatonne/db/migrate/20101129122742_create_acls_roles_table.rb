class CreateAclsRolesTable < ActiveRecord::Migration

	def self.up
		sql  = "CREATE TABLE acls_roles ("
		sql += "acl_id int(11) NOT NULL, "
		sql += "role_id int(11) NOT NULL, "
		sql += "created_at timestamp NOT NULL DEFAULT '0000-00-00 00:00:00', "
		sql += "updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, "
		sql += "PRIMARY KEY (acl_id, role_id), "
		sql += "CONSTRAINT `fk_acls_roles_acl_id` FOREIGN KEY (acl_id) REFERENCES acls (id) ON DELETE CASCADE, "
		sql += "CONSTRAINT `fk_acls_roles_role_id` FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE CASCADE "
		sql += ") ENGINE=InnoDB DEFAULT CHARSET=utf8"
		ActiveRecord::Base.connection.execute(sql)

		# created_at trigger
		sql  = "CREATE TRIGGER trg_insert_acls_roles "
		sql += "BEFORE INSERT ON acls_roles "
		sql += "FOR EACH ROW "
		sql += "BEGIN "
		sql += "SET NEW.created_at = NOW();"
		sql += "SET NEW.updated_at = NOW();"
		sql += "END"
		ActiveRecord::Base.connection.execute(sql)
	end

	def self.down
		sql = "DROP TRIGGER trg_insert_acls_roles"
		ActiveRecord::Base.connection.execute(sql)

		sql = "DROP TABLE acls_roles"
		ActiveRecord::Base.connection.execute(sql)
	end

end
