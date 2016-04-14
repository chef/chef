#
# Author:: Thom May (<thom@chef.io>)
# Copyright:: Copyright (c) 2016 Chef Software, Inc.
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

describe Chef::Resource::AptRepository do

  let(:resource) { Chef::Resource::AptRepository.new("multiverse") }

  it "should create a new Chef::Resource::AptUpdate" do
    expect(resource).to be_a_kind_of(Chef::Resource)
    expect(resource).to be_a_kind_of(Chef::Resource::AptRepository)
  end

  it "the default keyserver should be keyserver.ubuntu.com" do
    expect(resource.keyserver).to eql("keyserver.ubuntu.com")
  end

  it "the default distribution should be nillable" do
    expect(resource.distribution(nil)).to eql(nil)
    expect(resource.distribution).to eql(nil)
  end
end
