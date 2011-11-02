#
# Author:: Andrew Fulcher (<andrew.fulcher@gmail.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
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

require 'chef/handler'

class Chef
  class Handler
    class ResultToServer < ::Chef::Handler

      def report
        Chef::Log.info("Returning result of the run to Chef Server")
	
	chef_server_url = Chef::Config[:chef_server_url]
	node_name = Chef::Config[:node_name]

	report = data.only(:start_time,:exception,:success,:end_time,:elapsed_time,:backtrace)
	report[:updated_resources] = data[:updated_resources].map{|r| r.to_s} unless data[:updated_resources].nil?

	conn = Chef::REST.new(chef_server_url)
	host_attributes = conn.get_rest("nodes/#{node_name}")
	host_attributes.normal_attrs[:last_run] = report
	conn.put_rest("nodes/#{node_name}", host_attributes)
	
      end

    end
  end
end
