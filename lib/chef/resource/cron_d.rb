#
# Copyright:: 2008-2018, Chef Software, Inc.
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

require "chef/resource"
require "shellwords"

class Chef
  class Resource
    class CronD < Chef::Resource
      preview_resource true
      resource_name :cron_d

      introduced "14.3"
      description ""

      property :cron_name, String,
               description: "Set the name of the cron job. If this isn't specified we'll use the resource name.",
               name_property: true

      property :cookbook, String

      property :predefined_value, String,
               description: 'Schedule your cron job with one of the special predefined value instead of ** * pattern. This correspond to "@reboot", "@yearly", "@annually", "@monthly", "@weekly", "@daily", "@midnight" or "@hourly".',
               equal_to: %w{ @reboot @yearly @annually @monthly @weekly @daily @midnight @hourly }

      property :minute, [Integer, String],
               description: "",
               default: "*", callbacks: {
                 "should be a valid minute spec" => ->(spec) { validate_numeric(spec, 0, 59) }
               }

      property :hour, [Integer, String],
               description: "",
               default: "*", callbacks: {
                 "should be a valid hour spec" => ->(spec) { validate_numeric(spec, 0, 23) }
               }

      property :day, [Integer, String],
               description: "",
               default: "*", callbacks: {
                 "should be a valid day spec" => ->(spec) { validate_numeric(spec, 1, 31) }
               }

      property :month, [Integer, String],
               description: "",
               default: "*", callbacks: {
                 "should be a valid month spec" => ->(spec) { validate_month(spec) }
               }

      property :weekday, [Integer, String],
               description: "",
               default: "*", callbacks: {
                 "should be a valid weekday spec" => ->(spec) { validate_dow(spec) }
               }

      property :command, String,
               description: "The command to run.",
               required: true

      property :user, String,
               description: "The user to run the cron job as.",
               default: "root"

      property :mailto, [String, NilClass],
               description: "Set the MAILTO environment variable in the cron.d file."

      property :path, [String, NilClass],
               description: "Set the PATH environment variable in the cron.d file."

      property :home, [String, NilClass],
               description: ""

      property :shell, [String, NilClass],
               description: "Set the HOME environment variable in the cron.d file."

      property :comment, [String, NilClass],
               description: "A comment to place in the cron.d file."

      property :environment, Hash,
               description: "A Hash containing additional arbitrary environment variables under which the cron job will be run.",
               default: {}

      property :mode, [String, Integer],
               description: "The octal mode of the generated crontab file.",
               default: "0600"

      def after_created
        raise ArgumentError, "The 'cookbook' property for the cron_d resource is no longer supported now that this resource ships in Chef itself." if new_resource.cookbook
      end

      def validate_numeric(spec, min, max)
        return true if spec == "*"
        #  binding.pry
        if spec.respond_to? :to_int
          return false unless spec >= min && spec <= max
          return true
        end

        # Lists of invidual values, ranges, and step values all share the validity range for type
        spec.split(%r{\/|-|,}).each do |x|
          next if x == "*"
          return false unless x =~ /^\d+$/
          x = x.to_i
          return false unless x >= min && x <= max
        end
        true
      end

      def validate_month(spec)
        return true if spec == "*"
        if spec.respond_to? :to_int
          validate_numeric(spec, 1, 12)
        elsif spec.respond_to? :to_str
          return true if spec == "*"
          # Named abbreviations are permitted but not as part of a range or with stepping
          return true if %w{jan feb mar apr may jun jul aug sep oct nov dec}.include? spec.downcase
          # 1-12 are legal for months
          validate_numeric(spec, 1, 12)
        else
          false
        end
      end

      def validate_dow(spec)
        return true if spec == "*"
        if spec.respond_to? :to_int
          validate_numeric(spec, 0, 7)
        elsif spec.respond_to? :to_str
          return true if spec == "*"
          # Named abbreviations are permitted but not as part of a range or with stepping
          return true if %w{sun mon tue wed thu fri sat}.include? spec.downcase
          # 0-7 are legal for days of week
          validate_numeric(spec, 0, 7)
        else
          false
        end
      end

      action :create do
        create_template(:create)
      end

      action :create_if_missing do
        create_template(:create_if_missing)
      end

      action :delete do
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

          template "/etc/cron.d/#{sanitized_name}" do
            source ::File.expand_path("../support/cron.d.erb", __FILE__)
            local true
            mode new_resource.mode
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
              environment: new_resource.environment
            )
            action create_action
          end
        end
      end
    end
  end
end
