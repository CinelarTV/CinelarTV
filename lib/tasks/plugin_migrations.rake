# frozen_string_literal: true

namespace :plugin do
  desc "Run all pending plugin migrations (or a specific plugin: plugin:migrate[plugin-name])"
  task :migrate, [:plugin_name] => :environment do |_t, args|
    require_relative "../plugin/migrator"

    plugin_name = args[:plugin_name]
    Plugin::Migrator.migrate!(plugin_name)

    count = Plugin::Migrator.pending_count(plugin_name)
    if count > 0
      puts "\n⚠ #{count} migration(s) still pending."
    else
      puts "\n✓ All plugin migrations are up to date."
    end
  end

  desc "Show migration status for all enabled plugins"
  task status: :environment do
    require_relative "../plugin/migrator"

    results = Plugin::Migrator.status

    if results.empty?
      puts "No enabled plugins with migrations found."
      next
    end

    puts "Plugin Migration Status:"
    puts "-" * 50
    results.each do |r|
      if r[:total] == 0
        puts "  #{r[:name]}: no migrations"
      elsif r[:pending] == 0
        puts "  #{r[:name]}: up to date (#{r[:total]} applied)"
      else
        puts "  #{r[:name]}: #{r[:pending]} pending / #{r[:total]} total"
      end
    end
  end

  desc "Rollback the last migration for a specific plugin (or all: plugin:rollback)"
  task :rollback, [:plugin_name] => :environment do |_t, args|
    require_relative "../plugin/migrator"

    plugin_name = args[:plugin_name]

    if plugin_name
      record = Plugin::Migrator.send(:find_record!, plugin_name)
      migrate_dir = Plugin::Migrator.migration_dir_for(plugin_name)
      raise "No migrations found for #{plugin_name}" unless migrate_dir

      context = ActiveRecord::MigrationContext.new(migrate_dir, Plugin::Migrator::MIGRATION_CONTEXT)
      migration = context.migrations.last
      raise "No migrations to rollback for #{plugin_name}" unless migration

      applied = Plugin::Migrator.send(:applied_versions, plugin_name)
      unless applied.include?(migration.version)
        raise "Last migration (#{migration.version}) is not applied"
      end

      puts "Rolling back #{migration.name} (#{migration.version})..."
      ActiveRecord::Base.transaction do
        context.run_migration(migration, :down)
        ActiveRecord::Base.connection.execute(
          ActiveRecord::Base.sanitize_sql([
            "DELETE FROM #{Plugin::Migrator::SCHEMA_VERSION_TABLE} WHERE plugin_name = ? AND version = ?",
            plugin_name, migration.version
          ])
        )
      end
      puts "Done."
    else
      Plugin::Migrator.send(:enabled_records).each do |record|
        migrate_dir = Plugin::Migrator.migration_dir_for(record.id)
        next unless migrate_dir

        applied = Plugin::Migrator.send(:applied_versions, record.id)
        next if applied.empty?

        context = ActiveRecord::MigrationContext.new(migrate_dir, Plugin::Migrator::MIGRATION_CONTEXT)
        migration = context.migrations.reverse.find { |m| applied.include?(m.version) }
        next unless migration

        puts "Rolling back #{record.id}/#{migration.name}..."
        ActiveRecord::Base.transaction do
          context.run_migration(migration, :down)
          ActiveRecord::Base.connection.execute(
            ActiveRecord::Base.sanitize_sql([
              "DELETE FROM #{Plugin::Migrator::SCHEMA_VERSION_TABLE} WHERE plugin_name = ? AND version = ?",
              record.id, migration.version
            ])
          )
        end
      end
      puts "Done."
    end
  end

  desc "Mark existing plugin migrations as applied (backfill for existing installations)"
  task backfill: :environment do
    require_relative "../plugin/migrator"

    Plugin::Migrator.ensure_table!

    Plugin::Migrator.send(:enabled_records).each do |record|
      migrate_dir = Plugin::Migrator.migration_dir_for(record.id)
      next unless migrate_dir && Dir.exist?(migrate_dir)

      all = Plugin::Migrator.send(:all_migrations, migrate_dir)
      applied = Plugin::Migrator.send(:applied_versions, record.id)

      pending = all.reject { |m| applied.include?(m.version) }
      next if pending.empty?

      pending.each do |migration|
        already_in_db = ActiveRecord::Base.connection.select_value(
          ActiveRecord::Base.sanitize_sql([
            "SELECT version FROM schema_migrations WHERE version = ?",
            migration.version
          ])
        )

        if already_in_db
          ActiveRecord::Base.connection.execute(
            ActiveRecord::Base.sanitize_sql([
              "INSERT INTO #{Plugin::Migrator::SCHEMA_VERSION_TABLE} (plugin_name, version, created_at) VALUES (?, ?, ?) ON CONFLICT DO NOTHING",
              record.id, migration.version, Time.current
            ])
          )
          puts "  #{record.id}/#{migration.name} (#{migration.version}) -> marked as applied"
        else
          puts "  #{record.id}/#{migration.name} (#{migration.version}) -> PENDING"
        end
      end
    end

    puts "\nBackfill complete. Run `plugin:migrate` to apply remaining pending migrations."
  end

  desc "One-time migration: backfill + migrate plugins (for existing installations upgrading to new system)"
  task upgrade: :environment do
    Rake::Task["plugin:backfill"].invoke
    Rake::Task["plugin:migrate"].invoke
    puts "\nAll done. `db:migrate` will now handle plugin migrations automatically."
  end
end
