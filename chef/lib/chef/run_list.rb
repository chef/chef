#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Nuo Yan (<nuoyan@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2008-2010 Opscode, Inc.
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

require 'chef/mixin/deep_merge'

class Chef
  class RunList
    include Enumerable

    # @run_list is an array of strings that describe the items to execute in order.
    # For example:
    #   @run_list = ['recipe[foo::bar]', 'role[webserver]']
    # Thus,
    #   self.role_names would return ['webserver']
    #   self.recipe_names would return ['foo::bar']
    attr_reader :run_list

    def initialize
      @run_list = Array.new
    end
    
    def role_names
      run_list.inject([]){|memo, run_list_item| type, short_name, typed_name = parse_entry(run_list_item); memo << short_name if type=="role" ; memo}
    end

    def recipe_names
      run_list.inject([]){|memo, run_list_item| type, short_name, typed_name = parse_entry(run_list_item); memo << short_name if type=="recipe" ; memo}
    end

    # Add an item of the form "recipe[foo::bar]" or "role[webserver]"
    def <<(run_list_item)
      type, short_name, typed_name = parse_entry(item)
      
      self.run_list << run_list_item
      self
    end

    def ==(*isequal)
      check_array = nil
      if isequal[0].kind_of?(Chef::RunList)
        check_array = isequal[0].run_list
      else
        check_array = isequal.flatten
      end
      
      return false if check_array.length != run_list.length

      check_array.each_index do |i|
        to_check = check_array[i]
        type, name, typed_name = parse_entry(to_check)
        return false if run_list[i] != typed_name
      end

      true
    end

    def to_s
      run_list.join(", ")
    end

    def empty?
      run_list.length == 0 ? true : false
    end

    def [](pos)
      run_list[pos]
    end

    def []=(pos, item)
      type, entry, fentry = parse_entry(item)
      run_list[pos] = fentry 
    end

    def each(&block)
      run_list.each { |i| block.call(i) }
    end

    def each_index(&block)
      run_list.each_index { |i| block.call(i) }
    end

    def include?(item)
      type, entry, fentry = parse_entry(item)
      run_list.include?(fentry)
    end

    def reset!(*args)
      self.run_list = Array.new
      args.flatten.each do |item|
        if item.kind_of?(Chef::RunList)
          item.each { |r| self << r }
        else
          self << item
        end
      end
      self
    end

    def remove(item)
      self.run_list.delete_if{|i| i == item}
      self
    end

    def expand(data_source='server', couchdb=nil, rest=nil)
      couchdb = couchdb ? couchdb : Chef::CouchDB.new
      recipes = Array.new
      default_attrs = Mash.new
      override_attrs = Mash.new
      seen_roles = Hash.new

      # for each run list item, add recipes and expand roles into
      # their constituent recipes recursively
      run_list.each do |entry|
        type, name, typed_name = parse_entry(entry)
        case type
        when 'recipe'
          recipes << name unless recipes.include?(name)
        when 'role'
          # don't duplicate role expansion
          next if seen_roles.has_key?(name)
          seen_roles[name] = true

          # expand role
          role = expand_role(name, data_source)
          nested_recipes, nested_default_attrs, nested_override_attrs = role.run_list.expand(data_source, couchdb, rest)

          # add its recipes
          nested_recipes.each { |r| recipes <<  r unless recipes.include?(r) }
          
          # merge its attributes
          default_attrs = Chef::Mixin::DeepMerge.merge(default_attrs, Chef::Mixin::DeepMerge.merge(role.default_attributes,nested_default_attrs))
          override_attrs = Chef::Mixin::DeepMerge.merge(override_attrs, Chef::Mixin::DeepMerge.merge(role.override_attributes, nested_override_attrs))
        end
      end
      
      return recipes, default_attrs, override_attrs
    end
    
    private

    # Return a [type, short_name, typed_name] entry, e.g.,
    # If passed
    #   'recipe[aws::elastic_ip]'
    # will return
    #   ['recipe', 'aws::elastic_ip', 'recipe[aws::elastic_ip]']
    def parse_entry(entry)
      case entry
      when /^(.+)\[(.+)\]$/
        [ $1, $2, entry ]
      else
        [ 'recipe', entry, "recipe[#{entry}]" ]
      end
    end
    
    # data_source should be one of 'disk', 'server', or
    # 'couchdb'. If running in Chef Solo, it adopts the behavior of
    # 'disk'.
    def expand_role(name, data_source)
      begin
        if data_source == 'disk' || Chef::Config[:solo]
          # Load the role from disk
          Chef::Role.from_disk(name) || raise(Chef::Exceptions::RoleNotFound)
        elsif data_source == 'server'
          # Load the role from the server
           begin
            (rest || Chef::REST.new(Chef::Config[:role_url])).get_rest("roles/#{name}") 
          rescue Net::HTTPServerException
            raise Chef::Exceptions::RoleNotFound if $!.message == '404 "Not Found"'
            raise
          end
        elsif data_source == 'couchdb'
          # Load the role from couchdb
          Chef::Role.cdb_load(name, couchdb) rescue Chef::Exceptions::CouchDBNotFound raise(Chef::Exceptions::RoleNotFound)
        end
      rescue Chef::Exceptions::RoleNotFound
        Chef::Log.error("Role #{name} is in the runlist but does not exist. Skipping expand.")
        next
      end
    end

  end
end

