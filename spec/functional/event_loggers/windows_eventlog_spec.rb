#
# Author:: Jay Mundrawala (<jdm@chef.io>)
#
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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
require "securerandom"
require "chef/event_loggers/windows_eventlog"
if Chef::Platform.windows? && (not Chef::Platform.windows_server_2003?)
  require "win32/eventlog"
  include Win32
end

describe Chef::EventLoggers::WindowsEventLogger, :windows_only, :not_supported_on_win2k3 do
  def rand
    random.rand(1 << 32).to_s
  end

  let(:random)       { Random.new }
  let(:run_id)       { rand }
  let(:version)      { rand }
  let(:elapsed_time) { rand }
  let(:logger)       { Chef::EventLoggers::WindowsEventLogger.new }
  let(:flags)        { nil }
  let(:node)         { nil }
  let(:run_status)   { double("Run Status", { run_id: run_id, elapsed_time: elapsed_time }) }
  let(:event_log)    { EventLog.new("Application") }
  let!(:offset)      { event_log.read_last_event.record_number }
  let(:mock_exception) { double("Exception", { message: rand, backtrace: [rand, rand] }) }

  it "is available" do
    expect(Chef::EventLoggers::WindowsEventLogger.available?).to be_truthy
  end

  it "writes run_start event with event_id 10000 and contains version" do
    logger.run_start(version)

    expect(event_log.read(flags, offset).any? do |e|
             e.source == "Chef" && e.event_id == 10000 &&
                                               e.string_inserts[0].include?(version) end).to be_truthy
  end

  it "writes run_started event with event_id 10001 and contains the run_id" do
    logger.run_started(run_status)

    expect(event_log.read(flags, offset).any? do |e|
             e.source == "Chef" && e.event_id == 10001 &&
                                               e.string_inserts[0].include?(run_id) end).to be_truthy
  end

  it "writes run_completed event with event_id 10002 and contains the run_id and elapsed time" do
    logger.run_started(run_status)
    logger.run_completed(node)

    expect(event_log.read(flags, offset).any? do |e|
      e.source == "Chef" && e.event_id == 10002 &&
                                         e.string_inserts[0].include?(run_id) &&
                                         e.string_inserts[1].include?(elapsed_time.to_s)
    end).to be_truthy
  end

  it "writes run_failed event with event_id 10003 and contains the run_id, elapsed time, and exception info" do
    logger.run_started(run_status)
    logger.run_failed(mock_exception)

    expect(event_log.read(flags, offset).any? do |e|
      e.source == "Chef" && e.event_id == 10003 &&
        e.string_inserts[0].include?(run_id) &&
        e.string_inserts[1].include?(elapsed_time.to_s) &&
        e.string_inserts[2].include?(mock_exception.class.name) &&
        e.string_inserts[3].include?(mock_exception.message) &&
        e.string_inserts[4].include?(mock_exception.backtrace[0]) &&
        e.string_inserts[4].include?(mock_exception.backtrace[1])
    end).to be_truthy
  end

  it "writes run_failed event with event_id 10003 even when run_status is not set" do
    logger.run_failed(mock_exception)

    expect(event_log.read(flags, offset).any? do |e|
      e.source == "Chef" && e.event_id == 10003 &&
        e.string_inserts[0].include?("UNKNOWN") &&
        e.string_inserts[1].include?("UNKNOWN") &&
        e.string_inserts[2].include?(mock_exception.class.name) &&
        e.string_inserts[3].include?(mock_exception.message) &&
        e.string_inserts[4].include?(mock_exception.backtrace[0]) &&
        e.string_inserts[4].include?(mock_exception.backtrace[1])
    end).to be_truthy
  end

end
