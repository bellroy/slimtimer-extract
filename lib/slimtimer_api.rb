require 'httparty'
require 'yaml'

class SlimtimerApi
  include HTTParty

  # I'd prefer to use json instead, but slimtimer reports empty JSON objects
  # instead for time values, like:
  # {
  #   updated_at: {},
  #   created_at: {},
  #   name: 'foo',
  #   ...
  # }
  format :xml

  def initialize(email, password)
    @api_key                = SlimtimerConfig["api_key"]
    @user_id, @access_token = get_access_token(email, password)
  end

  def tasks(offset = 0, show_completed = 'yes', role = 'owner,coworker')
    result = get('/tasks', :show_completed => show_completed, :role => role, :offset => offset)
    return [] unless result['tasks']
    
    case result['tasks']['task']
    when Hash
      [result['tasks']['task']]
    when Array
      result['tasks']['task']
    end
  end

private

  def get(path, query = {})
    options = {
      :headers => { "Accept" => "application/xml" },
      :base_uri => "http://www.slimtimer.com/users/#{@user_id}",
      :query => base_query.merge(query)
    }
    self.class.get(path, options)
  end

  def get_access_token(email, password)
    response = self.class.post("http://slimtimer.com/users/token",
      :headers => {
        "Accept"       => "application/xml",
        "Content-Type" => "application/x-yaml"
      },
      :body => {
        'user' => { 'email' => email, 'password' => password },
        'api_key' => @api_key
      }.to_yaml)
    [response['response']['user_id'], response['response']['access_token']]
  end

  def base_query
    @base_query ||= { :api_key => @api_key, :access_token => @access_token }
  end
end

