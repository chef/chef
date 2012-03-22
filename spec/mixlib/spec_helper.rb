$:.unshift File.expand_path("../../../lib", __FILE__)
require 'mixlib/shellout'
require 'ap'

def windows?
  !!(RUBY_PLATFORM =~ /mswin|mingw|windows/)
end

# def jruby?

def unix?
  !windows?
end

if windows?
  LINE_ENDING = "\r\n"
  ECHO_LC_ALL = "echo %LC_ALL%"
else
  LINE_ENDING = "\n"
  ECHO_LC_ALL = "echo $LC_ALL"
end

RSpec.configure do |config|
  config.mock_with :rspec
  config.filter_run :focus => true
  config.filter_run_excluding :external => true

  # Add jruby filters here
  config.filter_run_excluding :windows_only => true unless windows?
  config.filter_run_excluding :unix_only => true unless unix?

  config.run_all_when_everything_filtered = true
end
