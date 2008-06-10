#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
# License:: GNU General Public License version 2 or later
# 
# This program and entire repository is free software; you can
# redistribute it and/or modify it under the terms of the GNU 
# General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#

class Chef
  class ResourceCollection
    include Enumerable
    
    def initialize
      @resources = Array.new
      @resources_by_name = Hash.new
    end
    
    def [](index)
      @resources[index]
    end
    
    def []=(index, arg)
      is_chef_resource(arg)
      raise ArgumentError, "Already have a resource named #{arg.to_s}" if @resources_by_name.has_key?(arg.to_s)
      @resources[index] = arg 
      @resources_by_name[arg.to_s] = index
    end
    
    def <<(*args)
      args.flatten.each do |a|
        is_chef_resource(a)
        raise ArgumentError, "Already have a resource named #{a.to_s}" if @resources_by_name.has_key?(a.to_s)
        @resources << a
        @resources_by_name[a.to_s] = @resources.length - 1
      end
    end
    
    def push(*args)
      args.flatten.each do |a|
        is_chef_resource(a)
        raise ArgumentError, "Already have a resource named #{a.to_s}" if @resources_by_name.has_key?(a.to_s)
        @resources.push(a)
        @resources_by_name[a.to_s] = @resources.length - 1 
      end
    end
  
    def each
      @resources.each do |r|
        yield r
      end
    end
    
    def each_index
      @resources.each_index do |i|
        yield i
      end
    end
    
    def lookup(resource)
      lookup_by = nil
      if resource.kind_of?(Chef::Resource)
        lookup_by = resource.to_s
      elsif resource.kind_of?(String)
        lookup_by = resource
      else
        raise ArgumentError, "Must pass a Chef::Resource or String to lookup"
      end
      res = @resources_by_name[lookup_by]
      unless res
        raise ArgumentError, "Cannot find a resource matching #{lookup_by} (did you define it first?)"
      end
      @resources[res]
    end

    # Find existing resources by searching the list of existing resources.  Possible
    # forms are:
    #
    # resources(:file => "foobar")
    # resources(:file => [ "foobar", "baz" ])
    # resources("file[foobar]", "file[baz]")
    # resources("file[foobar,baz]")
    #
    # Returns the matching resource, or an Array of matching resources. 
    #
    # Raises an ArgumentError if you feed it bad lookup information
    # Raises a Runtime Error if it can't find the resources you are looking for.
    def resources(*args)
      results = Array.new
      args.each do |arg|
        case arg
        when Hash
          results << find_resource_by_hash(arg)
        when String
          results << find_resource_by_string(arg)
        else
          raise ArgumentError, "resources takes arguments as a hash or strings!"
        end
      end
      flat_results = results.flatten
      flat_results.length == 1 ? flat_results[0] : flat_results
    end
    
    # Serialize this object as a hash 
    def to_json(*a)
      instance_vars = Hash.new
      self.instance_variables.each do |iv|
        instance_vars[iv] = self.instance_variable_get(iv)
      end
      results = {
        'json_class' => self.class.name,
        'instance_vars' => instance_vars
      }
      results.to_json(*a)
    end
    
    def self.json_create(o)
      collection = self.new()
      o["instance_vars"].each do |k,v|
        collection.instance_variable_set(k.to_sym, v)
      end
      collection
    end

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
        when /^(.+)\[(.+?),(.+)\]$/
          resource_type = $1
          arg =~ /^.+\[(.+)\]$/
          resource_list = $1
          resource_list.split(",").each do |name|
            resource_name = "#{resource_type}[#{name}]" 
            results << lookup(resource_name)
          end
        when /^(.+)\[(.+)\]$/
          resource_type = $1
          name = $2
          resource_name = "#{resource_type}[#{name}]"
          results << lookup(resource_name)
        else
          raise ArgumentError, "You must have a string like resource_type[name]!"
        end
        return results
      end

      def is_chef_resource(arg)
        unless arg.kind_of?(Chef::Resource)
          raise ArgumentError, "Members must be Chef::Resource's" 
        end
        true
      end
  end
end