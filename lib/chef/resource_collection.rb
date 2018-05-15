#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
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

require "chef/resource_collection/resource_set"
require "chef/resource_collection/resource_list"
require "chef/resource_collection/resource_collection_serialization"
require "chef/log"
require "forwardable"

##
# ResourceCollection currently handles two tasks:
# 1) Keeps an ordered list of resources to use when converging the node
# 2) Keeps a unique list of resources (keyed as `type[name]`) used for notifications
class Chef
  class ResourceCollection
    include ResourceCollectionSerialization
    extend Forwardable

    attr_reader :resource_set, :resource_list
    attr_accessor :run_context

    protected :resource_set, :resource_list

    def initialize(run_context = nil)
      @run_context = run_context
      @resource_set = ResourceSet.new
      @resource_list = ResourceList.new
    end

    # @param resource [Chef::Resource] The resource to insert
    # @param resource_type [String,Symbol] If known, the resource type used in the recipe, Eg `package`, `execute`
    # @param instance_name [String] If known, the recource name as used in the recipe, IE `vim` in `package 'vim'`
    # This method is meant to be the 1 insert method necessary in the future.  It should support all known use cases
    #   for writing into the ResourceCollection.
    def insert(resource, opts = {})
      resource_type ||= opts[:resource_type] # Would rather use Ruby 2.x syntax, but oh well
      instance_name ||= opts[:instance_name]
      resource_list.insert(resource)
      if !(resource_type.nil? && instance_name.nil?)
        resource_set.insert_as(resource, resource_type, instance_name)
      else
        resource_set.insert_as(resource)
      end
    end

    def delete(key)
      resource_list.delete(key)
      resource_set.delete(key)
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
      [:find] # find overridden below
    resource_set_methods = [:resources, :keys, :validate_lookup_spec!]

    def_delegators :resource_list, *resource_list_methods
    def_delegators :resource_set, *resource_set_methods

    def lookup_local(key)
      resource_set.lookup(key)
    end

    def find_local(*args)
      resource_set.find(*args)
    end

    def lookup(key)
      if run_context.nil?
        lookup_local(key)
      else
        lookup_recursive(run_context, key)
      end
    end

    def find(*args)
      if run_context.nil?
        find_local(*args)
      else
        find_recursive(run_context, *args)
      end
    end

    def self.from_hash(o)
      collection = new()
      { "@resource_list" => "ResourceList", "@resource_set" => "ResourceSet" }.each_pair do |name, klass|
        obj = Chef::ResourceCollection.const_get(klass).from_hash(o["instance_vars"].delete(name))
        collection.instance_variable_set(name.to_sym, obj)
      end
      collection.instance_variable_set(:@run_context, o["instance_vars"].delete("@run_context"))
      collection
    end

    private

    def lookup_recursive(rc, key)
      rc.resource_collection.resource_set.lookup(key)
    rescue Chef::Exceptions::ResourceNotFound
      raise if rc.parent_run_context.nil?
      lookup_recursive(rc.parent_run_context, key)
    end

    def find_recursive(rc, *args)
      rc.resource_collection.resource_set.find(*args)
    rescue Chef::Exceptions::ResourceNotFound
      raise if rc.parent_run_context.nil?
      find_recursive(rc.parent_run_context, *args)
    end
  end
end
