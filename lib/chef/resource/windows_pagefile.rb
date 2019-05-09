#
# Copyright:: 2012-2018, Nordstrom, Inc.
# Copyright:: 2017-2018, Chef Software, Inc.
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

class Chef
  class Resource
    class WindowsPagefile < Chef::Resource
      resource_name :windows_pagefile
      provides(:windows_pagefile) { true }

      description "Use the windows_pagefile resource to configure pagefile settings on Windows."
      introduced "14.0"

      property :path, String,
               coerce: proc { |x| x.tr("/", '\\') },
               description: "An optional property to set the pagefile name if it differs from the resource block's name.",
               name_property: true

      property :system_managed, [TrueClass, FalseClass],
               description: "Configures whether the system manages the pagefile size."

      property :automatic_managed, [TrueClass, FalseClass],
               description: "Enable automatic management of pagefile initial and maximum size. Setting this to true ignores 'initial_size' and 'maximum_size' properties.",
               default: false

      property :initial_size, Integer,
               description: "Initial size of the pagefile in megabytes."

      property :maximum_size, Integer,
               description: "Maximum size of the pagefile in megabytes."

      action :set do
        description "Configures the default pagefile, creating if it doesn't exist."

        pagefile = new_resource.path
        initial_size = new_resource.initial_size
        maximum_size = new_resource.maximum_size
        system_managed = new_resource.system_managed
        automatic_managed = new_resource.automatic_managed

        if automatic_managed
          set_automatic_managed unless automatic_managed?
        else
          unset_automatic_managed if automatic_managed?

          # Check that the resource is not just trying to unset automatic managed, if it is do nothing more
          if (initial_size && maximum_size) || system_managed
            validate_name
            create(pagefile) unless exists?(pagefile)

            if system_managed
              set_system_managed(pagefile) unless max_and_min_set?(pagefile, 0, 0)
            else
              unless max_and_min_set?(pagefile, initial_size, maximum_size)
                set_custom_size(pagefile, initial_size, maximum_size)
              end
            end
          end
        end
      end

      action :delete do
        description "Deletes the specified pagefile."

        validate_name
        delete(new_resource.path) if exists?(new_resource.path)
      end

      action_class do
        # make sure the provided name property matches the appropriate format
        # we do this here and not in the property itself because if automatic_managed
        # is set then this validation is not necessary / doesn't make sense at all
        def validate_name
          return if /^.:.*.sys/ =~ new_resource.path
          raise "#{new_resource.path} does not match the format DRIVE:\\path\\file.sys for pagefiles. Example: C:\\pagefile.sys"
        end

        # See if the pagefile exists
        #
        # @param [String] pagefile path to the pagefile
        # @return [Boolean]
        def exists?(pagefile)
          @exists ||= begin
            logger.trace("Checking if #{pagefile} exists by runing: wmic.exe pagefileset where SettingID=\"#{get_setting_id(pagefile)}\" list /format:list")
            cmd = shell_out("wmic.exe pagefileset where SettingID=\"#{get_setting_id(pagefile)}\" list /format:list", returns: [0])
            cmd.stderr.empty? && (cmd.stdout =~ /SettingID=#{get_setting_id(pagefile)}/i)
          end
        end

        # is the max/min pagefile size set?
        #
        # @param [String] pagefile path to the pagefile
        # @param [String] min the minimum size of the pagefile
        # @param [String] max the minimum size of the pagefile
        # @return [Boolean]
        def max_and_min_set?(pagefile, min, max)
          @max_and_min_set ||= begin
            logger.trace("Checking if #{pagefile} min: #{min} and max #{max} are set")
            cmd = shell_out("wmic.exe pagefileset where SettingID=\"#{get_setting_id(pagefile)}\" list /format:list", returns: [0])
            cmd.stderr.empty? && (cmd.stdout =~ /InitialSize=#{min}/i) && (cmd.stdout =~ /MaximumSize=#{max}/i)
          end
        end

        # create a pagefile
        #
        # @param [String] pagefile path to the pagefile
        def create(pagefile)
          converge_by("create pagefile #{pagefile}") do
            logger.trace("Running wmic.exe pagefileset create name=\"#{pagefile}\"")
            cmd = shell_out("wmic.exe pagefileset create name=\"#{pagefile}\"")
            check_for_errors(cmd.stderr)
          end
        end

        # delete a pagefile
        #
        # @param [String] pagefile path to the pagefile
        def delete(pagefile)
          converge_by("remove pagefile #{pagefile}") do
            logger.trace("Running wmic.exe pagefileset where SettingID=\"#{get_setting_id(pagefile)}\" delete")
            cmd = shell_out("wmic.exe pagefileset where SettingID=\"#{get_setting_id(pagefile)}\" delete")
            check_for_errors(cmd.stderr)
          end
        end

        # see if the pagefile is automatically managed by Windows
        #
        # @return [Boolean]
        def automatic_managed?
          @automatic_managed ||= begin
            logger.trace("Checking if pagefiles are automatically managed")
            cmd = shell_out("wmic.exe computersystem where name=\"%computername%\" get AutomaticManagedPagefile /format:list")
            cmd.stderr.empty? && (cmd.stdout =~ /AutomaticManagedPagefile=TRUE/i)
          end
        end

        # turn on automatic management of all pagefiles by Windows
        def set_automatic_managed
          converge_by("set pagefile to Automatic Managed") do
            logger.trace("Running wmic.exe computersystem where name=\"%computername%\" set AutomaticManagedPagefile=True")
            cmd = shell_out("wmic.exe computersystem where name=\"%computername%\" set AutomaticManagedPagefile=True")
            check_for_errors(cmd.stderr)
          end
        end

        # turn off automatic management of all pagefiles by Windows
        def unset_automatic_managed
          converge_by("set pagefile to User Managed") do
            logger.trace("Running wmic.exe computersystem where name=\"%computername%\" set AutomaticManagedPagefile=False")
            cmd = shell_out("wmic.exe computersystem where name=\"%computername%\" set AutomaticManagedPagefile=False")
            check_for_errors(cmd.stderr)
          end
        end

        # set a custom size for the pagefile (vs the defaults)
        #
        # @param [String] pagefile path to the pagefile
        # @param [String] min the minimum size of the pagefile
        # @param [String] max the minimum size of the pagefile
        def set_custom_size(pagefile, min, max)
          converge_by("set #{pagefile} to InitialSize=#{min} & MaximumSize=#{max}") do
            logger.trace("Running wmic.exe pagefileset where SettingID=\"#{get_setting_id(pagefile)}\" set InitialSize=#{min},MaximumSize=#{max}")
            cmd = shell_out("wmic.exe pagefileset where SettingID=\"#{get_setting_id(pagefile)}\" set InitialSize=#{min},MaximumSize=#{max}", returns: [0])
            check_for_errors(cmd.stderr)
          end
        end

        # set a pagefile size to be system managed
        #
        # @param [String] pagefile path to the pagefile
        def set_system_managed(pagefile)
          converge_by("set #{pagefile} to System Managed") do
            logger.trace("Running wmic.exe pagefileset where SettingID=\"#{get_setting_id(pagefile)}\" set InitialSize=0,MaximumSize=0")
            cmd = shell_out("wmic.exe pagefileset where SettingID=\"#{get_setting_id(pagefile)}\" set InitialSize=0,MaximumSize=0", returns: [0])
            check_for_errors(cmd.stderr)
          end
        end

        def get_setting_id(pagefile)
          split_path = pagefile.split('\\')
          "#{split_path[1]} @ #{split_path[0]}"
        end

        # raise if there's an error on stderr on a shellout
        def check_for_errors(stderr)
          raise stderr.chomp unless stderr.empty?
        end
      end
    end
  end
end
