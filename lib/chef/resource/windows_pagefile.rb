#
# Copyright:: 2012-2018, Nordstrom, Inc.
# Copyright:: Copyright (c) Chef Software Inc.
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
      unified_mode true

      provides(:windows_pagefile) { true }

      description "Use the **windows_pagefile** resource to configure pagefile settings on Windows."
      introduced "14.0"
      examples <<~DOC
      **Set the system to manage pagefiles**:

      ```ruby
      windows_pagefile 'Enable automatic management of pagefiles' do
        automatic_managed true
      end
      ```

      **Delete a pagefile**:

      ```ruby
      windows_pagefile 'Delete the pagefile' do
        path 'C'
        action :delete
      end
      ```

      **Switch to system managed pagefiles**:

      ```ruby
      windows_pagefile 'Change the pagefile to System Managed' do
        path 'E:\'
        system_managed true
        action :set
      end
      ```

      **Create a pagefile with an initial and maximum size**:

      ```ruby
      windows_pagefile 'create the pagefile with these sizes' do
        path 'f:\'
        initial_size 100
        maximum_size 200
      end
      ```
      DOC

      property :path, String,
        coerce: proc { |x| x.tr("/", "\\") },
        description: "An optional property to set the pagefile name if it differs from the resource block's name.",
        name_property: true

      property :system_managed, [TrueClass, FalseClass],
        description: "Configures whether the system manages the pagefile size."

      property :automatic_managed, [TrueClass, FalseClass],
        description: "Enable automatic management of pagefile initial and maximum size. Setting this to true ignores `initial_size` and `maximum_size` properties."

      property :initial_size, Integer,
        description: "Initial size of the pagefile in megabytes."

      property :maximum_size, Integer,
        description: "Maximum size of the pagefile in megabytes."

      action :set, description: "Configures the default pagefile, creating if it doesn't exist." do
        automatic_managed = new_resource.automatic_managed

        if automatic_managed
          set_automatic_managed unless automatic_managed?
        elsif automatic_managed == false
          unset_automatic_managed if automatic_managed?
        else
          pagefile = clarify_pagefile_name
          initial_size = new_resource.initial_size
          maximum_size = new_resource.maximum_size
          system_managed = new_resource.system_managed

          # the method below is designed to raise an exception if the drive you are trying to create a pagefile for doesn't exist.
          # PowerShell will happily let you create a pagefile called h:\pagefile.sys even though you don't have an H:\ drive.

          pagefile_drive_exist?(pagefile)
          create(pagefile) unless exists?(pagefile)

          if (initial_size && maximum_size) || system_managed
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

      action :delete, description: "Deletes the specified pagefile." do
        pagefile = clarify_pagefile_name
        delete(pagefile) if exists?(pagefile)
      end

      action_class do
        private

        # We are adding support for a number of possibilities for how users will express the drive and location they want the pagefile written to.
        def clarify_pagefile_name
          case new_resource.path
          # user enters C, C:, C:\, C:\\
          when /^[a-zA-Z]/
            new_resource.path[0] + ":\\pagefile.sys"
          # user enters C:\pagefile.sys OR c:\foo\bar\pagefile.sys as the path
          when /^[a-zA-Z]:.*.sys/
            new_resource.path
          else
            raise "#{new_resource.path} does not match the format DRIVE:\\path\\pagefile.sys for pagefiles. Example: C:\\pagefile.sys"
          end
        end

        # raise an exception if the target drive location is invalid
        def pagefile_drive_exist?(pagefile)
          if ::Dir.exist?(pagefile[0] + ":\\") == false
            raise "You are trying to create a pagefile on a drive that does not exist!"
          end
        end

        # See if the pagefile exists
        #
        # @param [String] pagefile path to the pagefile
        # @return [Boolean]
        def exists?(pagefile)
          @exists ||= begin
            logger.trace("Checking if #{pagefile} exists by running: Get-CimInstance Win32_PagefileSetting | Where-Object { $_.name -eq $($pagefile)} ")
            cmd =  "$page_file_name = '#{pagefile}';"
            cmd << "$pagefile = Get-CimInstance Win32_PagefileSetting | Where-Object { $_.name -eq $($page_file_name)};"
            cmd << "if ([string]::IsNullOrEmpty($pagefile)) { return $false } else { return $true }"
            powershell_exec!(cmd).result
          end
        end

        # is the max/min pagefile size set?
        #
        # @param [String] pagefile path to the pagefile
        # @param [String] min the minimum size of the pagefile
        # @param [String] max the minimum size of the pagefile
        # @return [Boolean]
        def max_and_min_set?(pagefile, min, max)
          logger.trace("Checking if #{pagefile} has max and initial disk size values set")
          cmd =  "$page_file = '#{pagefile}';"
          cmd << "$driveLetter = $page_file.split(':')[0];"
          cmd << "$page_file_settings = Get-CimInstance -ClassName Win32_PageFileSetting -Filter \"SettingID='pagefile.sys @ $($driveLetter):'\" -Property * -ErrorAction Stop;"
          cmd << "if ($page_file_settings.InitialSize -eq #{min} -and $page_file_settings.MaximumSize -eq #{max})"
          cmd << "{ return $true }"
          cmd << "else { return $false }"
          powershell_exec!(cmd).result
        end

        # create a pagefile
        #
        # @param [String] pagefile path to the pagefile
        def create(pagefile)
          converge_by("create pagefile #{pagefile}") do
            logger.trace("Running New-CimInstance -ClassName Win32_PageFileSetting to create new pagefile : #{pagefile}")
            powershell_exec! <<~ELM
              New-CimInstance -ClassName Win32_PageFileSetting -Property  @{Name = "#{pagefile}"}
            ELM
          end
        end

        # delete a pagefile
        #
        # @param [String] pagefile path to the pagefile
        def delete(pagefile)
          converge_by("remove pagefile #{pagefile}") do
            logger.trace("Running Remove-CimInstance for pagefile : #{pagefile}")
            powershell_exec! <<~EOL
              $page_file = "#{pagefile}"
              $driveLetter = $page_file.split(':')[0]
              $PageFile = (Get-CimInstance -ClassName Win32_PageFileSetting -Filter "SettingID='pagefile.sys @ $($driveLetter):'" -ErrorAction Stop)
              $null = ($PageFile | Remove-CimInstance -ErrorAction SilentlyContinue)
            EOL
          end
        end

        # see if the pagefile is automatically managed by Windows
        #
        # @return [Boolean]
        def automatic_managed?
          @automatic_managed ||= begin
            logger.trace("Checking if pagefiles are automatically managed")
            cmd = "$sys = Get-CimInstance Win32_ComputerSystem -Property *;"
            cmd << "return $sys.AutomaticManagedPagefile"
            powershell_exec!(cmd).result
          end
        end

        # turn on automatic management of all pagefiles by Windows
        def set_automatic_managed
          converge_by("Set pagefile to Automatic Managed") do
            logger.trace("Running Set-CimInstance -InputObject $sys -Property @{AutomaticManagedPagefile=$true} -PassThru")
            powershell_exec! <<~EOH
              $sys = Get-CimInstance Win32_ComputerSystem -Property *
              Set-CimInstance -InputObject $sys -Property @{AutomaticManagedPagefile=$true} -PassThru
            EOH
          end
        end

        # turn off automatic management of all pagefiles by Windows
        def unset_automatic_managed
          converge_by("Turn off Automatically Managed on pagefiles") do
            logger.trace("Running Set-CimInstance -InputObject $sys -Property @{AutomaticManagedPagefile=$false} -PassThru")
            powershell_exec! <<~EOH
              $sys = Get-CimInstance Win32_ComputerSystem -Property *
              Set-CimInstance -InputObject $sys -Property @{AutomaticManagedPagefile=$false} -PassThru
            EOH
          end
        end

        # set a custom size for the pagefile (vs the defaults)
        #
        # @param [String] pagefile path to the pagefile
        # @param [String] min the minimum size of the pagefile
        # @param [String] max the minimum size of the pagefile
        def set_custom_size(pagefile, min, max)
          converge_by("set #{pagefile} to InitialSize=#{min} & MaximumSize=#{max}") do
            logger.trace("Set-CimInstance -Property @{InitialSize = #{min} MaximumSize = #{max}")
            powershell_exec! <<~EOD
              $page_file = "#{pagefile}"
              $driveLetter = $page_file.split(':')[0]
              Get-CimInstance -ClassName Win32_PageFileSetting -Filter "SettingID='pagefile.sys @ $($driveLetter):'" -ErrorAction Stop | Set-CimInstance -Property @{
              InitialSize = #{min}
              MaximumSize = #{max}}
            EOD
          end
        end

        # set a pagefile size to be system managed
        #
        # @param [String] pagefile path to the pagefile
        def set_system_managed(pagefile)
          converge_by("set #{pagefile} to System Managed") do
            logger.trace("Running ")
            powershell_exec! <<~EOM
              $page_file = "#{pagefile}"
              $driveLetter = $page_file.split(':')[0]
              Get-CimInstance -ClassName Win32_PageFileSetting -Filter "SettingID='pagefile.sys @ $($driveLetter):'" -ErrorAction Stop | Set-CimInstance -Property @{
              InitialSize = 0
              MaximumSize = 0}
            EOM
          end
        end
      end
    end
  end
end
