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

# Abuse ruby's constant lookup to avoid undefined constant errors
module Shef
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

require 'chef'
require 'chef/knife'
Chef::Knife.load_commands
require 'chef/mixins'
require 'chef/application'
require 'chef/applications'

require 'chef/shef'
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
  each { |f| require f }

RSpec.configure do |config|
  config.include(Matchers)
  config.filter_run :focus => true
  config.filter_run_excluding :external => true

  # Add jruby filters here
  config.filter_run_excluding :windows_only => true unless windows?
  config.filter_run_excluding :unix_only => true unless unix?
  config.filter_run_excluding :requires_root => true unless ENV['USER'] == 'root'

  config.run_all_when_everything_filtered = true
  config.treat_symbols_as_metadata_keys_with_true_values = true
end
