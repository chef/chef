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
    # * config::: This will generally be the `Chef::Config`, but any Hash-like
    #   object with Symbol keys will work. See 'Parameters' section.
    # === Parameters/Config
    # * :lockfile::: if set, this will be used as the full path to the lockfile.
    # * :file_cache_path::: if `:lockfile` is not set, the lock file will be
    #   named "chef-client-running.pid" and be placed in the directory given by
    #   `:file_cache_path`
    def initialize(config)
      @runlock_file = config[:lockfile] || "#{config[:file_cache_path]}/chef-client-running.pid"
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
      unless runlock.flock(File::LOCK_EX|File::LOCK_NB)
        # Another chef client running...
        runpid = runlock.read.strip.chomp
        Chef::Log.info("Chef client #{runpid} is running, will wait for it to finish and then run.")
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

