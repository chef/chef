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
    class InspecWaiver < Chef::Resource
      provides :inspec_waiver, target_mode: true
      target_mode support: :full

      description "Use the **inspec_waiver** resource to add a waiver to the Compliance Phase."
      introduced "17.5"
      examples <<~DOC
      **Activate the default waiver in the openssh cookbook's compliance segment**:

      ```ruby
        inspec_waiver 'openssh' do
          action :add
        end
      ```

      **Activate all waivers in the openssh cookbook's compliance segment**:

      ```ruby
        inspec_waiver 'openssh::.*' do
          action :add
        end
      ```

      **Add an InSpec waiver to the Compliance Phase**:

      ```ruby
        inspec_waiver 'Add waiver entry for control' do
          control 'my_inspec_control_01'
          run_test false
          justification "The subject of this control is not managed by #{ChefUtils::Dist::Infra::PRODUCT} on the systems in policy group \#{node['policy_group']}"
          expiration '2022-01-01'
          action :add
        end
      ```

      **Add an InSpec waiver to the Compliance Phase using the 'name' property to identify the control**:

      ```ruby
        inspec_waiver 'my_inspec_control_01' do
          justification "The subject of this control is not managed by #{ChefUtils::Dist::Infra::PRODUCT} on the systems in policy group \#{node['policy_group']}"
          action :add
        end
      ```

      **Add an InSpec waiver to the Compliance Phase using an arbitrary YAML, JSON, or TOML file**:

      ```ruby
        # files ending in .yml or .yaml that exist are parsed as YAML
        inspec_waiver "/path/to/my/waiver.yml"

        inspec_waiver "my-waiver-name" do
          source "/path/to/my/waiver.yml"
        end

        # files ending in .json that exist are parsed as JSON
        inspec_waiver "/path/to/my/waiver.json"

        inspec_waiver "my-waiver-name" do
          source "/path/to/my/waiver.json"
        end

        # files ending in .toml that exist are parsed as TOML
        inspec_waiver "/path/to/my/waiver.toml"

        inspec_waiver "my-waiver-name" do
          source "/path/to/my/waiver.toml"
        end
      ```

      **Add an InSpec waiver to the Compliance Phase using a hash**:

      ```ruby
        my_hash = { "ssh-01" => {
          "expiration_date" => "2033-07-31",
          "run" => false,
          "justification" => "because"
        } }

        inspec_waiver "my-waiver-name" do
          source my_hash
        end
      ```

      Note that the **inspec_waiver** resource does not update and will not fire notifications (similar to the log resource). This is done to preserve the ability to use
      the resource while not causing the updated resource count to be larger than zero. Since the resource does not update the state of the managed node, this behavior
      is still consistent with the configuration management model. Instead, you should use events to observe configuration changes for the compliance phase. It is
      possible to use the `notify_group` resource to chain notifications of the two resources, but notifications are the wrong model to use, and you should use pure ruby
      conditionals instead. Compliance configuration should be independent of other resources and should only be conditional based on state/attributes, not other resources.
      DOC

      property :control, String,
        name_property: true,
        description: "The name of the control being waived"

      property :expiration, String,
        description: "The expiration date of the waiver - provided in YYYY-MM-DD format",
        callbacks: {
          "Expiration date should be a valid calendar date and match the following format: YYYY-MM-DD" => proc { |e|
            re = Regexp.new("\\d{4}-\\d{2}-\\d{2}$").freeze
            if re.match?(e)
              Date.valid_date?(*e.split("-").map(&:to_i))
            else
              e.nil?
            end
          },
        }

      property :run_test, [true, false],
        description: "If present and true, the control will run and be reported, but failures in it won’t make the overall run fail. If absent or false, the control will not be run."

      property :justification, String,
        description: "Can be any text you want and might include a reason for the waiver as well as who signed off on the waiver."

      property :source, [ Hash, String ]

      action :add, description: "Add a waiver to the compliance phase" do
        if run_context.waiver_collection.valid?(new_resource.control)
          include_waiver(new_resource.control)
        else
          include_waiver(waiver_hash)
        end
      end

      action_class do
        # If the source is nil and the control / name_property contains a file separator and is a string of a
        # file that exists, then use that as the file (similar to the package provider automatic source property).  Otherwise
        # just return the source.
        #
        # @api private
        def source
          @source ||= build_source
        end

        def build_source
          return new_resource.source unless new_resource.source.nil?
          return nil unless new_resource.control.count(::File::SEPARATOR) > 0 || (::File::ALT_SEPARATOR && new_resource.control.count(::File::ALT_SEPARATOR) > 0 )
          return nil unless ::File.exist?(new_resource.control)

          new_resource.control
        end

        def waiver_hash
          case source
          when Hash
            source
          when String
            parse_file(source)
          when nil
            if new_resource.justification.nil? || new_resource.justification == ""
              raise Chef::Exceptions::ValidationFailed, "Entries for an InSpec waiver must have a justification given, this parameter must have a value."
            end

            control_hash = {}
            control_hash["expiration_date"] = new_resource.expiration.to_s unless new_resource.expiration.nil?
            control_hash["run"] = new_resource.run_test unless new_resource.run_test.nil?
            control_hash["justification"] = new_resource.justification.to_s

            { new_resource.control => control_hash }
          end
        end
      end
    end
  end
end
