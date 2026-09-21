# frozen_string_literal: true

namespace :reset_dev_site do
  desc "Reset the entire site in development"
  task reset: :environment do
    if Rails.env.development?
      puts "Resetting the database..."
      Rake::Task["db:drop"].invoke
      Rake::Task["db:create"].invoke
      # db:migrate now includes plugin migrations automatically —
      # Plugin::Instance#activate! registers each plugin's db/migrate directory
      # into ActiveRecord::Tasks::DatabaseTasks.migrations_paths.
      Rake::Task["db:migrate"].invoke
      Rake::Task["db:seed"].invoke

      puts "Deleting all the uploaded files..."
      FileUtils.rm_rf(Dir["#{Rails.root}/public/uploads/*"])

      puts "CinelarTV has been reset successfully"
    else
      puts "This task can only be run in development"
    end
  end
end
