#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
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

require_relative "../exceptions"
require_relative "compliance"
require_relative "declare_resource"
require_relative "definitions"
require_relative "include_recipe"
require_relative "reboot_pending"
require_relative "resources"
require_relative "universal"
require_relative "../mixin/notifying_block"
require_relative "../mixin/lazy_module_include"

class Chef
  module DSL
    # Part of a family of DSL mixins.
    #
    # Chef::DSL::Recipe mixes into Recipes and Providers.
    #   - this is restricted to recipe/resource/provider context where a resource collection exists.
    #   - cookbook authors should typically include modules into here.
    #
    # Chef::DSL::Universal mixes into Recipes, LWRP Resources+Providers, Core Resources+Providers, and Attributes files.
    #   - this adds resources and attributes files.
    #   - do not add helpers which manipulate the resource collection.
    #   - this is for general-purpose stuff that is useful nearly everywhere.
    #   - it also pollutes the namespace of nearly every context, watch out.
    #
    module Recipe
      include Chef::DSL::Compliance
      include Chef::DSL::Universal
      include Chef::DSL::DeclareResource
      include Chef::Mixin::NotifyingBlock
      include Chef::DSL::IncludeRecipe
      include Chef::DSL::RebootPending
      include Chef::DSL::Resources
      include Chef::DSL::Definitions
      extend Chef::Mixin::LazyModuleInclude

      def resource_class_for(snake_case_name)
        Chef::Resource.resource_for_node(snake_case_name, run_context.node)
      end

      def have_resource_class_for?(snake_case_name)
        not resource_class_for(snake_case_name).nil?
      rescue NameError
        false
      end

      def exec(args)
        raise Chef::Exceptions::ResourceNotFound, "exec was called, but you probably meant to use an execute resource.  If not, please call Kernel#exec explicitly.  The exec block called was \"#{args}\""
      end
    end
  end
end
