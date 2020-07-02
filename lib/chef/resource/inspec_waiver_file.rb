#
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
require_relative "../dist"
require_relative "mixin/from_file"
require "yaml"

class Chef
  class Resource
    class InspecWaiverFile < Chef::Resource
      provides :inspec_waiver_file
      unified_mode true

      description "Use the **inspec_waiver_file** resource to add or remove entries from an inspec waiver file. This can be used in conjunction with the audit cookbook"
      introduced "16.3"
      examples <<~DOC
      **Add an InSpec waiver entry to a given waiver file**:

      ```ruby
        inspec_waiver_file 'Add waiver entry for control' do
          file 'C:\\chef\\inspec_waiver.yml'
          control 'my_inspec_control_01'
          run_test false
          justification "The subject of this control is not managed by Chef on the systems in policy group \#{node['policy_group']}"
          expiration 2021-01-01
          action :add
        end
      ```

      **Add an InSpec waiver entry to a given waiver file using the 'name' property to identify the control**:

      ```ruby
        inspec_waiver_file 'my_inspec_control_01' do
          file 'C:\\chef\\inspec_waiver.yml'
          justification "The subject of this control is not managed by Chef on the systems in policy group \#{node['policy_group']}"
          action :add
        end
      ```

      **Remove an InSpec waiver entry to a given waiver file**:

      ```ruby
        inspec_waiver_file "my_inspec_control_01" do
          file '/etc/chef/inspec_waiver.yml'
          action :remove
        end
      ```
      DOC

      property :control, String,
        name_property: true,
        description: "The name of the control being added or removed to the waiver file"

      property :file, String,
        required: true,
        description: "The path to the waiver file being modified"

      property :expiration, String,
        description: "The expiration date of the given waiver - provided in YYYY-MM-DD format",
        callbacks: {
          "Expiration date should match the following format: YYYY-MM-DD" => proc { |e|
            re = Regexp.new('([12]\d{3}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01]))').freeze
            re.match?(e)
          },
          }

      property :run_test, [true, false],
        description: "If present and true, the control will run and be reported, but failures in it won’t make the overall run fail. If absent or false, the control will not be run."

      property :justification, String,
        description: "Can be any text you want and might include a reason for the waiver as well as who signed off on the waiver."

      load_current_value do |desired_state|
        filename = desired_state.file
        if ::File.file?(filename) && ::File.readable?(filename) && !::File.zero?(filename)
          yaml_contents = IO.read(filename)
          waiver_hash = ::YAML.safe_load(yaml_contents)

          file desired_state.file
          if waiver_hash.key?("#{desired_state.control}")
            control desired_state.control
            if waiver_hash[desired_state.control].key?("expiration_date")
              expiration waiver_hash[desired_state.control]["expiration_date"]
            else
              expiration "1111-11-11"
            end
            if waiver_hash[desired_state.control].key?("run")
              run_test waiver_hash[desired_state.control]["run"]
            end
            if waiver_hash[desired_state.control].key?("justification")
              justification waiver_hash[desired_state.control]["justification"]
            else
              justification ""
            end
          else
            control ""
          end
        else
          file ""
          control ""
          justification ""
          expiration "1111-11-11"
        end
      end

      action :add do
        converge_if_changed :file do
          file "Create Waiver File #{new_resource.file}" do
            path new_resource.file
            action :create_if_missing
          end
        end
        converge_if_changed :control, :expiration, :run_test, :justification do
          yaml_contents = IO.read(new_resource.file)
          waiver_hash = if yaml_contents.empty?
                          {}
                        else
                          waiver_hash = ::YAML.safe_load(yaml_contents)
                        end
          waiver_hash["#{new_resource.control}"] = {}
          control_hash = {}
          control_hash["expiration_date"] = new_resource.expiration.to_s unless new_resource.expiration.nil?
          control_hash["run"] = new_resource.run_test unless new_resource.run_test.nil?
          control_hash["justification"] = new_resource.justification.to_s
          waiver_hash["#{new_resource.control}"] = control_hash
          waiver_hash = waiver_hash.sort.to_h
          ::File.open(new_resource.file, "w") { |f| f.puts waiver_hash.to_yaml }
        end
      end

      action :remove do
        if current_resource.file == new_resource.file
          yaml_contents = IO.read(filename)
          waiver_hash = ::YAML.safe_load(yaml_contents)
          if waiver_hash.key?(new_resource.control)
            converge_by "Removing #{new_resource.control} from waiver file #{new_resource.file}" do
              waiver_hash.delete("#{new_resource.control}")
              waiver_hash = waiver_hash.sort.to_h
              ::File.open(new_resource.file, "w") { |f| f.puts waiver_hash.to_yaml }
            end
          end
        end
      end
    end
  end
end