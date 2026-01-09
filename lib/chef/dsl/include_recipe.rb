#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "../log"

class Chef
  module DSL
    module IncludeRecipe

      def include_recipe(*recipe_names)
        run_context.include_recipe(*recipe_names, current_cookbook: cookbook_name)
      end

      def load_recipe(recipe_name)
        run_context.load_recipe(recipe_name, current_cookbook: cookbook_name)
      end
    end
  end
end
