#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
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

require File.join(File.dirname(__FILE__), "..", "mixin", "command")
require 'etc'

class Chef
  class Provider
    class User 
      class Useradd < Chef::Provider::User
        def create_user
          command = "useradd"
          command << set_options
          run_command(command)
        end
        
        def manage_user
          command = "usermod"
          command << set_options
          run_command(command)
        end
        
        def remove_user
          command = "userdel"
          command << " -r" if @new_resource.supports[:manage_home]
          command << " #{@new_resource.username}"
        end
        
        def lock_user
          run_command("usermod -L #{@new_resource.username}")
        end
        
        def unlock_user
          run_command("usermod -U #{@new_resource.username}")
        end
        
        def set_options
          opts << " -c '#{@new_resource.comment}'" if @new_resource.comment
          opts << " -d '#{@new_resource.home}'" if @new_resource.home
          opts << " -g '#{@new_resource.gid}'" if @new_resource.gid
          opts << " -u '#{@new_resource.uid}'" if @new_resource.uid
          opts << " -s '#{@new_resource.shell}'" if @new_resource.shell
          opts << " -p '#{@new_resource.password}'" if @new_resource.password
          if @new_resource.supports[:manage_home]
            case @node[:operatingsystem]
            when "Fedora","RedHat","CentOS"
              opts << " -M"
            else
              opts << " -m"
            end
          end
          opts << " #{@new_resource.username}"
          opts
        end
      
      end
    end
  end
end