#
# Copyright:: Copyright (c) Chef Software Inc.
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

describe Chef::Resource::User::WindowsUser, "#uid" do
  let(:resource) { Chef::Resource::User::WindowsUser.new("notarealuser") }

  it "allows a string" do
    resource.uid "100"
    expect(resource.uid).to eql(100)
  end

  it "allows an integer" do
    resource.uid 100
    expect(resource.uid).to eql(100)
  end

  it "does not allow a hash" do
    expect { resource.uid({ woot: "i found it" }) }.to raise_error(ArgumentError)
  end
end
