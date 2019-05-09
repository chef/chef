#
# Copyright:: 2018, Webb Agile Solutions Ltd.
# Copyright:: 2018-2018, Chef Software Inc.
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
      resource_name :sysctl
      provides(:sysctl) { true }
      provides(:sysctl_param) { true }

      description "Use the sysctl resource to set or remove kernel parameters using the sysctl"\
                  " command line tool and configuration files in the system's sysctl.d directory. "\
                  "Configuration files managed by this resource are named 99-chef-KEYNAME.conf. If"\
                  " an existing value was already set for the value it will be backed up to the node"\
                  " and restored if the :remove action is used later."

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
               required: true

      property :conf_dir, String,
               description: "The configuration directory to write the config to.",
               default: "/etc/sysctl.d"

      def after_created
        raise "The sysctl resource requires Linux as it needs sysctl and the sysctl.d directory functionality." unless node["os"] == "linux"
        raise "The sysctl resource does not support SLES releases less than 12 as it requires a sysctl.d directory" if platform_family?("suse") && node["platform_version"].to_i < 12
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
        begin
          value get_sysctl_value(key)
        rescue
          current_value_does_not_exist!
        end
      end

      action :apply do
        description "Apply a sysctl value."

        converge_if_changed do
          # set it temporarily
          set_sysctl_param(new_resource.key, new_resource.value)

          directory new_resource.conf_dir

          file "#{new_resource.conf_dir}/99-chef-#{new_resource.key.tr('/', '.')}.conf" do
            content "#{new_resource.key} = #{new_resource.value}"
          end

          execute "Load sysctl values" do
            command "sysctl #{'-e ' if new_resource.ignore_error}-p"
            default_env true
            action :run
          end
        end
      end

      action :remove do
        description "Remove a sysctl value."

        # only converge the resource if the file actually exists to delete
        if ::File.exist?("#{new_resource.conf_dir}/99-chef-#{new_resource.key.tr('/', '.')}.conf")
          converge_by "removing sysctl config at #{new_resource.conf_dir}/99-chef-#{new_resource.key.tr('/', '.')}.conf" do
            file "#{new_resource.conf_dir}/99-chef-#{new_resource.key.tr('/', '.')}.conf" do
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
        def set_sysctl_param(key, value)
          shell_out!("sysctl #{'-e ' if new_resource.ignore_error}-w \"#{key}=#{value}\"")
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
        raise unless ::File.exist?("/etc/sysctl.d/99-chef-#{key.tr('/', '.')}.conf")
        k, v = ::File.read("/etc/sysctl.d/99-chef-#{key.tr('/', '.')}.conf").match(/(.*) = (.*)/).captures
        raise "Unknown sysctl key!" if k.nil?
        raise "Unknown sysctl value!" if v.nil?
        v
      end
    end
  end
end
