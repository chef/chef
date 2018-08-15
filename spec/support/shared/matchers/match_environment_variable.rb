
require "rspec/expectations"
require "spec/support/platform_helpers"

RSpec::Matchers.define :match_environment_variable do |varname|
  match do |actual|
    expected = if windows? && ENV[varname].nil?
                 # On Windows, if an environment variable is not set, the command
                 # `echo %VARNAME%` outputs %VARNAME%
                 "%#{varname}%"
               else
                 ENV[varname].to_s
               end

    actual == expected
  end
end
