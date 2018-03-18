#
# Author:: Bryan W. Berry (<bryan.berry@gmail.com>)
# Author:: Seth Vargo (<sethvargo@gmail.com>)
#
# Copyright:: 2011-2018, Bryan w. Berry
# Copyright:: 2012-2018, Seth Vargo
# Copyright:: 2015-2018, Chef Software, Inc.
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

require "chef/resource"

class Chef
  class Resource
    class Sudo < Chef::Resource
      resource_name "sudo"
      provides "sudo"

      description "Use the sudo resource to add or remove individual sudo entries using sudoers.d files."\
                  " Sudo version 1.7.2 or newer is required to use the sudo resource as it relies on the"\
                  " '#includedir' directive introduced in version 1.7.2. The resource does not enforce"\
                  " installing the version. Supported releases of Ubuntu, Debian and RHEL (6+) all support"\
                  " this feature."
      introduced "14.0"

      # acording to the sudo man pages sudo will ignore files in an include dir that have a `.` or `~`
      # We convert either to `__`
      property :filename, String,
               description: "The name of the sudoers.d file",
               name_property: true,
               coerce: proc { |x| x.gsub(/[\.~]/, "__") }

      property :users, [String, Array],
               description: "User(s) to provide sudo privileges to. This accepts either an array or a comma separated.",
               default: lazy { [] },
               coerce: proc { |x| x.is_a?(Array) ? x : x.split(/\s*,\s*/) }

      property :groups, [String, Array],
               description: "Group(s) to provide sudo privileges to. This accepts either an array or a comma separated list. Leading % on group names is optional.",
               default: lazy { [] },
               coerce: proc { |x| coerce_groups(x) }

      property :commands, Array,
               description: "An array of commands this sudoer can execute.",
               default: ["ALL"]

      property :host, String,
               description: "The host to set in the sudo config.",
               default: "ALL"

      property :runas, String,
               description: "User the command(s) can be run as",
               default: "ALL"

      property :nopasswd, [TrueClass, FalseClass],
               description: "Allow running sudo without specifying a password sudo",
               default: false

      property :noexec, [TrueClass, FalseClass],
               description: "Prevent commands from shelling out.",
               default: false

      property :template, String,
               description: "The name of the erb template in your cookbook if you wish to supply your own template."

      property :variables, [Hash, nil],
               description: "The variables to pass to the custom template. Ignored if not using a custom template.",
               default: nil

      property :defaults, Array,
               description: "An array of defaults for the user/group.",
               default: lazy { [] }

      property :command_aliases, Array,
               description: "Command aliases that can be used as allowed commands later in the config",
               default: lazy { [] }

      property :setenv, [TrueClass, FalseClass],
               description: "Whether to permit the preserving of environment with sudo -E.",
               default: false

      property :env_keep_add, Array,
               description: "An array of strings to add to env_keep.",
               default: lazy { [] }

      property :env_keep_subtract, Array,
               description: "An array of strings to remove from env_keep.",
               default: lazy { [] }

      property :visudo_path, String,
               description: "The path to visudo for config verification.",
               default: "/usr/sbin/visudo"

      property :config_prefix, String,
               description: "The directory containing the sudoers config file.",
               default: lazy { "config_prefix" }

      alias_method :user, :users
      alias_method :group, :groups

      # make sure each group starts with a %
      def coerce_groups(x)
        # split strings on the commas with optional spaces on either side
        groups = x.is_a?(Array) ? x : x.split(/\s*,\s*/)

        # make sure all the groups start with %
        groups.map { |g| g[0] == "%" ? g : "%#{g}" }
      end

      # default config prefix paths based on platform
      def config_prefix
        case node["platform_family"]
        when "smartos"
          "/opt/local/etc"
        when "mac_os_x"
          "/private/etc"
        else
          "/etc"
        end
      end

      action :create do
        description "Create a single sudoers config in the sudoers.d directory"

        validate_platform
        validate_properties

        if docker? # don't even put this into resource collection unless we're in docker
          declare_resource(:package, "sudo") do
            action :nothing
            not_if "which sudo"
          end.run_action(:install)
        end

        target = "#{new_resource.config_prefix}/sudoers.d/"
        declare_resource(:directory, target) unless ::File.exist?(target)

        Chef::Log.warn("#{new_resource.filename} will be rendered, but will not take effect because the #{new_resource.config_prefix}/sudoers config lacks the includedir directive that loads configs from #{new_resource.config_prefix}/sudoers.d/!") if ::File.readlines("#{new_resource.config_prefix}/sudoers").grep(/includedir/).empty?

        if new_resource.template
          Chef::Log.debug("Template property provided, all other properties ignored.")

          declare_resource(:template, "#{target}#{new_resource.filename}") do
            source new_resource.template
            mode "0440"
            variables new_resource.variables
            verify "#{new_resource.visudo_path} -cf %{path}" if visudo_present?
            action :create
          end
        else
          declare_resource(:template, "#{target}#{new_resource.filename}") do
            source "sudoer.erb"
            source ::File.expand_path("../support/sudoer.erb", __FILE__)
            local true
            mode "0440"
            variables sudoer:            (new_resource.groups + new_resource.users).join(","),
                      host:               new_resource.host,
                      runas:              new_resource.runas,
                      nopasswd:           new_resource.nopasswd,
                      noexec:             new_resource.noexec,
                      commands:           new_resource.commands,
                      command_aliases:    new_resource.command_aliases,
                      defaults:           new_resource.defaults,
                      setenv:             new_resource.setenv,
                      env_keep_add:       new_resource.env_keep_add,
                      env_keep_subtract:  new_resource.env_keep_subtract
            verify "#{new_resource.visudo_path} -cf %{path}" if visudo_present?
            action :create
          end
        end
      end

      action :install do
        Chef::Log.warn("The sudo :install action has been renamed :create. Please update your cookbook code for the new action")
        action_create
      end

      action :remove do
        Chef::Log.warn("The sudo :remove action has been renamed :delete. Please update your cookbook code for the new action")
        action_delete
      end

      # Removes a user from the sudoers group
      action :delete do
        description "Remove a sudoers config from the sudoers.d directory"

        file "#{new_resource.config_prefix}/sudoers.d/#{new_resource.filename}" do
          action :delete
        end
      end

      action_class do
        # Make sure we fail on FreeBSD
        def validate_platform
          return unless platform_family?("freebsd")
          raise "The sudo resource cannot run on FreeBSD as FreeBSD does not support using a sudoers.d config directory."
        end

        # Ensure that the inputs are valid (we cannot just use the resource for this)
        def validate_properties
          # if group, user, env_keep_add, env_keep_subtract and template are nil, throw an exception
          raise "You must specify users, groups, env_keep_add, env_keep_subtract, or template properties!" if new_resource.users.empty? && new_resource.groups.empty? && new_resource.template.nil? && new_resource.env_keep_add.empty? && new_resource.env_keep_subtract.empty?

          # if specifying user or group and template at the same time fail
          raise "You cannot specify users or groups properties and also specify a template. To use your own template pass in all template variables using the variables property." if (!new_resource.users.empty? || !new_resource.groups.empty?) && !new_resource.template.nil?
        end

        def visudo_present?
          return if ::File.exist?(new_resource.visudo_path)
          Chef::Log.warn("The visudo binary cannot be found at '#{new_resource.visudo_path}'. Skipping sudoer file validation. If visudo is on this system you can specify the path using the 'visudo_path' property.")
        end
      end
    end
  end
end
