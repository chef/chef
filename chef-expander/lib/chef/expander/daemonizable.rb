#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'etc'
require 'chef/expander/loggable'

module Chef
  module Expander

    class AlreadyRunning < RuntimeError
    end

    class NoSuchUser < ArgumentError
    end

    class NoSuchGroup < ArgumentError
    end

    module Daemonizable
      include Loggable

      # Daemonizes the process if configured to do so, and ensures that only one
      # copy of the process is running with a given config by obtaining an
      # exclusive lock on the pidfile. Also sets process user and group if so
      # configured.
      # ===Raises
      # * AlreadyRunning::: when another process has the exclusive lock on the pidfile
      # * NoSuchUser::: when a user is configured that doesn't exist
      # * NoSuchGroup::: when a group is configured that doesn't exist
      # * SystemCallError::: if there is an error creating the pidfile
      def configure_process
        Expander.config.daemonize? ? daemonize : ensure_exclusive
        set_user_and_group
      end

      def daemonize
        acquire_locks
        exit if fork
        Process.setsid
        exit if fork
        write_pid
        Dir.chdir('/')
        STDIN.reopen("/dev/null")
        STDOUT.reopen("/dev/null", "a")
        STDERR.reopen("/dev/null", "a")
      end

      # When not forking into the background, this ensures only one chef-expander
      # is running with a given config and writes the process id to the pidfile.
      def ensure_exclusive
        acquire_locks
        write_pid
      end

      def set_user_and_group
        return nil if Expander.config.user.nil?

        if Expander.config.group.nil?
          log.info {"Changing user to #{Expander.config.user}"}
        else
          log.info {"Changing user to #{Expander.config.user} and group to #{Expander.config.group}"}
        end

        unless (set_group && set_user)
          log.error {"Unable to change user to #{Expander.config.user} - Are you root?"}
        end
      end

      # Deletes the pidfile, releasing the exclusive lock on it in the process.
      def release_locks
        File.unlink(@pidfile.path) if File.exist?(@pidfile.path)
        @pidfile.close unless @pidfile.closed?
      end

      private

      def set_user
        Process::Sys.setuid(target_uid)
        true
      rescue Errno::EPERM => e
        log.debug {e}
        false
      end

      def set_group
        if gid = target_uid
          Process::Sys.setgid(gid)
        end
        true
      rescue Errno::EPERM
        log.debug {e}
        false
      end

      def target_uid
        user = Expander.config.user
        user.kind_of?(Fixnum) ? user : Etc.getpwnam(user).uid
      rescue ArgumentError => e
        log.debug {e}
        raise NoSuchUser, "Cannot change user to #{user} - failed to find the uid"
      end

      def target_gid
        if group = Expander.config.group
          group.kind_of?(Fixnum) ? group : Etc.getgrnam(group).gid
        else
          nil
        end
      rescue ArgumentError => e
        log.debug {e}
        raise NoSuchGroup, "Cannot change group to #{group} - failed to find the gid"
      end

      def acquire_locks
        @pidfile = File.open(Expander.config.pidfile, File::RDWR|File::CREAT, 0644)
        unless @pidfile.flock(File::LOCK_EX | File::LOCK_NB)
          pid = @pidfile.read.strip
          msg = "Another instance of chef-expander (pid: #{pid}) has a lock on the pidfile (#{Expander.config.pidfile}). \n"\
                "Configure a different pidfile to run multiple instances of chef-expander at once."
          raise AlreadyRunning, msg
        end
      rescue Exception
        @pidfile.close if @pidfile && !@pidfile.closed?
        raise
      end

      def write_pid
        @pidfile.truncate(0)
        @pidfile.print("#{Process.pid}\n")
        @pidfile.flush
      end

    end
  end
end