#
# Copyright:: Copyright 2012-2018, Chef Software Inc.
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

require "chef/provider/user"

class Chef
  class Provider
    class User
      class Aix < Chef::Provider::User
        provides :user, os: "aix"
        provides :aix_user

        UNIVERSAL_OPTIONS = [[:comment, "-c"], [:gid, "-g"], [:shell, "-s"], [:uid, "-u"]].freeze

        def create_user
          command = compile_command("useradd") do |useradd|
            useradd.concat(universal_options)
            useradd.concat(useradd_options)
          end
          shell_out_compact!(command)
          add_password
        end

        def manage_user
          add_password
          manage_home
          return if universal_options.empty?
          command = compile_command("usermod") do |u|
            u.concat(universal_options)
          end
          shell_out_compact!(command)
        end

        def remove_user
          command = [ "userdel" ]
          command << "-r" if new_resource.manage_home
          command << "-f" if new_resource.force
          command << new_resource.username
          shell_out_compact!(command)
        end

        # Aix does not support -r like other unix, sytem account is created by adding to 'system' group
        def useradd_options
          opts = []
          opts << "-g" << "system" if new_resource.system
          opts
        end

        def check_lock
          lock_info = shell_out_compact!("lsuser", "-a", "account_locked", new_resource.username)
          if whyrun_mode? && passwd_s.stdout.empty? && lock_info.stderr.match(/does not exist/)
            # if we're in whyrun mode and the user is not yet created we assume it would be
            return false
          end
          raise Chef::Exceptions::User, "Cannot determine if #{new_resource} is locked!" if lock_info.stdout.empty?

          status = /\S+\s+account_locked=(\S+)/.match(lock_info.stdout)
          @locked =
            if status && status[1] == "true"
              true
            else
              false
            end

          @locked
        end

        def lock_user
          shell_out_compact!("chuser", "account_locked=true", new_resource.username)
        end

        def unlock_user
          shell_out_compact!("chuser", "account_locked=false", new_resource.username)
        end

        def compile_command(base_command)
          base_command = Array(base_command)
          yield base_command
          base_command << new_resource.username
          base_command
        end

        def universal_options
          @universal_options ||=
            begin
              opts = []
              # magic allows UNIVERSAL_OPTIONS to be overridden in a subclass
              self.class::UNIVERSAL_OPTIONS.each do |field, option|
                update_options(field, option, opts)
              end
              if updating_home?
                opts << "-d" << new_resource.home
                if new_resource.manage_home
                  logger.trace("#{new_resource} managing the users home directory")
                  opts << "-m"
                else
                  logger.trace("#{new_resource} setting home to #{new_resource.home}")
                end
              end
              opts << "-o" if new_resource.non_unique
              opts
            end
        end

        def update_options(field, option, opts)
          return unless current_resource.send(field).to_s != new_resource.send(field).to_s
          return unless new_resource.send(field)
          logger.trace("#{new_resource} setting #{field} to #{new_resource.send(field)}")
          opts << option << new_resource.send(field).to_s
        end

        def updating_home?
          # will return false if paths are equivalent
          # Pathname#cleanpath does a better job than ::File::expand_path (on both unix and windows)
          # ::File.expand_path("///tmp") == ::File.expand_path("/tmp") => false
          # ::File.expand_path("\\tmp") => "C:/tmp"
          return true if current_resource.home.nil? && new_resource.home
          new_resource.home && Pathname.new(current_resource.home).cleanpath != Pathname.new(new_resource.home).cleanpath
        end

        private

        def add_password
          return unless current_resource.password != new_resource.password && new_resource.password
          logger.trace("#{new_resource.username} setting password to #{new_resource.password}")
          command = "echo '#{new_resource.username}:#{new_resource.password}' | chpasswd -e"
          shell_out!(command)
        end

        # Aix specific handling to update users home directory.
        def manage_home
          return unless updating_home? && new_resource.manage_home
          # -m option does not work on aix, so move dir.
          universal_options.delete("-m")
          if ::File.directory?(current_resource.home)
            logger.trace("Changing users home directory from #{current_resource.home} to #{new_resource.home}")
            FileUtils.mv current_resource.home, new_resource.home
          else
            logger.trace("Creating users home directory #{new_resource.home}")
            FileUtils.mkdir_p new_resource.home
          end
        end

      end
    end
  end
end
