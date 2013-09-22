#
# Author:: Daniel DeLeo (<dan@opscode.com>)
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

require 'chef/mixin/create_path'
require 'fcntl'

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
    attr_reader :runlock_file

    # Create a new instance of RunLock
    # === Arguments
    # * :lockfile::: the full path to the lockfile.
    def initialize(lockfile)
      @runlock_file = lockfile
      @runlock = nil
    end

    # Acquire the system-wide lock. Will block indefinitely if another process
    # already has the lock.
    #
    # Each call to acquire should have a corresponding call to #release.
    #
    # The implementation is based on File#flock (see also: flock(2)).
    def acquire
      # ensure the runlock_file path exists
      create_path(File.dirname(runlock_file))
      @runlock = File.open(runlock_file,'w+')
      # if we support FD_CLOEXEC (linux, !windows), then use it.
      # NB: ruby-2.0.0-p195 sets FD_CLOEXEC by default, but not ruby-1.8.7/1.9.3
      if Fcntl.const_defined?('F_SETFD') && Fcntl.const_defined?('FD_CLOEXEC')
        runlock.fcntl(Fcntl::F_SETFD, runlock.fcntl(Fcntl::F_GETFD, 0) | Fcntl::FD_CLOEXEC)
      end
      unless runlock.flock(File::LOCK_EX|File::LOCK_NB)
        # Another chef client running...
        runpid = runlock.read.strip.chomp
        Chef::Log.warn("Chef client #{runpid} is running, will wait for it to finish and then run.")
        runlock.flock(File::LOCK_EX)
      end
      # We grabbed the run lock.  Save the pid.
      runlock.truncate(0)
      runlock.rewind # truncate doesn't reset position to 0.
      runlock.write(Process.pid.to_s)
    end

    # Release the system-wide lock.
    def release
      if runlock
        runlock.flock(File::LOCK_UN)
        runlock.close
        # Don't unlink the pid file, if another chef-client was waiting, it
        # won't be recreated. Better to leave a "dead" pid file than not have
        # it available if you need to break the lock.
        reset
      end
    end

    private

    def reset
      @runlock = nil
    end

  end
end

