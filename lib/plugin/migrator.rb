# frozen_string_literal: true

module Plugin
  # Manages plugin database migrations separately from core migrations.
  #
  # Plugin migrations are NOT included in schema.rb, so new installations
  # using `db:schema:load` won't fail on missing plugin tables. Instead,
  # plugin migrations are tracked in a dedicated `plugin_schema_versions`
  # table and run via `bin/rails plugin:migrate`.
  #
  # Inspired by Discourse's approach to plugin migration management.
  class Migrator
    SCHEMA_VERSION_TABLE = "plugin_schema_versions"

    class << self
      def ensure_table!
        return if ActiveRecord::Base.connection.table_exists?(SCHEMA_VERSION_TABLE)

        ActiveRecord::Base.connection.create_table(SCHEMA_VERSION_TABLE) do |t|
          t.string   :plugin_name, null: false
          t.string   :version,     null: false
          t.datetime :created_at,  null: false
        end

        ActiveRecord::Base.connection.add_index(
          SCHEMA_VERSION_TABLE,
          [:plugin_name, :version],
          unique: true,
          name: "idx_plugin_schema_versions_unique"
        )
      end

      def migrate!(plugin_name = nil)
        ensure_table!

        plugins = if plugin_name
                    [find_record!(plugin_name)]
                  else
                    enabled_records
                  end

        plugins.each { |record| migrate_record!(record) }
      end

      def migrate_record!(record)
        migrate_dir = migration_dir_for(record.id)
        return unless migrate_dir && Dir.exist?(migrate_dir)

        pending = pending_migrations(record.id, migrate_dir)
        return if pending.empty?

        puts "Migrating #{record.id} (#{pending.size} pending)..." unless quiet?

        pending.each { |migration| run_migration!(record.id, migration) }
      end

      def status(plugin_name = nil)
        ensure_table!

        records = if plugin_name
                    [find_record!(plugin_name)]
                  else
                    enabled_records
                  end

        records.map do |record|
          migrate_dir = migration_dir_for(record.id)
          next { name: record.id, pending: 0, total: 0 } unless migrate_dir && Dir.exist?(migrate_dir)

          all     = all_migrations(migrate_dir)
          applied = applied_versions(record.id)
          pending = all.reject { |m| applied.include?(m.version.to_s) }

          { name: record.id, pending: pending.size, total: all.size }
        end
      end

      def pending_count(plugin_name = nil)
        status(plugin_name).sum { |s| s[:pending] }
      end

      def migration_dir_for(plugin_name)
        record = find_record(plugin_name)
        return unless record

        dir = File.join(File.dirname(record.manifest.plugin_rb_path), "db", "migrate")
        Dir.exist?(dir) ? dir : nil
      end

      private

      def find_record!(plugin_name)
        find_record(plugin_name) || raise(ArgumentError, "Plugin '#{plugin_name}' not found or not enabled")
      end

      def find_record(plugin_name)
        enabled_records.find { |r| r.id == plugin_name }
      end

      def enabled_records
        Plugin::Registry.global&.ordered&.select(&:enabled?) || []
      end

      def pending_migrations(plugin_name, migrate_dir)
        applied = applied_versions(plugin_name)
        all_migrations(migrate_dir).reject { |m| applied.include?(m.version.to_s) }
      end

      # Returns an array of Migration objects from the given directory.
      # MigrationContext.new accepts only the path in Rails 7.2 —  passing a
      # string as the second argument (schema_migration) is deprecated and
      # causes a warning; omit it to use the default connection.
      def all_migrations(migrate_dir)
        ActiveRecord::MigrationContext.new(migrate_dir).migrations
      end

      def applied_versions(plugin_name)
        return Set.new unless table_has_column?("version")

        ActiveRecord::Base.connection.select_values(
          sanitize_sql([
            "SELECT version FROM #{SCHEMA_VERSION_TABLE} WHERE plugin_name = ?",
            plugin_name
          ])
        ).to_set
      end

      # Run a single migration up and record it in plugin_schema_versions.
      #
      # The public API for running a specific version is:
      #   MigrationContext#migrate(target_version)
      # which calls #up(target_version) internally. We build a context for
      # the directory that contains this single migration file so that
      # `migrate(version)` only ever sees that one file.
      #
      # We do NOT use ActiveRecord::SchemaMigration to record the run —
      # we use our own plugin_schema_versions table so that plugin migrations
      # stay completely separate from core schema_migrations.
      def run_migration!(plugin_name, migration)
        migration_dir = File.dirname(migration.filename)

        # Build a context scoped to the directory of this one file.
        context = ActiveRecord::MigrationContext.new(migration_dir)

        ActiveRecord::Base.transaction do
          # migrate(version) runs :up to that version, which executes the
          # migration if it has not already been run according to schema_migrations.
          # Since we track versions ourselves, we pass suppress_messages to
          # avoid duplicate schema_migrations entries — but we still need the
          # migration to actually execute, so we call `up` directly on the
          # migration class.
          migration.migrate(:up)

          ActiveRecord::Base.connection.execute(
            sanitize_sql([
              "INSERT INTO #{SCHEMA_VERSION_TABLE} (plugin_name, version, created_at) VALUES (?, ?, ?)",
              plugin_name, migration.version.to_s, Time.current
            ])
          )
        end

        puts "  #{migration.name} (#{migration.version}) ✓" unless quiet?
      rescue StandardError => e
        puts "  #{migration.name} (#{migration.version}) ✗ FAILED: #{e.message}" unless quiet?
        raise
      end

      def table_has_column?(column_name)
        ActiveRecord::Base.connection.column_exists?(SCHEMA_VERSION_TABLE, column_name)
      rescue ActiveRecord::StatementInvalid, ActiveRecord::TableDoesNotExist
        false
      end

      def sanitize_sql(args)
        ActiveRecord::Base.sanitize_sql(args)
      end

      def quiet?
        ENV["VERBOSE"] == "0" || Rails.env.test?
      end
    end
  end
end
