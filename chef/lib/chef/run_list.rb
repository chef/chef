#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Nuo Yan (<nuoyan@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
# Author:: Seth Falcon (<seth@opscode.com>)
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

require 'chef/run_list/run_list_item'
require 'chef/run_list/run_list_expansion'
require 'chef/run_list/versioned_recipe_list'
require 'chef/mixin/params_validate'

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
      @run_list_items.inject([]){|memo, run_list_item| memo << run_list_item.name if run_list_item.role? ; memo}
    end

    alias :roles :role_names

    def recipe_names
      @run_list_items.inject([]){|memo, run_list_item| memo << run_list_item.name if run_list_item.recipe? ; memo}
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

    def to_json(*args)
      to_a.to_json(*args)
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

    def each(&block)
      @run_list_items.each { |i| block.call(i) }
    end

    def each_index(&block)
      @run_list_items.each_index { |i| block.call(i) }
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
      @run_list_items.delete_if{|i| i == item}
      self
    end
    alias :delete :remove


    def expand(data_source='server', expansion_opts={})
      expansion = expansion_for_data_source(data_source, expansion_opts)
      expansion.expand(expansion_opts[:environment])
      expansion
    end

    # Converts a string run list entry to a RunListItem object.
    def parse_entry(entry)
      RunListItem.new(entry)
    end

    def coerce_to_run_list_item(item)
      item.kind_of?(RunListItem) ? item : parse_entry(item)
    end

    def expansion_for_data_source(data_source, opts={})
      data_source = 'disk' if Chef::Config[:solo]
      case data_source.to_s
      when 'disk'
        RunListExpansionFromDisk.new(@run_list_items)
      when 'server'
        RunListExpansionFromAPI.new(@run_list_items, opts[:rest])
      when 'couchdb'
        RunListExpansionFromCouchDB.new(@run_list_items, opts[:couchdb])
      end
    end

    # Return a hash mapping cookbook names to a CookbookVersion
    # object.
    #
    # This is the final version-resolved list of cookbooks for the
    # RunList.
    #
    # all_cookbooks - a hash mapping cookbook names to an array of
    # available CookbookVersions.
    #
    # cookbook_constraints - an array of hashes describing the
    # expanded run list.  Each element is a hash containing keys :name
    # and :version_constraint.
    #
    def constrain(all_cookbooks, cookbook_constraints)
      cookbooks = cookbook_constraints.inject({}) do |included_cookbooks, cookbook_constraint|
        expand_cookbook_deps(included_cookbooks, all_cookbooks, cookbook_constraint, ["Run list"])
        included_cookbooks
      end
      ans = {}
      cookbooks.each do |k, v|
        ans[k] = v[:cookbook]
      end
      ans
    end

    def path_to_s(path)
      "[" + path.join(" -> ") + "]"
    end

    # Accumulates transitive cookbook dependencies no more than once
    # in included_cookbooks
    #
    # included_cookbooks - accumulator for return value, a hash
    # mapping cookbook name to a hash with keys :cookbook,
    # :version_constraint, and :parent.
    #
    #  all_cookbooks - A hash mapping cookbook name to an array of
    # CookbookVersion objects.  These represent all the cookbooks that
    # are available in a given environment.
    #
    # recipe - A hash with keys :name and :version_constraint. 
    #
    # parent_path - A list of cookbook names (or "Run list" for
    # top-level) that tracks where we are in the dependency
    # tree.
    #
    def expand_cookbook_deps(included_cookbooks, all_cookbooks, recipe, parent_path)
      # determine the recipe's parent cookbook, which might be the
      # recipe name in the default case
      cookbook_name = (recipe[:name][/^(.+)::/, 1] || recipe[:name])
      constraint = recipe[:version_constraint]
      if included_cookbooks[cookbook_name]
        # If the new constraint includes the cookbook we have already
        # selected, we will continue.  We can't swap at this point
        # because we've already included the dependencies induced by
        # the version we have.
        already_selected = included_cookbooks[cookbook_name]
        if !constraint.include?(already_selected[:cookbook])
          prev_constraint = already_selected[:version_constraint]
          prev_version = already_selected[:cookbook].version
          prev_path = already_selected[:parent]
          msg = ["Unable to satisfy constraint #{cookbook_name} (#{constraint})",
                 "from #{path_to_s(parent_path)}.",
                 "Already already selected #{cookbook_name}@#{prev_version} via",
                 "#{cookbook_name} (#{prev_constraint}) #{path_to_s(prev_path)}"
                ].join(" ")
          raise Chef::Exceptions::CookbookVersionConflict, msg
        end
        # we've already processed this cookbook, no need to recurse
        return
      end

      choices = all_cookbooks[cookbook_name] || []
      choices = choices.select { |cb| constraint.include?(cb) }
      Chef::Log.debug "Node requires #{cookbook_name} (#{constraint})"
      if choices.empty?
        msg = ("#{path_to_s(parent_path)} depends on cookbook #{cookbook_name} " +
               "(#{constraint}), which is not available on this node")
        raise Chef::Exceptions::CookbookVersionUnavailable, msg
      end
      # pick the highest version
      cookbook = choices.sort.last
      included_cookbooks[cookbook_name] = {
        :cookbook => cookbook,
        :version_constraint => constraint,
        # store a copy of our path (not strictly necessary, but avoids
        # a future code tweak from breaking)
        :parent => parent_path.dup
      }
      # add current cookbook to a new copy of the parent path to
      # pass to the recursive call
      parent_path = parent_path.dup
      parent_path << cookbook_name
      cookbook.metadata.dependencies.each do |dep_name, version_constraint|
        recipe = {
          :name => dep_name,
          :version_constraint => Chef::VersionConstraint.new(version_constraint)
        }
        expand_cookbook_deps(included_cookbooks, all_cookbooks, recipe, parent_path)
      end
    end
  end
end

