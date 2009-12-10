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

require 'chef/provider/user'

class Chef
  class Provider
    class User 
      class Useradd < Chef::Provider::User
        def create_user
          command = "useradd"
          command << set_options
          run_command(:command => command)
        end
        
        def manage_user
          command = "usermod"
          command << set_options
          run_command(:command => command)
        end
        
        def remove_user
          command = "userdel"
          command << " -r" if @new_resource.supports[:manage_home]
          command << " #{@new_resource.username}"
          run_command(:command => command)
        end
        
        def check_lock
          status = popen4("passwd -S #{@new_resource.username}") do |pid, stdin, stdout, stderr|
            status_line = stdout.gets.split(' ')
            case status_line[1]
            when /^P/
              @locked = false
            when /^N/
              @locked = false
            when /^L/
              @locked = true
            end
          end

          unless status.exitstatus == 0
            raise Chef::Exceptions::User, "Cannot determine if #{@new_resource} is locked!"
          end

          @locked
        end
        
        def lock_user
          run_command(:command => "usermod -L #{@new_resource.username}")
        end
        
        def unlock_user
          run_command(:command => "usermod -U #{@new_resource.username}")
        end
        
        def set_options
          opts = ''
          
          field_list = {
            'comment' => "-c",
            'gid' => "-g",
            'uid' => "-u",
            'shell' => "-s",
            'password' => "-p"
          }
          field_list.sort{ |a,b| a[0] <=> b[0] }.each do |field, option|
            field_symbol = field.to_sym
            if @current_resource.send(field_symbol) != @new_resource.send(field_symbol)
              if @new_resource.send(field_symbol)
                Chef::Log.debug("Setting #{@new_resource} #{field} to #{@new_resource.send(field_symbol)}")
                opts << " #{option} '#{@new_resource.send(field_symbol)}'"
              end
            end
          end
          if @current_resource.home != @new_resource.home && @new_resource.home
            if @new_resource.supports[:manage_home]
              Chef::Log.debug("Managing the home directory for #{@new_resource}")
              opts << " -d '#{@new_resource.home}' -m"
            else
              Chef::Log.debug("Setting #{@new_resource} home to #{@new_resource.home}")
              opts << " -d '#{@new_resource.home}'"
            end
          end
          opts << " -o" if @new_resource.supports[:non_unique]
          opts << " #{@new_resource.username}"
          opts
        end
      
      end
    end
  end
end
