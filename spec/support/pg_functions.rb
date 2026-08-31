# frozen_string_literal: true

# schema.rb does not capture custom SQL functions created with `execute`.
# In CI, `db:prepare` uses schema:load, so immutable_unaccent (created by
# migration 20260708000001) never exists. Create it here for test env.
ActiveRecord::Base.connection.execute(<<~SQL)
  CREATE OR REPLACE FUNCTION immutable_unaccent(text)
  RETURNS text AS $$
    SELECT public.unaccent($1)
  $$ LANGUAGE sql IMMUTABLE;
SQL
