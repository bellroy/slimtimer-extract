require 'dm-core'

%w[slimtimer_api slimtimer_config].each do |file|
  require File.join(File.dirname(__FILE__), file)
end

%w[user].each do |file|
  require File.join(File.dirname(__FILE__), '..', 'models', file)
end

class Slimtimer
  MAX_CONSECUTIVE_TIMEOUTS = 5

  ONE_DAY  = 24 * 60 * 60
  ONE_WEEK = 7 * ONE_DAY

  def initialize
    @users  = SlimtimerConfig["users"]
  end

  def fetch_tasks_and_entries
    @tasks = fetch_tasks
    log "    Got #{tasks.size} tasks; updating"
    # TODO: update DB

    fetch_entries
  end

  # Load all tasks associated with the Slimtimer God
  def fetch_tasks
    god_name     = SlimtimerConfig["god"]
    god          = @users.find { |u| u["name"] == god }
    god_username = god["username"]
    god_password = god["password"]

    st_god = SlimtimerApi.new(god_username, god_password)
    log "  Slimtimer connected as user #{god_name}"

    log "  Loading tasks"
    fetch_with_pagination st_god, :tasks, 50
  end

  # Load all time entries of all users
  def fetch_entries(tasks)
    @users.each do |user|
      db_user = User.first(:username => user["username"])
      unless db_user
        db_user = User.create(
          :username => user["username"],
          :name     => user["name"]
        )
      end
      
      fetch_user_entries db_user, user["username"], user["password"]
    end
  end

private

  def fetch_user_entries(db_user, email, password)
    st_user = SlimtimerApi.new(email, password)
    log "  Slimtimer connected as user #{email}"
  
    # last_entry  = db_user.time_entries.first(:order => [:end_time.desc])
    # start_range = last_entry ? last_entry.end_time - TWO_WEEKS : Time.local(2010, 1, 1)
    start_range = Time.now - (2 * ONE_WEEK)
    end_range   = [start_range + ONE_DAY, Time.now].min

    until end_range >= Time.now

    end
  end


  # Fetches all records for the given entity.
  # Slimtimer has a default limits of records that are returned.
  # The solution is to paginate through the results.
  # http://slimtimer.com/help/api
  def fetch_with_pagination(connection, entity, per_page)
    offset  = 0
    records = []

    begin
      set = handle_timeouts(MAX_CONSECUTIVE_TIMEOUTS, "loading tasks (offset: #{offset})") do
        connection.send(entity, offset, "yes", "owner,coworker,reporter")
      end

      records += set
      offset  += per_page
    end until set.empty?

    records
  end

  # Runs a given block, handling timeouts
  # It will retry the block up to _max_timeouts_ times.
  # If max_timeouts is exceeded, it'll spit out the given _task_ to stderr,
  # and exit the script with an error code.
  def handle_timeouts(max_timeouts, task)
    timeouts = 0

    begin
      yield
    rescue Timeout::Error
      timeouts += 1

      if timeouts > max_timeouts
        raise "SlimTimer timed out #{timeouts} times, so we gave up."
      else
        retry
      end
    end
  end

  # Find tasks that are missing.  That is, find tasks we have time_entries for, but for some unknown reason
  # the slimtimer api to slurp all tasks doesn't return.
  def get_missing_tasks(st)
    all_tasks = SlimtimerTask.all
    missing_ids=TimeEntry.all(:slimtimer_task_id.not => all_tasks.map(&:id)).map(&:slimtimer_task_id).uniq
    log.info "Trying to get info on #{missing_ids.length} missing tasks" if missing_ids.length>0
    missing_ids.each do |task_id|
      task = handle_timeouts(MAX_CONSECUTIVE_SLIMTIMER_TIMEOUTS, "Loading specific task : #{task_id}") do
        st.find_task(task_id)
      end
      if task
        SlimtimerTask.update([task])
      else
        log.warn "Unable to find task id : #{task_id}.  Creating an artificial one..."
        SlimtimerTask.update(['id' => task_id,
                              'name' => "Missing (#{task_id})",
                              'hours' => 0,
                              'completed' => false])
      end
    end
  end

  def log(string)
    p string
  end
end
