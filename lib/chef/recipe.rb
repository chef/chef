#--
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

require "chef/dsl/recipe"
require "chef/mixin/from_file"
require "chef/mixin/deprecation"

class Chef
  # == Chef::Recipe
  # A Recipe object is the context in which Chef recipes are evaluated.
  class Recipe
    attr_accessor :cookbook_name, :recipe_name, :recipe, :params, :run_context

    include Chef::DSL::Recipe

    include Chef::Mixin::FromFile
    include Chef::Mixin::Deprecation

    # Parses a potentially fully-qualified recipe name into its
    # cookbook name and recipe short name.
    #
    # For example:
    #   "aws::elastic_ip" returns [:aws, "elastic_ip"]
    #   "aws" returns [:aws, "default"]
    #   "::elastic_ip" returns [ current_cookbook, "elastic_ip" ]
    #--
    # TODO: Duplicates functionality of RunListItem
    def self.parse_recipe_name(recipe_name, current_cookbook: nil)
      case recipe_name
      when /(.+?)::(.+)/
        [ $1.to_sym, $2 ]
      when /^::(.+)/
        raise "current_cookbook is nil, cannot resolve #{recipe_name}" if current_cookbook.nil?
        [ current_cookbook.to_sym, $1 ]
      else
        [ recipe_name.to_sym, "default" ]
      end
    end

    def initialize(cookbook_name, recipe_name, run_context)
      @cookbook_name = cookbook_name
      @recipe_name = recipe_name
      @run_context = run_context
      # TODO: 5/19/2010 cw/tim: determine whether this can be removed
      @params = Hash.new
    end

    # Used in DSL mixins
    def node
      run_context.node
    end

    # Used by the DSL to look up resources when executing in the context of a
    # recipe.
    def resources(*args)
      run_context.resource_collection.find(*args)
    end

    # This was moved to Chef::Node#tag, redirecting here for compatibility
    def tag(*tags)
      run_context.node.tag(*tags)
    end

    # Returns true if the node is tagged with *all* of the supplied +tags+.
    #
    # === Parameters
    # tags<Array>:: A list of tags
    #
    # === Returns
    # true<TrueClass>:: If all the parameters are present
    # false<FalseClass>:: If any of the parameters are missing
    def tagged?(*tags)
      tags.each do |tag|
        return false unless run_context.node.tags.include?(tag)
      end
      true
    end

    # Removes the list of tags from the node.
    #
    # === Parameters
    # tags<Array>:: A list of tags
    #
    # === Returns
    # tags<Array>:: The current list of run_context.node.tags
    def untag(*tags)
      tags.each do |tag|
        run_context.node.tags.delete(tag)
      end
    end

    def to_s
      "cookbook: #{cookbook_name ? cookbook_name : "(none)"}, recipe: #{recipe_name ? recipe_name : "(none)"} "
    end

    def inspect
      to_s
    end
  end
end
