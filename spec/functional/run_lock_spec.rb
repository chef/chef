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

  # This behavior works on windows, but the tests use fork :(
  describe "when locking the chef-client run", :unix_only => true do

    ##
    # Lockfile location and helpers

    let(:random_temp_root) do
      Kernel.srand(Time.now.to_i + Process.pid)
      "/tmp/#{Kernel.rand(Time.now.to_i + Process.pid)}"
    end

    let(:lockfile){ "#{random_temp_root}/this/long/path/does/not/exist/chef-client-running.pid" }

    # make sure to start with a clean slate.
    before(:each){ FileUtils.rm_r(random_temp_root) if File.exist?(random_temp_root) }
    after(:each){ FileUtils.rm_r(random_temp_root) if File.exist?(random_temp_root) }

    WAIT_ON_LOCK_TIME = 1.0
    def wait_on_lock
      Timeout::timeout(WAIT_ON_LOCK_TIME) do
        until File.exist?(lockfile)
          sleep 0.1
        end
      end
    rescue Timeout::Error
      raise "Lockfile never created, abandoning test"
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

    CLIENT_PROCESS_TIMEOUT = 2
    BREATHING_ROOM = 1

    # ClientProcess is defined below
    let!(:p1) { ClientProcess.new(self, 'p1') }
    let!(:p2) { ClientProcess.new(self, 'p2') }
    after do
      p1.stop
      p2.stop
    end

    context "when the lockfile does not already exist" do
      context "when a client acquires the lock but has not yet saved the pid" do
        before { p1.run_to("acquired lock") }

        it "the lockfile is created" do
          expect(File.exist?(lockfile)).to be_truthy
        end

        it "the lockfile is locked" do
          run_lock = Chef::RunLock.new(lockfile)
          begin
            expect(run_lock.test).to be_falsey
          ensure
            run_lock.release
          end
        end

        it "sets FD_CLOEXEC on the lockfile", :supports_cloexec => true do
          run_lock = File.open(lockfile)
          expect(run_lock.fcntl(Fcntl::F_GETFD, 0) & Fcntl::FD_CLOEXEC).to eq(Fcntl::FD_CLOEXEC)
        end

        it "the lockfile is empty" do
          expect(IO.read(lockfile)).to eq('')
        end

        it "and a second client tries to acquire the lock, it doesn't get the lock until *after* the first client exits" do
          # Start p2 and tell it to move forward in the background
          p2.run_to("acquired lock") do
            # While p2 is trying to acquire, wait a bit and then let p1 complete
            sleep(BREATHING_ROOM)
            expect(p2.last_event).to eq("started")
            p1.run_to_completion
          end

          p2.run_to_completion
        end

        it "and a second client tries to get the lock and the first is killed, the second client gets the lock immediately" do
          p2.run_to("acquired lock") do
            sleep BREATHING_ROOM
            expect(p2.last_event).to eq("started")
            p1.stop
          end
          p2.run_to_completion
        end
      end

      context "when a client acquires the lock and saves the pid" do
        before { p1.run_to("saved pid") }

        it "the lockfile is created" do
          expect(File.exist?(lockfile)).to be_truthy
        end

        it "the lockfile is locked" do
          run_lock = Chef::RunLock.new(lockfile)
          begin
            expect(run_lock.test).to be_falsey
          ensure
            run_lock.release
          end
        end

        it "sets FD_CLOEXEC on the lockfile", :supports_cloexec => true do
          run_lock = File.open(lockfile)
          expect(run_lock.fcntl(Fcntl::F_GETFD, 0) & Fcntl::FD_CLOEXEC).to eq(Fcntl::FD_CLOEXEC)
        end

        it "the PID is in the lockfile" do
          expect(IO.read(lockfile)).to eq p1.pid.to_s
        end

        it "and a second client tries to acquire the lock, it doesn't get the lock until *after* the first client exits" do
          # Start p2 and tell it to move forward in the background
          p2.run_to("acquired lock") do
            # While p2 is trying to acquire, wait a bit and then let p1 complete
            sleep(BREATHING_ROOM)
            expect(p2.last_event).to eq("started")
            p1.run_to_completion
          end

          p2.run_to_completion
        end

        it "when a second client tries to get the lock and the first is killed, the second client gets the lock immediately" do
          p2.run_to("acquired lock") do
            sleep BREATHING_ROOM
            expect(p2.last_event).to eq("started")
            p1.stop
          end
          p2.run_to_completion
        end
      end

      context "when a client acquires a lock and exits normally" do
        before { p1.run_to_completion }

        it "the lockfile remains" do
          expect(File.exist?(lockfile)).to be_truthy
        end

        it "the lockfile is not locked" do
          run_lock = Chef::RunLock.new(lockfile)
          begin
            expect(run_lock.test).to be_truthy
          ensure
            run_lock.release
          end
        end

        it "the PID is in the lockfile" do
          expect(IO.read(lockfile)).to eq p1.pid.to_s
        end

        it "and a second client tries to acquire the lock, it gets the lock immediately" do
          p2.run_to_completion
        end
      end
    end

    it "test returns true and acquires the lock" do
      run_lock = Chef::RunLock.new(lockfile)
      p1 = fork do
        expect(run_lock.test).to eq(true)
        run_lock.save_pid
        sleep 2
        exit! 1
      end

      wait_on_lock

      p2 = fork do
        expect(run_lock.test).to eq(false)
        exit! 0
      end

      Process.waitpid2(p2)
      Process.waitpid2(p1)
    end

    it "test returns without waiting when the lock is acquired" do
      run_lock = Chef::RunLock.new(lockfile)
      p1 = fork do
        run_lock.acquire
        run_lock.save_pid
        sleep 2
        exit! 1
      end

      wait_on_lock

      expect(run_lock.test).to eq(false)
      Process.waitpid2(p1)
    end

  end

  #
  # Runs a process in the background that will:
  #
  # 1. start up (`started` event)
  # 2. acquire the runlock file (`acquired lock` event)
  # 3. save the pid to the lockfile (`saved pid` event)
  # 4. exit
  #
  # You control exactly how far the client process goes with the `run_to`
  # method: it will stop at any given spot so you can test for race conditions.
  #
  # It uses a pair of pipes to communicate with the process. The tests will
  # send an event name over to the process, which gives the process permission
  # to run until it reaches that event (at which point it waits for another event
  # name). The process sends the name of each event it reaches back to the tests.
  #
  class ClientProcess
    def initialize(example, name)
      @example = example
      @name = name
      @read_from_process, @write_to_tests = IO.pipe
      @read_from_tests, @write_to_process = IO.pipe
    end

    attr_reader :example
    attr_reader :name
    attr_reader :pid

    def fire_event(event)
      # Let the caller know what event we've reached
      write_to_tests.puts(event)

      # Block until the client tells us where to stop
      if !@run_to_event || event == @run_to_event
        @run_to_event = read_from_tests.gets.strip
      end
    end

    def last_event
      while true
        event = readline_nonblock(read_from_process)
        break if event.nil?
        @last_event = event.strip
      end
      @last_event
    end

    def run_to(event, &background_block)
      # Start the process if it's not started
      start if !pid

      # Tell the process what to stop at (also means it can go)
      write_to_process.puts event

      # Run the background block
      background_block.call if background_block

      # Wait until it gets there
      Timeout::timeout(CLIENT_PROCESS_TIMEOUT) do
        until @last_event == event
          @last_event = read_from_process.gets.strip
        end
      end
    end

    def run_to_completion
      # Start the process if it's not started
      start if !pid

      # Tell the process to stop at nothing (no blocking)
      @write_to_process.puts "nothing"

      # Wait for the process to exit
      wait_for_exit
    end

    def wait_for_exit
      Timeout::timeout(CLIENT_PROCESS_TIMEOUT) do
        Process.wait(pid) if pid
      end
    end

    def stop
      if pid
        begin
          Process.kill(:KILL, pid)
          Timeout::timeout(CLIENT_PROCESS_TIMEOUT) do
            Process.waitpid2(pid)
          end
        # Process not found is perfectly fine when we're trying to kill a process :)
        rescue Errno::ESRCH
        end
      end
    end

    private

    attr_reader :read_from_process
    attr_reader :write_to_tests
    attr_reader :read_from_tests
    attr_reader :write_to_process

    def start
      @pid = fork do
        Timeout::timeout(CLIENT_PROCESS_TIMEOUT) do
          run_lock = Chef::RunLock.new(example.lockfile)
          fire_event("started")
          run_lock.acquire
          fire_event("acquired lock")
          run_lock.save_pid
          fire_event("saved pid")
          exit!(0)
        end
      end
    end

    def readline_nonblock(fd)
      buffer = ""
      buffer << fd.read_nonblock(1) while buffer[-1] != "\n"

      buffer
    #rescue IO::EAGAINUnreadable
    rescue IO::WaitReadable
      unless buffer == ""
        sleep 0.1
        retry
      end
      nil
    end
  end
end
