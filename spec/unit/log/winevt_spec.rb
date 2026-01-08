#
# Author:: Jay Mundrawala (jdm@chef.io)
# Author:: SAWANOBORI Yukihiko (<sawanoboriyu@higanworks.com>)
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

describe Chef::Log::WinEvt, :windows_only do
  let(:evtlog) { instance_double("Win32::EventLog") }
  let(:winevt) { Chef::Log::WinEvt.new(evtlog) }
  let(:app) { Chef::Application.new }

  before do
    Chef::Log.init(MonoLogger.new(winevt))
    Chef::Log.level = :info
  end

  it "should send message with severity info to Windows Event Log." do
    expect(evtlog).to receive(:report_event).with(
      event_type: ::Win32::EventLog::INFO_TYPE,
      source: Chef::Log::WinEvt::SOURCE,
      event_id: Chef::Log::WinEvt::INFO_EVENT_ID,
      data: ["*** Chef 12.4.0.dev.0 ***"]
    )

    expect {
      Chef::Log.info("*** Chef 12.4.0.dev.0 ***")
    }.not_to output.to_stderr
  end

  it "should send message with severity warning to Windows Event Log." do
    expect(evtlog).to receive(:report_event).with(
      event_type: ::Win32::EventLog::WARN_TYPE,
      source: Chef::Log::WinEvt::SOURCE,
      event_id: Chef::Log::WinEvt::WARN_EVENT_ID,
      data: ["No config file found or specified on command line. Using command line options instead."]
    )

    expect {
      Chef::Log.warn("No config file found or specified on command line. Using command line options instead.")
    }.not_to output.to_stderr
  end

  it "should fallback into send message with severity info to Windows Event Log when wrong format." do
    expect(winevt).to receive(:info).with("chef message")
    winevt.write("chef message")
  end
end
