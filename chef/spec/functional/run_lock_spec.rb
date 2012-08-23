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

describe Chef::Client::RunLock do

  # This behavior is believed to work on windows, but the tests use UNIX APIs.
  describe "when locking the chef-client run", :unix_only => true do
    it "allows only one chef client run per lockfile" do
      read, write = IO.pipe
      run_lock = Chef::Client::RunLock.new(:file_cache_path => "/var/chef/cache", :lockfile => "/tmp/chef-client-running.pid")
      p1 = fork do
        run_lock.acquire
        write.puts 1
        #puts "[#{Time.new.to_i % 100}] p1 (#{Process.pid}) running with lock"
        sleep 2
        write.puts 2
        #puts "[#{Time.new.to_i % 100}] p1 (#{Process.pid}) releasing lock"
        run_lock.release
      end

      p2 = fork do
        run_lock.acquire
        write.puts 3
        #puts "[#{Time.new.to_i % 100}] p2 (#{Process.pid}) running with lock"
        run_lock.release
      end

      Process.waitpid2(p1)
      Process.waitpid2(p2)

      write.close
      order = read.read
      read.close

      order.should == "1\n2\n3\n"
    end

    it "clears the lock if the process dies unexpectedly" do
      read, write = IO.pipe
      run_lock = Chef::Client::RunLock.new(:file_cache_path => "/var/chef/cache", :lockfile => "/tmp/chef-client-running.pid")
      p1 = fork do
        run_lock.acquire
        write.puts 1
        #puts "[#{Time.new.to_i % 100}] p1 (#{Process.pid}) running with lock"
        sleep 1
        write.puts 2
        #puts "[#{Time.new.to_i % 100}] p1 (#{Process.pid}) releasing lock"
        run_lock.release
      end

      p2 = fork do
        run_lock.acquire
        write.puts 3
        #puts "[#{Time.new.to_i % 100}] p2 (#{Process.pid}) running with lock"
        run_lock.release
      end
      Process.kill(:KILL, p1)

      Process.waitpid2(p1)
      Process.waitpid2(p2)

      write.close
      order = read.read
      read.close

      order.should =~ /3\Z/
    end
  end

end

