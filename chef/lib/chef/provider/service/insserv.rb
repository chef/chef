#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'chef/provider/service'
require 'chef/provider/service/init'
require 'chef/mixin/command'

class Chef
  class Provider
    class Service
      class Insserv < Chef::Provider::Service::Init

        def load_current_resource
          super

          # Look for a /etc/rc.*/SnnSERVICE link to signifiy that the service would be started in a runlevel
          if Dir.glob("/etc/rc**/S*#{@current_resource.service_name}").empty?
            @current_resource.enabled false
          else
            @current_resource.enabled true 
          end
  
          @current_resource
        end

        def enable_service()
          run_command(:command => "/sbin/insserv -r -f #{@new_resource.service_name}")
          run_command(:command => "/sbin/insserv -d -f #{@new_resource.service_name}")
        end

        def disable_service()
          run_command(:command => "/sbin/insserv -r -f #{@new_resource.service_name}")
        end
      end
    end
  end
end
