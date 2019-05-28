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

require_relative "../resource"
require "shellwords" unless defined?(Shellwords)
require_relative "../dist"

class Chef
  class Resource
    class CronD < Chef::Resource
      resource_name :cron_d

      introduced "14.4"
      description "Use the cron_d resource to manage cron definitions in /etc/cron.d. This is similar to the 'cron' resource, but it does not use the monolithic /etc/crontab file."

      # validate a provided value is between two other provided values
      # we also allow * as a valid input
      # @param spec the value to validate
      # @param min the lowest value allowed
      # @param max the highest value allowed
      # @return [Boolean] valid or not?
      def self.validate_numeric(spec, min, max)
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

      # validate the provided month value to be jan - dec, 1 - 12, or *
      # @param spec the value to validate
      # @return [Boolean] valid or not?
      def self.validate_month(spec)
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

      # validate the provided day of the week is sun-sat, 0-7, or *
      # @param spec the value to validate
      # @return [Boolean] valid or not?
      def self.validate_dow(spec)
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

      property :cron_name, String,
               description: "An optional property to set the cron name if it differs from the resource block's name.",
               name_property: true

      property :cookbook, String, desired_state: false

      property :predefined_value, String,
               description: 'Schedule your cron job with one of the special predefined value instead of ** * pattern. This correspond to "@reboot", "@yearly", "@annually", "@monthly", "@weekly", "@daily", "@midnight" or "@hourly".',
               equal_to: %w{ @reboot @yearly @annually @monthly @weekly @daily @midnight @hourly }

      property :minute, [Integer, String],
               description: "The minute at which the cron entry should run (0 - 59).",
               default: "*", callbacks: {
                 "should be a valid minute spec" => ->(spec) { validate_numeric(spec, 0, 59) },
               }

      property :hour, [Integer, String],
               description: "The hour at which the cron entry should run (0 - 23).",
               default: "*", callbacks: {
                 "should be a valid hour spec" => ->(spec) { validate_numeric(spec, 0, 23) },
               }

      property :day, [Integer, String],
               description: "The day of month at which the cron entry should run (1 - 31).",
               default: "*", callbacks: {
                 "should be a valid day spec" => ->(spec) { validate_numeric(spec, 1, 31) },
               }

      property :month, [Integer, String],
               description: "The month in the year on which a cron entry is to run (1 - 12, jan-dec, or *).",
               default: "*", callbacks: {
                 "should be a valid month spec" => ->(spec) { validate_month(spec) },
               }

      property :weekday, [Integer, String],
               description: "The day of the week on which this entry is to run (0-7, mon-sun, or *), where Sunday is both 0 and 7.",
               default: "*", callbacks: {
                 "should be a valid weekday spec" => ->(spec) { validate_dow(spec) },
               }

      property :command, String,
               description: "The command to run.",
               required: true

      property :user, String,
               description: "The name of the user that runs the command.",
               default: "root"

      property :mailto, String,
               description: "Set the MAILTO environment variable in the cron.d file."

      property :path, String,
               description: "Set the PATH environment variable in the cron.d file."

      property :home, String,
               description: "Set the HOME environment variable in the cron.d file."

      property :shell, String,
               description: "Set the SHELL environment variable in the cron.d file."

      property :comment, String,
               description: "A comment to place in the cron.d file."

      property :environment, Hash,
               description: "A Hash containing additional arbitrary environment variables under which the cron job will be run in the form of ``({'ENV_VARIABLE' => 'VALUE'})``.",
               default: lazy { Hash.new }

      property :mode, [String, Integer],
               description: "The octal mode of the generated crontab file.",
               default: "0600"

      property :random_delay, Integer,
               description: "Set the RANDOM_DELAY environment variable in the cron.d file."

      # warn if someone passes the deprecated cookbook property
      def after_created
        raise ArgumentError, "The 'cookbook' property for the cron_d resource is no longer supported now that it ships as a core resource." if cookbook
      end

      action :create do
        description "Add a cron definition file to /etc/cron.d."

        create_template(:create)
      end

      action :create_if_missing do
        description "Add a cron definition file to /etc/cron.d, but do not update an existing file."

        create_template(:create_if_missing)
      end

      action :delete do
        description "Remove a cron definition file from /etc/cron.d if it exists."

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
