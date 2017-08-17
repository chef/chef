#
# Author:: Nimisha Sharad (<nimisha.sharad@msystechnologies.com>)
# Copyright:: Copyright 2008-2017, Chef Software, Inc.
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

describe Chef::Resource::WindowsPath do
  subject { Chef::Resource::WindowsPath.new("some_path") }

  it { is_expected.to be_a_kind_of(Chef::Resource) }
  it { is_expected.to be_a_instance_of(Chef::Resource::WindowsPath) }

  it "sets resource name as :windows_path" do
    expect(subject.resource_name).to eql(:windows_path)
  end

  it "sets the path as it's name" do
    expect(subject.path).to eql("some_path")
  end

  it "sets the default action as :add" do
    expect(subject.action).to eql(:add)
  end
end
