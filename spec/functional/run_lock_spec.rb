#
# Author:: Daniel DeLeo (<dan@chef.io>)
# Copyright:: Copyright 2012-2016, Chef Software, Inc.
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

require File.expand_path("../../spec_helper", __FILE__)
require "chef/client"

describe Chef::RunLock do

  # This behavior works on windows, but the tests use fork :(
  describe "when locking the chef-client run", :unix_only => true do

    ##
    # Lockfile location and helpers

    let(:random_temp_root) do
      Kernel.srand(Time.now.to_i + Process.pid)
      "#{Dir.tmpdir}/#{Kernel.rand(Time.now.to_i + Process.pid)}"
    end

    let(:lockfile) { "#{random_temp_root}/this/long/path/does/not/exist/chef-client-running.pid" }

    # make sure to start with a clean slate.
    before(:each) { log_event("rm -rf before"); FileUtils.rm_r(random_temp_root) if File.exist?(random_temp_root) }
    after(:each) { log_event("rm -rf after"); FileUtils.rm_r(random_temp_root) if File.exist?(random_temp_root) }

    def log_event(message, time = Time.now.strftime("%H:%M:%S.%L"))
      events << [ message, time ]
    end

    def events
      @events ||= []
    end

    WAIT_ON_LOCK_TIME = 1.0
    def wait_on_lock(from_fork)
      Timeout.timeout(WAIT_ON_LOCK_TIME) do
        from_fork.readline
      end
    rescue Timeout::Error
      raise "Lockfile never created, abandoning test"
    end

    CLIENT_PROCESS_TIMEOUT = 10
    BREATHING_ROOM = 1

    # ClientProcess is defined below
    let!(:p1) { ClientProcess.new(self, "p1") }
    let!(:p2) { ClientProcess.new(self, "p2") }
    after(:each) do |example|
      begin
        p1.stop
        p2.stop
      rescue
        example.exception = $!
        raise
      ensure
        if example.exception
          print_events
        end
      end
    end

    def print_events
      # Consume any remaining events that went on the channel and print them all
      p1.last_event
      p2.last_event
      events.each_with_index.sort_by { |(message, time), index| [ time, index ] }.each do |(message, time), index|
        print "#{time} #{message}\n"
      end
    end

    context "when the lockfile does not already exist" do
      context "when a client creates the lockfile but has not yet acquired the lock" do
        before { p1.run_to("created lock") }
        shared_context "second client gets the lock" do
          it "the lockfile is created" do
            log_event("lockfile exists? #{File.exist?(lockfile)}")
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

          it "the lockfile is empty" do
            expect(IO.read(lockfile)).to eq("")
          end

          context "and a second client gets the lock" do
            before { p2.run_to("acquired lock") }
            it "the first client does not get the lock until the second finishes" do
              p1.run_to("acquired lock") do
                p2.run_to_completion
              end
            end
            it "and the first client tries to get the lock and the second is killed, the first client gets the lock immediately" do
              p1.run_to("acquired lock") do
                sleep BREATHING_ROOM
                expect(p1.last_event).to match(/after (started|created lock)/)
                p2.stop
              end
              p1.run_to_completion
            end
          end
        end

        context "and the second client has done nothing" do
          include_context "second client gets the lock"
        end

        context "and the second client has created the lockfile but not yet acquired the lock" do
          before { p2.run_to("created lock") }
          include_context "second client gets the lock"
        end
      end

      context "when a client acquires the lock but has not yet saved the pid" do
        before { p1.run_to("acquired lock") }

        it "the lockfile is created" do
          log_event("lockfile exists? #{File.exist?(lockfile)}")
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
          expect(IO.read(lockfile)).to eq("")
        end

        it "and a second client tries to acquire the lock, it doesn't get the lock until *after* the first client exits" do
          # Start p2 and tell it to move forward in the background
          p2.run_to("acquired lock") do
            # While p2 is trying to acquire, wait a bit and then let p1 complete
            sleep(BREATHING_ROOM)
            expect(p2.last_event).to match(/after (started|created lock)/)
            p1.run_to_completion
          end

          p2.run_to_completion
        end

        it "and a second client tries to get the lock and the first is killed, the second client gets the lock immediately" do
          p2.run_to("acquired lock") do
            sleep BREATHING_ROOM
            expect(p2.last_event).to match(/after (started|created lock)/)
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
            expect(p2.last_event).to match(/after (started|created lock)/)
            p1.run_to_completion
          end

          p2.run_to_completion
        end

        it "when a second client tries to get the lock and the first is killed, the second client gets the lock immediately" do
          p2.run_to("acquired lock") do
            sleep BREATHING_ROOM
            expect(p2.last_event).to match(/after (started|created lock)/)
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
      from_tests, to_fork = IO.pipe
      from_fork, to_tests = IO.pipe
      p1 = fork do
        expect(run_lock.test).to eq(true)
        to_tests.puts "lock acquired"
        # Wait for the test to tell us we can exit before exiting
        from_tests.readline
        exit! 0
      end

      wait_on_lock(from_fork)

      p2 = fork do
        expect(run_lock.test).to eq(false)
        exit! 0
      end

      pid, exit_status = Process.waitpid2(p2)
      expect(exit_status).to eq(0)
      to_fork.puts "you can exit now"
      pid, exit_status = Process.waitpid2(p1)
      expect(exit_status).to eq(0)
    end

    it "test returns without waiting when the lock is acquired" do
      run_lock = Chef::RunLock.new(lockfile)
      from_tests, to_fork = IO.pipe
      from_fork, to_tests = IO.pipe
      p1 = fork do
        run_lock.acquire
        to_tests.puts "lock acquired"
        # Wait for the test to tell us we can exit before exiting
        from_tests.readline
        exit! 0
      end

      wait_on_lock(from_fork)
      expect(run_lock.test).to eq(false)

      to_fork.puts "you can exit now"
      pid, exit_status = Process.waitpid2(p1)
      expect(exit_status).to eq(0)
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

    def last_event
      loop do
        line = readline_nonblock(read_from_process)
        break if line.nil?
        event, time = line.split("@")
        example.log_event("#{name}.last_event got #{event}")
        example.log_event("[#{name}] #{event}", time.strip)
        @last_event = event
      end
      @last_event
    end

    def run_to(to_event, &background_block)
      example.log_event("#{name}.run_to(#{to_event.inspect})")

      # Start the process if it's not started
      start if !pid

      # Tell the process what to stop at (also means it can go)
      write_to_process.print "#{to_event}\n"

      # Run the background block
      yield if background_block

      # Wait until it gets there
      Timeout.timeout(CLIENT_PROCESS_TIMEOUT) do
        until @last_event == "after #{to_event}"
          got_event, time = read_from_process.gets.split("@")
          example.log_event("#{name}.last_event got #{got_event}")
          example.log_event("[#{name}] #{got_event}", time.strip)
          @last_event = got_event
        end
      end

      example.log_event("#{name}.run_to(#{to_event.inspect}) finished")
    end

    def run_to_completion
      example.log_event("#{name}.run_to_completion")
      # Start the process if it's not started
      start if !pid

      # Tell the process to stop at nothing (no blocking)
      @write_to_process.print "nothing\n"

      # Wait for the process to exit
      wait_for_exit
      example.log_event("#{name}.run_to_completion finished")
    end

    def wait_for_exit
      example.log_event("#{name}.wait_for_exit (pid #{pid})")
      Timeout.timeout(CLIENT_PROCESS_TIMEOUT) do
        Process.wait(pid) if pid
      end
      example.log_event("#{name}.wait_for_exit finished (pid #{pid})")
    end

    def stop
      if pid
        example.log_event("#{name}.stop (pid #{pid})")
        begin
          # Send it the kill signal over and over until it dies
          Timeout.timeout(CLIENT_PROCESS_TIMEOUT) do
            Process.kill(:KILL, pid)
            sleep(0.05) until Process.waitpid2(pid, Process::WNOHANG)
          end
          example.log_event("#{name}.stop finished (stopped pid #{pid})")
        # Process not found is perfectly fine when we're trying to kill a process :)
        rescue Errno::ESRCH
          example.log_event("#{name}.stop finished (pid #{pid} wasn't running)")
        end
      end
    end

    def fire_event(event)
      # Let the caller know what event we've reached
      write_to_tests.print("after #{event}@#{Time.now.strftime("%H:%M:%S.%L")}\n")

      # Block until the client tells us where to stop
      if !@run_to_event || event == @run_to_event
        write_to_tests.print("waiting for instructions after #{event}@#{Time.now.strftime("%H:%M:%S.%L")}\n")
        @run_to_event = read_from_tests.gets.strip
        write_to_tests.print("told to run to #{@run_to_event} after #{event}@#{Time.now.strftime("%H:%M:%S.%L")}\n")
      elsif @run_to_event
        write_to_tests.print("continuing until #{@run_to_event} after #{event}@#{Time.now.strftime("%H:%M:%S.%L")}\n")
      end
    end

    private

    attr_reader :read_from_process
    attr_reader :write_to_tests
    attr_reader :read_from_tests
    attr_reader :write_to_process

    class TestRunLock < Chef::RunLock
      attr_accessor :client_process
      def create_lock
        super
        client_process.fire_event("created lock")
      end
    end

    def start
      example.log_event("#{name}.start")
      @pid = fork do
        begin
          Timeout.timeout(CLIENT_PROCESS_TIMEOUT) do
            run_lock = TestRunLock.new(example.lockfile)
            run_lock.client_process = self
            fire_event("started")
            run_lock.acquire
            fire_event("acquired lock")
            run_lock.save_pid
            fire_event("saved pid")
            exit!(0)
          end
        rescue
          fire_event($!.message.lines.join(" // "))
          raise
        end
      end
      example.log_event("#{name}.start forked (pid #{pid})")
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
