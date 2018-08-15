#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2010-2016, Chef Software Inc.
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
    class NodeList < Knife

      deps do
        require "chef/node"
        require "chef/json_compat"
      end

      banner "knife node list (options)"

      option :with_uri,
        short: "-w",
        long: "--with-uri",
        description: "Show corresponding URIs"

      def run
        env = Chef::Config[:environment]
        output(format_list_for_display( env ? Chef::Node.list_by_environment(env) : Chef::Node.list ))
      end

    end
  end
end
