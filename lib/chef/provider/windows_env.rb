#
# Author:: Doug MacEachern (<dougm@vmware.com>)
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

require_relative "../provider"
require_relative "../resource/windows_env"
require_relative "../mixin/windows_env_helper"

class Chef
  class Provider
    class WindowsEnv < Chef::Provider
      include Chef::Mixin::WindowsEnvHelper
      attr_accessor :key_exists

      provides :env
      provides :windows_env

      def whyrun_supported?
        false
      end

      def initialize(new_resource, run_context)
        super
        @key_exists = true
      end

      def load_current_resource
        @current_resource = Chef::Resource::WindowsEnv.new(new_resource.name)
        current_resource.key_name(new_resource.key_name)

        if env_key_exists(new_resource.key_name)
          current_resource.value(env_value(new_resource.key_name))
        else
          @key_exists = false
          logger.trace("#{new_resource} key does not exist")
        end

        current_resource
      end

      def env_key_exists(key_name)
        env_value(key_name) ? true : false
      end

      # Check to see if value needs any changes
      #
      # ==== Returns
      # <true>:: If a change is required
      # <false>:: If a change is not required
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

      def action_create
        if @key_exists
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
          return true # do not delete the key
        else
          new_value =
            current_values.select do |item|
              not new_values.include?(item)
            end.join(new_resource.delim)

          if new_value.empty?
            return false # nothing left here, delete the key
          else
            old_value = new_resource.value(new_value)
            create_env
            logger.trace("#{new_resource} deleted #{old_value} element")
            new_resource.updated_by_last_action(true)
            return true # we removed the element and updated; do not delete the key
          end
        end
      end

      def action_delete
        if ( ENV[new_resource.key_name] || @key_exists ) && !delete_element
          delete_env
          logger.info("#{new_resource} deleted")
          new_resource.updated_by_last_action(true)
        end
      end

      def action_modify
        if @key_exists
          if requires_modify_or_create?
            modify_env
            logger.info("#{new_resource} modified")
            new_resource.updated_by_last_action(true)
          end
        else
          raise Chef::Exceptions::WindowsEnv, "Cannot modify #{new_resource} - key does not exist!"
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
            return @env_obj if @env_obj.username.split('\\').last.casecmp(new_resource.user) == 0
          end
        end
        @env_obj = nil
      end
    end
  end
end
