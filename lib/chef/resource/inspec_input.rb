#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
    class InspecInput < Chef::Resource
      provides :inspec_input, target_mode: true
      target_mode support: :full

      description "Use the **inspec_input** resource to add an input to the Compliance Phase."
      introduced "17.5"
      examples <<~DOC

      **Activate the default input in the openssh cookbook's compliance segment**:

      ```ruby
        inspec_input 'openssh' do
          action :add
        end
      ```

      **Activate all inputs in the openssh cookbook's compliance segment**:

      ```ruby
        inspec_input 'openssh::.*' do
          action :add
        end
      ```

      **Add an InSpec input to the Compliance Phase from a hash**:

      ```ruby
        inspec_input { ssh_custom_path: '/whatever2' }
      ```

      **Add an InSpec input to the Compliance Phase using the 'name' property to identify the input**:

      ```ruby
        inspec_input "setting my input" do
          source( { ssh_custom_path: '/whatever2' })
        end
      ```

      **Add an InSpec input to the Compliance Phase using a TOML, JSON, or YAML file**:

      ```ruby
        inspec_input "/path/to/my/input.yml"
      ```

      **Add an InSpec input to the Compliance Phase using a TOML, JSON, or YAML file, using the 'name' property**:

      ```ruby
        inspec_input "setting my input" do
          source "/path/to/my/input.yml"
        end
      ```

      Note that the **inspec_input** resource does not update and will not fire notifications (similar to the log resource). This is done to preserve the ability to use
      the resource while not causing the updated resource count to be larger than zero. Since the resource does not update the state of the managed node, this behavior
      is still consistent with the configuration management model. Instead, you should use events to observe configuration changes for the compliance phase. It is
      possible to use the `notify_group` resource to chain notifications of the two resources, but notifications are the wrong model to use, and you should use pure ruby
      conditionals instead. Compliance configuration should be independent of other resources and should only be conditional based on state/attributes, not other resources.
      DOC

      property :name, [ Hash, String ]

      property :input, [ Hash, String ],
        name_property: true

      property :source, [ Hash, String ],
        name_property: true

      action :add, description: "Add an input to the compliance phase" do
        if run_context.input_collection.valid?(new_resource.input)
          include_input(new_resource.input)
        else
          include_input(input_hash)
        end
      end

      action_class do
        # If the source is nil and the input / name_property contains a file separator and is a string of a
        # file that exists, then use that as the file (similar to the package provider automatic source property).  Otherwise
        # just return the source.
        #
        # @api private
        def source
          @source ||= build_source
        end

        def build_source
          return new_resource.source unless new_resource.source.nil?
          return nil unless new_resource.input.count(::File::SEPARATOR) > 0 || (::File::ALT_SEPARATOR && new_resource.input.count(::File::ALT_SEPARATOR) > 0 )

          # InSpec gets processed locally, so no TargetIO
          return nil unless ::File.exist?(new_resource.input)

          new_resource.input
        end

        def input_hash
          case source
          when Hash
            source
          when String
            parse_file(source)
          when nil
            raise Chef::Exceptions::ValidationFailed, "Could not find the input #{new_resource.input} in any cookbook segment."
          end
        end
      end
    end
  end
end
