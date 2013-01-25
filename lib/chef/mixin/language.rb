#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'chef/dsl/platform_introspection'
require 'chef/dsl/data_query'
require 'chef/mixin/deprecation'

class Chef
  module Mixin

    # == [DEPRECATED] Chef::Mixin::DeprecatedLanguageModule
    # This module is a temporary replacement for the previous
    # Chef::Mixin::Language. That module's functionality was split into two
    # modules, Chef::DSL::PlatformIntrospection, and Chef::DSL::DataQuery.
    #
    # This module includes both PlatformIntrospection and DataQuery to provide
    # the same interfaces and behavior as the prior Mixin::Language.
    #
    # This module is loaded via const_missing hook when Chef::Mixin::Language
    # is accessed. See chef/mixin/deprecation for details.
    module DeprecatedLanguageModule

      include Chef::DSL::PlatformIntrospection
      include Chef::DSL::DataQuery

    end

    deprecate_constant(:Language, DeprecatedLanguageModule, <<-EOM)
Chef::Mixin::Language is deprecated. Use either (or both)
Chef::DSL::PlatformIntrospection or Chef::DSL::DataQuery instead.
EOM
  end
end
