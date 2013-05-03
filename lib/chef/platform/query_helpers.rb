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

        require 'ruby-wmi'

        host = WMI::Win32_OperatingSystem.find(:first)
        (host.version && host.version.start_with?("5.2"))
      end
    end

  end
end
