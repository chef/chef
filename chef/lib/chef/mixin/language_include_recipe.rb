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

      def include_recipe(*args)
        args.flatten.each do |recipe|
          if @node.run_state[:seen_recipes].has_key?(recipe)
            Chef::Log.debug("I am not loading #{recipe}, because I have already seen it.")
            next
          end        

          Chef::Log.debug("Loading Recipe #{recipe} via include_recipe")
          @node.run_state[:seen_recipes][recipe] = true

          rmatch = recipe.match(/(.+?)::(.+)/)
          if rmatch
            cookbook = @cookbook_loader[rmatch[1]]
            cookbook.load_recipe(rmatch[2], @node, @collection, @definitions, @cookbook_loader)
          else
            cookbook = @cookbook_loader[recipe]
            cookbook.load_recipe("default", @node, @collection, @definitions, @cookbook_loader)
          end
        end
      end

      def require_recipe(*args)
        include_recipe(*args)
      end

    end
  end
end
      
