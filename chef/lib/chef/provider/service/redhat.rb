#
# Author:: AJ Christensen (<aj@hjksolutions.com>)
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

require 'chef/provider/service'
require 'chef/provider/service/init'
require 'chef/mixin/command'

class Chef
  class Provider
    class Service
      class Redhat < Chef::Provider::Service::Init
        
        def initialize(node, new_resource, collection=nil, definitions=nil, cookbook_loader=nil)
          super(node, new_resource, collection, definitions, cookbook_loader)
           @init_command = "/sbin/service #{@new_resource.service_name}"
         end
        
        def load_current_resource
          super
          
          unless ::File.exists? "/sbin/chkconfig"
            raise Chef::Exceptions::Service, "/sbin/chkconfig does not exist!"
          end

          status = popen4("/sbin/chkconfig --list #{@current_resource.service_name}") do |pid, stdin, stdout, stderr|
            if stdout.gets =~ /\d:on/
              @current_resource.enabled true
            else
              @current_resource.enabled false
            end
          end  

          @current_resource        
        end

        def enable_service()
          run_command(:command => "/sbin/chkconfig #{@new_resource.service_name} on")
        end

        def disable_service()
          run_command(:command => "/sbin/chkconfig #{@new_resource.service_name} off")
        end
        
      end
    end
  end
end
