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

require "chef/exceptions"
require "chef/dsl/resources"
require "chef/dsl/definitions"
require "chef/dsl/data_query"
require "chef/dsl/include_recipe"
require "chef/dsl/registry_helper"
require "chef/dsl/reboot_pending"
require "chef/dsl/audit"
require "chef/dsl/powershell"
require "chef/dsl/core"
require "chef/mixin/lazy_module_include"

class Chef
  module DSL
    # Part of a family of DSL mixins.
    #
    # Chef::DSL::Recipe mixes into Recipes and LWRP Providers.
    #   - this does not target core chef resources and providers.
    #   - this is restricted to recipe/resource/provider context where a resource collection exists.
    #   - cookbook authors should typically include modules into here.
    #
    # Chef::DSL::Core mixes into Recipes, LWRP Providers and Core Providers
    #   - this adds cores providers on top of the Recipe DSL.
    #   - this is restricted to recipe/resource/provider context where a resource collection exists.
    #   - core chef authors should typically include modules into here.
    #
    # Chef::DSL::Universal mixes into Recipes, LWRP Resources+Providers, Core Resources+Providers, and Attributes files.
    #   - this adds resources and attributes files.
    #   - do not add helpers which manipulate the resource collection.
    #   - this is for general-purpose stuff that is useful nearly everywhere.
    #   - it also pollutes the namespace of nearly every context, watch out.
    #
    module Recipe
      include Chef::DSL::Core
      include Chef::DSL::DataQuery
      include Chef::DSL::IncludeRecipe
      include Chef::DSL::RegistryHelper
      include Chef::DSL::RebootPending
      include Chef::DSL::Audit
      include Chef::DSL::Powershell
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

      # @deprecated Use Chef::DSL::Recipe instead, will be removed in Chef 13
      module FullDSL
        include Chef::DSL::Recipe
        extend Chef::Mixin::LazyModuleInclude
      end
    end
  end
end

# Avoid circular references for things that are only used in instance methods
require "chef/resource"

# **DEPRECATED**
# This used to be part of chef/mixin/recipe_definition_dsl_core. Load the file to activate the deprecation code.
require "chef/mixin/recipe_definition_dsl_core"
