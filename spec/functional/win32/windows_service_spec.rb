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
if Chef::Platform.windows?
  require 'chef/application/windows_service'
  include Chef::Mixin::ShellOut
end

def get_pid(result)
  result = result.split
  result = result[result.length-1]
  result = result.split(")")
  result[0]
end

describe "Chef::Application::WindowsService", :windows_only do
  let (:instance) {Chef::Application::WindowsService.new}

  it "runs chef-client in new process" do
    tempfilename = Tempfile.new("log")
    Chef::Config.merge!({:log_location => tempfilename.path, :log_level => :info})
    instance.stub(:parse_options)
    instance.should_receive(:configure_chef).twice
    instance.service_init
    instance.stub(:running?).and_return(true, false)
    instance.instance_variable_get(:@service_signal).stub(:wait)
    instance.stub(:state).and_return(4)
    instance.should_receive(:run_chef_client).and_call_original
    instance.should_receive(:shell_out).and_call_original
    instance.service_main
    result1 = shell_out("grep 'Chef-client pid:' #{tempfilename.path}")
    result2 = shell_out("grep 'Child process exited' #{tempfilename.path}")
    result1.stdout.should_not == ""
    result2.stdout.should_not == ""
    pid_child = get_pid(result1.stdout)
    pid_parent = get_pid(result2.stdout)
    tempfilename.unlink
    pid_child.should_not == pid_parent
  end
end
