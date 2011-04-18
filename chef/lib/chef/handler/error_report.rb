#
# Author:: Adam Jacob (<adam@opscode.com>)
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
require 'chef/resource/directory'

class Chef
  class Handler
    class ErrorReport < ::Chef::Handler

      def report
        Chef::Log.fatal("Saving node information to #{report_path}")

        File.open(report_path, "w") do |file|
          file.puts Chef::JSONCompat.to_json_pretty(data)
        end
      end

      def report_path
        File.join(Chef::Config[:file_cache_path], "failed-run-data.json")
      end

    end
  end
end
