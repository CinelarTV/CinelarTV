# frozen_string_literal: true

namespace :reset_dev_site do
  desc "Reset the entire site in development"
  task reset: :environment do
    if Rails.env.development?
      puts "Resetting the database..."
      Rake::Task["db:drop"].invoke
      Rake::Task["db:create"].invoke
      Rake::Task["db:migrate"].invoke
      Rake::Task["db:seed"].invoke

      # Delete all the uploaded files

      puts "Deleting all the uploaded files..."

      FileUtils.rm_rf(Dir["#{Rails.root}/public/uploads/*"])

      puts "CinelarTV has been reseted successfully"
    else
      puts "This task can only be run in development"
    end
  end
end
