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

require File.expand_path('../../spec_helper', __FILE__)
require 'chef/client'

describe Chef::RunLock do

  # This behavior is believed to work on windows, but the tests use UNIX APIs.
  describe "when locking the chef-client run", :unix_only => true do

    ##
    # Lockfile location and helpers

    let(:random_temp_root) do
      Kernel.srand(Time.now.to_i + Process.pid)
      "/tmp/#{Kernel.rand(Time.now.to_i + Process.pid)}"
    end

    let(:file_cache_path){ "/var/chef/cache" }
    let(:lockfile){ "#{random_temp_root}/this/long/path/does/not/exist/chef-client-running.pid" }

    # make sure to start with a clean slate.
    before(:each){ FileUtils.rm_r(random_temp_root) if File.exist?(random_temp_root) }
    after(:each){ FileUtils.rm_r(random_temp_root) }

    def wait_on_lock
      tries = 0
      until File.exist?(lockfile)
        raise "Lockfile never created, abandoning test" if tries > 10
        tries += 1
        sleep 0.1
      end
    end

    ##
    # Side channel via a pipe allows child processes to send errors to the parent

    # Don't lazy create the pipe or else we might not share it with subprocesses
    let!(:error_pipe) do
      r,w = IO.pipe
      w.sync = true
      [r,w]
    end

    let(:error_read) { error_pipe[0] }
    let(:error_write) { error_pipe[1] }

    after do
      error_read.close unless error_read.closed?
      error_write.close unless error_write.closed?
    end

    # Send a RuntimeError from the child process to the parent process. Also
    # prints error to $stdout, just in case something goes wrong with the error
    # marshaling stuff.
    def send_side_channel_error(message)
      $stderr.puts(message)
      $stderr.puts(caller)
      e = RuntimeError.new(message)
      error_write.print(Marshal.dump(e))
    end

    # Read the error (if any) from the error channel. If a marhaled error is
    # present, it is unmarshaled and raised (which will fail the test)
    def raise_side_channel_error!
      error_write.close
      err = error_read.read
      error_read.close
      begin
        # ArgumentError from Marshal.load indicates no data, which we assume
        # means no error in child process.
        raise Marshal.load(err)
      rescue ArgumentError
        nil
      end
    end

    ##
    # Interprocess synchronization via a pipe. This allows us to control the
    # state of the processes competing over the lock without relying on sleep.

    let!(:sync_pipe) do
      r,w = IO.pipe
      w.sync = true
      [r,w]
    end
    let(:sync_read) { sync_pipe[0] }
    let(:sync_write) { sync_pipe[1] }

    after do
      sync_read.close unless sync_read.closed?
      sync_write.close unless sync_write.closed?
    end

    # Wait on synchronization signal. If not received within the timeout, an
    # error is sent via the error channel, and the process exits.
    def sync_wait
      if IO.select([sync_read], nil, nil, 20).nil?
        # timeout reading from the sync pipe.
        send_side_channel_error("Error syncing processes in run lock test (timeout)")
        exit!(1)
      else
        sync_read.getc
      end
    end

    # Sends a character in the sync pipe, which wakes ("unlocks") another
    # process that is waiting on the sync signal
    def sync_send
      sync_write.putc("!")
      sync_write.flush
    end

    ##
    # IPC to record test results in a pipe. Tests can read pipe contents to
    # check that operations occur in the expected order.

    let!(:results_pipe) do
      r,w = IO.pipe
      w.sync = true
      [r,w]
    end
    let(:results_read) { results_pipe[0] }
    let(:results_write) { results_pipe[1] }

    after do
      results_read.close unless results_read.closed?
      results_write.close unless results_write.closed?
    end

    # writes the message to the results pipe for later checking.
    # note that nothing accounts for the pipe filling and waiting forever on a
    # read or write call, so don't put too much data in.
    def record(message)
      results_write.puts(message)
      results_write.flush
    end

    def results
      results_write.flush
      results_write.close
      message = results_read.read
      results_read.close
      message
    end

    ##
    # Run lock is the system under test
    let!(:run_lock) { Chef::RunLock.new(:file_cache_path => file_cache_path, :lockfile => lockfile) }

    it "creates the full path to the lockfile" do
      lambda { run_lock.acquire }.should_not raise_error(Errno::ENOENT)
      File.should exist(lockfile)
    end

    it "sets FD_CLOEXEC on the lockfile", :supports_cloexec => true do
      run_lock.acquire
      (run_lock.runlock.fcntl(Fcntl::F_GETFD, 0) & Fcntl::FD_CLOEXEC).should == Fcntl::FD_CLOEXEC
    end

    it "allows only one chef client run per lockfile" do
      # First process, gets the lock and keeps it.
      p1 = fork do
        run_lock.acquire
        record "p1 has lock"
        # Wait until the other process is trying to get the lock:
        sync_wait
        # sleep a little bit to make process p2 wait on the lock
        sleep 2
        record "p1 releasing lock"
        run_lock.release
        exit!(0)
      end

      # Wait until p1 creates the lockfile
      wait_on_lock

      p2 = fork do
        # inform process p1 that we're trying to get the lock
        sync_send
        run_lock.acquire
        record "p2 has lock"
        run_lock.release
        exit!(0)
      end

      Process.waitpid2(p1)
      Process.waitpid2(p2)

      raise_side_channel_error!

      expected=<<-E
p1 has lock
p1 releasing lock
p2 has lock
E
      results.should == expected
    end

    it "clears the lock if the process dies unexpectedly" do
      p1 = fork do
        run_lock.acquire
        record "p1 has lock"
        sleep 60
        record "p1 still has lock"
        exit! 1
      end

      wait_on_lock
      Process.kill(:KILL, p1)
      Process.waitpid2(p1)


      p2 = fork do
        run_lock.acquire
        record "p2 has lock"
        run_lock.release
        exit! 0
      end

      Process.waitpid2(p2)

      results.should =~ /p2 has lock\Z/
    end
  end

end

