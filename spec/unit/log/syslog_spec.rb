#
# Author:: SAWANOBORI Yukihiko (<sawanoboriyu@higanworks.com>)
# Copyright:: Copyright 2015-2016, Chef Software, Inc.
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
require "chef"

describe "Chef::Log::Syslog", :unix_only => true do
  let(:syslog) { Chef::Log::Syslog.new }
  let(:app) { Chef::Application.new }

  before do
    Chef::Log.init(MonoLogger.new(syslog))
    @old_log_level = Chef::Log.level
    Chef::Log.level = :info
    @old_loggers = Chef::Log.loggers
    Chef::Log.use_log_devices([syslog])
  end

  after do
    Chef::Log.level = @old_log_level
    Chef::Log.use_log_devices(@old_loggers)
  end

  it "should send message with severity info to syslog." do
    expect(syslog).to receive(:info).with("*** Chef 12.4.0.dev.0 ***")
    Chef::Log.info("*** Chef 12.4.0.dev.0 ***")
  end

  it "should send message with severity warning to syslog." do
    expect(syslog).to receive(:warn).with("No config file found or specified on command line, using command line options.")
    Chef::Log.warn("No config file found or specified on command line, using command line options.")
  end

  it "should fallback into send message with severity info to syslog when wrong format." do
    expect(syslog).to receive(:info).with("chef message")
    syslog.write("chef message")
  end
end
