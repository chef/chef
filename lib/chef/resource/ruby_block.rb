#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: AJ Christensen (<aj@chef.io>)
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

require_relative "../resource"
require_relative "../provider/ruby_block"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class RubyBlock < Chef::Resource
      unified_mode true

      provides :ruby_block, target_mode: true

      description "Use the **ruby_block** resource to execute Ruby code during a #{ChefUtils::Dist::Infra::PRODUCT} run. Ruby code in the `ruby_block` resource is evaluated with other resources during convergence, whereas Ruby code outside of a `ruby_block` resource is evaluated before other resources, as the recipe is compiled."

      default_action :run
      allowed_actions :create, :run

      def block(&block)
        if block_given? && block
          @block = block
        else
          @block
        end
      end

      property :block_name, String, name_property: true
    end
  end
end
