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

require 'pathname'
require 'chef/mixin/shell_out'
require 'chef/provider/user'

class Chef
  class Provider
    class User
      class Useradd < Chef::Provider::User
        include Chef::Mixin::ShellOut

        UNIVERSAL_OPTIONS = [[:comment, "-c"], [:gid, "-g"], [:password, "-p"], [:shell, "-s"], [:uid, "-u"]]

        def create_user
          command = compile_command("useradd") do |useradd|
            useradd << universal_options
            useradd << useradd_options
          end
          shell_out!(command)
        end

        def manage_user
          if universal_options != ""
            command = compile_command("usermod") do |u|
              u << universal_options
            end
            shell_out!(command)
          end
        end

        def remove_user
          command = "userdel"
          command << " -r" if managing_home_dir?
          command << " #{@new_resource.username}"
          shell_out!(command)
        end

        def locked?
          status = check_lock_status

          status_line = status.stdout.split(' ')
          @locked = status_line[1].start_with? "L"

          unless status.exitstatus == 0
            raise_lock_error = false
            # we can get an exit code of 1 even when it's successful on rhel/centos (redhat bug 578534)
            if status.exitstatus == 1 && ['redhat', 'centos'].include?(node[:platform])
              passwd_version = shell_out!('rpm -q passwd').stdout.chomp

              if passwd_version != 'passwd-0.73-1'
                raise_lock_error = true
              end
            else
              raise_lock_error = true
            end

            raise Chef::Exceptions::User, "Cannot determine if #{@new_resource} is locked!" if raise_lock_error
          end

          @locked
        end

        def lock_user
          shell_out!("usermod #{@new_resource.username} -e 1")
        end

        def unlock_user
          shell_out!("usermod #{@new_resource.username} -p *")
        end

        def lock_pass
          shell_out!("usermod -L #{@new_resource.username}")
        end

        def unlock_pass
          shell_out!("usermod -U #{@new_resource.username}")
        end

        def deprecated_lock
          lock_pass
        end

        def deprecated_unlock
          unlock_pass
        end

        def compile_command(base_command)
          yield base_command
          base_command << " #{@new_resource.username}"
          base_command
        end

        def universal_options
          @universal_options ||=
            begin
              opts = ''
              # magic allows UNIVERSAL_OPTIONS to be overridden in a subclass
              self.class::UNIVERSAL_OPTIONS.each do |field, option|
                update_options(field, option, opts)
              end
              if updating_home?
                if managing_home_dir?
                  Chef::Log.debug("#{@new_resource} managing the users home directory")
                  opts << " -m -d '#{@new_resource.home}'"
                else
                  Chef::Log.debug("#{@new_resource} setting home to #{@new_resource.home}")
                  opts << " -d '#{@new_resource.home}'"
                end
              end
              opts << " -o" if @new_resource.non_unique || @new_resource.supports[:non_unique]
              opts
            end
        end

        def update_options(field, option, opts)
          if @current_resource.send(field) != @new_resource.send(field)
            if @new_resource.send(field)
              Chef::Log.debug("#{@new_resource} setting #{field} to #{@new_resource.send(field)}")
              opts << " #{option} '#{@new_resource.send(field)}'"
            end
          end
        end

        def useradd_options
          opts = ''
          opts << " -r" if @new_resource.system
          opts
        end

        def updating_home?
          # will return false if paths are equivalent
          # Pathname#cleanpath does a better job than ::File::expand_path (on both unix and windows)
          # ::File.expand_path("///tmp") == ::File.expand_path("/tmp") => false
          # ::File.expand_path("\\tmp") => "C:/tmp"
          return true if @current_resource.home.nil? && @new_resource.home
          @new_resource.home and Pathname.new(@current_resource.home).cleanpath != Pathname.new(@new_resource.home).cleanpath
        end

        def managing_home_dir?
          @new_resource.manage_home || @new_resource.supports[:manage_home]
        end

        private

        def check_lock_status
          shell_out("passwd -S #{@new_resource.username}")
        end

      end
    end
  end
end
