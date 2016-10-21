#--
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Christopher Walters (<cw@chef.io>)
# Copyright:: Copyright 2008-2016 Chef Software, Inc.
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

require "chef/dsl/platform_introspection"
require "chef/mixin/powershell_out"
require "chef/mixin/shell_out"

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
    module Universal
      include Chef::DSL::PlatformIntrospection
      include Chef::Mixin::PowershellOut
      include Chef::Mixin::ShellOut
    end
  end
end
