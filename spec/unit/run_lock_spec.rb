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

  default_cache_path = windows? ? 'C:\chef' : '/var/chef'
  default_pid_location = windows? ? 'C:\chef\cache\chef-client-running.pid' : '/var/chef/cache/chef-client-running.pid'

  describe "when first created" do
    it "locates the lockfile in the file cache path by default" do
      Chef::Config.stub(:cache_path).and_return(default_cache_path)
      run_lock = Chef::RunLock.new(Chef::Config.lockfile)
      run_lock.runlock_file.should == default_pid_location
    end

    it "locates the lockfile in the user-configured path when set" do
      Chef::Config.lockfile = "/tmp/chef-client-running.pid"
      run_lock = Chef::RunLock.new(Chef::Config.lockfile)
      run_lock.runlock_file.should == "/tmp/chef-client-running.pid"
    end
  end

  describe "acquire" do
    let(:lockfile) { "/tmp/chef-client-running.pid" }
    subject(:runlock) { Chef::RunLock.new(lockfile) }

    def stub_unblocked_run
      runlock.stub(:test).and_return(true)
    end

    def stub_blocked_run(duration)
      runlock.stub(:test).and_return(false)
      runlock.stub(:wait) { sleep(duration) }
      runlock.stub(:runpid).and_return(666) # errors read blocking pid
    end

    describe "when Chef::Config[:run_lock_timeout] is not set (set to default)" do
      describe "and the lockfile is not locked by another client run" do
        it "should not wait" do
          stub_unblocked_run
          Chef::RunLock.any_instance.should_not_receive(:wait)
          runlock.acquire
        end
      end

      describe "and the lockfile is locked by another client run" do
        it "should wait for the lock to be released" do
          stub_blocked_run(0.001)
          runlock.should_receive(:wait)
          runlock.acquire
        end
      end
    end

    describe "when Chef::Config[:run_lock_timeout] is set to 0" do
      before(:each) do
        @default_timeout = Chef::Config[:run_lock_timeout]
        Chef::Config[:run_lock_timeout] = 0
      end

      after(:each) do
        Chef::Config[:run_lock_timeout] = @default_timeout
      end

      describe "and the lockfile is not locked by another client run" do
        it "should acquire the lock" do
          stub_unblocked_run
          runlock.should_not_receive(:wait)
          runlock.acquire
        end
      end

      describe "and the lockfile is locked by another client run" do
        it "should raise Chef::Exceptions::RunLockTimeout" do
          stub_blocked_run(0.001)
          runlock.should_not_receive(:wait)
          expect{ runlock.acquire }.to raise_error(Chef::Exceptions::RunLockTimeout)
        end
      end
    end

    describe "when Chef::Config[:run_lock_timeout] is set to >0" do
      before(:each) do
        @default_timeout = Chef::Config[:run_lock_timeout]
        @timeout = 0.1
        Chef::Config[:run_lock_timeout] = @timeout
      end

      after(:each) do
        Chef::Config[:run_lock_timeout] = @default_timeout
      end

      describe "and the lockfile is not locked by another client run" do
        it "should acquire the lock" do
          stub_unblocked_run
          runlock.should_not_receive(:wait)
          runlock.acquire
        end
      end

      describe "and the lockfile is locked by another client run" do
        describe "and the lock is released before the timeout expires" do
          it "should acquire the lock" do
            stub_blocked_run(@timeout/2.0)
            runlock.should_receive(:wait)
            expect{ runlock.acquire }.not_to raise_error
          end
        end

        describe "and the lock is not released before the timeout expires" do
          it "should raise a RunLockTimeout exception" do
            stub_blocked_run(2.0)
            runlock.should_receive(:wait)
            expect{ runlock.acquire }.to raise_error(Chef::Exceptions::RunLockTimeout)
          end
        end
      end
    end
  end

  # See also: spec/functional/run_lock_spec

end
