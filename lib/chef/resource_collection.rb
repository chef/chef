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
require 'chef/resource_collection/resource_collection_serialization'

##
# TODO add class documentation
class Chef
  class ResourceCollection
    include ResourceCollectionSerialization

    attr_reader :resource_set, :resource_list

    def initialize
      @resource_set = ResourceSet.new
      @resource_list = ResourceList.new
    end

    # TODO fundamentally we want to write objects into 2 different data containers.  We can proxy reads, but it is
    # much harder to proxy writes through 1 object.

    # TODO insert calls we might need?
    # :insert, :insert_at, :[]=, :<<, :push
    # :insert_as

    # TODO when there were 2 resources with the same key in resource_set, how do we handle notifications since they get copied?
    # Did the old class only keep the last seen reference?

    # TODO do we need to implement a dup method?  Run_context was shallowly copying resource_collection before

    RESOURCE_LIST_METHODS = Enumerable.instance_methods +
        [:all_resources, :[], :each, :execute_each_resource, :each_index, :empty?]
    RESOURCE_SET_METHODS = [:lookup, :find, :resources]

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
