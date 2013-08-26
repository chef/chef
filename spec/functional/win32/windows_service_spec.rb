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
end

describe "Chef::Application::WindowsService", :windows_only do
  let (:instance) {Chef::Application::WindowsService.new}
  before do
    instance.stub(:parse_options)
  end
  it "runs chef-client in new process" do
    pending "state/loop testing issue"
    instance.should_receive(:configure_chef).twice
    instance.service_init
    (instance.instance_variable_get(:@service_signal)).stub(:wait)
#    instance.should_receive(:state).and_return(String.new("RUNNING"))
    instance.should_receive(:run_chef_client).and_call_original
    instance.should_receive(:shell_out).and_call_original
    instance.service_main
  end
end
