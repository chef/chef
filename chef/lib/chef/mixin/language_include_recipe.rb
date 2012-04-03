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
#

require 'chef/log'

class Chef
  module Mixin
    module LanguageIncludeRecipe

      def include_recipe(*recipe_names)
        result_recipes = Array.new
        recipe_names.flatten.each do |recipe_name|
          if node.run_state[:seen_recipes].has_key?(recipe_name) or node.run_state[:seen_recipes].has_key?(recipe_name + "::default")
            Chef::Log.debug("I am not loading #{recipe_name}, because I have already seen it.")
            next
          end
          node.run_state[:seen_recipes][recipe_name] = true
          begin
            if(Chef::Config[:restricted_recipes].include?(recipe_name))
              raise Chef::Exceptions::RestrictedRecipe.new(recipe_name)
            end

            Chef::Log.debug("Loading Recipe #{recipe_name} via include_recipe")

            cookbook_name, recipe_short_name = Chef::Recipe.parse_recipe_name(recipe_name)
            
            run_context = self.is_a?(Chef::RunContext) ? self : self.run_context
            cookbook = run_context.cookbook_collection[cookbook_name]
            result_recipes << cookbook.load_recipe(recipe_short_name, run_context)
            node.run_state[:runnable_recipes] << recipe_name
          rescue Chef::Exceptions::RestrictedRecipe => e
            if(e.recipe_name == recipe_name)
              msg = 'Restricted recipe encountered:'
            else
              msg = "Restricted recipe dependency found. (#{recipe_name} depends on #{e.recipe_name})."
            end
            Chef::Log.warn msg << " #{recipe_name} -> Not Loaded"
            raise e
          end
        end
        result_recipes
      end

      def require_recipe(*args)
        include_recipe(*args)
      end

    end
  end
end
