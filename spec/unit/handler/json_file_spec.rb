#
# Author:: Adam Jacob (<adam@chef.io>)
# Copyright:: Copyright 2010-2016, Chef Software Inc.
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

describe Chef::Handler::JsonFile do
  before(:each) do
    @handler = Chef::Handler::JsonFile.new(:the_sun => "will rise", :path => "/tmp/foobarbazqux")
  end

  it "accepts arbitrary config options" do
    expect(@handler.config[:the_sun]).to eq("will rise")
  end

  it "creates the directory where the reports will be saved" do
    expect(FileUtils).to receive(:mkdir_p).with("/tmp/foobarbazqux")
    expect(File).to receive(:chmod).with(00700, "/tmp/foobarbazqux")
    @handler.build_report_dir
  end

  describe "when reporting success" do
    before(:each) do
      @node = Chef::Node.new
      @events = Chef::EventDispatch::Dispatcher.new
      @run_status = Chef::RunStatus.new(@node, @events)
      @expected_time = Time.now
      allow(Time).to receive(:now).and_return(@expected_time, @expected_time + 5)
      @run_status.start_clock
      @run_status.stop_clock
      @run_context = Chef::RunContext.new(@node, {}, @events)
      @run_status.run_context = @run_context
      @run_status.exception = Exception.new("Boy howdy!")
      @file_mock = StringIO.new
      allow(File).to receive(:open).and_yield(@file_mock)
    end

    it "saves run status data to a file as JSON" do
      expect(@handler).to receive(:build_report_dir)
      @handler.run_report_unsafe(@run_status)
      reported_data = Chef::JSONCompat.parse(@file_mock.string)
      expect(reported_data["exception"]).to eq("Exception: Boy howdy!")
      expect(reported_data["start_time"]).to eq(@expected_time.to_s)
      expect(reported_data["end_time"]).to eq((@expected_time + 5).to_s)
      expect(reported_data["elapsed_time"]).to eq(5)
    end

  end
end
