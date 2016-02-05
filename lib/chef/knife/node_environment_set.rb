#
# Author:: Jimmy McCrory (<jimmy.mccrory@gmail.com>)
# Copyright:: Copyright 2014-2016, Jimmy McCrory
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

require "chef/knife"

class Chef
  class Knife
    class NodeEnvironmentSet < Knife

      deps do
        require "chef/node"
      end

      banner "knife node environment set NODE ENVIRONMENT"

      def run
        if @name_args.size < 2
          ui.fatal "You must specify a node name and an environment."
          show_usage
          exit 1
        else
          @node_name = @name_args[0]
          @environment = @name_args[1]
        end

        node = Chef::Node.load(@node_name)

        node.chef_environment = @environment

        node.save

        config[:attribute] = "chef_environment"

        output(format_for_display(node))
      end

    end
  end
end
