#
# Author:: Stephen Haynes (<sh@nomitor.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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
      class Pw < Chef::Provider::User

        def load_current_resource
          super
          raise Chef::Exceptions::User, "Could not find binary /usr/sbin/pw for #{@new_resource}" unless ::File.exists?("/usr/sbin/pw")
        end

        def create_user
          command = "pw useradd"
          command << set_options
          shell_out!(command)
          modify_password
        end

        def manage_user
          command = "pw usermod"
          command << set_options
          shell_out!(command)
          modify_password
        end

        def remove_user
          command = "pw userdel #{@new_resource.username}"
          command << " -r" if @new_resource.supports[:manage_home]
          shell_out!(command)
        end

        def check_lock
          @locked = case @current_resource.password
                    when /^\*LOCKED\*/
                      true
                    else
                      false
                    end
        end

        def lock_user
          shell_out!("pw lock #{@new_resource.username}")
        end

        def unlock_user
          shell_out!("pw unlock #{@new_resource.username}")
        end

        def set_options
          opts = " #{@new_resource.username}"

          field_list = {
            'comment' => "-c",
            'home' => "-d",
            'gid' => "-g",
            'uid' => "-u",
            'shell' => "-s"
          }
          field_list.sort{ |a,b| a[0] <=> b[0] }.each do |field, option|
            field_symbol = field.to_sym
            if @current_resource.send(field_symbol) != @new_resource.send(field_symbol)
              if @new_resource.send(field_symbol)
                Chef::Log.debug("#{@new_resource} setting #{field} to #{@new_resource.send(field_symbol)}")
                opts << " #{option} '#{@new_resource.send(field_symbol)}'"
              end
            end
          end
          if @new_resource.supports[:manage_home]
            Chef::Log.debug("#{@new_resource} is managing the users home directory")
            opts << " -m"
          end
          opts
        end

        def modify_password

          unless password_changed?
            Chef::Log.debug("#{new_resource} no change needed to password")
            return
          end

          Chef::Log.debug("#{new_resource} updating password")
          command = "pw usermod #{@new_resource.username} -H 0"
          status = shell_out! command, :input => "#{@new_resource.password}"

          raise Chef::Exceptions::User, "pw failed - #{status.inspect}!" unless status.exitstatus == 0
        end

        def password_changed?
          @current_resource.password != @new_resource.password
        end
      end
    end
  end
end
