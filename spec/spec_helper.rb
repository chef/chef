#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

# Configure this first so it doesn't trigger annoying warning when we use it.
# Main rspec configuration comes later
RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
end

# Abuse ruby's constant lookup to avoid undefined constant errors
module Shell
  JUST_TESTING_MOVE_ALONG = true unless defined? JUST_TESTING_MOVE_ALONG
  IRB = nil unless defined? IRB
end

# Ruby 1.9 Compat
$:.unshift File.expand_path("../..", __FILE__)


require 'rubygems'
require 'rspec/mocks'

$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift(File.expand_path("../lib", __FILE__))
$:.unshift(File.dirname(__FILE__))

if ENV["COVERAGE"]
  require 'simplecov'
  SimpleCov.start do
    add_filter "/spec/"
    add_group "Remote File", "remote_file"
    add_group "Resources", "/resource/"
    add_group "Providers", "/provider/"
    add_group "Knife", "knife"
  end
end

require 'chef'
require 'chef/knife'

Dir['lib/chef/knife/**/*.rb'].
  map {|f| f.gsub('lib/', '') }.
  map {|f| f.gsub(%r[\.rb$], '') }.
  each {|f| require f }

require 'chef/mixins'
require 'chef/dsl'
require 'chef/application'
require 'chef/applications'

require 'chef/shell'
require 'chef/util/file_edit'

require 'chef/config'

# If you want to load anything into the testing environment
# without versioning it, add it to spec/support/local_gems.rb
require 'spec/support/local_gems.rb' if File.exists?(File.join(File.dirname(__FILE__), 'support', 'local_gems.rb'))

# Explicitly require spec helpers that need to load first
require 'spec/support/platform_helpers'

# Autoloads support files
# Excludes support/platforms by default
# Do not change the gsub.
Dir["spec/support/**/*.rb"].
  reject { |f| f =~ %r{^spec/support/platforms} }.
  reject { |f| f =~ %r{^spec/support/pedant} }.
  map { |f| f.gsub(%r{.rb$}, '') }.
  map { |f| f.gsub(%r[spec/], '')}.
  each { |f| require f }

OHAI_SYSTEM = Ohai::System.new
OHAI_SYSTEM.all_plugins("platform")
TEST_PLATFORM = OHAI_SYSTEM["platform"].dup.freeze
TEST_PLATFORM_VERSION = OHAI_SYSTEM["platform_version"].dup.freeze

RSpec.configure do |config|
  config.include(Matchers)
  config.filter_run :focus => true
  config.filter_run_excluding :external => true

  # Tests that randomly fail, but may have value.
  config.filter_run_excluding :volatile => true
  config.filter_run_excluding :volatile_on_solaris => true if solaris?

  # Add jruby filters here
  config.filter_run_excluding :windows_only => true unless windows?
  config.filter_run_excluding :not_supported_on_mac_osx_106 => true if mac_osx_106?
  config.filter_run_excluding :not_supported_on_win2k3 => true if windows_win2k3?
  config.filter_run_excluding :not_supported_on_solaris => true if solaris?
  config.filter_run_excluding :win2k3_only => true unless windows_win2k3?
  config.filter_run_excluding :windows_2008r2_or_later => true unless windows_2008r2_or_later?
  config.filter_run_excluding :windows64_only => true unless windows64?
  config.filter_run_excluding :windows32_only => true unless windows32?
  config.filter_run_excluding :windows_powershell_dsc_only => true unless windows_powershell_dsc?
  config.filter_run_excluding :windows_powershell_no_dsc_only => true unless ! windows_powershell_dsc?
  config.filter_run_excluding :windows_domain_joined_only => true unless windows_domain_joined?
  config.filter_run_excluding :solaris_only => true unless solaris?
  config.filter_run_excluding :system_windows_service_gem_only => true unless system_windows_service_gem?
  config.filter_run_excluding :unix_only => true unless unix?
  config.filter_run_excluding :supports_cloexec => true unless supports_cloexec?
  config.filter_run_excluding :selinux_only => true unless selinux_enabled?
  config.filter_run_excluding :ruby_18_only => true unless ruby_18?
  config.filter_run_excluding :ruby_19_only => true unless ruby_19?
  config.filter_run_excluding :ruby_gte_19_only => true unless ruby_gte_19?
  config.filter_run_excluding :ruby_20_only => true unless ruby_20?
  config.filter_run_excluding :ruby_gte_20_only => true unless ruby_gte_20?
  config.filter_run_excluding :requires_root => true unless root?
  config.filter_run_excluding :requires_root_or_running_windows => true unless (root? || windows?)
  config.filter_run_excluding :requires_unprivileged_user => true if root?
  config.filter_run_excluding :uses_diff => true unless has_diff?
  config.filter_run_excluding :ruby_gte_20_and_openssl_gte_101 => true unless (ruby_gte_20? && openssl_gte_101?)
  config.filter_run_excluding :openssl_lt_101 => true unless openssl_lt_101?
  config.filter_run_excluding :ruby_lt_20 => true unless ruby_lt_20?

  running_platform_arch = `uname -m`.strip

  config.filter_run_excluding :arch => lambda {|target_arch|
    running_platform_arch != target_arch
  }

  # Functional Resource tests that are provider-specific:
  # context "on platforms that use useradd", :provider => {:user => Chef::Provider::User::Useradd}} do #...
  config.filter_run_excluding :provider => lambda {|criteria|
    type, target_provider = criteria.first

    platform = TEST_PLATFORM.dup
    platform_version = TEST_PLATFORM_VERSION.dup

    begin
      provider_for_running_platform = Chef::Platform.find_provider(platform, platform_version, type)
      provider_for_running_platform != target_provider
    rescue ArgumentError # no provider for platform
      true
    end
  }

  config.run_all_when_everything_filtered = true
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.before(:each) do
    Chef::Config.reset
  end
end

require 'webrick/utils'

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
        @timeout_info = Hash.new
      end
    end
  end
end

# We are no longer using the 'json' gem - deny all access to it!
orig_require = Kernel.send(:instance_method, :require)
Kernel.send(:remove_method, :require)
Kernel.send(:define_method, :require) { |path|
  raise LoadError, 'JSON gem is no longer allowed - use Chef::JSONCompat.to_json' if path == 'json'
  orig_require.bind(Kernel).call(path)
}
# Enough stuff needs json serialization that I'm just adding it here for equality asserts
require 'chef/json_compat'
