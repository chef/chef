#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require_relative "chef/version"

require_relative "chef/mash"
require_relative "chef/exceptions"
require_relative "chef/log"
require_relative "chef/config"
require_relative "chef/providers"
require_relative "chef/resources"

require_relative "chef/daemon"

require_relative "chef/run_status"
require_relative "chef/handler"
require_relative "chef/handler/json_file"
require_relative "chef/event_dispatch/dsl"
require_relative "chef/chef_class"

require_relative "chef/target_io"

require_relative "chef/licensing"
require_relative "chef/context"

if ChefUtils::Dist::Infra::EXEC == "chef"
  # Switch to workstation entitlement if running in Test Kitchen context
  Chef::Context.switch_to_workstation_entitlement if Chef::Context.test_kitchen_context?

  # Fetch and persist license when Chef is loaded as a library
  # This ensures licensing is checked even when not using Chef::Application
  Chef::Licensing.fetch_and_persist
end
