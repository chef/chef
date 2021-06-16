#
# Copyright:: Copyright (c) Chef Software Inc.
# Copyright:: 2016-2020, Virender Khatri
#
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

class Chef
  class Resource
    class Alternatives < Chef::Resource
      unified_mode true

      provides(:alternatives) { true }

      description "Use the **alternatives** resource to configure command alternatives in Linux using the alternatives or update-alternatives packages."
      introduced "16.0"
      examples <<~DOC
      **Install an alternative**:

      ```ruby
      alternatives 'python install 2' do
        link_name 'python'
        path '/usr/bin/python2.7'
        priority 100
        action :install
      end
      ```

      **Set an alternative**:

      ```ruby
      alternatives 'python set version 3' do
        link_name 'python'
        path '/usr/bin/python3'
        action :set
      end
      ```

      **Set the automatic alternative state**:

      ```ruby
      alternatives 'python auto' do
        link_name 'python'
        action :auto
      end
      ```

      **Refresh an alternative**:

      ```ruby
      alternatives 'python refresh' do
        link_name 'python'
        action :refresh
      end
      ```

      **Remove an alternative**:

      ```ruby
      alternatives 'python remove' do
        link_name 'python'
        path '/usr/bin/python3'
        action :remove
      end
      ```
      DOC

      property :link_name, String,
        name_property: true,
        description: "The name of the link to create. This will be the command you type on the command line such as `ruby` or `gcc`."

      property :link, String,
        default: lazy { |n| "/usr/bin/#{n.link_name}" },
        default_description: "/usr/bin/LINK_NAME",
        description: "The path to the alternatives link."

      property :path, String,
        description: "The absolute path to the original application binary such as `/usr/bin/ruby27`."

      property :priority, [String, Integer],
        coerce: proc { |n| n.to_i },
        description: "The priority of the alternative."

      def define_resource_requirements
        requirements.assert(:install) do |a|
          a.assertion do
            !new_resource.priority.nil?
          end

          a.failure_message("Could not set alternatives for #{new_resource.link_name}, you must provide the :priority property")
        end

        requirements.assert(:install, :set, :remove) do |a|
          a.assertion do
            !new_resource.path.nil?
          end

          a.failure_message("Could not set alternatives for #{new_resource.link_name}, you must provide the :path property")
        end

        requirements.assert(:install, :set, :remove) do |a|
          a.assertion do
            ::File.exist?(new_resource.path)
          end

          a.whyrun("Assuming file #{new_resource.path} already exists or was created already")
          a.failure_message("Could not set alternatives for #{new_resource.link_name}, missing #{new_resource.path}")
        end
      end

      action :install, description: "Install an alternative on the system including symlinks." do
        if path_priority != new_resource.priority
          converge_by("adding alternative #{new_resource.link} #{new_resource.link_name} #{new_resource.path} #{new_resource.priority}") do
            output = shell_out(alternatives_cmd, "--install", new_resource.link, new_resource.link_name, new_resource.path, new_resource.priority)
            unless output.exitstatus == 0
              raise "failed to add alternative #{new_resource.link} #{new_resource.link_name} #{new_resource.path} #{new_resource.priority}"
            end
          end
        end
      end

      action :set, description: "Set the symlink for an alternative." do
        if current_path != new_resource.path
          converge_by("setting alternative #{new_resource.link_name} #{new_resource.path}") do
            output = shell_out(alternatives_cmd, "--set", new_resource.link_name, new_resource.path)
            unless output.exitstatus == 0
              raise "failed to set alternative #{new_resource.link_name} #{new_resource.path} \n #{output.stdout.strip}"
            end
          end
        end
      end

      action :remove, description: "Remove an alternative and all associated links." do
        if path_exists?
          converge_by("removing alternative #{new_resource.link_name} #{new_resource.path}") do
            shell_out(alternatives_cmd, "--remove", new_resource.link_name, new_resource.path)
          end
        end
      end

      action :auto, description: "Set an alternative up in automatic mode with the highest priority automatically selected." do
        converge_by("setting auto alternative #{new_resource.link_name}") do
          shell_out(alternatives_cmd, "--auto", new_resource.link_name)
        end
      end

      action :refresh, description: "Refresh alternatives." do
        converge_by("refreshing alternative #{new_resource.link_name}") do
          shell_out(alternatives_cmd, "--refresh", new_resource.link_name)
        end
      end

      action_class do
        #
        # @return [String] The appropriate alternatives command based on the platform
        #
        def alternatives_cmd
          if debian?
            "update-alternatives"
          else
            "alternatives"
          end
        end

        #
        # @return [Integer] The current path priority for the link_name alternative
        #
        def path_priority
          # https://rubular.com/r/IcUlEU0mSNaMm3
          escaped_path = Regexp.new(Regexp.escape("#{new_resource.path} - priority ") + "(.*)")
          match = shell_out(alternatives_cmd, "--display", new_resource.link_name).stdout.match(escaped_path)

          match.nil? ? nil : match[1].to_i
        end

        #
        # @return [String] The current path for the link_name alternative
        #
        def current_path
          # https://rubular.com/r/ylsuvzUtquRPqc
          match = shell_out(alternatives_cmd, "--display", new_resource.link_name).stdout.match(/link currently points to (.*)/)
          match[1]
        end

        #
        # @return [Boolean] does the path exist for the link_name alternative
        #
        def path_exists?
          # https://rubular.com/r/ogvDdq8h2IKRff
          escaped_path = Regexp.new(Regexp.escape("#{new_resource.path} - priority"))
          shell_out(alternatives_cmd, "--display", new_resource.link_name).stdout.match?(escaped_path)
        end
      end
    end
  end
end
