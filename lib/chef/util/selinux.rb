#
# Author:: Sean O'Meara
# Author:: Kevin Keane
# Author:: Lamont Granquist (<lamont@opscode.com>)
#
# Copyright:: Copyright (c) 2011 Opscode, Inc.
# Copyright:: Copyright (c) 2013, North County Tech Center, LLC
#
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

require 'chef/mixin/shell_out'

#
# NB: We take the approach that provisioning an selinux enabled server
# without installing the selinux utilities is completely incoherent
# and needs to be fixed in the provisioner / base image.
#

class Chef
  class Util
    class Selinux

      include Chef::Mixin::ShellOut

      attr_accessor :setenforce_path
      attr_accessor :getenforce_path
      attr_accessor :selinuxenabled_path

      def setenforce_path
        @setenforce_path ||= which("setenforce")
      end

      def getenforce_path
        @getenforce_path ||= which("getenforce")
      end

      def selinuxenabled_path
        @selinuxenabled_path ||= which("selinuxenabled")
      end

      def setenforce(state)
        if setenforce_path
          case state
          when :enforcing
            shell_out!("#{setenforce_path} 1")
          when :permissive
            shell_out!("#{setenforce_path} 0")
          else
            raise ArgumentError, "Bad argument to Chef::Util::Seliux#setenforce: #{state}"
          end
        else
          # FIXME?: manually roll our own setenforce
        end
        raise RuntimeError, "Called setenforce but binary does not exist (try installing selinux-utils or libselinux-utils)"
      end

      def getenforce
        if getenforce_path
          cmd = shell_out!(getenforce_path)
          case cmd.stdout
          when /Permissive/i
            return :permissive
          when /Enforcing/i
            return :enforcing
          when /Disabled/i
            return :disabled
          else
            raise RuntimeError, "Unknown output from getenforce: #{cmd.stdout}"
          end
        else
          # FIXME?: manually roll our own getenforce
        end
        raise RuntimeError, "Called getenforce but binary does not exist (try installing selinux-utils or libselinux-utils)"
      end

      def selinuxenabled?
        if selinuxenabled_path
          cmd = shell_out(selinuxenabled_path)
          case cmd.exitstatus
          when 1
            return false
          when 0
            return true
          else
            raise RuntimeError, "Unknown exit code from selinuxenabled: #{cmd.exitstatus}"
          end
        else
          # FIXME?: manually roll our own selinuxenabled
        end
        false
      end

      private

      def which(cmd)
        paths = ENV['PATH'].split(File::PATH_SEPARATOR) + [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ]
        paths.each do |path|
          filename = File.join(path, cmd)
          return filename if File.executable?(filename)
        end
        false
      end
    end
  end
end

