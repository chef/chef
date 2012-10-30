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
        Chef::FileCache.store("failed-run-data.json", Chef::JSONCompat.to_json_pretty(data), 0640)
        Chef::Log.fatal("Saving node information to #{Chef::FileCache.load("failed-run-data.json", false)}")
      end

    end
  end
end
