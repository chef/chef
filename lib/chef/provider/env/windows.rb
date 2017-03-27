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

require "chef/mixin/windows_env_helper"

class Chef
  class Provider
    class Env
      class Windows < Chef::Provider::Env
        include Chef::Mixin::WindowsEnvHelper

        provides :env, os: "windows"

        def whyrun_supported?
          false
        end

        def create_env
          obj = env_obj(@new_resource.key_name)
          unless obj
            obj = WIN32OLE.connect("winmgmts://").get("Win32_Environment").spawninstance_
            obj.name = @new_resource.key_name
            obj.username = "<System>"
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

        def env_value(key_name)
          obj = env_obj(key_name)
          obj ? obj.variablevalue : ENV[key_name]
        end

        def env_obj(key_name)
          wmi = WmiLite::Wmi.new
          # Note that by design this query is case insensitive with regard to key_name
          environment_variables = wmi.query("select * from Win32_Environment where name = '#{key_name}'")
          if environment_variables && environment_variables.length > 0
            environment_variables[0].wmi_ole_object
          end
        end

      end
    end
  end
end
