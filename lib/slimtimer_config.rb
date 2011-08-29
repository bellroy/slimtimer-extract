require 'yaml'

class SlimtimerConfig

  def self.[](key)
    config[key]
  end

private

  def self.config
    YAML.load_file File.join(File.dirname(__FILE__), '..', 'config/slimtimer.yml')
  end
end
