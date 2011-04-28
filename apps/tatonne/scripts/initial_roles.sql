SET @me := (SELECT id FROM users WHERE email = 'whitney@tatonne.com');

INSERT INTO roles (name, created_at, updated_at, creator_id, updater_id) VALUES('admin', NOW(), NOW(), @me, @me);
INSERT INTO roles (name, created_at, updated_at, creator_id, updater_id) VALUES('buyer', NOW(), NOW(), @me, @me);
INSERT INTO roles (name, created_at, updated_at, creator_id, updater_id) VALUES('merchant', NOW(), NOW(), @me, @me);

SET @admin_role := (SELECT id FROM roles WHERE name = 'admin');
INSERT INTO roles_users (user_id, role_id, created_at, updated_at) VALUES(@me, @admin_role, NOW(), NOW());
