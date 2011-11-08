#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

require 'chef/knife'
require 'chef/knife/core/node_presenter'

class Chef
  class Knife
    class NodeShow < Knife

      include Knife::Core::NodeFormattingOptions

      deps do
        require 'chef/node'
        require 'chef/json_compat'
      end

      banner "knife node show NODE (options)"

      @attrs_to_show = []
      option :attribute,
        :short => "-a [ATTR]",
        :long => "--attribute [ATTR]",
        :proc => lambda {|val| @attrs_to_show << val},
        :description => "Show one or more attributes"

      option :run_list,
        :short => "-r",
        :long => "--run-list",
        :description => "Show only the run list"

      option :environment,
        :short        => "-E",
        :long         => "--environment",
        :description  => "Show only the Chef environment"

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
        self.class.attrs_to_show = []
      end

      def self.attrs_to_show=(attrs)
        @attrs_to_show = attrs
      end
    end
  end
end

