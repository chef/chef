#--
# Author:: Lamont Granquist <lamont@chef.io>
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

require "chef-utils/dsl/which" unless defined?(ChefUtils::DSL::Which)
require "chef-utils/dsl/default_paths" unless defined?(ChefUtils::DSL::DefaultPaths)
require_relative "chef_utils_wiring" unless defined?(Chef::Mixin::ChefUtilsWiring)

class Chef
  module Mixin
    module Which
      include ChefUtils::DSL::Which
      include ChefUtils::DSL::DefaultPaths
      include ChefUtilsWiring

      private

      # we dep-inject default paths into this API for historical reasons
      #
      # @api private
      def __extra_path
        __default_paths
      end
    end
  end
end
