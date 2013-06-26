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
  map { |f| f.gsub(%r{.rb$}, '') }.
  map { |f| f.gsub(%r[spec/], '')}.
  each { |f| require f }

RSpec.configure do |config|
  config.include(Matchers)
  config.filter_run :focus => true
  config.filter_run_excluding :external => true

  # Tests that randomly fail, but may have value.
  config.filter_run_excluding :volatile => true

  # Add jruby filters here
  config.filter_run_excluding :windows_only => true unless windows?
  config.filter_run_excluding :not_supported_on_win2k3 => true if windows_win2k3?
  config.filter_run_excluding :not_supported_on_solaris => true if solaris?
  config.filter_run_excluding :win2k3_only => true unless windows_win2k3?
  config.filter_run_excluding :windows64_only => true unless windows64?
  config.filter_run_excluding :windows32_only => true unless windows32?
  config.filter_run_excluding :system_windows_service_gem_only => true unless system_windows_service_gem?
  config.filter_run_excluding :unix_only => true unless unix?
  config.filter_run_excluding :supports_cloexec => true unless supports_cloexec?
  config.filter_run_excluding :selinux_only => true unless selinux_enabled?
  config.filter_run_excluding :ruby_18_only => true unless ruby_18?
  config.filter_run_excluding :ruby_19_only => true unless ruby_19?
  config.filter_run_excluding :requires_root => true unless ENV['USER'] == 'root'
  config.filter_run_excluding :requires_unprivileged_user => true if ENV['USER'] == 'root'
  config.filter_run_excluding :uses_diff => true unless has_diff?

  config.run_all_when_everything_filtered = true
  config.treat_symbols_as_metadata_keys_with_true_values = true
end
