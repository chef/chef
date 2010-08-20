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
require 'json'

class Chef
  class Knife
    class CookbookList < Knife

      banner "knife cookbook list (options)"

      option :with_uri,
        :short => "-w",
        :long => "--with-uri",
        :description => "Show corresponding URIs"

      def run
        env          = config[:environment]
        api_endpoint = env ? "/environments/#{env}/cookbooks" : "/cookbooks/_latest"
        output(format_cookbooks_for_display(rest.get_rest(api_endpoint)))
      end

      def format_cookbooks_for_display(api_result)
        api_result.map do |name, uri|
          version = uri.split("/").last
          result = [name, version]
          result << uri if config[:with_uri]
          result
        end
      end
    end
  end
end



