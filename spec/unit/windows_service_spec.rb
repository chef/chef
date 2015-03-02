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
  let (:shell_out_result) {Object.new}
  let (:tempfile) {Tempfile.new "log_file"}
  before do
    allow(instance).to receive(:parse_options)
    allow(shell_out_result).to receive(:stdout)
    allow(shell_out_result).to receive(:stderr)
  end
  it "runs chef-client in new process" do
    expect(instance).to receive(:configure_chef).twice
    instance.service_init
    expect(instance).to receive(:run_chef_client).and_call_original
    expect(instance).to receive(:shell_out).and_return(shell_out_result)
    allow(instance).to receive(:running?).and_return(true, false)
    allow(instance.instance_variable_get(:@service_signal)).to receive(:wait)
    allow(instance).to receive(:state).and_return(4)
    instance.service_main
  end

  context 'when running chef-client' do
    it "passes config params to new process with a default timeout of 2 hours (7200 seconds)" do
      Chef::Config.merge!({:log_location => tempfile.path, :config_file => "test_config_file", :log_level => :info})
      expect(instance).to receive(:configure_chef).twice
      instance.service_init
      allow(instance).to receive(:running?).and_return(true, false)
      allow(instance.instance_variable_get(:@service_signal)).to receive(:wait)
      allow(instance).to receive(:state).and_return(4)
      expect(instance).to receive(:run_chef_client).and_call_original
      expect(instance).to receive(:shell_out).with("chef-client  --no-fork -c test_config_file -L #{tempfile.path}", {:timeout => 7200}).and_return(shell_out_result)
      instance.service_main
      tempfile.unlink
    end

    it "passes config params to new process with a the timeout specified in the config" do
      Chef::Config.merge!({:log_location => tempfile.path, :config_file => "test_config_file", :log_level => :info})
      Chef::Config[:windows_service][:watchdog_timeout] = 10
      expect(instance).to receive(:configure_chef).twice
      instance.service_init
      allow(instance).to receive(:running?).and_return(true, false)
      allow(instance.instance_variable_get(:@service_signal)).to receive(:wait)
      allow(instance).to receive(:state).and_return(4)
      expect(instance).to receive(:run_chef_client).and_call_original
      expect(instance).to receive(:shell_out).with("chef-client  --no-fork -c test_config_file -L #{tempfile.path}", {:timeout => 10}).and_return(shell_out_result)
      instance.service_main
      tempfile.unlink
    end
  end
end
