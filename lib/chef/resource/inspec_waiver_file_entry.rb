#
# Author:: Davin Taddeo (<davin@chef.io>)
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
autoload :YAML, "yaml"
require "date"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class InspecWaiverFileEntry < Chef::Resource
      provides :inspec_waiver_file_entry
      unified_mode true

      description "Use the **inspec_waiver_file_entry** resource to add or remove entries from an InSpec waiver file. This can be used in conjunction with the Compliance Phase."
      introduced "17.1"
      examples <<~DOC
      **Add an InSpec waiver entry to a given waiver file**:

      ```ruby
        inspec_waiver_file_entry 'Add waiver entry for control' do
          file_path 'C:\\chef\\inspec_waiver_file.yml'
          control 'my_inspec_control_01'
          run_test false
          justification "The subject of this control is not managed by #{ChefUtils::Dist::Infra::PRODUCT} on the systems in policy group \#{node['policy_group']}"
          expiration '2022-01-01'
          action :add
        end
      ```

      **Add an InSpec waiver entry to a given waiver file using the 'name' property to identify the control**:

      ```ruby
        inspec_waiver_file_entry 'my_inspec_control_01' do
          justification "The subject of this control is not managed by #{ChefUtils::Dist::Infra::PRODUCT} on the systems in policy group \#{node['policy_group']}"
          action :add
        end
      ```

      **Remove an InSpec waiver entry to a given waiver file**:

      ```ruby
        inspec_waiver_file_entry "my_inspec_control_01" do
          action :remove
        end
      ```
      DOC

      property :control, String,
        name_property: true,
        description: "The name of the control being added or removed to the waiver file"

      property :file_path, String,
        required: true,
        description: "The path to the waiver file being modified",
        default: "#{ChefConfig::Config.etc_chef_dir}/inspec_waivers.yml",
        default_description: "`/etc/chef/inspec_waivers.yml` on Linux/Unix and `C:\\chef\\inspec_waivers.yml` on Windows"

      property :expiration, String,
        description: "The expiration date of the given waiver - provided in YYYY-MM-DD format",
        callbacks: {
          "Expiration date should be a valid calendar date and match the following format: YYYY-MM-DD" => proc { |e|
            re = Regexp.new('\d{4}-\d{2}-\d{2}$').freeze
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

      property :backup, [false, Integer],
        description: "The number of backups to be kept in /var/chef/backup (for UNIX- and Linux-based platforms) or C:/chef/backup (for the Microsoft Windows platform). Set to false to prevent backups from being kept.",
        default: false

      action :add do
        if new_resource.justification.nil? || new_resource.justification == ""
          raise Chef::Exceptions::ValidationFailed, "Entries in the InSpec waiver file must have a justification given, this parameter must have a value."
        end

        filename = new_resource.file_path
        waiver_hash = load_waiver_file_to_hash(filename)
        control_hash = {}
        control_hash["expiration_date"] = new_resource.expiration.to_s unless new_resource.expiration.nil?
        control_hash["run"] = new_resource.run_test unless new_resource.run_test.nil?
        control_hash["justification"] = new_resource.justification.to_s

        unless waiver_hash[new_resource.control] == control_hash
          waiver_hash[new_resource.control] = control_hash
          waiver_hash = waiver_hash.sort.to_h

          file "Update Waiver File #{new_resource.file_path} to update waiver for control #{new_resource.control}" do
            path new_resource.file_path
            content ::YAML.dump(waiver_hash)
            backup new_resource.backup
            action :create
          end
        end
      end

      action :remove do
        filename = new_resource.file_path
        waiver_hash = load_waiver_file_to_hash(filename)
        if waiver_hash.key?(new_resource.control)
          waiver_hash.delete(new_resource.control)
          waiver_hash = waiver_hash.sort.to_h
          file "Update Waiver File #{new_resource.file_path} to remove waiver for control #{new_resource.control}" do
            path new_resource.file_path
            content ::YAML.dump(waiver_hash)
            backup new_resource.backup
            action :create
          end
        end
      end

      action_class do
        def load_waiver_file_to_hash(file_name)
          if file_name =~ %r{(/|C:\\).*(.yaml|.yml)}i
            if ::File.exist?(file_name)
              hash = ::YAML.load_file(file_name)
              if hash == false || hash.nil? || hash == ""
                {}
              else
                ::YAML.load_file(file_name)
              end
            else
              {}
            end
          else
            raise "Waiver files needs to be a YAML file which should have a .yaml or .yml extension -\"#{file_name}\" does not have an appropriate extension"
          end
        end
      end
    end
  end
end
