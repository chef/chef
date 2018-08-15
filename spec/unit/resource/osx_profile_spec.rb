#
# Author:: Nate Walck (<nate.walck@gmail.com>)
# Copyright:: Copyright 2015-2016, Facebook, Inc.
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

describe Chef::Resource::OsxProfile do
  let(:resource) do
    Chef::Resource::OsxProfile.new(
    "fakey_fakerton")
  end

  it "has a resource name of profile" do
    expect(resource.resource_name).to eql(:osx_profile)
  end

  it "the profile_name property is the name_property" do
    expect(resource.profile_name).to eql("fakey_fakerton")
  end

  it "sets the default action as :install" do
    expect(resource.action).to eql([:install])
  end

  it "supports :install, :remove actions" do
    expect { resource.action :install }.not_to raise_error
    expect { resource.action :remove }.not_to raise_error
  end

  it "allows you to set the profile property" do
    resource.profile "com.testprofile.screensaver"
    expect(resource.profile).to eql("com.testprofile.screensaver")
  end

  it "allows you to set the profile property to a string" do
    resource.profile "com.testprofile.screensaver"
    expect(resource.profile).to be_a(String)
    expect(resource.profile).to eql("com.testprofile.screensaver")
  end

  it "allows you to set the profile property to a hash" do
    test_profile = { "profile" => false }
    resource.profile test_profile
    expect(resource.profile).to be_a(Hash)
  end
end
