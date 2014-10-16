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

##
# ResourceCollection currently handles two tasks:
# 1) Keeps an ordered list of resources to use when converging the node
# 2) Keeps a unique list of resources (keyed as `type[name]`) used for notifications
class Chef
  class ResourceCollection
    include ResourceCollectionSerialization

    def initialize
      @resource_set = ResourceSet.new
      @resource_list = ResourceList.new
    end

    # @param resource [Chef::Resource] The resource to insert
    # @param resource_type [String,Symbol] If known, the resource type used in the recipe, Eg `package`, `execute`
    # @param instance_name [String] If known, the recource name as used in the recipe, IE `vim` in `package 'vim'`
    # @param at_location [Integer] If know, a location in the @resource_list to insert resource
    # If you know the at_location but not the resource_type or instance_name, pass them in as nil
    # This method is meant to be the 1 insert method necessary in the future.  It should support all known use cases
    #   for writing into the ResourceCollection.
    def insert(resource, resource_type=nil, instance_name=nil, at_location=nil)
      if at_location
        @resource_list.insert_at(at_location, resource)
      else
        @resource_list.insert(resource)
      end
      unless resource_type.nil? || instance_name.nil?
        @resource_set.insert_as(resource, resource_type, instance_name)
      else
        @resource_set.insert_as(resource)
      end
    end

    # @param insert_at_index [Integer] Location to insert resources
    # @param resources [Chef::Resource] Resources to insert
    # @depreciated Callers should use the insert method above and loop through their resources as necessary
    def insert_at(insert_at_index, *resources)
      @resource_list.insert_at(insert_at_index, *resources)
      resources.each do |resource|
        @resource_set.insert_as(resource)
      end
    end

    # @depreciated
    def []=(index, resource)
      @resource_list[index] = resource
      @resource_set.insert_as(resource)
    end

    # @depreciated
    def <<(*resources)
      resources.flatten.each do |res|
        insert(res)
      end
      self
    end

    # @depreciated
    alias_method :push, :<<

    # TODO when there were 2 resources with the same key in resource_set, how do we handle notifications since they get copied?
    # Did the old class only keep the last seen reference?

    # TODO do we need to implement a dup method?  Run_context was shallowly copying resource_collection before

    # Read-only methods are simple to proxy - doing that below

    RESOURCE_LIST_METHODS = Enumerable.instance_methods +
        [:iterator, :all_resources, :[], :each, :execute_each_resource, :each_index, :empty?] -
        [:find] # find needs to run on the set
    RESOURCE_SET_METHODS = [:lookup, :find, :resources, :keys, :validate_lookup_spec!]

    def method_missing(name, *args, &block)
      if RESOURCE_LIST_METHODS.include?(name)
        proxy = @resource_list
      elsif RESOURCE_SET_METHODS.include?(name)
        proxy = @resource_set
      else
        raise NoMethodError.new("ResourceCollection does not proxy `#{name}`", name, args)
      end
      if block
        proxy.send(name, *args, &block)
      else
        proxy.send(name, *args)
      end

    end

  end
end
