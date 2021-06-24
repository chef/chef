#--
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "platform_introspection"
require_relative "data_query"
require_relative "chef_vault"
require_relative "registry_helper"
require_relative "powershell"
require_relative "secret"
require_relative "../mixin/powershell_exec"
require_relative "../mixin/powershell_out"
require_relative "../mixin/shell_out"
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
    module Universal
      include Chef::DSL::PlatformIntrospection
      include Chef::DSL::DataQuery
      include Chef::DSL::ChefVault
      include Chef::DSL::RegistryHelper
      include Chef::DSL::Powershell
      include Chef::DSL::Secret
      include Chef::Mixin::PowershellExec
      include Chef::Mixin::PowershellOut
      include Chef::Mixin::ShellOut
      extend Chef::Mixin::LazyModuleInclude
    end
  end
end
