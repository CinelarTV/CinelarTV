# frozen_string_literal: true

class MigrateSeasonsToUuid < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    # 1. Add uuid column to seasons
    add_column :seasons, :uuid, :uuid, default: -> { "gen_random_uuid()" }, null: false

    # 2. Add temporary season_uuid column to episodes
    add_column :episodes, :season_uuid, :uuid

    # 3. Copy data: season.uuid -> episodes.season_uuid
    execute <<-SQL.squish
      UPDATE episodes
      SET season_uuid = seasons.uuid
      FROM seasons
      WHERE episodes.season_id = seasons.id
    SQL

    # 4. Remove old FK, indexes, and season_id column from episodes
    remove_foreign_key :episodes, :seasons
    remove_index :episodes, [:season_id, :position]
    remove_index :episodes, [:season_id]
    remove_column :episodes, :season_id

    # 5. Rename season_uuid -> season_id in episodes
    rename_column :episodes, :season_uuid, :season_id
    change_column_null :episodes, :season_id, false
    add_index :episodes, [:season_id, :position]
    add_index :episodes, [:season_id]

    # 6. In seasons: remove old bigint id, rename uuid -> id, make primary key
    execute "ALTER TABLE seasons DROP CONSTRAINT IF EXISTS seasons_pkey"
    remove_column :seasons, :id
    rename_column :seasons, :uuid, :id
    execute "ALTER TABLE seasons ADD PRIMARY KEY (id)"

    # 7. Now add FK (both sides are uuid)
    add_foreign_key :episodes, :seasons
  end

  def down
    # Reverse: add bigint id back to seasons
    execute "ALTER TABLE seasons ADD COLUMN id bigserial PRIMARY KEY"

    # Add temporary old_id column to episodes
    add_column :episodes, :old_season_id, :bigint

    execute <<-SQL.squish
      UPDATE episodes
      SET old_season_id = seasons.id
      FROM seasons
      WHERE episodes.season_id = seasons.id
    SQL

    # Remove FK and uuid season_id from episodes
    remove_foreign_key :episodes, :seasons
    remove_index :episodes, [:season_id, :position]
    remove_index :episodes, [:season_id]
    remove_column :episodes, :season_id
    rename_column :episodes, :old_season_id, :season_id
    add_index :episodes, [:season_id, :position]
    add_index :episodes, [:season_id]
    add_foreign_key :episodes, :seasons

    # Remove uuid column from seasons
    remove_column :seasons, :uuid
  end
end
