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

class Chef
  class Resource
    class ChocolateySource < Chef::Resource
      unified_mode true
      provides :chocolatey_source

      description "Use the **chocolatey_source** resource to add, remove, enable, or disable Chocolatey sources."
      introduced "14.3"
      examples <<~DOC
        **Add a Chocolatey source**

        ```ruby
        chocolatey_source 'MySource' do
          source 'http://example.com/something'
          action :add
        end
        ```

        **Remove a Chocolatey source**

        ```ruby
        chocolatey_source 'MySource' do
          action :remove
        end
        ```
      DOC

      property :source_name, String, name_property: true,
               description: "An optional property to set the source name if it differs from the resource block's name."

      property :source, String,
        description: "The source URL."

      property :bypass_proxy, [TrueClass, FalseClass], default: false,
               description: "Whether or not to bypass the system's proxy settings to access the source."

      property :admin_only, [TrueClass, FalseClass], default: false,
               description: "Whether or not to set the source to be accessible to only admins.",
               introduced: "15.1"

      property :allow_self_service, [TrueClass, FalseClass], default: false,
               description: "Whether or not to set the source to be used for self service.",
               introduced: "15.1"

      property :priority, Integer, default: 0,
               description: "The priority level of the source."

      property :disabled, [TrueClass, FalseClass], default: false, desired_state: false, skip_docs: true

      load_current_value do
        element = fetch_source_element(source_name)
        current_value_does_not_exist! if element.nil?

        source_name element["id"]
        source element["value"]
        bypass_proxy element["bypassProxy"] == "true"
        admin_only element["adminOnly"] == "true"
        allow_self_service element["selfService"] == "true"
        priority element["priority"].to_i
        disabled element["disabled"] == "true"
      end

      # @param [String] id the source name
      # @return [REXML::Attributes] finds the source element with the
      def fetch_source_element(id)
        require "rexml/document" unless defined?(REXML::Document)

        config_file = "#{ENV["ALLUSERSPROFILE"]}\\chocolatey\\config\\chocolatey.config"
        raise "Could not find the Chocolatey config at #{config_file}!" unless ::File.exist?(config_file)

        config_contents = REXML::Document.new(::File.read(config_file))
        data = REXML::XPath.first(config_contents, "//sources/source[@id=\"#{id}\"]")
        data ? data.attributes : nil # REXML just returns nil if it can't find anything so avoid an undefined method error
      end

      action :add, description: "Adds a Chocolatey source" do

        raise "#{new_resource}: When adding a Chocolatey source you must pass the 'source' property!" unless new_resource.source

        converge_if_changed do
          shell_out!(choco_cmd("add"))
        end
      end

      action :remove, description: "Removes a Chocolatey source." do

        if current_resource
          converge_by("remove Chocolatey source '#{new_resource.source_name}'") do
            shell_out!(choco_cmd("remove"))
          end
        end
      end

      action :disable, description: "Disables a Chocolatey source. **New in Chef Infra Client 15.1.**" do
        if current_resource.disabled != true
          converge_by("disable Chocolatey source '#{new_resource.source_name}'") do
            shell_out!(choco_cmd("disable"))
          end
        end
      end

      action :enable, description: "Enables a Chocolatey source. **New in Chef Infra Client 15.1.**" do
        if current_resource.disabled == true
          converge_by("enable Chocolatey source '#{new_resource.source_name}'") do
            shell_out!(choco_cmd("enable"))
          end
        end
      end

      action_class do
        # @param [String] action the name of the action to perform
        # @return [String] the choco source command string
        def choco_cmd(action)
          cmd = "#{ENV["ALLUSERSPROFILE"]}\\chocolatey\\bin\\choco source #{action} -n \"#{new_resource.source_name}\""
          if action == "add"
            cmd << " -s #{new_resource.source} --priority=#{new_resource.priority}"
            cmd << " --bypassproxy" if new_resource.bypass_proxy
            cmd << " --allowselfservice" if new_resource.allow_self_service
            cmd << " --adminonly" if new_resource.admin_only
          end
          cmd
        end
      end
    end
  end
end
