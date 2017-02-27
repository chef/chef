#
# Copyright:: Copyright 2014-2016, Chef Software, Inc.
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

describe Chef::Audit::Logger do

  before(:each) do
    Chef::Audit::Logger.instance_variable_set(:@buffer, nil)
  end

  it "calling puts creates @buffer and adds the message" do
    Chef::Audit::Logger.puts("Output message")
    expect(Chef::Audit::Logger.read_buffer).to eq("Output message\n")
  end

  it "calling puts multiple times adds to the message" do
    Chef::Audit::Logger.puts("Output message")
    Chef::Audit::Logger.puts("Output message")
    Chef::Audit::Logger.puts("Output message")
    expect(Chef::Audit::Logger.read_buffer).to eq("Output message\nOutput message\nOutput message\n")
  end

  it "calling it before @buffer is set returns an empty string" do
    expect(Chef::Audit::Logger.read_buffer).to eq("")
  end

end
