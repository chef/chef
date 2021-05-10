#
# Author:: Doug MacEachern (<dougm@vmware.com>)
# Author:: Tyler Cloke (<tyler@chef.io>)
# Copyright:: Copyright 2010-2016, VMware, Inc.
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
require_relative "../mixin/windows_env_helper"
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class WindowsEnv < Chef::Resource
      unified_mode true

      provides :windows_env
      provides :env # backwards compat with the pre-Chef 14 resource name

      description "Use the **windows_env** resource to manage environment keys in Microsoft Windows. After an environment key is set, Microsoft Windows must be restarted before the environment key will be available to the Task Scheduler.\n\nThis resource was previously called the **env** resource; its name was updated in #{ChefUtils::Dist::Infra::PRODUCT} 14.0 to reflect the fact that only Windows is supported. Existing cookbooks using `env` will continue to function, but should be updated to use the new name. Note: On UNIX-based systems, the best way to manipulate environment keys is with the `ENV` variable in Ruby; however, this approach does not have the same permanent effect as using the windows_env resource."
      examples <<~DOC
      **Set an environment variable**:

      ```ruby
      windows_env 'ComSpec' do
        value 'C:\\Windows\\system32\\cmd.exe'
      end
      ```
      DOC

      default_action :create
      allowed_actions :create, :delete, :modify

      property :key_name, String,
        description: "An optional property to set the name of the key that is to be created, deleted, or modified if it differs from the resource block's name.",
        name_property: true

      property :value, String,
        description: "The value of the environmental variable to set.",
        required: %i{create modify}

      property :delim, [ String, nil, false ],
        description: "The delimiter that is used to separate multiple values for a single key.",
        desired_state: false

      property :user, String, default: "<System>"

      action_class do
        include Chef::Mixin::WindowsEnvHelper

        def whyrun_supported?
          false
        end

        def load_current_resource
          @current_resource = Chef::Resource::WindowsEnv.new(new_resource.name)
          current_resource.key_name(new_resource.key_name)

          if key_exists?
            current_resource.value(env_value(new_resource.key_name))
          else
            logger.trace("#{new_resource} key does not exist")
          end

          current_resource
        end

        def key_exists?
          @key_exists ||= !!env_value(new_resource.key_name)
        end

        def requires_modify_or_create?
          if new_resource.delim
            # e.g. check for existing value within PATH
            new_values.inject(0) do |index, val|
              next_index = current_values.find_index val
              return true if next_index.nil? || next_index < index

              next_index
            end
            false
          else
            new_resource.value != current_resource.value
          end
        end

        alias_method :compare_value, :requires_modify_or_create?

        # e.g. delete a PATH element
        #
        # ==== Returns
        # <true>:: If we handled the element case and caller should not delete the key
        # <false>:: Caller should delete the key, either no :delim was specific or value was empty
        #           after we removed the element.
        def delete_element
          return false unless new_resource.delim # no delim: delete the key

          needs_delete = new_values.any? { |v| current_values.include?(v) }
          if !needs_delete
            logger.trace("#{new_resource} element '#{new_resource.value}' does not exist")
            true # do not delete the key
          else
            new_value =
              current_values.select do |item|
                not new_values.include?(item)
              end.join(new_resource.delim)

            if new_value.empty?
              false # nothing left here, delete the key
            else
              old_value = new_resource.value(new_value)
              create_env
              logger.trace("#{new_resource} deleted #{old_value} element")
              new_resource.updated_by_last_action(true)
              true # we removed the element and updated; do not delete the key
            end
          end
        end

        def create_env
          obj = env_obj(@new_resource.key_name)
          unless obj
            obj = WIN32OLE.connect("winmgmts://").get("Win32_Environment").spawninstance_
            obj.name = @new_resource.key_name
            obj.username = new_resource.user
          end
          obj.variablevalue = @new_resource.value
          obj.put_
          value = @new_resource.value
          value = expand_path(value) if @new_resource.key_name.casecmp("PATH") == 0
          ENV[@new_resource.key_name] = value
          broadcast_env_change
        end

        def delete_env
          obj = env_obj(@new_resource.key_name)
          if obj
            obj.delete_
            broadcast_env_change
          end
          if ENV[@new_resource.key_name]
            ENV.delete(@new_resource.key_name)
          end
        end

        def modify_env
          if new_resource.delim
            new_resource.value((new_values + current_values).uniq.join(new_resource.delim))
          end
          create_env
        end

        # Returns the current values to split by delimiter
        def current_values
          @current_values ||= current_resource.value.split(new_resource.delim)
        end

        # Returns the new values to split by delimiter
        def new_values
          @new_values ||= new_resource.value.split(new_resource.delim)
        end

        def env_value(key_name)
          obj = env_obj(key_name)
          obj.variablevalue if obj
        end

        def env_obj(key_name)
          return @env_obj if @env_obj

          wmi = WmiLite::Wmi.new
          # Note that by design this query is case insensitive with regard to key_name
          environment_variables = wmi.query("select * from Win32_Environment where name = '#{key_name}'")
          if environment_variables && environment_variables.length > 0
            environment_variables.each do |env|
              @env_obj = env.wmi_ole_object
              return @env_obj if @env_obj.username.split("\\").last.casecmp(new_resource.user) == 0
            end
          end
          @env_obj = nil
        end
      end

      action :create, description: "Create an environment variable. If an environment variable already exists (but does not match), update that environment variable to match." do
        if key_exists?
          if requires_modify_or_create?
            modify_env
            logger.info("#{new_resource} altered")
            new_resource.updated_by_last_action(true)
          end
        else
          create_env
          logger.info("#{new_resource} created")
          new_resource.updated_by_last_action(true)
        end
      end

      action :delete, description: "Delete an environment variable." do
        if ( ENV[new_resource.key_name] || key_exists? ) && !delete_element
          delete_env
          logger.info("#{new_resource} deleted")
          new_resource.updated_by_last_action(true)
        end
      end

      action :modify, description: "Modify an existing environment variable. This prepends the new value to the existing value, using the delimiter specified by the `delim` property." do
        if key_exists?
          if requires_modify_or_create?
            modify_env
            logger.info("#{new_resource} modified")
            new_resource.updated_by_last_action(true)
          end
        else
          raise Chef::Exceptions::WindowsEnv, "Cannot modify #{new_resource} - key does not exist!"
        end
      end
    end
  end
end
