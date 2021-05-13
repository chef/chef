#
# Copyright:: 2018, Webb Agile Solutions Ltd.
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
    class Sysctl < Chef::Resource
      unified_mode true

      provides(:sysctl) { true }
      provides(:sysctl_param) { true }

      description "Use the **sysctl** resource to set or remove kernel parameters using the `sysctl` command line tool and configuration files in the system's `sysctl.d` directory. Configuration files managed by this resource are named `99-chef-KEYNAME.conf`."
      examples <<~DOC
      **Set vm.swappiness**:

      ```ruby
      sysctl 'vm.swappiness' do
        value 19
      end
      ```

      **Remove kernel.msgmax**:

      **Note**: This only removes the sysctl.d config for kernel.msgmax. The value will be set back to the kernel default value.

      ```ruby
      sysctl 'kernel.msgmax' do
        action :remove
      end
      ```

      **Adding Comments to sysctl configuration files**:

      ```ruby
      sysctl 'vm.swappiness' do
        value 19
        comment "define how aggressively the kernel will swap memory pages."
      end
      ```

      This produces /etc/sysctl.d/99-chef-vm.swappiness.conf as follows:

      ```
      # define how aggressively the kernel will swap memory pages.
      vm.swappiness = 1
      ```

      **Converting sysctl settings from shell scripts**:

      Example of existing settings:

      ```bash
      fs.aio-max-nr = 1048576 net.ipv4.ip_local_port_range = 9000 65500 kernel.sem = 250 32000 100 128
      ```

      Converted to sysctl resources:

      ```ruby
      sysctl 'fs.aio-max-nr' do
        value '1048576'
      end

      sysctl 'net.ipv4.ip_local_port_range' do
        value '9000 65500'
      end

      sysctl 'kernel.sem' do
        value '250 32000 100 128'
      end
      ```
      DOC

      introduced "14.0"

      property :key, String,
        description: "The kernel parameter key in dotted format if it differs from the resource block's name.",
        name_property: true

      property :ignore_error, [TrueClass, FalseClass],
        description: "Ignore any errors when setting the value on the command line.",
        default: false, desired_state: false

      property :value, [Array, String, Integer, Float],
        description: "The value to set.",
        coerce: proc { |v| coerce_value(v) },
        required: [:apply]

      property :comment, [Array, String],
        description: "Comments, placed above the resource setting in the generated file. For multi-line comments, use an array of strings, one per line.",
        default: [],
        introduced: "15.8"

      property :conf_dir, String,
        description: "The configuration directory to write the config to.",
        default: "/etc/sysctl.d"

      def after_created
        raise "The sysctl resource requires Linux as it needs sysctl and the sysctl.d directory functionality." unless node["os"] == "linux"
      end

      def coerce_value(v)
        case v
        when Array
          v.join(" ")
        else
          v.to_s
        end
      end

      load_current_value do

        value get_sysctl_value(key)
      rescue
        current_value_does_not_exist!

      end

      action :apply, description: "Apply a sysctl value." do
        converge_if_changed do
          # set it temporarily
          set_sysctl_param(new_resource.key, new_resource.value)

          directory new_resource.conf_dir

          file "#{new_resource.conf_dir}/99-chef-#{new_resource.key.tr("/", ".")}.conf" do
            content contruct_sysctl_content
          end

          execute "Load sysctl values" do
            command "sysctl #{"-e " if new_resource.ignore_error}-p"
            default_env true
            action :run
          end
        end
      end

      action :remove, description: "Remove a sysctl value." do
        # only converge the resource if the file actually exists to delete
        if ::File.exist?("#{new_resource.conf_dir}/99-chef-#{new_resource.key.tr("/", ".")}.conf")
          converge_by "removing sysctl config at #{new_resource.conf_dir}/99-chef-#{new_resource.key.tr("/", ".")}.conf" do
            file "#{new_resource.conf_dir}/99-chef-#{new_resource.key.tr("/", ".")}.conf" do
              action :delete
            end

            execute "Load sysctl values" do
              default_env true
              command "sysctl -p"
              action :run
            end
          end
        end
      end

      action_class do
        #
        # Shell out to set the sysctl value
        #
        # @param [String] key The sysctl key
        # @param [String] value The value of the sysctl key
        #
        def set_sysctl_param(key, value)
          shell_out!("sysctl #{"-e " if new_resource.ignore_error}-w \"#{key}=#{value}\"")
        end

        #
        # construct a string, joining members of new_resource.comment and new_resource.value
        #
        # @return [String] The text file content
        #
        def contruct_sysctl_content
          sysctl_lines = Array(new_resource.comment).map { |c| "# #{c.strip}" }

          sysctl_lines << "#{new_resource.key} = #{new_resource.value}"

          sysctl_lines.join("\n")
        end
      end

      private

      # shellout to sysctl to get the current value
      # ignore missing keys by using '-e'
      # convert tabs to spaces since sysctl tab deliminates multivalue parameters
      # strip the newline off the end of the output as well
      #
      # Chef creates a file in sysctld with parameter configuration
      # Thus this config will persists even after rebooting the system
      # User can be in a half configured state, where he has already updated the value
      # which he wants to be configured from the resource
      # Therefore we need an extra check with sysctld to ensure a correct idempotency
      #
      def get_sysctl_value(key)
        val = shell_out!("sysctl -n -e #{key}").stdout.tr("\t", " ").strip
        raise unless val == get_sysctld_value(key)

        val
      end

      # Check if chef has already configured a value for the given key and
      # return the value. Raise in case this conf file needs to be created
      # or updated
      def get_sysctld_value(key)
        raise unless ::File.exist?("/etc/sysctl.d/99-chef-#{key.tr("/", ".")}.conf")

        k, v = ::File.read("/etc/sysctl.d/99-chef-#{key.tr("/", ".")}.conf").match(/(.*) = (.*)/).captures
        raise "Unknown sysctl key!" if k.nil?
        raise "Unknown sysctl value!" if v.nil?

        v
      end
    end
  end
end
