#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2008, 2009 Opscode, Inc.
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

require 'chef/resource_collection/resource_set'
require 'chef/resource_collection/resource_list'
require 'chef/resource_collection/resource_collection_serialization'
require 'chef/log'
require 'forwardable'

##
# ResourceCollection currently handles two tasks:
# 1) Keeps an ordered list of resources to use when converging the node
# 2) Keeps a unique list of resources (keyed as `type[name]`) used for notifications
class Chef
  class ResourceCollection
    include ResourceCollectionSerialization
    extend Forwardable

    attr_reader :resource_set, :resource_list
    private :resource_set, :resource_list

    def initialize
      @resource_set = ResourceSet.new
      @resource_list = ResourceList.new
    end

    # @param resource [Chef::Resource] The resource to insert
    # @param resource_type [String,Symbol] If known, the resource type used in the recipe, Eg `package`, `execute`
    # @param instance_name [String] If known, the recource name as used in the recipe, IE `vim` in `package 'vim'`
    # This method is meant to be the 1 insert method necessary in the future.  It should support all known use cases
    #   for writing into the ResourceCollection.
    def insert(resource, opts={})
      resource_type ||= opts[:resource_type] # Would rather use Ruby 2.x syntax, but oh well
      instance_name ||= opts[:instance_name]
      resource_list.insert(resource)
      if !(resource_type.nil? && instance_name.nil?)
        resource_set.insert_as(resource, resource_type, instance_name)
      else
        resource_set.insert_as(resource)
      end
    end

    # @deprecated
    def []=(index, resource)
      Chef::Log.warn("`[]=` is deprecated, use `insert` (which only inserts at the end)")
      resource_list[index] = resource
      resource_set.insert_as(resource)
    end

    # @deprecated
    def push(*resources)
      Chef::Log.warn("`push` is deprecated, use `insert`")
      resources.flatten.each do |res|
        insert(res)
      end
      self
    end

    # @deprecated
    alias_method :<<, :insert

    # Read-only methods are simple to delegate - doing that below

    resource_list_methods = Enumerable.instance_methods +
        [:iterator, :all_resources, :[], :each, :execute_each_resource, :each_index, :empty?] -
        [:find] # find needs to run on the set
    resource_set_methods = [:lookup, :find, :resources, :keys, :validate_lookup_spec!]

    def_delegators :resource_list, *resource_list_methods
    def_delegators :resource_set, *resource_set_methods

  end
end
