#
# Author:: Adam Jacob (<adam@chef.io>)
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

require_relative "../knife"
require_relative "core/node_presenter"
require_relative "core/formatting_options"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Knife
    class NodeShow < Knife

      include Knife::Core::FormattingOptions
      include Knife::Core::MultiAttributeReturnOption

      deps do
        require "chef/node" unless defined?(Chef::Node)
        require "chef/json_compat" unless defined?(Chef::JSONCompat)
      end

      banner "knife node show NODE (options)"

      option :run_list,
        short: "-r",
        long: "--run-list",
        description: "Show only the run list."

      option :environment,
        short: "-E",
        long: "--environment",
        description: "Show only the #{ChefUtils::Dist::Infra::PRODUCT} environment."

      def run
        ui.use_presenter Knife::Core::NodePresenter
        @node_name = @name_args[0]

        if @node_name.nil?
          show_usage
          ui.fatal("You must specify a node name")
          exit 1
        end

        node = Chef::Node.load(@node_name)
        output(format_for_display(node))
      end
    end
  end
end
