#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Nuo Yan (<nuoyan@chef.io>)
# Author:: Tim Hinderliter (<tim@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Author:: Seth Falcon (<seth@chef.io>)
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

require "chef/run_list/run_list_item"
require "chef/run_list/run_list_expansion"
require "chef/run_list/versioned_recipe_list"
require "chef/mixin/params_validate"

class Chef
  class RunList
    include Enumerable
    include Chef::Mixin::ParamsValidate

    # @run_list_items is an array of RunListItems that describe the items to
    # execute in order. RunListItems can load from and convert to the string
    # forms users set on roles and nodes.
    # For example:
    #   @run_list_items = ['recipe[foo::bar]', 'role[webserver]']
    # Thus,
    #   self.role_names would return ['webserver']
    #   self.recipe_names would return ['foo::bar']
    attr_reader :run_list_items

    # For backwards compat
    alias :run_list :run_list_items

    def initialize(*run_list_items)
      @run_list_items = run_list_items.map { |i| coerce_to_run_list_item(i) }
    end

    def role_names
      @run_list_items.inject([]) { |memo, run_list_item| memo << run_list_item.name if run_list_item.role?; memo }
    end

    alias :roles :role_names

    def recipe_names
      @run_list_items.inject([]) { |memo, run_list_item| memo << run_list_item.name if run_list_item.recipe?; memo }
    end

    alias :recipes :recipe_names

    # Add an item of the form "recipe[foo::bar]" or "role[webserver]";
    # takes a String or a RunListItem
    def <<(run_list_item)
      run_list_item = coerce_to_run_list_item(run_list_item)
      @run_list_items << run_list_item unless @run_list_items.include?(run_list_item)
      self
    end

    alias :push :<<
    alias :add :<<

    def ==(other)
      if other.kind_of?(Chef::RunList)
        other.run_list_items == @run_list_items
      else
        return false unless other.respond_to?(:size) && (other.size == @run_list_items.size)
        other_run_list_items = other.dup

        other_run_list_items.map! { |item| coerce_to_run_list_item(item) }
        other_run_list_items == @run_list_items
      end
    end

    def to_s
      @run_list_items.join(", ")
    end

    def for_json
      to_a.map { |item| item.to_s }
    end

    def to_json(*a)
      Chef::JSONCompat.to_json(for_json, *a)
    end

    def empty?
      @run_list_items.length == 0 ? true : false
    end

    def [](pos)
      @run_list_items[pos]
    end

    def []=(pos, item)
      @run_list_items[pos] = parse_entry(item)
    end

    # FIXME: yard with @yield
    def each
      @run_list_items.each { |i| yield(i) }
    end

    # FIXME: yard with @yield
    def each_index
      @run_list_items.each_index { |i| yield(i) }
    end

    def include?(item)
      @run_list_items.include?(parse_entry(item))
    end

    def reset!(*args)
      @run_list_items.clear
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
      @run_list_items.delete_if { |i| i == item }
      self
    end
    alias :delete :remove

    # Expands this run_list: recursively expand roles into their included
    # recipes.
    # Returns a RunListExpansion object.
    def expand(environment, data_source = "server", expansion_opts = {})
      expansion = expansion_for_data_source(environment, data_source, expansion_opts)
      expansion.expand
      expansion
    end

    # Converts a string run list entry to a RunListItem object.
    def parse_entry(entry)
      RunListItem.new(entry)
    end

    def coerce_to_run_list_item(item)
      item.kind_of?(RunListItem) ? item : parse_entry(item)
    end

    def expansion_for_data_source(environment, data_source, opts = {})
      case data_source.to_s
      when "disk"
        RunListExpansionFromDisk.new(environment, @run_list_items)
      when "server"
        RunListExpansionFromAPI.new(environment, @run_list_items, opts[:rest])
      end
    end

  end
end
