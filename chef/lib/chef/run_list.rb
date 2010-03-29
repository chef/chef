#
# Author:: Adam Jacob (<adam@opscode.com>)
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

require 'chef/mixin/deep_merge'

class Chef
  class RunList
    include Enumerable

    attr_reader :recipes, :roles, :run_list

    def initialize
      @run_list = Array.new
      @recipes = Array.new
      @roles = Array.new
      @seen_roles = Array.new
    end

    def <<(item)
      type, entry, fentry = parse_entry(item)
      case type
      when 'recipe'
        @recipes << entry unless @recipes.include?(entry)
      when 'role'
        @roles << entry unless @roles.include?(entry)
      end
      @run_list << fentry unless @run_list.include?(fentry)
      self
    end

    def ==(*isequal)
      check_array = nil
      if isequal[0].kind_of?(Chef::RunList)
        check_array = isequal[0].run_list
      else
        check_array = isequal.flatten
      end
      
      return false if check_array.length != @run_list.length

      check_array.each_index do |i|
        to_check = check_array[i]
        type, name, fname = parse_entry(to_check)
        return false if @run_list[i] != fname
      end

      true
    end

    def to_s
      @run_list.join(", ")
    end

    def empty?
      @run_list.length == 0 ? true : false
    end

    def [](pos)
      @run_list[pos]
    end

    def []=(pos, item)
      type, entry, fentry = parse_entry(item)
      @run_list[pos] = fentry 
    end

    def each(&block)
      @run_list.each { |i| block.call(i) }
    end

    def each_index(&block)
      @run_list.each_index { |i| block.call(i) }
    end

    def include?(item)
      type, entry, fentry = parse_entry(item)
      @run_list.include?(fentry)
    end

    def reset!(*args)
      @run_list = Array.new
      @recipes = Array.new
      @roles = Array.new
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
      type, entry, fentry = parse_entry(item)
      @run_list.delete_if { |i| i == fentry }
      if type == "recipe"
        @recipes.delete_if { |i| i == entry }
      elsif type == "role"
        @roles.delete_if { |i| i == entry }
      end
      self
    end

    def expand(from='server', couchdb=nil, rest=nil)
      couchdb = couchdb ? couchdb : Chef::CouchDB.new
      recipes = Array.new
      default_attrs = Mash.new
      override_attrs = Mash.new
      
      @run_list.each do |entry|
        type, name, fname = parse_entry(entry)
        case type
        when 'recipe'
          recipes << name unless recipes.include?(name)
        when 'role'
          role = begin
                   next if @seen_roles.include?(name)
                   @seen_roles << name
                   if from == 'disk' || Chef::Config[:solo]
                     # Load the role from disk
                     Chef::Role.from_disk("#{name}") || raise(Chef::Exceptions::RoleNotFound)
                   elsif from == 'server'
                     # Load the role from the server
                     begin
                       (rest || Chef::REST.new(Chef::Config[:role_url])).get_rest("roles/#{name}") 
                     rescue Net::HTTPServerException
                       raise Chef::Exceptions::RoleNotFound if $!.message == '404 "Not Found"'
                       raise
                     end
                   elsif from == 'couchdb'
                     # Load the role from couchdb
                     Chef::Role.cdb_load(name, couchdb) rescue Chef::Exceptions::CouchDBNotFound raise(Chef::Exceptions::RoleNotFound)
                   end
                 rescue Chef::Exceptions::RoleNotFound
                   Chef::Log.error("Role #{name} is in the runlist but does not exist. Skipping expand.")
                   next
                 end
          rec, d, o = role.run_list.expand(from, couchdb, rest)
          rec.each { |r| recipes <<  r unless recipes.include?(r) }
          default_attrs = Chef::Mixin::DeepMerge.merge(default_attrs, Chef::Mixin::DeepMerge.merge(role.default_attributes,d))
          override_attrs = Chef::Mixin::DeepMerge.merge(override_attrs, Chef::Mixin::DeepMerge.merge(role.override_attributes, o))
        end
      end
      return recipes, default_attrs, override_attrs
    end

    def parse_entry(entry)
      case entry 
      when /^(.+)\[(.+)\]$/
        [ $1, $2, entry ]
      else
        [ 'recipe', entry, "recipe[#{entry}]" ]
      end
    end

  end
end

