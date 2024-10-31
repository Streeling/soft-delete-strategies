-- Copyright https://www.crunchydata.com/blog/row-level-security-for-tenants-in-postgres

CREATE TABLE organization (
    org_id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(255) UNIQUE,
    created_at TIMESTAMPTZ default now(),
    deleted_at TIMESTAMPTZ default now(),
);

CREATE TABLE events (
  org_id UUID,
  event_type TEXT,
  event_value INT,
  occurred_at TIMESTAMPTZ default now(),
);

-- Turn on RLS
ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- Set policy
CREATE POLICY event_isolation_policy
  ON events
  USING (org_id::TEXT = current_user);

-- or
CREATE POLICY event_session_user
  ON events
  TO application
  USING (org_id = NULLIF(current_setting('rls.org_id', TRUE), '')::uuid);

