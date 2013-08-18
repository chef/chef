#
# Author:: Mukta Aphale (<mukta.aphale@clogeny.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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
#

require 'spec_helper'
require 'chef/mixin/shell_out'

def get_pid(result)
  result = result.split
  result = result[result.length-1]
  result = result.split(")")
  result[0]
end

describe Chef::Client do
  include Chef::Mixin::ShellOut
  context "fork", :windows_only do
    it "creates a new process" do
      pending "Test for chef client for windows as a service"
      shell_out("ruby.exe ..\\..\\lib\\chef\\application\\windows_service.rb --logfile test1.log")
      result1 = shell_out("grep 'Chef-client pid:' test1.log")
      result2 = shell_out("grep 'Child process successfully reaped' test1.log")
      pid_child = get_pid(result1.stdout)
      pid_parent = get_pid(result2.stdout)
      pid_child.should_not == pid_parent
      File.delete("test1.log")
    end
  end
end