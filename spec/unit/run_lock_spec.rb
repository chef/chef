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

  default_pid_location = windows? ? 'C:\chef\cache\chef-client-running.pid' : '/var/chef/cache/chef-client-running.pid'

  describe "when first created" do
    it "locates the lockfile in the file cache path by default" do
      run_lock = Chef::RunLock.new(Chef::Config.lockfile)
      run_lock.runlock_file.should == default_pid_location
    end

    it "locates the lockfile in the user-configured path when set" do
      Chef::Config.lockfile = "/tmp/chef-client-running.pid"
      run_lock = Chef::RunLock.new(Chef::Config.lockfile)
      run_lock.runlock_file.should == "/tmp/chef-client-running.pid"
    end
  end

  # See also: spec/functional/run_lock_spec

end
