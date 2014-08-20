#
# Author:: Doug MacEachern (<dougm@vmware.com>)
# Copyright:: Copyright (c) 2010 VMware, Inc.
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

require 'chef/win32/api/system' if RUBY_PLATFORM =~ /mswin|mingw32|windows/

class Chef
  class Provider
    class Env
      class Windows < Chef::Provider::Env
        include Chef::ReservedNames::Win32::API::System if RUBY_PLATFORM =~ /mswin|mingw32|windows/

        def create_env
          obj = env_obj(@new_resource.key_name)
          unless obj
            obj = WIN32OLE.connect("winmgmts://").get("Win32_Environment").spawninstance_
            obj.name = @new_resource.key_name
            obj.username = "<System>"
          end
          obj.variablevalue = @new_resource.value
          obj.put_
          ENV[@new_resource.key_name] = @new_resource.value
          broadcast_env_change
        end

        def delete_env
          obj = env_obj(@new_resource.key_name)
          if obj
            obj.delete_
            ENV.delete(@new_resource.key_name)
            broadcast_env_change
          end
        end

        def env_value(key_name)
          obj = env_obj(key_name)
          return obj ? obj.variablevalue : nil
        end

        def env_obj(key_name)
          wmi = WmiLite::Wmi.new
          # Note that by design this query is case insensitive with regard to key_name
          environment_variables = wmi.query("select * from Win32_Environment where name = '#{key_name}'")
          if environment_variables && environment_variables.length > 0
            environment_variables[0].wmi_ole_object
          end
        end

        #see: http://msdn.microsoft.com/en-us/library/ms682653%28VS.85%29.aspx
        HWND_BROADCAST = 0xffff
        WM_SETTINGCHANGE = 0x001A
        SMTO_BLOCK = 0x0001
        SMTO_ABORTIFHUNG = 0x0002
        SMTO_NOTIMEOUTIFNOTHUNG = 0x0008

        def broadcast_env_change
          flags = SMTO_BLOCK | SMTO_ABORTIFHUNG | SMTO_NOTIMEOUTIFNOTHUNG
          SendMessageTimeoutA(HWND_BROADCAST, WM_SETTINGCHANGE, 0, FFI::MemoryPointer.from_string('Environment').address, flags, 5000, nil)
        end
      end
    end
  end
end
