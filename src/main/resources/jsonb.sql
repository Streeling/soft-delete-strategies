-- Copyright https://postgres.fm/episodes/soft-delete
-- https://brandur.org/fragments/deleted-record-insert

CREATE TABLE deleted_record (
    id uuid PRIMARY KEY DEFAULT gen_ulid(),
    data jsonb NOT NULL,
    deleted_at timestamptz NOT NULL DEFAULT current_timestamp,
    object_id uuid NOT NULL,
    table_name varchar(200) NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT current_timestamp
);

CREATE FUNCTION deleted_record_insert() RETURNS trigger
    LANGUAGE plpgsql
AS $$
    BEGIN
        EXECUTE 'INSERT INTO deleted_record (data, object_id, table_name) VALUES ($1, $2, $3)'
        USING to_jsonb(OLD.*), OLD.id, TG_TABLE_NAME;

        RETURN OLD;
    END;
$$;

CREATE TRIGGER deleted_record_insert AFTER DELETE ON credit
    FOR EACH ROW EXECUTE FUNCTION deleted_record_insert();
CREATE TRIGGER deleted_record_insert AFTER DELETE ON discount
    FOR EACH ROW EXECUTE FUNCTION deleted_record_insert();
CREATE TRIGGER deleted_record_insert AFTER DELETE ON invoice
    FOR EACH ROW EXECUTE FUNCTION deleted_record_insert();


