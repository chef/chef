#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software, Inc.
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
module Shell
  JUST_TESTING_MOVE_ALONG = true unless defined? JUST_TESTING_MOVE_ALONG
  IRB = nil unless defined? IRB
end

# Ruby 1.9 Compat
$:.unshift File.expand_path("../..", __FILE__)

require "rubygems"
require "rspec/mocks"

$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift(File.expand_path("../lib", __FILE__))
$:.unshift(File.dirname(__FILE__))

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/spec/"
    add_group "Remote File", "remote_file"
    add_group "Resources", "/resource/"
    add_group "Providers", "/provider/"
    add_group "Knife", "knife"
  end
end

require "chef"
require "chef/knife"

Dir["lib/chef/knife/**/*.rb"].
  map { |f| f.gsub("lib/", "") }.
  map { |f| f.gsub(%r{\.rb$}, "") }.
  each { |f| require f }

require "chef/resource_resolver"
require "chef/provider_resolver"

require "chef/mixins"
require "chef/dsl"
require "chef/application"
require "chef/applications"

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
require "spec/support/local_gems.rb" if File.exists?(File.join(File.dirname(__FILE__), "support", "local_gems.rb"))

# Explicitly require spec helpers that need to load first
require "spec/support/platform_helpers"
require "spec/support/shared/unit/mock_shellout"

# Autoloads support files
# Excludes support/platforms by default
# Do not change the gsub.
Dir["spec/support/**/*.rb"].
  reject { |f| f =~ %r{^spec/support/platforms} }.
  reject { |f| f =~ %r{^spec/support/pedant} }.
  map { |f| f.gsub(%r{.rb$}, "") }.
  map { |f| f.gsub(%r{spec/}, "") }.
  each { |f| require f }

OHAI_SYSTEM = Ohai::System.new
OHAI_SYSTEM.all_plugins(["platform", "hostname", "languages/powershell"])

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

RSpec.configure do |config|
  config.include(Matchers)
  config.include(MockShellout::RSpec)
  config.filter_run :focus => true
  config.filter_run_excluding :external => true

  # Explicitly disable :should syntax
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.mock_with :rspec do |c|
    c.syntax = :expect
  end

  # Only run these tests on platforms that are also chef workstations
  config.filter_run_excluding :workstation if solaris? || aix?

  # Tests that randomly fail, but may have value.
  config.filter_run_excluding :volatile => true
  config.filter_run_excluding :volatile_on_solaris => true if solaris?
  config.filter_run_excluding :volatile_from_verify => false

  config.filter_run_excluding :skip_appveyor => true if ENV["APPVEYOR"]
  config.filter_run_excluding :appveyor_only => true unless ENV["APPVEYOR"]
  config.filter_run_excluding :skip_travis => true if ENV["TRAVIS"]

  config.filter_run_excluding :windows_only => true unless windows?
  config.filter_run_excluding :not_supported_on_mac_osx_106 => true if mac_osx_106?
  config.filter_run_excluding :not_supported_on_mac_osx => true if mac_osx?
  config.filter_run_excluding :mac_osx_only => true if !mac_osx?
  config.filter_run_excluding :not_supported_on_win2k3 => true if windows_win2k3?
  config.filter_run_excluding :not_supported_on_solaris => true if solaris?
  config.filter_run_excluding :not_supported_on_gce => true if gce?
  config.filter_run_excluding :not_supported_on_nano => true if windows_nano_server?
  config.filter_run_excluding :win2k3_only => true unless windows_win2k3?
  config.filter_run_excluding :win2012r2_only => true unless windows_2012r2?
  config.filter_run_excluding :windows_2008r2_or_later => true unless windows_2008r2_or_later?
  config.filter_run_excluding :windows64_only => true unless windows64?
  config.filter_run_excluding :windows32_only => true unless windows32?
  config.filter_run_excluding :windows_nano_only => true unless windows_nano_server?
  config.filter_run_excluding :ruby64_only => true unless ruby_64bit?
  config.filter_run_excluding :ruby32_only => true unless ruby_32bit?
  config.filter_run_excluding :windows_powershell_dsc_only => true unless windows_powershell_dsc?
  config.filter_run_excluding :windows_powershell_no_dsc_only => true unless ! windows_powershell_dsc?
  config.filter_run_excluding :windows_domain_joined_only => true unless windows_domain_joined?
  config.filter_run_excluding :windows_not_domain_joined_only => true if windows_domain_joined?
  # We think this line was causing rspec tests to not run on the Jenkins windows
  # testers. If we ever fix it we should restore it.
  # config.filter_run_excluding :windows_service_requires_assign_token => true if !STDOUT.isatty && !windows_user_right?("SeAssignPrimaryTokenPrivilege")
  config.filter_run_excluding :windows_service_requires_assign_token => true
  config.filter_run_excluding :solaris_only => true unless solaris?
  config.filter_run_excluding :system_windows_service_gem_only => true unless system_windows_service_gem?
  config.filter_run_excluding :unix_only => true unless unix?
  config.filter_run_excluding :linux_only => true unless linux?
  config.filter_run_excluding :aix_only => true unless aix?
  config.filter_run_excluding :debian_family_only => true unless debian_family?
  config.filter_run_excluding :supports_cloexec => true unless supports_cloexec?
  config.filter_run_excluding :selinux_only => true unless selinux_enabled?
  config.filter_run_excluding :requires_root => true unless root?
  config.filter_run_excluding :requires_root_or_running_windows => true unless root? || windows?
  config.filter_run_excluding :requires_unprivileged_user => true if root?
  config.filter_run_excluding :uses_diff => true unless has_diff?
  config.filter_run_excluding :openssl_gte_101 => true unless openssl_gte_101?
  config.filter_run_excluding :openssl_lt_101 => true unless openssl_lt_101?
  config.filter_run_excluding :aes_256_gcm_only => true unless aes_256_gcm?
  config.filter_run_excluding :broken => true
  config.filter_run_excluding :not_wpar => true unless wpar?
  config.filter_run_excluding :not_supported_under_fips => true if fips?

  # these let us use chef: ">= 13" or ruby: "~> 2.0.0" or any other Gem::Dependency-style constraint
  config.filter_run_excluding chef: DependencyProc.with(Chef::VERSION)
  config.filter_run_excluding ruby: DependencyProc.with(RUBY_VERSION)

  config.filter_run_excluding :choco_installed => true unless choco_installed?

  running_platform_arch = `uname -m`.strip unless windows?

  config.filter_run_excluding :arch => lambda { |target_arch|
    running_platform_arch != target_arch
  }

  # Functional Resource tests that are provider-specific:
  # context "on platforms that use useradd", :provider => {:user => Chef::Provider::User::Useradd}} do #...
  config.filter_run_excluding :provider => lambda { |criteria|
    type, target_provider = criteria.first

    node = TEST_NODE.dup
    resource_class = Chef::ResourceResolver.resolve(type, node: node)
    if resource_class
      resource = resource_class.new("test", Chef::RunContext.new(node, nil, nil))
      begin
        provider = resource.provider_for_action(Array(resource_class.default_action).first)
        provider.class != target_provider
      rescue Chef::Exceptions::ProviderNotFound # no provider for platform
        true
      end
    else
      true
    end
  }

  config.run_all_when_everything_filtered = true

  config.before(:each) do
    Chef.reset!

    Chef::ChefFS::FileSystemCache.instance.reset!

    Chef::Config.reset

    # By default, treat deprecation warnings as errors in tests.
    Chef::Config.treat_deprecation_warnings_as_errors(true)

    # Set environment variable so the setting persists in child processes
    ENV["CHEF_TREAT_DEPRECATION_WARNINGS_AS_ERRORS"] = "1"
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
end

require "webrick/utils"
require "thread"

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
      def initialize
      end

      def register(*args)
      end

      def cancel(*args)
      end
    end
  end
end

# Enough stuff needs json serialization that I'm just adding it here for equality asserts
require "chef/json_compat"
