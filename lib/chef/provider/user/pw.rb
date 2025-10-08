#
# Author:: Stephen Haynes (<sh@nomitor.com>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../user"

class Chef
  class Provider
    class User
      class Pw < Chef::Provider::User
        provides :pw_user
        provides :user, os: "freebsd"

        def load_current_resource
          super
          raise Chef::Exceptions::User, "Could not find binary /usr/sbin/pw for #{new_resource}" unless ::File.exist?("/usr/sbin/pw")
        end

        def create_user
          shell_out!("pw", "useradd", set_options)
          modify_password
        end

        def manage_user
          shell_out!("pw", "usermod", set_options)
          modify_password
        end

        def remove_user
          command = [ "pw", "userdel", new_resource.username ]
          command << "-r" if new_resource.manage_home
          shell_out!(command)
        end

        def check_lock
          @locked = case current_resource.password
                    when /^\*LOCKED\*/
                      true
                    else
                      false
                    end
          @locked
        end

        def lock_user
          shell_out!("pw", "lock", new_resource.username)
        end

        def unlock_user
          shell_out!("pw", "unlock", new_resource.username)
        end

        def set_options
          opts = [ new_resource.username ]

          field_list = {
            "comment" => "-c",
            "home" => "-d",
            "gid" => "-g",
            "uid" => "-u",
            "shell" => "-s",
          }
          field_list.sort_by { |a| a[0] }.each do |field, option|
            field_symbol = field.to_sym
            next unless current_resource.send(field_symbol) != new_resource.send(field_symbol)

            if new_resource.send(field_symbol)
              logger.trace("#{new_resource} setting #{field} to #{new_resource.send(field_symbol)}")
              opts << option
              opts << new_resource.send(field_symbol)
            end
          end
          if new_resource.manage_home
            logger.trace("#{new_resource} is managing the users home directory")
            opts << "-m"
          end
          opts
        end

        def modify_password
          if !new_resource.password.nil? && (current_resource.password != new_resource.password)
            logger.trace("#{new_resource} updating password")
            command = "pw usermod #{new_resource.username} -H 0"
            shell_out!(command, input: new_resource.password.to_s)
          else
            logger.debug("#{new_resource} no change needed to password")
          end
        end
      end
    end
  end
end
