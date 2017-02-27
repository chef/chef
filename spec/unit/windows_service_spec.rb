#
# Author:: Mukta Aphale (<mukta.aphale@clogeny.com>)
# Copyright:: Copyright 2013-2016, Chef Software, Inc.
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
require "spec_helper"
if Chef::Platform.windows?
  require "chef/application/windows_service"
end

describe "Chef::Application::WindowsService", :windows_only do
  let(:shell_out_result) { double("shellout", stdout: nil, stderr: nil) }
  let(:config_options) do
    {
      log_location: STDOUT,
      config_file: "test_config_file",
      log_level: :info,
    }
  end
  let(:timeout) { 7200 }
  let(:shellout_options) do
    {
      :timeout => timeout,
      :logger => Chef::Log,
    }
  end

  before do
    Chef::Config.merge!(config_options)
    allow(subject).to receive(:configure_chef)
    allow(subject).to receive(:parse_options)
    allow(MonoLogger).to receive(:new)
    allow(subject).to receive(:running?).and_return(true, false)
    allow(subject).to receive(:state).and_return(4)
    subject.service_init
  end

  subject { Chef::Application::WindowsService.new }

  it "passes DEFAULT_LOG_LOCATION to chef-client instead of STDOUT" do
    expect(subject).to receive(:shell_out).with(
      "chef-client.bat  --no-fork -c test_config_file -L #{Chef::Application::WindowsService::DEFAULT_LOG_LOCATION}",
      shellout_options
    ).and_return(shell_out_result)
    subject.service_main
  end

  context "has a log location configured" do
    let(:tempfile) { Tempfile.new "log_file" }
    let(:config_options) do
      {
        log_location: tempfile.path,
        config_file: "test_config_file",
        log_level: :info,
      }
    end

    after do
      tempfile.unlink
    end

    it "uses the configured log location" do
      expect(subject).to receive(:shell_out).with(
        "chef-client.bat  --no-fork -c test_config_file -L #{tempfile.path}",
        shellout_options
      ).and_return(shell_out_result)
      subject.service_main
    end

    context "configured to Event Logger" do
      let(:config_options) do
        {
          log_location: Chef::Log::WinEvt.new,
          config_file: "test_config_file",
          log_level: :info,
        }
      end

      it "does not pass log location to new process" do
        expect(subject).to receive(:shell_out).with(
          "chef-client.bat  --no-fork -c test_config_file",
          shellout_options
        ).and_return(shell_out_result)
        subject.service_main
      end
    end
  end

  context "configueres a watchdog timeout" do
    let(:timeout) { 10 }

    before do
      Chef::Config[:windows_service][:watchdog_timeout] = 10
    end

    it "passes watchdog timeout to new process" do
      expect(subject).to receive(:shell_out).with(
        "chef-client.bat  --no-fork -c test_config_file -L #{Chef::Application::WindowsService::DEFAULT_LOG_LOCATION}",
        shellout_options
      ).and_return(shell_out_result)
      subject.service_main
    end
  end
end
