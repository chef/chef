#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2009-2016, Bryan McLellan
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

require_relative "../../resource"
require_relative "../helpers/cron_validations"
require_relative "../../provider/cron" # do not remove. we actually need this below

class Chef
  class Resource
    class Cron < Chef::Resource
      unified_mode true

      use "cron_shared"

      provides :cron

      description "Use the **cron** resource to manage cron entries for time-based job scheduling. Properties for a schedule will default to * if not provided. The cron resource requires access to a crontab program, typically cron."

      state_attrs :minute, :hour, :day, :month, :weekday, :user

      default_action :create
      allowed_actions :create, :delete

      property :time, Symbol,
        description: "A time interval.",
        equal_to: Chef::Provider::Cron::SPECIAL_TIME_VALUES

    end
  end
end
