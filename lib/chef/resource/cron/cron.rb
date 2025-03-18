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
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class Cron < Chef::Resource

      use "cron_shared"

      provides :cron, target_mode: true
      target_mode support: :full

      description "Use the **cron** resource to manage cron entries for time-based job scheduling. Properties for a schedule will default to * if not provided. The cron resource requires access to a crontab program, typically cron. Warning: The cron resource should only be used to modify an entry in a crontab file. The `cron_d` resource directly manages `cron.d` files. This resource ships in #{ChefUtils::Dist::Infra::PRODUCT} 14.4 or later and can also be found in the [cron](https://github.com/chef-cookbooks/cron) cookbook) for previous #{ChefUtils::Dist::Infra::PRODUCT} releases."

      examples <<~'DOC'
      **Run a program at a specified interval**

      ```ruby
      cron 'noop' do
        hour '5'
        minute '0'
        command '/bin/true'
      end
      ```

      **Run an entry if a folder exists**

      ```ruby
      cron 'ganglia_tomcat_thread_max' do
        command "/usr/bin/gmetric
          -n 'tomcat threads max'
          -t uint32
          -v '/usr/local/bin/tomcat-stat --thread-max'"
        only_if { ::File.exist?('/home/jboss') }
      end
      ```

      **Run every Saturday, 8:00 AM**

      The following example shows a schedule that will run every hour at 8:00 each Saturday morning, and will then send an email to “admin@example.com” after each run.

      ```ruby
      cron 'name_of_cron_entry' do
        minute '0'
        hour '8'
        weekday '6'
        mailto 'admin@example.com'
        action :create
      end
      ```

      **Run once a week**

      ```ruby
      cron 'cookbooks_report' do
        minute '0'
        hour '0'
        weekday '1'
        user 'chefio'
        mailto 'sysadmin@example.com'
        home '/srv/supermarket/shared/system'
        command %W{
          cd /srv/supermarket/current &&
          env RUBYLIB="/srv/supermarket/current/lib"
          RAILS_ASSET_ID=`git rev-parse HEAD` RAILS_ENV="#{rails_env}"
          bundle exec rake cookbooks_report
        }.join(' ')
        action :create
      end
      ```

      **Run only in November**

      The following example shows a schedule that will run at 8:00 PM, every weekday (Monday through Friday), but only in November:

      ```ruby
      cron 'name_of_cron_entry' do
        minute '0'
        hour '20'
        day '*'
        month '11'
        weekday '1-5'
        action :create
      end
      ```
      DOC

      state_attrs :minute, :hour, :day, :month, :weekday, :user

      default_action :create
      allowed_actions :create, :delete

      property :time, Symbol,
        description: "A time interval.",
        equal_to: Chef::Provider::Cron::SPECIAL_TIME_VALUES

    end
  end
end
