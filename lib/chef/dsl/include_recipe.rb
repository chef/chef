#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2008-2018, Chef Software Inc.
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

require "chef/log"

class Chef
  module DSL
    module IncludeRecipe

      def include_recipe(*recipe_names)
        run_context.include_recipe(*recipe_names, current_cookbook: cookbook_name)
      end

      def load_recipe(recipe_name)
        run_context.load_recipe(recipe_name, current_cookbook: cookbook_name)
      end

      def require_recipe(*args)
        Chef::Log.warn("require_recipe is deprecated and will be removed in a future release, please use include_recipe")
        include_recipe(*args)
      end

    end
  end
end
