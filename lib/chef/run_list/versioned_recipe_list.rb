#
# Author:: Stephen Delano (<stephen@chef.io>)
# Author:: Seth Falcon (<seth@chef.io>)
# Copyright:: Copyright 2010-2017, Chef Software Inc.
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
require "chef/version_class"
require "chef/version_constraint"

# Why does this class exist?
# Why did we not just modify RunList/RunListItem?
class Chef
  class RunList
    class VersionedRecipeList < Array

      def initialize
        super
        @versions = Hash.new
      end

      def add_recipe(name, version = nil)
        if version && @versions.has_key?(name)
          unless Chef::Version.new(@versions[name]) == Chef::Version.new(version)
            raise Chef::Exceptions::CookbookVersionConflict, "Run list requires #{name} at versions #{@versions[name]} and #{version}"
          end
        end
        @versions[name] = version if version
        self << name unless include?(name)
      end

      def with_versions
        map { |recipe_name| { :name => recipe_name, :version => @versions[recipe_name] } }
      end

      # Return an Array of Hashes, each of the form:
      #  {:name => RECIPE_NAME, :version_constraint => Chef::VersionConstraint }
      def with_version_constraints
        map do |recipe_name|
          constraint = Chef::VersionConstraint.new(@versions[recipe_name])
          { :name => recipe_name, :version_constraint => constraint }
        end
      end

      # Return an Array of Strings, each of the form:
      #  "NAME@VERSION"
      def with_version_constraints_strings
        map do |recipe_name|
          if @versions[recipe_name]
            "#{recipe_name}@#{@versions[recipe_name]}"
          else
            recipe_name
          end
        end
      end

      # Get an array of strings of the fully-qualified recipe names (with ::default appended) and
      # with the versions in "NAME@VERSION" format.
      #
      # @return [Array] Array of strings with fully-qualified recipe names
      def with_fully_qualified_names_and_version_constraints
        map do |recipe_name|
          qualified_recipe = if recipe_name.include?("::")
                               recipe_name
                             else
                               "#{recipe_name}::default"
                             end

          version = @versions[recipe_name]
          qualified_recipe = "#{qualified_recipe}@#{version}" if version

          qualified_recipe
        end
      end

      # For "foo::default" also include "foo", for "foo" also include "foo::default", for
      # "foo::bar" just return "foo::bar".  This makes it easier for people to search on
      # default recipe names.
      #
      # @return [Array] Array of strings with fully-qualified and unexpanded recipe names
      def with_duplicate_names
        map do |recipe_name|
          if recipe_name.end_with?("::default")
            [ recipe_name.sub(/::default$/, ""), recipe_name ]
          elsif recipe_name.include?("::")
            recipe_name
          else
            [ recipe_name, "#{recipe_name}::default" ]
          end
        end.flatten
      end
    end
  end
end
