#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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
  class Platform

    class << self
      def windows?
        if RUBY_PLATFORM =~ /mswin|mingw|windows/
          true
        else
          false
        end
      end

      def windows_server_2003?
        return false unless windows?

        require 'chef/win32/wmi'

        # CHEF-4888: Work around ruby #2618, expected to be fixed in Ruby 2.1.0
        # https://github.com/ruby/ruby/commit/588504b20f5cc880ad51827b93e571e32446e5db
        # https://github.com/ruby/ruby/commit/27ed294c7134c0de582007af3c915a635a6506cd
        WIN32OLE.ole_initialize

        wmi = Chef::ReservedNames::Win32::WMI.new
        host = wmi.first_of('Win32_OperatingSystem')
        is_server_2003 = (host['version'] && host['version'].start_with?("5.2"))

        WIN32OLE.ole_uninitialize

        is_server_2003
      end
    end

  end
end
