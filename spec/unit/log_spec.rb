#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'tempfile'
require 'logger'
require 'spec_helper'

describe Chef::Log do
end

describe Chef::Log::Syslog do
  let(:logger) { Chef::Log::Syslog.new }

  it "should send message with severity info to syslog." do
    expect_any_instance_of(Logger::Syslog).to receive(:info).with("*** Chef 12.4.0.dev.0 ***")
    logger.write("[2015-04-23T15:16:23+09:00] INFO: *** Chef 12.4.0.dev.0 ***")
  end

  it "should send message with severity warning to syslog." do
    expect_any_instance_of(Logger::Syslog).to receive(:warn).with("No config file found or specified on command line, using command line options.")
    logger.write("[2015-04-23T15:16:20+09:00] WARN: No config file found or specified on command line, using command line options.")
  end

  it "should fallback into send message with severity info to syslog when wrong format." do
    expect_any_instance_of(Logger::Syslog).to receive(:info).with("chef message")
    logger.write("chef message")
  end
end
