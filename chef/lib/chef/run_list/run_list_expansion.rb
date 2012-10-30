#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2010, 2011 Opscode, Inc.
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

require 'chef/mash'

require 'chef/mixin/deep_merge'

require 'chef/role'
require 'chef/rest'

class Chef
  class RunList
    # Abstract Base class for expanding a run list. Subclasses must handle
    # fetching roles from a data source by defining +fetch_role+
    class RunListExpansion

      attr_reader :run_list_items

      # A VersionedRecipeList of recipes. Populated only after #expand
      # is called.
      attr_reader :recipes

      attr_reader :default_attrs

      attr_reader :override_attrs

      attr_reader :environment

      attr_reader :missing_roles_with_including_role

      # The data source passed to the constructor. Not used in this class.
      # In subclasses, this is a couchdb or Chef::REST object pre-configured
      # to fetch roles from their correct location.
      attr_reader :source

      # Returns a Hash of the form "including_role" => "included_role_or_recipe".
      # This can be used to show the expanded run list (ordered) graph.
      # ==== Caveats
      # * Duplicate roles are not shown.
      attr_reader :run_list_trace

      def initialize(environment, run_list_items, source=nil)
        @environment = environment
        @missing_roles_with_including_role = Array.new

        @run_list_items = run_list_items.dup
        @source = source

        @default_attrs = Mash.new
        @override_attrs = Mash.new

        @recipes = Chef::RunList::VersionedRecipeList.new

        @applied_roles = {}
        @run_list_trace = Hash.new {|h, key| h[key] = [] }
      end

      # Did we find any errors (expanding roles)?
      def errors?
        @missing_roles_with_including_role.length > 0
      end

      alias :invalid? :errors?

      # Recurses over the run list items, expanding roles. After this,
      # +recipes+ will contain the fully expanded recipe list
      def expand
        # Sure do miss function arity when being recursive
        expand_run_list_items(@run_list_items)
      end

      # Fetches and inflates a role
      # === Returns
      # Chef::Role  in most cases
      # false       if the role has already been applied
      # nil         if the role does not exist
      def inflate_role(role_name, included_by)
        return false if applied_role?(role_name) # Prevent infinite loops
        applied_role(role_name)
        fetch_role(role_name, included_by)
      end

      def apply_role_attributes(role)
        @default_attrs = Chef::Mixin::DeepMerge.role_merge(@default_attrs, role.default_attributes)
        @override_attrs = Chef::Mixin::DeepMerge.role_merge(@override_attrs, role.override_attributes)
      end

      def applied_role?(role_name)
        @applied_roles.has_key?(role_name)
      end

      # Returns an array of role names that were expanded; this
      # includes any roles that were in the original, pre-expansion
      # run_list as well as roles processed during
      # expansion. Populated only after #expand is called.
      def roles
        @applied_roles.keys
      end

      # In subclasses, this method will fetch the role from the data source.
      def fetch_role(name, included_by)
        raise NotImplementedError
      end

      # When a role is not found, an error message is logged, but no
      # exception is raised.  We do add an entry in the errors collection.
      # === Returns
      # nil
      def role_not_found(name, included_by)
        Chef::Log.error("Role #{name} (included by '#{included_by}') is in the runlist but does not exist. Skipping expand.")
        @missing_roles_with_including_role << [name, included_by]
        nil
      end

      def errors
        @missing_roles_with_including_role.map {|item| item.first }
      end

      private

      # these methods modifies internal state based on arguments, so hide it.

      def applied_role(role_name)
        @applied_roles[role_name] = true
      end

      def expand_run_list_items(items, included_by="top level")
        if entry = items.shift
          @run_list_trace[included_by.to_s] << entry.to_s

          case entry.type
          when :recipe
            recipes.add_recipe(entry.name, entry.version)
          when :role
            if role = inflate_role(entry.name, included_by)
              expand_run_list_items(role.run_list_for(@environment).run_list_items, role)
              apply_role_attributes(role)
            end
          end
          expand_run_list_items(items, included_by)
        end
      end

    end

    # Expand a run list from disk. Suitable for chef-solo
    class RunListExpansionFromDisk < RunListExpansion

      def fetch_role(name, included_by)
        Chef::Role.from_disk(name)
      rescue Chef::Exceptions::RoleNotFound
        role_not_found(name, included_by)
      end

    end

    # Expand a run list from the chef-server API.
    class RunListExpansionFromAPI < RunListExpansion

      def rest
        @rest ||= (source || Chef::REST.new(Chef::Config[:role_url]))
      end

      def fetch_role(name, included_by)
        rest.get_rest("roles/#{name}")
      rescue Net::HTTPServerException => e
        if e.message == '404 "Not Found"'
          role_not_found(name, included_by)
        else
          raise
        end
      end
    end

  end
end
