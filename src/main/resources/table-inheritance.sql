-- Copyright https://stackoverflow.com/questions/506432/cascading-soft-delete

CREATE TABLE countries (
    id int primary key,
    name text unique,
    deleted_at timestamp
);
CREATE TABLE countries_archive (
    CHECK ( deleted_at IS NOT NULL )
) INHERITS(countries);

CREATE TABLE capitals (
    id int primary key,
    name text,
    country_id int references countries(id) on delete cascade,
    deleted_at timestamp
);
CREATE TABLE capitals_archive (
    CHECK ( deleted_at IS NOT NULL )
) INHERITS(capitals);

CREATE OR REPLACE FUNCTION archive_record()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'UPDATE' AND NEW.deleted_at IS NOT NULL) THEN
        EXECUTE format('DELETE FROM %I.%I WHERE id = $1', TG_TABLE_SCHEMA, TG_TABLE_NAME) USING OLD.id;
        RETURN OLD;
    END IF;
    IF (TG_OP = 'DELETE') THEN
        IF (OLD.deleted_at IS NULL) THEN
            OLD.deleted_at := timenow();
        END IF;
        EXECUTE format('INSERT INTO %I.%I SELECT $1.*'
                    , TG_TABLE_SCHEMA, TG_TABLE_NAME || '_archive')
        USING OLD;
    END IF;
    RETURN NULL;
END;
  $$ LANGUAGE plpgsql;

CREATE TRIGGER soft_delete_countries
    AFTER
        UPDATE OF deleted_at
        OR DELETE
    ON countries
    FOR EACH ROW
    EXECUTE PROCEDURE archive_record();

CREATE TRIGGER soft_delete_capitals
    AFTER
        UPDATE OF deleted_at
        OR DELETE
    ON capitals
    FOR EACH ROW
    EXECUTE PROCEDURE archive_record();

INSERT INTO countries (id, name) VALUES (1, 'France');
INSERT INTO countries (id, name) VALUES (2, 'India');
INSERT INTO capitals VALUES (1, 'Paris', 1);
INSERT INTO capitals VALUES (2, 'Bengaluru', 2);

SELECT 'BEFORE countries' as "info", * FROM ONLY countries;
SELECT 'BEFORE countries_archive' as "info", * FROM countries_archive;
SELECT 'BEFORE capitals' as "info", * FROM ONLY capitals;
SELECT 'BEFORE capitals_archive' as "info", * FROM capitals_archive;

-- Delete one country via hard-DELETE and one via soft-delete
DELETE FROM countries WHERE id = 1;
UPDATE countries SET deleted_at = '2018-12-01' WHERE id = 2;

SELECT 'AFTER countries' as "info", * FROM ONLY countries;
SELECT 'AFTER countries_archive' as "info", * FROM countries_archive;
SELECT 'AFTER capitals' as "info", * FROM ONLY capitals;
SELECT 'AFTER capitals_archive' as "info", * FROM capitals_archive;