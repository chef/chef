#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
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

require File.join(File.dirname(__FILE__), "..", "service")
require File.join(File.dirname(__FILE__), "..", "..", "mixin", "command")

class Chef
  class Provider
    class Debian < Chef::Provider::Service
      def load_current_resource
        super
        status = popen4("update-rc.d -n -f #{@current_resource.service_name} remove") do |pid, stdin, stdout, stderr|
          stdin.close
          if stdout.gets(nil) =~ /etc\/rc[\dS].d\/S|not installed/
            Chef::Log.debug("#{@current_resource} is currently enabled")
            @current_resource.enabled(true)
          else
            Chef::Log.debug("#{@current_resource} is currently disabled")
            @current_resource.enabled(false)
          end
        end  

        unless status.exitstatus == 0
          raise Chef::Exception::Service, "update-rc.d -n -f #{@current_resource.service_name} failed - #{status.inspect}"
        end

        @current_resource        
      end

      def enable_service(name)
        run_command(:command => "update-rc.d #{name} defaults")
      end

      def disable_service(name)
        run_command(:command => "update-rc.d -f #{name} remove")
      end
    end
  end
end
