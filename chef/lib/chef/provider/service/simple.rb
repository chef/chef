#
# Author:: Mathieu Sauve-Frankel <msf@kisoku.net>
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
require 'chef/mixin/command'

class Chef
  class Provider
    class Service
      class Simple
        def start_service
          if @new_resource.start_command
            run_command(:command => @new_resource.start_command)
          else
            raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} requires that start_command to be set"
          end
        end

        def stop_service
          if @new_resource.stop_command
            run_command(:command => @new_resource.stop_command)
          else
            raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} requires that stop_command to be set"
          end
        end

        def restart_service
          if @new_resource.restart_command
            run_command(:command => @new_resource.restart_command)
          else
            stop_service
            sleep 1
            start_service
          end
        end

        def reload_service
          if @new_resource.reload_command
            run_command(:command => @new_resource.reload_command)
          else
            raise Chef::Exceptions::UnsupportedAction, "#{self.to_s} requires that reload_command to be set"
          end
      end
    end
  end
end
