#
# Author:: Daniel DeLeo (<dan@chef.io>)
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

require_relative "mixin/create_path"
require "fcntl"
if ChefUtils.windows?
  require_relative "win32/mutex"
end
require_relative "config"
require_relative "exceptions"
require "timeout" unless defined?(Timeout)
require "chef-utils" unless defined?(ChefUtils::CANARY)

class Chef

  # == Chef::RunLock
  # Provides an interface for acquiring and releasing a system-wide exclusive
  # lock.
  #
  # Used by Chef::Client to ensure only one instance of chef-client (or solo)
  # is modifying the system at a time.
  class RunLock
    include Chef::Mixin::CreatePath

    attr_reader :runlock
    attr_reader :mutex
    attr_reader :runlock_file

    # Create a new instance of RunLock
    # === Arguments
    # * :lockfile::: the full path to the lockfile.
    def initialize(lockfile)
      @runlock_file = lockfile
      @runlock = nil
      @mutex = nil
      @runpid = nil
    end

    # Acquire the system-wide lock. Will block indefinitely if another process
    # already has the lock and Chef::Config[:run_lock_timeout] is
    # not set. Otherwise will block for Chef::Config[:run_lock_timeout]
    # seconds and exit if the lock is not acquired.
    #
    # Each call to acquire should have a corresponding call to #release.
    #
    # The implementation is based on File#flock (see also: flock(2)).
    #
    # Either acquire() or test() methods should be called in order to
    # get the ownership of run_lock.
    def acquire
      if timeout_given?
        begin
          Timeout.timeout(time_to_wait) do
            unless test
              if time_to_wait > 0.0
                wait
              else
                exit_from_timeout
              end
            end
          end
        rescue Timeout::Error
          exit_from_timeout
        end
      else
        wait unless test
      end
    end

    #
    # Tests and if successful acquires the system-wide lock.
    # Returns true if the lock is acquired, false otherwise.
    #
    # Either acquire() or test() methods should be called in order to
    # get the ownership of run_lock.
    def test
      create_lock
      acquire_lock
    end

    #
    # Waits until acquiring the system-wide lock.
    #
    def wait
      Chef::Log.warn("#{ChefUtils::Dist::Infra::PRODUCT} #{runpid} is running, will wait for it to finish and then run.")
      if ChefUtils.windows?
        mutex.wait
      else
        runlock.flock(File::LOCK_EX)
      end
    end

    def save_pid
      runlock.truncate(0)
      runlock.rewind # truncate doesn't reset position to 0.
      runlock.write(Process.pid.to_s)
      # flush the file fsync flushes the system buffers
      # in addition to ruby buffers
      runlock.fsync
    end

    # Release the system-wide lock.
    def release
      if runlock
        if ChefUtils.windows?
          mutex.release
        else
          runlock.flock(File::LOCK_UN)
        end
        runlock.close
        # Don't unlink the pid file, if another chef-client was waiting, it
        # won't be recreated. Better to leave a "dead" pid file than not have
        # it available if you need to break the lock.
        reset
      end
    end

    # @api private solely for race condition tests
    def create_lock
      # ensure the runlock_file path exists
      create_path(File.dirname(runlock_file))
      @runlock = File.open(runlock_file, "a+")
    end

    # @api private solely for race condition tests
    def acquire_lock
      if ChefUtils.windows?
        acquire_win32_mutex
      else
        # If we support FD_CLOEXEC, then use it.
        # NB: ruby-2.0.0-p195 sets FD_CLOEXEC by default, but not
        # ruby-1.8.7/1.9.3
        if Fcntl.const_defined?("F_SETFD") && Fcntl.const_defined?("FD_CLOEXEC")
          runlock.fcntl(Fcntl::F_SETFD, runlock.fcntl(Fcntl::F_GETFD, 0) | Fcntl::FD_CLOEXEC)
        end
        # Flock will return 0 if it can acquire the lock otherwise it
        # will return false
        if runlock.flock(File::LOCK_NB | File::LOCK_EX) == 0
          true
        else
          false
        end
      end
    end

    private

    def reset
      @runlock = nil
      @mutex = nil
      @runpid = nil
    end

    # Since flock mechanism doesn't exist on windows we are using
    # platform Mutex.
    # We are creating a "Global" mutex here so that non-admin
    # users can not DoS chef-client by creating the same named
    # mutex we are using locally.
    # Mutex name is case-sensitive contrary to other things in
    # windows. "\" is the only invalid character.
    def acquire_win32_mutex
      @mutex = Chef::ReservedNames::Win32::Mutex.new("Global\\#{runlock_file.tr("\\", "/").downcase}")
      mutex.test
    end

    def runpid
      @runpid ||= runlock.read.strip
    end

    def timeout_given?
      !time_to_wait.nil?
    end

    def time_to_wait
      Chef::Config[:run_lock_timeout]
    end

    def exit_from_timeout
      rp = runpid
      release # Just to be on the safe side...
      raise Chef::Exceptions::RunLockTimeout.new(time_to_wait, rp)
    end
  end
end
