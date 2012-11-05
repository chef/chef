#
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'dep_selector'

class Chef
  module CookbookVersionSelector
    # This method replaces verbiage from DepSelector messages with
    # Chef-domain-specific verbiage, such as replacing package with
    # cookbook.
    #
    # TODO [cw, 2011/2/25]: this is a near-term hack. In the long run,
    # we'll do this better.
    def self.filter_dep_selector_message(message)
      m = message
      m.gsub!("Package", "Cookbook")
      m.gsub!("package", "cookbook")
      m.gsub!("Solution constraint", "Run list item")
      m.gsub!("solution constraint", "run list item")
      m
    end

    # all_cookbooks - a hash mapping cookbook names to an array of
    # available CookbookVersions.
    #
    # Creates a DependencyGraph from CookbookVersion objects
    def self.create_dependency_graph_from_cookbooks(all_cookbooks)
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
          pv = dep_graph.package(cb_name).add_version(Chef::Version.new(cb_version.version))
          cb_version_deps.each_pair do |dep_name, constraint_str|
            # if the dependency is specified as cookbook::recipe,
            # extract the cookbook component
            dep_cb_name = dep_name.split("::").first
            constraint = Chef::VersionConstraint.new(constraint_str)
            pv.dependencies << DepSelector::Dependency.new(dep_graph.package(dep_cb_name), constraint)
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
    def self.constrain(all_cookbooks, recipe_constraints)
      dep_graph = create_dependency_graph_from_cookbooks(all_cookbooks)

      # extract cookbook names from (possibly) fully-qualified recipe names
      cookbook_constraints = recipe_constraints.map do |recipe_spec|
        cookbook_name = (recipe_spec[:name][/^(.+)::/, 1] || recipe_spec[:name])
        DepSelector::SolutionConstraint.new(dep_graph.package(cookbook_name),
                                            recipe_spec[:version_constraint])
      end

      # Pass in the list of all available cookbooks (packages) so that
      # DepSelector can distinguish between "no version available for
      # cookbook X" and "no such cookbook X" when an environment
      # filters out all versions for a given cookbook.
      all_packages = all_cookbooks.inject([]) do |acc, (cookbook_name, cookbook_versions)|
        acc << dep_graph.package(cookbook_name)
        acc
      end

      # find a valid assignment of CoookbookVersions. If no valid
      # assignment exists, indicate which run_list_item causes the
      # unsatisfiability and try to hint at what might be wrong.
      soln =
        begin
          DepSelector::Selector.new(dep_graph).find_solution(cookbook_constraints, all_packages)
        rescue DepSelector::Exceptions::InvalidSolutionConstraints => e
          non_existent_cookbooks = e.non_existent_packages.map {|constraint| constraint.package.name}
          cookbooks_with_no_matching_versions = e.constrained_to_no_versions.map {|constraint| constraint.package.name}

          # Spend a whole lot of effort for pluralizing and
          # prettifying the message.
          message = ""
          if non_existent_cookbooks.length > 0
            message += "no such " + (non_existent_cookbooks.length > 1 ? "cookbooks" : "cookbook")
            message += " #{non_existent_cookbooks.join(", ")}"
          end

          if cookbooks_with_no_matching_versions.length > 0
            if message.length > 0
              message += "; "
            end

            message += "no versions match the constraints on " + (cookbooks_with_no_matching_versions.length > 1 ? "cookbooks" : "cookbook")
            message += " #{cookbooks_with_no_matching_versions.join(", ")}"
          end

          message = "Run list contains invalid items: #{message}."

          raise Chef::Exceptions::CookbookVersionSelection::InvalidRunListItems.new(message, non_existent_cookbooks, cookbooks_with_no_matching_versions)
        rescue DepSelector::Exceptions::NoSolutionExists => e
          raise Chef::Exceptions::CookbookVersionSelection::UnsatisfiableRunListItem.new(filter_dep_selector_message(e.message), e.unsatisfiable_solution_constraint, e.disabled_non_existent_packages, e.disabled_most_constrained_packages)
        rescue DepSelector::Exceptions::TimeBoundExceeded, DepSelector::Exceptions::TimeBoundExceededNoSolution
          raise Chef::Exceptions::CookbookVersionSelection::TimeBoundExceeded.new("Version constraints could not be solved in the time allowed")
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

    # Expands the run_list, constrained to the environment's CookbookVersion
    # constraints.
    #
    # Returns:
    #   Hash of: name to CookbookVersion
    def self.expand_to_cookbook_versions(run_list, environment, couchdb=nil)
      # expand any roles in this run_list.
      expanded_run_list = run_list.expand(environment, 'couchdb', :couchdb => couchdb).recipes.with_version_constraints

      cookbooks_for_environment = Chef::Environment.cdb_minimal_filtered_versions(environment, couchdb)
      cookbook_collection = constrain(cookbooks_for_environment, expanded_run_list)
      full_cookbooks = Chef::MinimalCookbookVersion.load_full_versions_of(cookbook_collection.values, couchdb)
      full_cookbooks.inject({}) do |cb_map, cookbook_version|
        cb_map[cookbook_version.name] = cookbook_version
        cb_map
      end
    end
  end
end
