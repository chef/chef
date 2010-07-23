#
# Author:: Daniel DeLeo (<dan@opscode.com>)
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

Chef::Log.info("")
Chef::Log.info("*" * 80)
Chef::Log.info("*   Starting Chef Server in Development Mode.")
Chef::Log.info("*   Start the server with `-e production` for normal use")
Chef::Log.info("*" * 80)
Chef::Log.info("")

Merb::Config.use do |c|
  c[:exception_details] = true
  c[:reload_classes]    = true
  c[:log_level]         = :debug
end
