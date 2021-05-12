#
# Copyright:: Copyright (c) Chef Software Inc.
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
require "shellwords" unless defined?(Shellwords)

class Chef
  class Resource
    class CronD < Chef::Resource
      unified_mode true

      use "cron_shared"

      provides :cron_d

      introduced "14.4"
      description "Use the **cron_d** resource to manage cron job files in the `/etc/cron.d` directory. This is similar to the 'cron' resource, but it does not use the monolithic /etc/crontab file."
      examples <<~DOC
        **Run a program on the fifth hour of the day**

        ```ruby
        cron_d 'noop' do
          hour '5'
          minute '0'
          command '/bin/true'
        end
        ```

        **Run an entry if a folder exists**

        ```ruby
        cron_d 'ganglia_tomcat_thread_max' do
          command "/usr/bin/gmetric
            -n 'tomcat threads max'
            -t uint32
            -v '/usr/local/bin/tomcat-stat
            --thread-max'"
          only_if { ::File.exist?('/home/jboss') }
        end
        ```

        **Run an entry every Saturday, 8:00 AM**

        ```ruby
        cron_d 'name_of_cron_entry' do
          minute '0'
          hour '8'
          weekday '6'
          mailto 'admin@example.com'
          command '/bin/true'
          action :create
        end
        ```

        **Run an entry at 8:00 PM, every weekday (Monday through Friday), but only in November**

        ```ruby
        cron_d 'name_of_cron_entry' do
          minute '0'
          hour '20'
          day '*'
          month '11'
          weekday '1-5'
          command '/bin/true'
          action :create
        end
        ```

        **Remove a cron job by name**:

        ```ruby
        cron_d 'job_to_remove' do
          action :delete
        end
        ```
      DOC

      property :cron_name, String,
        description: "An optional property to set the cron name if it differs from the resource block's name.",
        name_property: true

      property :cookbook, String, desired_state: false, skip_docs: true

      property :predefined_value, String,
        description: "Schedule your cron job with one of the special predefined value instead of ** * pattern.",
        equal_to: %w{ @reboot @yearly @annually @monthly @weekly @daily @midnight @hourly }

      property :comment, String,
        description: "A comment to place in the cron.d file."

      property :mode, [String, Integer],
        description: "The octal mode of the generated crontab file.",
        default: "0600"

      property :random_delay, Integer,
        description: "Set the `RANDOM_DELAY` environment variable in the cron.d file."

      # warn if someone passes the deprecated cookbook property
      def after_created
        raise ArgumentError, "The 'cookbook' property for the cron_d resource is no longer supported now that it ships as a core resource." if cookbook
      end

      action :create do
        description "Add a cron definition file to `/etc/cron.d`."

        create_template(:create)
      end

      action :create_if_missing, description: "Add a cron definition file to `/etc/cron.d`, but do not update an existing file." do

        create_template(:create_if_missing)
      end

      action :delete, description: "Remove a cron definition file from `/etc/cron.d` if it exists." do

        # cleanup the legacy named job if it exists
        file "legacy named cron.d file" do
          path "/etc/cron.d/#{new_resource.cron_name}"
          action :delete
        end

        file "/etc/cron.d/#{sanitized_name}" do
          action :delete
        end
      end

      action_class do
        # @return [String] cron_name property with . replaced with -
        def sanitized_name
          new_resource.cron_name.tr(".", "-")
        end

        def create_template(create_action)
          # cleanup the legacy named job if it exists
          file "#{new_resource.cron_name} legacy named cron.d file" do
            path "/etc/cron.d/#{new_resource.cron_name}"
            action :delete
            only_if { new_resource.cron_name != sanitized_name }
          end

          # @todo this is Chef 12 era cleanup. Someday we should remove it all
          template "/etc/cron.d/#{sanitized_name}" do
            source ::File.expand_path("../support/cron.d.erb", __dir__)
            local true
            mode new_resource.mode
            sensitive new_resource.sensitive
            variables(
              name: sanitized_name,
              predefined_value: new_resource.predefined_value,
              minute: new_resource.minute,
              hour: new_resource.hour,
              day: new_resource.day,
              month: new_resource.month,
              weekday: new_resource.weekday,
              command: new_resource.command,
              user: new_resource.user,
              mailto: new_resource.mailto,
              path: new_resource.path,
              home: new_resource.home,
              shell: new_resource.shell,
              comment: new_resource.comment,
              random_delay: new_resource.random_delay,
              environment: new_resource.environment
            )
            action create_action
          end
        end
      end
    end
  end
end
