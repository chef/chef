#
# Author:: Stephen Nelson-Smith (<sns@opscode.com>)
# Author:: Jon Ramsey (<jonathon.ramsey@gmail.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

class Chef
  class Provider
    class User
      class Solaris < Chef::Provider::User::Useradd
        UNIVERSAL_OPTIONS = [[:comment, "-c"], [:gid, "-g"], [:shell, "-s"], [:uid, "-u"]]

        attr_writer :password_file

        def initialize(new_resource, run_context)
          @password_file = "/etc/shadow"
          super
        end

        def create_user
          super
          manage_password
        end

        def manage_user
          manage_password
          super
        end

      private

        def manage_password
          if @current_resource.password != @new_resource.password && @new_resource.password
            Chef::Log.debug("#{@new_resource} setting password to #{@new_resource.password}")
            write_shadow_file
          end
        end

        def write_shadow_file
          buffer = Tempfile.new("shadow", "/etc")
          ::File.open(@password_file) do |shadow_file|
            shadow_file.each do |entry|
              user = entry.split(":").first
              if user == @new_resource.username
                buffer.write(updated_password(entry))
              else
                buffer.write(entry)
              end
            end
          end
          buffer.close

          # FIXME: mostly duplicates code with file provider deploying a file
          mode = ::File.stat(@password_file).mode & 07777
          uid  = ::File.stat(@password_file).uid
          gid  = ::File.stat(@password_file).gid

          FileUtils.chown uid, gid, buffer.path
          FileUtils.chmod mode, buffer.path

          FileUtils.mv buffer.path, @password_file
        end

        def updated_password(entry)
          fields = entry.split(":")
          fields[1] = @new_resource.password
          fields[2] = days_since_epoch
          fields.join(":")
        end

        def days_since_epoch
          (Time.now.to_i / 86400).floor
        end
      end
    end
  end
end

