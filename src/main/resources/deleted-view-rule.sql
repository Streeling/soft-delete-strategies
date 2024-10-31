-- Copyright https://evilmartians.com/chronicles/soft-deletion-with-postgresql-but-with-logic-on-the-database

-- https://gist.github.com/nepalez/beeae949356dbb4394ffc2352ee1530e

CREATE TABLE users (
  id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name text NOT NULL
);

CREATE TABLE orders (
  id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id integer NOT NULL,
  number text NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

--
ALTER TABLE users ADD COLUMN deleted boolean NOT NULL DEFAULT false;
ALTER TABLE orders ADD COLUMN deleted boolean NOT NULL DEFAULT false;

--
CREATE RULE "_soft_deletion" AS ON DELETE TO "orders" DO INSTEAD (
  UPDATE orders SET deleted = true WHERE id = old.id AND NOT deleted
);

CREATE RULE "_soft_deletion" AS ON DELETE TO "users" DO INSTEAD (
  UPDATE users SET deleted = true WHERE id = old.id AND NOT deleted
);

CREATE RULE "_delete_orders" AS ON UPDATE TO users
  WHERE NOT old.deleted AND new.deleted
  DO ALSO UPDATE orders SET deleted = true WHERE user_id = old.id;

--
ALTER SETTINGS SET rules.soft_deletion TO on;

CREATE OR REPLACE RULE "_soft_deletion"
  AS ON DELETE TO "orders"
  WHERE current_setting('rules.soft_deletion') = 'on'
  DO INSTEAD UPDATE orders SET deleted = true WHERE id = old.id;

--
SET rules.soft_deletion TO off;
DELETE FROM orders WHERE id = 5;
SELECT * FROM orders ORDER BY id;

--
ALTER TABLE orders RENAME TO _orders;
CREATE VIEW orders AS SELECT * FROM _orders WHERE NOT deleted;

ALTER TABLE users RENAME TO _users;
CREATE VIEW users AS SELECT * FROM _users WHERE deleted IS NULL OR NOT deleted;

ALTER TABLE orders RENAME TO _orders;
CREATE VIEW orders AS SELECT * FROM _orders WHERE deleted IS NULL OR NOT deleted;

CREATE RULE _soft_deletion AS ON DELETE TO orders DO INSTEAD (
  UPDATE _orders SET deleted = true WHERE id = old.id
);

CREATE RULE _soft_deletion AS ON DELETE TO users DO INSTEAD (
  UPDATE _users SET deleted = true WHERE id = old.id
);

-- here we deal with updates in _users table, not with a view
CREATE RULE _delete_orders AS ON UPDATE TO _users
  WHERE old.deleted IS NULL OR NOT old.deleted AND new.deleted
  DO ALSO UPDATE _orders SET deleted = true WHERE user_id = old.id;