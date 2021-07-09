#
# Copyright:: Chef Software, Inc.
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
    class WindowsDefenderExclusion < Chef::Resource

      provides :windows_defender_exclusion

      description "Use the **windows_defender_exclusion** resource to exclude paths, processes, or file types from Windows Defender realtime protection scanning."
      introduced "17.3"
      examples <<~DOC
      **Add excluded items to Windows Defender scans**:

      ```ruby
      windows_defender_exclusion 'Add to things to be excluded from scanning' do
        paths 'c:\\foo\\bar, d:\\bar\\baz'
        extensions 'png, foo, ppt, doc'
        process_paths 'c:\\windows\\system32'
        action :add
      end
      ```

      **Remove excluded items from Windows Defender scans**:

      ```ruby
      windows_defender_exclusion 'Remove things from the list to be excluded' do
        process_paths 'c:\\windows\\system32'
        action :remove
      end
      ```
      DOC
      unified_mode true

      property :paths, [String, Array], default: [],
        coerce: proc { |x| to_consistent_path_array(x) },
        description: "File or directory paths to exclude from scanning."

      property :extensions, [String, Array], default: [],
        coerce: proc { |x| to_consistent_path_array(x) },
        description: "File extensions to exclude from scanning."

      property :process_paths, [String, Array], default: [],
        coerce: proc { |x| to_consistent_path_array(x) },
        description: "Paths to executables to exclude from scanning."

      def to_consistent_path_array(x)
        fixed = x.dup || []
        fixed = fixed.split(/\s*,\s*/) if fixed.is_a?(String)
        fixed.map!(&:downcase)
        fixed.map! { |v| v.gsub(%r{/}, "\\") }
        fixed
      end

      load_current_value do |new_resource|
        Chef::Log.debug("Running 'Get-MpPreference | Select-Object ExclusionExtension,ExclusionPath,ExclusionProcess' to get Windows Defender State")

        values = powershell_exec!("Get-MPpreference | Select-Object ExclusionExtension,ExclusionPath,ExclusionProcess").result

        values.transform_values! { |x| Array(x) }

        paths new_resource.paths & values["ExclusionPath"]
        extensions new_resource.extensions & values["ExclusionExtension"]
        process_paths new_resource.process_paths & values["ExclusionProcess"]
      end

      action :add do
        converge_if_changed do
          powershell_exec!(add_cmd)
        end
      end

      action :remove do
        converge_if_changed do
          powershell_exec!(remove_cmd)
        end
      end

      action_class do
        MAPPING = {
          paths: "ExclusionPath",
          extensions: "ExclusionExtension",
          process_paths: "ExclusionProcess",
        }.freeze

        def add_cmd
          cmd = "Add-MpPreference -Force"

          MAPPING.each do |prop, flag|
            to_add = new_resource.send(prop) - current_resource.send(prop)
            cmd << " -#{flag} #{to_add.join(",")}" unless to_add.empty?
          end

          cmd
        end

        def remove_cmd
          cmd = "Remove-MpPreference -Force"

          MAPPING.each do |prop, flag|
            to_add = new_resource.send(prop) & current_resource.send(prop)
            cmd << " -#{flag} #{to_add.join(",")}" unless to_add.empty?
          end

          cmd
        end
      end
    end
  end
end
