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
  class ResourceCollection
    class ResourceList
      include ResourceCollection::ResourceCollectionSerialization
      include Enumerable

      attr_reader :iterator

      def initialize
        @resources = Array.new
        @insert_after_idx = nil
      end

      # TODO the differences between these 2 insert methods is very confusing
      def insert(resource)
        if @insert_after_idx
          # in the middle of executing a run, so any resources inserted now should
          # be placed after the most recent addition done by the currently executing
          # resource
          insert_at(@insert_after_idx += 1, resource)
        else
          is_chef_resource!(resource)
          @resources << resource
        end
      end

      # TODO this did not adjust @insert_after_idx in the old class - add test case and ask JohnK
      def insert_at(index, *resources)
        resources.each do |resource|
          is_chef_resource!(resource)
        end
        @resources.insert(index, *resources)
      end

      # @depreciated
      def []=(index, resource)
        @resources[index] = resource
      end

      def all_resources
        @resources
      end

      def [](index)
        @resources[index]
      end

      def each
        @resources.each do |resource|
          yield resource
        end
      end

      # TODO I would like to rename this to something that illustrates it sets the @insert_after_idx variable, then alias this old name
      # TODO or perhaps refactor it to have 2 pointers - 1 for the end of the list and 1 for resources we have processed
      #   so far, and then move that logic up into the ResourceCollection class to simplify this class
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
end

