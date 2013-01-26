#
# Author:: Adam Edwards (<adamed@opscode.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'chef/resource/script'
require 'chef/mixin/windows_architecture_helper'

class Chef
  class Resource
    class Powershell < Chef::Resource::WindowsSystemScript

      def initialize(name, run_context=nil)
        super(name, run_context, :powershell, "WindowsPowerShell\\v1.0\\powershell.exe")
      end
      
    end
  end
end
