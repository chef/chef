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
require 'chef' / 'node'

module Merb
  module ChefServerSlice
    module StatusHelper
      def recipe_list(node)
        data = Chef::Node.load(node)
        response = ""
        data.recipes.each do |recipe|
          response << "<em> #{recipe}</em>"
        end
        response
      end

      def get_info(node)
        data = Chef::Node.load(node)
        response = ""
        response << "<b>FQDN: </b><em>#{data[:fqdn]}</em><br>"
        response << "<b>IP Address: </b><em>#{data[:ipaddress]}</em><br>"
        ohai_time = Time.at(data[:ohai_time])
        response << "<b>Last Check-in: </b><em>#{ohai_time}</em><br>"
        response << "<b>Uptime: </b><em>#{data[:uptime]}</em><br>"
        response << "<b>Platform: </b><em>#{data[:platform]} #{data[:platform_version]}</em>"
        response
      end
    end

  end
end
