#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

describe Chef::Resource::Timezone do
  let(:resource) { Chef::Resource::Timezone.new("fakey_fakerton") }

  let(:shellout_tzutil) do
    double("shell_out", stdout: "UTC\n", exitstatus: 0, error?: false)
  end

  # note: This weird indention is correct
  let(:shellout_timedatectl) do
    double("shell_out", exitstatus: 0, error?: false, stdout: <<-OUTPUT)
    Local time: Tue 2020-08-18 20:55:05 UTC
    Universal time: Tue 2020-08-18 20:55:05 UTC
          RTC time: Tue 2020-08-18 20:55:05
         Time zone: Etc/UTC (UTC, +0000)
System clock synchronized: yes
systemd-timesyncd.service active: yes
   RTC in local TZ: no
    OUTPUT
  end

  let(:shellout_systemsetup_fail) do
    double("shell_out!", stdout: "You need administrator access to run this tool... exiting!", exitstatus: 0, error?: false) # yes it's a non-error exit
  end

  let(:shellout_systemsetup) do
    double("shell_out!", stdout: "Time Zone: UTC", exitstatus: 0, error?: false)
  end

  it "sets resource name as :timezone" do
    expect(resource.resource_name).to eql(:timezone)
  end

  it "the timezone property is the name_property" do
    expect(resource.timezone).to eql("fakey_fakerton")
  end

  it "sets the default action as :set" do
    expect(resource.action).to eql([:set])
  end

  it "supports the :set action only" do
    expect { resource.action :set }.not_to raise_error
    expect { resource.action :unset }.to raise_error(Chef::Exceptions::ValidationFailed)
  end

  describe "#current_macos_tz" do
    context "with admin privs" do
      it "returns the TZ" do
        expect(resource).to receive(:shell_out!).and_return(shellout_systemsetup)
        expect(resource.current_macos_tz).to eql("UTC")
      end
    end

    context "without admin privs" do
      it "returns the TZ" do
        expect(resource).to receive(:shell_out!).and_return(shellout_systemsetup_fail)
        expect { resource.current_macos_tz }.to raise_error(RuntimeError, "The timezone resource requires administrative privileges to run on macOS hosts!")
      end
    end
  end

  describe "#current_systemd_tz" do
    it "returns the TZ" do
      expect(resource).to receive(:shell_out).and_return(shellout_timedatectl)
      expect(resource.current_systemd_tz).to eql("Etc/UTC")
    end
  end

  describe "#current_windows_tz" do
    it "returns the TZ" do
      expect(resource).to receive(:shell_out).and_return(shellout_tzutil)
      expect(resource.current_windows_tz).to eql("UTC")
    end
  end

  describe "#current_rhel_tz" do
    it "returns the TZ" do
      allow(File).to receive(:exist?).with("/etc/sysconfig/clock").and_return true
      expect(File).to receive(:read).with("/etc/sysconfig/clock").and_return 'ZONE="UTC"'
      expect(resource.current_rhel_tz).to eql("UTC")
    end
  end
end
