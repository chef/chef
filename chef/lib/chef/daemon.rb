#
# Author:: AJ Christensen (<aj@junglist.gen.nz>)
# Copyright:: Copyright (c) 2008 OpsCode, Inc.
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

# I love you Merb (lib/merb-core/server.rb)

require 'chef/config'
require 'etc'

class Chef
  class Daemon
    class << self
      attr_accessor :name
=begin
def daemonize(name)
  exit if fork
  Process.setsid
  exit if fork
  $stdin.reopen("/dev/null")
  $stdout.reopen("/tmp/log", "a")
  $stderr.reopen($stdout)
end
=end

      def daemonize(name)
        @name = name
        pid = pid_from_file
        unless running?
          remove_pid_file()
          Chef::Log.info("Daemonizing..")
          begin
            exit if fork
            Process.setsid
            exit if fork
            Chef::Log.info("Forked, in #{Process.pid}")
            File.umask 0000
            $stdin.reopen("/dev/null")
            $stdout.reopen("/dev/null", "a")
            $stdout.reopen($stdout)
            at_exit { remove_pid_file }
          rescue NotImplementedError => e
            Chef.fatal!("There is no fork: #{e.message}")
          end
        else
          Chef.fatal!("Chef is already running pid #{pid}")
        end
      end
      
      def running?
        if pid_from_file.nil?
          false
        else
          Process.kill(0, pid_from_file)
          true
        end
      rescue Errno::ESRCH, Errno::ENOENT
        false
      #rescue Errno::EACCESS => e
      #  Chef.fatal!("You don't have access to the PID file at #{pid_file}: #{e.message}")
      end
    
      def pid_file
         Chef::Config[:pid_file] or "/tmp/#{@name}.pid"
      end
      
      def pid_from_file
        File.read(pid_file).chomp.to_i
      rescue Errno::ENOENT => e
        nil
      end
    
      def save_pid_file
        file = pid_file
        begin
          FileUtils.mkdir_p(File.dirname(file))
        rescue Errno::EACCESS => e
          Chef.fatal!("Failed store pid in #{File.dirname(file)}, permission denied: #{e.message}")
        end
      
        begin
          File.open(file, "w") { |f| f.write(Process.pid.to_s) }
        rescue Errno::EACCESS => e
          Chef.fatal!("Couldn't write to pidfile #{file}, permission denied: #{e.message}")
        end
      end
    
      def remove_pid_file
        FileUtils.rm(pid_file) if File.exists?(pid_file)
      end
           
      def change_privilege
        if Chef::Config[:user] and Chef::Config[:group]
          Chef::Log.info("About to change privilege to #{Chef::Config[:user]}:#{Chef::Config[:group]}")
          _change_privilege(Chef::Config[:user], Chef::Config[:group])
        elsif Chef::Config[:user]
          Chef::Log.info("About to change privilege to #{Chef::Config[:user]}")
          _change_privilege(Chef::Config[:user])
        end
      end
    
      def _change_privilege(user, group=user)
        uid, gid = Process.euid, Process.egid

        begin
          target_uid = Etc.getpwnam(user).uid
        rescue ArgumentError => e
          Chef.fatal!("Failed to get UID for user #{user}, does it exist? #{e.message}")
          return false
        end
   
        begin
          target_gid = Etc.getgrnam(group).gid
        rescue ArgumentERror => e
          Chef.fatal!("Failed to get GID for group #{group}, does it exist? #{e.message}")
          return false
        end
      
        if (uid != target_uid) or (gid != target_gid)
          Process.initgroups(user, target_gid)
          Process::GID.change_privilege(target_gid)
          Process::UID.change_privilege(target_uid)
        end
        true
      rescue Errno::EPERM => e
        Chef.fatal!("Permission denied when trying to change #{uid}:#{gid} to #{user}:#{group}. #{e.message}")
      end
    end
  end
end