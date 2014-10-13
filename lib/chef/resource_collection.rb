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

require 'chef/resource_set'
require 'chef/resource_list'

class Chef
  class ResourceCollection

    def initialize
      @resource_set = ResourceSet.new
      @resource_list = ResourceList.new
    end

    # TODO proxy all calls with
    # http://simonecarletti.com/blog/2010/05/understanding-ruby-and-rails-proxy-patter-delegation-and-basicobject/

    # TODO fundamentally we want to write objects into 2 different data containers.  We can proxy reads, but it is
    # much harder to proxy writes through 1 object.

    def all_resources
      @resource_list.all_resources
    end

    def [](index)
      @resource_list[index]
    end

    def []=(index, arg)
      @resource_list[index] = arg
    end

    def <<(*args)
      @resource_list.send(:<<, *args)
    end

    # 'push' is an alias method to <<
    alias_method :push, :<<

    def insert(resource)
      @resource_list.insert(resource)
    end

    def insert_at(insert_at_index, *resources)
      @resource_list.insert_at(insert_at_index, *resources)
    end

    def insert_as(resource_type, instance_name, resource)
      # TODO how does this compete with the above 2 methods?  How do I combine them?
      @resource_set.insert_as(resource_type, instance_name, resource)
    end

    def each
      @resource_list.each
    end

    def execute_each_resource(&resource_exec_block)
      @resource_list.execute_each_resource(&resource_exec_block)
    end

    def each_index
      @resource_list.each_index
    end

    def empty?
      @resources_list.empty?
    end

    def lookup(resource_type, instance_name)
      @resource_set.lookup(resource_type, instance_name)
    end

    def find(*args)
      @resource_list.find(*args)
    end

    # resources is a poorly named, but we have to maintain it for back
    # compat.
    alias_method :resources, :find

    private

      def find_resource_by_hash(arg)
        results = Array.new
        arg.each do |resource_name, name_list|
          names = name_list.kind_of?(Array) ? name_list : [ name_list ]
          names.each do |name|
            res_name = "#{resource_name.to_s}[#{name}]"
            results << lookup(res_name)
          end
        end
        return results
      end

      def find_resource_by_string(arg)
        results = Array.new
        case arg
        when MULTIPLE_RESOURCE_MATCH
          resource_type = $1
          arg =~ /^.+\[(.+)\]$/
          resource_list = $1
          resource_list.split(",").each do |name|
            resource_name = "#{resource_type}[#{name}]"
            results << lookup(resource_name)
          end
        when SINGLE_RESOURCE_MATCH
          resource_type = $1
          name = $2
          resource_name = "#{resource_type}[#{name}]"
          results << lookup(resource_name)
        else
          raise ArgumentError, "Bad string format #{arg}, you must have a string like resource_type[name]!"
        end
        return results
      end

      def is_chef_resource(arg)
        unless arg.kind_of?(Chef::Resource)
          raise ArgumentError, "Cannot insert a #{arg.class} into a resource collection: must be a subclass of Chef::Resource"
        end
        true
      end
  end

  module ResourceCollectionSerialization
    # Serialize this object as a hash
    def to_hash
      instance_vars = Hash.new
      self.instance_variables.each do |iv|
        instance_vars[iv] = self.instance_variable_get(iv)
      end
      {
          'json_class' => self.class.name,
          'instance_vars' => instance_vars
      }
    end

    def to_json(*a)
      Chef::JSONCompat.to_json(to_hash, *a)
    end

    def self.json_create(o)
      collection = self.new()
      o["instance_vars"].each do |k,v|
        collection.instance_variable_set(k.to_sym, v)
      end
      collection
    end
  end
end
