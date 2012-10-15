#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'chef/chef_fs/file_system'
require 'chef/chef_fs/file_system/base_fs_dir'
require 'chef/chef_fs/file_system/base_fs_object'

module FileSystemSupport
  class MemoryFile < Chef::ChefFS::FileSystem::BaseFSObject
    def initialize(name, parent, value)
      super(name, parent)
      @value = value
    end
    def read
      return @value
    end
  end

  class MemoryDir < Chef::ChefFS::FileSystem::BaseFSDir
    def initialize(name, parent)
      super(name, parent)
      @children = []
    end
    attr_reader :children
    def child(name)
      @children.select { |child| child.name == name }.first || Chef::ChefFS::FileSystem::NonexistentFSObject.new(name, self)
    end
    def add_child(child)
      @children.push(child)
    end
    def can_have_child?(name, is_dir)
      root.cannot_be_in_regex ? (name !~ root.cannot_be_in_regex) : true
    end
  end

  class MemoryRoot < MemoryDir
    def initialize(pretty_name, cannot_be_in_regex = nil)
      super('', nil)
      @pretty_name = pretty_name
      @cannot_be_in_regex = cannot_be_in_regex
    end

    attr_reader :cannot_be_in_regex

    def path_for_printing
      @pretty_name
    end
  end

  def memory_fs(pretty_name, value, cannot_be_in_regex = nil)
    if !value.is_a?(Hash)
      raise "memory_fs() must take a Hash"
    end
    dir = MemoryRoot.new(pretty_name, cannot_be_in_regex)
    value.each do |key, child|
      dir.add_child(memory_fs_value(child, key.to_s, dir))
    end
    dir
  end

  def memory_fs_value(value, name = '', parent = nil)
    if value.is_a?(Hash)
      dir = MemoryDir.new(name, parent)
      value.each do |key, child|
        dir.add_child(memory_fs_value(child, key.to_s, dir))
      end
      dir
    else
      MemoryFile.new(name, parent, value || "#{name}\n")
    end
  end

  def pattern(p)
    Chef::ChefFS::FilePattern.new(p)
  end

  def return_paths(*expected)
    ReturnPaths.new(expected)
  end

  def no_blocking_calls_allowed
    [ MemoryFile, MemoryDir ].each do |c|
      [ :children, :exists?, :read ].each do |m|
        c.any_instance.stub(m).and_raise("#{m.to_s} should not be called")
      end
    end
  end

  def list_should_yield_paths(fs, pattern_str, *expected_paths)
    result_paths = []
    Chef::ChefFS::FileSystem.list(fs, pattern(pattern_str)) { |result| result_paths << result.path }
    result_paths.should =~ expected_paths
  end
end

