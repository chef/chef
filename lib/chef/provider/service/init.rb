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
    class Service
      class Init < Chef::Provider::Service::Base
      
        def load_current_resource
          @current_resource        
        end
        
        def start_service
          run_command(:command => "/etc/init.d/#{name} start")
        end
          
        def stop_service
          run_command(:command => "/etc/init.d/#{name} stop")
        end

      end
    end
  end
end
