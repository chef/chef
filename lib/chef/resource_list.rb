#
# Author:: Tyler Ball (<tball@getchef.com>)
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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

require 'chef/resource'
require 'chef/resource_collection/stepable_iterator'
require 'chef/resource_collection/resource_collection_serialization'

class Chef
  class ResourceList
    include ResourceCollection::ResourceCollectionSerialization
    include Enumerable

    attr_reader :iterator

    def initialize
      @resources = Array.new
      @insert_after_idx = nil
    end

    def all_resources
      @resources
    end

    def [](index)
      @resources[index]
    end

    def []=(index, arg)
      is_chef_resource(arg)
      @resources[index] = arg
    end

    def <<(*args)
      args.flatten.each do |a|
        is_chef_resource(a)
        @resources << a
      end
      self
    end

    # 'push' is an alias method to <<
    alias_method :push, :<<

    def insert(resource)
      if @insert_after_idx
        # in the middle of executing a run, so any resources inserted now should
        # be placed after the most recent addition done by the currently executing
        # resource
        insert_at(@insert_after_idx + 1, resource)
        @insert_after_idx += 1
      else
        is_chef_resource(resource)
        @resources << resource
      end
    end

    def insert_at(insert_at_index, *resources)
      resources.each do |resource|
        is_chef_resource(resource)
      end
      @resources.insert(insert_at_index, *resources)
    end

    def each
      @resources.each do |resource|
        yield resource
      end
    end

    def execute_each_resource(&resource_exec_block)
      @iterator = ResourceCollection::StepableIterator.for_collection(@resources)
      @iterator.each_with_index do |resource, idx|
        @insert_after_idx = idx
        yield resource
      end
    end

    def each_index
      @resources.each_index do |i|
        yield i
      end
    end

    def empty?
      @resources.empty?
    end

  end
end
