-- Copyright https://github.com/arkhipov/temporal_tables

-- Install extension
CREATE EXTENSION temporal_tables;

-- Create a table
CREATE TABLE employees
(
  name text NOT NULL PRIMARY KEY,
  department text,
  salary numeric(20, 2)
);

-- Then
ALTER TABLE employees ADD COLUMN sys_period tstzrange NOT NULL;

CREATE TABLE employees_history (LIKE employees);

CREATE TRIGGER versioning_trigger
BEFORE INSERT OR UPDATE OR DELETE ON employees
FOR EACH ROW EXECUTE PROCEDURE versioning('sys_period',
                                          'employees_history',
                                          true);