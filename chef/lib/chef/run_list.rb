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
require 'dep_selector'

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

    # This method replaces verbiage from DepSelector messages with
    # Chef-domain-specific verbiage, such as replacing package with
    # cookbook.
    #
    # TODO [cw, 2011/2/25]: this is a near-term hack. In the long run,
    # we'll do this better.
    def filter_dep_selector_message(message)
      m = message
      m.gsub!("Package", "Cookbook")
      m.gsub!("package", "cookbook")
      m.gsub!("Solution constraint", "Run list item")
      m.gsub!("solution constraint", "run list item")
      m
    end

    # Creates a DependencyGraph from CookbookVersion objects
    def create_dependency_graph_from_cookbooks(all_cookbooks)
      dep_graph = DepSelector::DependencyGraph.new
      all_cookbooks.each do |cb_name, cb_versions|
        cb_versions.each do |cb_version|
          cb_version_deps = cb_version.metadata.dependencies
          # TODO [cw. 2011/2/10]: CookbookVersion#version returns a
          # String even though we're storing as a DepSelector::Version
          # object underneath. This should be changed so that we
          # return the object and handle proper serialization and
          # de-serialization. For now, I'm just going to create a
          # Version object from the String representation.
          pv = dep_graph.package(cb_name).add_version(DepSelector::Version.new(cb_version.version))
          cb_version_deps.each_pair do |dep_name, constraint_str|
            constraint = DepSelector::VersionConstraint.new(constraint_str)
            pv.dependencies << DepSelector::Dependency.new(dep_graph.package(dep_name), constraint)
          end
        end
      end

      dep_graph
    end

    # Return a hash mapping cookbook names to a CookbookVersion
    # object. If there is no solution that satisfies the constraints,
    # the first run list item that caused unsatisfiability is
    # returned.
    #
    # This is the final version-resolved list of cookbooks for the
    # RunList.
    #
    # all_cookbooks - a hash mapping cookbook names to an array of
    # available CookbookVersions.
    #
    # recipe_constraints - an array of hashes describing the expanded
    # run list.  Each element is a hash containing keys :name and
    # :version_constraint. The :name component is either the
    # fully-qualified recipe name (e.g. "cookbook1::non_default_recipe")
    # or just a cookbook name, indicating the default recipe is to be
    # run (e.g. "cookbook1").
    def constrain(all_cookbooks, recipe_constraints)
      dep_graph = create_dependency_graph_from_cookbooks(all_cookbooks)

      # extract cookbook names from (possibly) fully-qualified recipe names
      cookbook_constraints = recipe_constraints.map do |recipe_spec|
        cookbook_name = (recipe_spec[:name][/^(.+)::/, 1] || recipe_spec[:name])
        DepSelector::SolutionConstraint.new(dep_graph.package(cookbook_name),
                                            recipe_spec[:version_constraint])
      end

      # find a valid assignment of CoookbookVersions. If no valid
      # assignment exists, indicate which run_list_item causes the
      # unsatisfiability and try to hint at what might be wrong.
      soln =
        begin
          DepSelector::Selector.new(dep_graph).find_solution(cookbook_constraints)
        rescue DepSelector::Exceptions::InvalidSolutionConstraint,
               DepSelector::Exceptions::NoSolutionExists
          raise Chef::Exceptions::CookbookVersionConflict, filter_dep_selector_message($!.message)
        end

      # map assignment back to CookbookVersion objects
      selected_cookbooks = {}
      soln.each_pair do |cb_name, cb_version|
        # TODO [cw, 2011/2/10]: related to the TODO in
        # create_dependency_graph_from_cookbooks, cbv.version
        # currently returns a String, so we must compare to
        # cb_version.to_s, since it's a for-real Version object.
        selected_cookbooks[cb_name] = all_cookbooks[cb_name].find{|cbv| cbv.version == cb_version.to_s}
      end
      selected_cookbooks
    end

  end
end

