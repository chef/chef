#--
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Christopher Walters (<cw@opscode.com>)
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

###
# NOTE: This file and constant are here only for backwards compatibility.
# New code should use Chef::DSL::Recipe instead.
#
# This constant (module name) will eventually be deprecated and then removed.
###

require 'chef/mixin/deprecation'

class Chef
  module Mixin
    deprecate_constant(:RecipeDefinitionDSLCore, Chef::DSL::Recipe, <<-EOM)
Chef::Mixin::RecipeDefinitionDSLCore is deprecated. Use Chef::DSL::Recipe instead.
EOM
  end
end
