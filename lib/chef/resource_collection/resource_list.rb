#
# Author:: Tyler Ball (<tball@chef.io>)
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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

require "chef/resource"
require "chef/resource_collection/stepable_iterator"
require "chef/resource_collection/resource_collection_serialization"
require "forwardable"

# This class keeps the list of all known Resources in the order they are to be executed in.  It also keeps a pointer
# to the most recently executed resource so we can add resources-to-execute after this point.
class Chef
  class ResourceCollection
    class ResourceList
      include ResourceCollection::ResourceCollectionSerialization
      include Enumerable
      extend Forwardable

      attr_reader :iterator

      attr_reader :resources
      private :resources
      # Delegate direct access methods to the @resources array
      # 4 extra methods here are not included in the Enumerable's instance methods
      direct_access_methods = Enumerable.instance_methods + [ :[], :each, :each_index, :empty? ]
      def_delegators :resources, *(direct_access_methods)

      def initialize
        @resources = Array.new
        @insert_after_idx = nil
      end

      # @param resource [Chef::Resource] The resource to insert
      # If @insert_after_idx is nil, we are not currently executing a converge so the Resource is appended to the
      # end of the list.  If @insert_after_idx is NOT nil, we ARE currently executing a converge so the resource
      # is inserted into the middle of the list after the last resource that was converged.  If it is called multiple
      # times (when an LWRP contains multiple resources) it keeps track of that.  See this example ResourceList:
      # [File1, LWRP1, File2] # The iterator starts and points to File1.  It is executed and @insert_after_idx=0
      # [File1, LWRP1, File2] # The iterator moves to LWRP1.  It is executed and @insert_after_idx=1
      # [File1, LWRP1, Service1, File2] # The LWRP execution inserts Service1 and @insert_after_idx=2
      # [File1, LWRP1, Service1, Service2, File2] # The LWRP inserts Service2 and @insert_after_idx=3.  The LWRP
      #     finishes executing
      # [File1, LWRP1, Service1, Service2, File2] # The iterator moves to Service1 since it is the next non-executed
      #     resource.  The execute_each_resource call below resets @insert_after_idx=2
      # If Service1 was another LWRP, it would insert its resources between Service1 and Service2.  The iterator keeps
      # track of executed resources and @insert_after_idx keeps track of where the next resource to insert should be.
      def insert(resource)
        is_chef_resource!(resource)
        if @insert_after_idx
          @resources.insert(@insert_after_idx += 1, resource)
        else
          @resources << resource
        end
      end

      def delete(key)
        raise ArgumentError, "Must pass a Chef::Resource or String to delete" unless key.is_a?(String) || key.is_a?(Chef::Resource)
        key = key.to_s
        ret = @resources.reject! { |r| r.to_s == key }
        if ret.nil?
          raise Chef::Exceptions::ResourceNotFound, "Cannot find a resource matching #{key} (did you define it first?)"
        end
        ret
      end

      # @deprecated - can be removed when it is removed from resource_collection.rb
      def []=(index, resource)
        @resources[index] = resource
      end

      def all_resources
        @resources
      end

      # FIXME: yard with @yield
      def execute_each_resource
        @iterator = ResourceCollection::StepableIterator.for_collection(@resources)
        @iterator.each_with_index do |resource, idx|
          @insert_after_idx = idx
          yield resource
        end
      end

      def self.from_hash(o)
        collection = new()
        resources = o["instance_vars"]["@resources"].map { |r| Chef::Resource.from_hash(r) }
        collection.instance_variable_set(:@resources, resources)
        collection
      end
    end
  end
end
