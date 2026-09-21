# frozen_string_literal: true

# Enhances Rails db:migrate to automatically run plugin migrations
# and keeps schema.rb clean of plugin table definitions.

namespace :db do
  # Run plugin migrations after core migrations
  task :migrate do
    Rake::Task["plugin:migrate"].invoke
  end

  # Clean plugin tables from schema.rb after every dump
  namespace :schema do
    task :dump do
      Rake::Task["plugin:schema:clean"].invoke
    end
  end
end

namespace :plugin do
  namespace :schema do
    desc "Strip plugin table definitions from schema.rb (runs automatically after db:schema:dump)"
    task clean: :environment do
      require_relative "../plugin/migrator"

      schema_path = Rails.root.join("db", "schema.rb")
      next unless File.exist?(schema_path)

      content = File.read(schema_path)

      plugin_tables = collect_plugin_table_names
      next if plugin_tables.empty?

      plugin_fks = collect_plugin_foreign_keys(plugin_tables)

      original_lines = content.lines
      cleaned_lines = []
      skip_block = false
      block_depth = 0

      original_lines.each do |line|
        if line =~ /^\s*create_table\s+["'](\w+)["']/
          if plugin_tables.include?($1)
            skip_block = true
            block_depth = 0
            next
          end
        end

        if skip_block
          block_depth += line.scan(/\bdo\b/).size - line.scan(/\bend\b/).size
          if block_depth <= 0
            skip_block = false
          end
          next
        end

        if line =~ /^\s*add_foreign_key\s+["'](\w+)["']/
          next if plugin_fks.include?($1)
        end

        cleaned_lines << line
      end

      # Update schema version to latest core-only migration
      latest_core = latest_core_migration_version
      if latest_core
        cleaned_lines.map! do |line|
          if line =~ /ActiveRecord::Schema\[\d+\.\d+\]\.define\(version:/
            "ActiveRecord::Schema[7.2].define(version: #{latest_core}) do\n"
          else
            line
          end
        end
      end

      File.write(schema_path, cleaned_lines.join)
    end
  end

  private

  def collect_plugin_table_names
    tables = Set.new
    Plugin::Migrator.send(:enabled_records).each do |record|
      migrate_dir = Plugin::Migrator.migration_dir_for(record.id)
      next unless migrate_dir && Dir.exist?(migrate_dir)

      Dir.glob(File.join(migrate_dir, "*.rb")).each do |f|
        File.read(f).each_line do |line|
          tables << $1 if line =~ /create_table\s+["'](\w+)["']/
        end
      end
    end
    tables
  end

  def collect_plugin_foreign_keys(plugin_tables)
    fks = Set.new
    Plugin::Migrator.send(:enabled_records).each do |record|
      migrate_dir = Plugin::Migrator.migration_dir_for(record.id)
      next unless migrate_dir && Dir.exist?(migrate_dir)

      Dir.glob(File.join(migrate_dir, "*.rb")).each do |f|
        File.read(f).each_line do |line|
          if line =~ /add_foreign_key\s+["'](\w+)["']/
            fks << $1 if plugin_tables.include?($1)
          end
        end
      end
    end
    fks
  end

  def latest_core_migration_version
    core_dir = Rails.root.join("db", "migrate")
    return unless Dir.exist?(core_dir)

    Dir.glob(File.join(core_dir, "*.rb"))
      .map { |f| File.basename(f).split("_").first.to_i }
      .max
  end
end
