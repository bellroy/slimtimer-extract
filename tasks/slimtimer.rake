require File.join(File.dirname(__FILE__), '..', 'lib/slimtimer')

task :setup do
  database_config = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'config/database.yml'))
  DataMapper.setup :default, database_config
end

desc "Migrate then database"
task :migrate => :setup do
  require 'dm-migrations'
  DataMapper.auto_migrate!
end

namespace :slimtimer do

  desc "Fetch all time entries"
  task :fetch => :setup do
    Slimtimer.new.fetch_tasks_and_entries
  end
end
