#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# If you need to add anything in here, don't.
# Add it to one of the files in spec/support

# Abuse ruby's constant lookup to avoid undefined constant errors

$LOAD_PATH.unshift File.expand_path("..", __dir__)
$LOAD_PATH.unshift File.expand_path("../../chef-config/lib", __dir__)
$LOAD_PATH.unshift File.expand_path("../../chef-utils/lib", __dir__)

require "rubygems"
require "rspec/mocks"
require "rexml/document"
require "webmock/rspec"

require "chef/knife"

# cwd is knife/
Dir["lib/chef/knife/**/*.rb"]
  .map { |f| f.gsub("lib/", "") }
  .map { |f| f.gsub(/\.rb$/, "") }
  .each { |f| require f }

require "chef/resource_resolver"
require "chef/provider_resolver"

require "chef/mixins"
require "chef/dsl"

require "chef/shell"
require "chef/util/file_edit"

require "chef/config"

require "chef/chef_fs/file_system_cache"

require "chef/api_client_v1"

require "chef/mixin/versioned_api"
require "chef/server_api_versions"

if ENV["CHEF_FIPS"] == "1"
  Chef::Config.init_openssl
end

# If you want to load anything into the testing environment
# without versioning it, add it to spec/support/local_gems.rb
require "spec/support/local_gems" if File.exist?(File.join(File.dirname(__FILE__), "support", "local_gems.rb"))

# Explicitly require spec helpers that need to load first
require "spec/support/platform_helpers"
require "spec/support/shared/unit/mock_shellout"
require "spec/support/recipe_dsl_helper"
require "spec/support/key_helpers"
require "spec/support/shared/unit/knife_shared"
require "spec/support/shared/functional/knife"
require "spec/support/shared/integration/knife_support"
require "spec/support/shared/matchers/exit_with_code"
require "spec/support/shared/matchers/match_environment_variable"

# Autoloads support files
# Excludes support/platforms by default
# Do not change the gsub.
Dir["spec/support/**/*.rb"]
  .reject { |f| f =~ %r{^spec/support/platforms} }
  .reject { |f| f =~ %r{^spec/support/pedant} }
  .map { |f| f.gsub(/.rb$/, "") }
  .map { |f| f.gsub(%r{spec/}, "") }
  .each { |f| require f }

OHAI_SYSTEM = Ohai::System.new
OHAI_SYSTEM.all_plugins(["platform", "hostname", "languages/powershell", "uptime"])

test_node = Chef::Node.new
test_node.automatic["os"] = (OHAI_SYSTEM["os"] || "unknown_os").dup.freeze
test_node.automatic["platform_family"] = (OHAI_SYSTEM["platform_family"] || "unknown_platform_family").dup.freeze
test_node.automatic["platform"] = (OHAI_SYSTEM["platform"] || "unknown_platform").dup.freeze
test_node.automatic["platform_version"] = (OHAI_SYSTEM["platform_version"] || "unknown_platform_version").dup.freeze
TEST_NODE = test_node.freeze
TEST_OS = TEST_NODE["os"]
TEST_PLATFORM = TEST_NODE["platform"]
TEST_PLATFORM_VERSION = TEST_NODE["platform_version"]
TEST_PLATFORM_FAMILY = TEST_NODE["platform_family"]

provider_priority_map ||= nil
resource_priority_map ||= nil
provider_handler_map ||= nil
resource_handler_map ||= nil

class UnexpectedSystemExit < RuntimeError
  def self.from(system_exit)
    new(system_exit.message).tap { |e| e.set_backtrace(system_exit.backtrace) }
  end
end

RSpec.configure do |config|
  config.include(RSpec::Matchers)
  config.include(MockShellout::RSpec)
  config.filter_run focus: true
  config.filter_run_excluding external: true
  config.raise_on_warning = true

  # Explicitly disable :should syntax
  # And set max_formatted_output_length to nil to prevent RSpec from doing truncation.
  config.expect_with :rspec do |c|
    c.syntax = :expect
    c.max_formatted_output_length = nil
  end
  config.mock_with :rspec do |c|
    c.syntax = :expect
    c.allow_message_expectations_on_nil = false
  end

  # TODO - which if any of these filters apply to knife tests?
  #
  # Only run these tests on platforms that are also chef workstations
  config.filter_run_excluding :workstation if solaris? || aix?

  # Tests that randomly fail, but may have value.
  config.filter_run_excluding volatile: true
  config.filter_run_excluding volatile_on_solaris: true if solaris?
  config.filter_run_excluding volatile_from_verify: false

  config.filter_run_excluding skip_buildkite: true if ENV["BUILDKITE"]

  config.filter_run_excluding windows_only: true unless windows?
  config.filter_run_excluding unix_only: true unless unix?

  # check for particular binaries we need

  running_platform_arch = `uname -m`.strip unless windows?

  config.filter_run_excluding arch: lambda { |target_arch|
    running_platform_arch != target_arch
  }

  config.run_all_when_everything_filtered = true

  config.before(:each) do
    # it'd be nice to run this with connections blocked or only to localhost, but we do make lots
    # of real connections, so cannot.  we reset it to allow connections every time to avoid
    # tests setting connections to be disabled and that state leaking into other tests.
    WebMock.allow_net_connect!
    Chef.reset!
    Chef::ChefFS::FileSystemCache.instance.reset!
    Chef::Config.reset
    Chef::Log.setup!
    Chef::ServerAPIVersions.instance.reset!
    Chef::Config[:log_level] = :fatal
    Chef::Log.level(Chef::Config[:log_level])

    # By default, treat deprecation warnings as errors in tests.
    # and set environment variable so the setting persists in child processes
    Chef::Config.treat_deprecation_warnings_as_errors(true)
    ENV["CHEF_TREAT_DEPRECATION_WARNINGS_AS_ERRORS"] = "1"
  end

  # This bit of jankiness guards against specs which accidentally drop privs when running as
  # root -- which are nearly impossible to debug and so we bail out very hard if this
  # condition ever happens.  If a spec stubs Process.[e]uid this can throw a false positive
  # which the spec must work around by unmocking Process.[e]uid to and_call_original in its
  # after block.
  # Should not be a problem with knife which does not escalate local privs, but
  # it seems wise to continue to guard against.
  if Process.euid == 0 && Process.uid == 0
    config.after(:each) do
      if Process.uid != 0
        RSpec.configure { |c| c.fail_fast = true }
        raise "rspec was invoked as root, but the last test dropped real uid to #{Process.uid}"
      end
      if Process.euid != 0
        RSpec.configure { |c| c.fail_fast = true }
        raise "rspec was invoked as root, but the last test dropped effective uid to #{Process.euid}"
      end
    end
  end

  # raise if anyone commits any test to CI with :focus set on it
  if ENV["CI"]
    config.before(:example, :focus) do
      raise "This example was committed with `:focus` and should not have been"
    end
  end

  config.before(:suite) do
    ARGV.clear
  end

  # Protect Rspec from accidental exit(0) causing rspec to terminate without error
  config.around(:example) do |ex|
    ex.run
  rescue SystemExit => e
    raise UnexpectedSystemExit.from(e)

  end
end

require "webrick/utils"
#    Webrick uses a centralized/synchronized timeout manager. It works by
#    starting a thread to check for timeouts on an interval. The timeout
#    checker thread cannot be stopped or canceled in any easy way, and it
#    makes calls to Time.new, which fail when rspec is in the process of
#    creating a method stub for that method. Since our tests don't rely on
#    any timeout behavior enforced by webrick, disable the timeout manager
#    via a monkey patch.
#
#    Hopefully this fails loudly if the webrick code should change. As of this
#    writing, the relevant code is in webrick/utils, which can be located on
#    your system with:
#
#    $ gem which webrick/utils
module WEBrick
  module Utils
    class TimeoutHandler
      def initialize; end

      def register(*args); end

      def cancel(*args); end
    end
  end
end

# Enough stuff needs json serialization that I'm just adding it here for equality asserts
require "chef/json_compat"
