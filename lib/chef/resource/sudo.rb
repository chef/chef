#
# Author:: Bryan W. Berry (<bryan.berry@gmail.com>)
# Author:: Seth Vargo (<sethvargo@gmail.com>)
#
# Copyright:: 2011-2018, Bryan w. Berry
# Copyright:: 2012-2018, Seth Vargo
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../resource"

class Chef
  class Resource
    class Sudo < Chef::Resource
      unified_mode true

      provides(:sudo) { true }

      description "Use the **sudo** resource to add or remove individual sudo entries using sudoers.d files."\
                  " Sudo version 1.7.2 or newer is required to use the sudo resource, as it relies on the"\
                  " `#includedir` directive introduced in version 1.7.2. This resource does not enforce"\
                  " installation of the required sudo version. Chef-supported releases of Ubuntu, SuSE, Debian,"\
                  " and RHEL (6+) all support this feature."
      introduced "14.0"
      examples <<~DOC
      **Grant a user sudo privileges for any command**

      ```ruby
      sudo 'admin' do
        user 'admin'
      end
      ```

      **Grant a user and groups sudo privileges for any command**

      ```ruby
      sudo 'admins' do
        users 'bob'
        groups 'sysadmins, superusers'
      end
      ```

      **Grant passwordless sudo privileges for specific commands**

      ```ruby
      sudo 'passwordless-access' do
        commands ['/bin/systemctl restart httpd', '/bin/systemctl restart mysql']
        nopasswd true
      end
      ```
      DOC

      # According to the sudo man pages sudo will ignore files in an include dir that have a `.` or `~`
      # We convert either to `__`
      property :filename, String,
        description: "The name of the sudoers.d file if it differs from the name of the resource block",
        name_property: true,
        coerce: proc { |x| x.gsub(/[\.~]/, "__") }

      property :users, [String, Array],
        description: "User(s) to provide sudo privileges to. This property accepts either an array or a comma separated list.",
        default: [],
        coerce: proc { |x| x.is_a?(Array) ? x : x.split(/\s*,\s*/) }

      property :groups, [String, Array],
        description: "Group(s) to provide sudo privileges to. This property accepts either an array or a comma separated list. Leading % on group names is optional.",
        default: [],
        coerce: proc { |x| coerce_groups(x) }

      property :commands, Array,
        description: "An array of full paths to commands this sudoer can execute.",
        default: ["ALL"]

      property :host, String,
        description: "The host to set in the sudo configuration.",
        default: "ALL"

      property :runas, String,
        description: "User that the command(s) can be run as.",
        default: "ALL"

      property :nopasswd, [TrueClass, FalseClass],
        description: "Allow sudo to be run without specifying a password.",
        default: false

      property :noexec, [TrueClass, FalseClass],
        description: "Prevent commands from shelling out.",
        default: false

      property :template, String,
        description: "The name of the erb template in your cookbook, if you wish to supply your own template."

      property :variables, [Hash, nil],
        description: "The variables to pass to the custom template. This property is ignored if not using a custom template.",
        default: nil

      property :defaults, Array,
        description: "An array of defaults for the user/group.",
        default: []

      property :command_aliases, Array,
        description: "Command aliases that can be used as allowed commands later in the configuration.",
        default: []

      property :setenv, [TrueClass, FalseClass],
        description: "Determines whether or not to permit preservation of the environment with `sudo -E`.",
        default: false

      property :env_keep_add, Array,
        description: "An array of strings to add to `env_keep`.",
        default: []

      property :env_keep_subtract, Array,
        description: "An array of strings to remove from `env_keep`.",
        default: []

      property :visudo_path, String,
        deprecated: true

      property :visudo_binary, String,
        description: "The path to visudo for configuration verification.",
        default: "/usr/sbin/visudo"

      property :config_prefix, String,
        description: "The directory that contains the sudoers configuration file.",
        default: lazy { platform_config_prefix }, default_description: "Prefix values based on the node's platform"

      # handle legacy cookbook property
      def after_created
        raise "The 'visudo_path' property from the sudo cookbook has been replaced with the 'visudo_binary' property. The path is now more intelligently determined and for most users specifying the path should no longer be necessary. If this resource still cannot determine the path to visudo then provide the absolute path to the binary with the 'visudo_binary' property." if visudo_path
      end

      # VERY old legacy properties
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
      # @return [String]
      def platform_config_prefix
        case node["platform_family"]
        when "smartos"
          "/opt/local/etc"
        when "mac_os_x"
          "/private/etc"
        when "freebsd"
          "/usr/local/etc"
        else
          "/etc"
        end
      end

      action :create, description: "Create a single sudoers configuration file in the `sudoers.d` directory." do
        validate_properties

        if docker? # don't even put this into resource collection unless we're in docker
          package "sudo" do
            not_if "which sudo"
          end
        end

        target = "#{new_resource.config_prefix}/sudoers.d/"
        directory(target)

        Chef::Log.warn("#{new_resource.filename} will be rendered, but will not take effect because the #{new_resource.config_prefix}/sudoers config lacks the includedir directive that loads configs from #{new_resource.config_prefix}/sudoers.d/!") if ::File.readlines("#{new_resource.config_prefix}/sudoers").grep(/includedir/).empty?
        file_path = "#{target}#{new_resource.filename}"

        if new_resource.template
          logger.trace("Template property provided, all other properties ignored.")

          template file_path do
            source new_resource.template
            mode "0440"
            variables new_resource.variables
            verify visudo_content(file_path) if visudo_present?
            action :create
          end
        else
          template file_path do
            source ::File.expand_path("support/sudoer.erb", __dir__)
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
            verify visudo_content(file_path) if visudo_present?
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
      action :delete, description: "Remove a sudoers configuration file from the `sudoers.d` directory." do
        file "#{new_resource.config_prefix}/sudoers.d/#{new_resource.filename}" do
          action :delete
        end
      end

      action_class do
        # Ensure that the inputs are valid (we cannot just use the resource for this)
        def validate_properties
          # if group, user, env_keep_add, env_keep_subtract and template are nil, throw an exception
          raise "You must specify users, groups, env_keep_add, env_keep_subtract, or template properties!" if new_resource.users.empty? && new_resource.groups.empty? && new_resource.template.nil? && new_resource.env_keep_add.empty? && new_resource.env_keep_subtract.empty?

          # if specifying user or group and template at the same time fail
          raise "You cannot specify users or groups properties and also specify a template. To use your own template pass in all template variables using the variables property." if (!new_resource.users.empty? || !new_resource.groups.empty?) && !new_resource.template.nil?
        end

        def visudo_present?
          return true if ::File.exist?(new_resource.visudo_binary)

          Chef::Log.warn("The visudo binary cannot be found at '#{new_resource.visudo_binary}'. Skipping sudoer file validation. If visudo is on this system you can specify the path using the 'visudo_binary' property.")
        end

        def visudo_content(path)
          if ::File.exist?(path)
            "cat #{new_resource.config_prefix}/sudoers | #{new_resource.visudo_binary} -cf - && #{new_resource.visudo_binary} -cf %{path}"
          else
            "cat #{new_resource.config_prefix}/sudoers %{path} | #{new_resource.visudo_binary} -cf -"
          end
        end
      end
    end
  end
end
