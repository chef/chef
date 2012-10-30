#
# Author:: Mark Mzyk <mmzyk@opscode.com>
# Author:: Seth Chisamore <schisamo@opscode.com>
# Author:: Bryan McLellan <btm@opscode.com>
# Copyright:: Copyright (c) 2011-2012 Opscode, Inc.
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

class Chef
  module Mixin
    module FileClass

      def file_class
        @host_os_file ||= if Chef::Platform.windows?
          require 'chef/win32/file'
          begin
            Chef::ReservedNames::Win32::File.verify_links_supported!
          rescue Chef::Exceptions::Win32APIFunctionNotImplemented => e
            message = "Link resource is not supported on this version of Windows"
            message << ": #{node[:kernel][:name]}" if node
            message << " (#{node[:platform_version]})" if node
            Chef::Log.fatal(message)
            raise e
          end
          Chef::ReservedNames::Win32::File
        else
          ::File
        end
      end
    end
  end
end


