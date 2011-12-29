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
#

# Abuse ruby's constant lookup to avoid undefined constant errors
module Shef
  JUST_TESTING_MOVE_ALONG = true unless defined? JUST_TESTING_MOVE_ALONG
  IRB = nil unless defined? IRB
end

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

Dir[File.join(File.dirname(__FILE__), 'lib', '**', '*.rb')].sort.each { |lib| require lib }

CHEF_SPEC_DATA = File.expand_path(File.dirname(__FILE__) + "/data/")
CHEF_SPEC_BACKUP_PATH = File.join(Dir.tmpdir, 'test-backup-path')

Chef::Config[:log_level] = :fatal
Chef::Config[:cache_type] = "Memory"
Chef::Config[:cache_options] = { }
Chef::Config[:persistent_queue] = false
Chef::Config[:file_backup_path] = CHEF_SPEC_BACKUP_PATH

Chef::Log.level(Chef::Config.log_level)
Chef::Config.solo(false)

Chef::Log.logger = Logger.new(StringIO.new)

def windows?
  if RUBY_PLATFORM =~ /mswin|mingw|windows/
    true
  else
    false
  end
end

DEV_NULL = windows? ? 'NUL' : '/dev/null'

def redefine_argv(value)
  Object.send(:remove_const, :ARGV)
  Object.send(:const_set, :ARGV, value)
end

def with_argv(*argv)
  original_argv = ARGV
  redefine_argv(argv.flatten)
  begin
    yield
  ensure
    redefine_argv(original_argv)
  end
end

# Sets $VERBOSE for the duration of the block and back to its original value afterwards.
def with_warnings(flag)
  old_verbose, $VERBOSE = $VERBOSE, flag
  yield
ensure
  $VERBOSE = old_verbose
end

def with_constants(constants, &block)
  saved_constants = {}
  constants.each do |constant, val|
    saved_constants[ constant ] = Object.const_get( constant )
    with_warnings(nil) { Object.const_set( constant, val ) }
  end
  begin
    block.call
  ensure
    constants.each do |constant, val|
      with_warnings(nil) { Object.const_set( constant, saved_constants[ constant ] ) }
    end
  end
end

def sha256_checksum(path)
  Digest::SHA256.hexdigest(File.read(path))
end

# load shared contexts & examples
Dir[File.join(File.dirname(__FILE__), 'support', 'shared','**', '*.rb')].sort.each { |lib| require lib }

# load custom matchers
Dir[File.join(File.dirname(__FILE__), 'support', 'matchers', '*.rb')].sort.each { |lib| require lib }
RSpec.configure do |config|
  config.include(Matchers)
end
