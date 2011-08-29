# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

job_type :rake, 'cd :path && RAILS_ENV=:environment bundle exec rake :task :output'

every :day, :at => '1:34 am' do
  rake "slimtimer:fetch"
end
