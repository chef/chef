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

class Chef
  class RunLock
    attr_reader :runlock
    attr_reader :runlock_file

    def initialize(config)
      @runlock_file = config[:lockfile] || "#{config[:file_cache_path]}/chef-client-running.pid"
      @runlock = nil
    end

    def acquire
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

