#
# Author:: AJ Christensen (<aj@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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
require "support/shared/unit/resource/static_provider_resolution"

describe Chef::Resource::YumPackage, "initialize" do

  static_provider_resolution(
    resource: Chef::Resource::YumPackage,
    provider: Chef::Provider::Package::Yum,
    name: :yum_package,
    action: :install,
    os: "linux",
    platform_family: "rhel"
  )

end

describe Chef::Resource::YumPackage do
  before(:each) do
    @resource = Chef::Resource::YumPackage.new("foo")
  end

  # this set of tests is somewhat terrible.  the yum provider promiscuously writes over
  # the new_resource.package_named/version/arch properties.  until that is fixed properly
  # we need to coerce and dup those properties into normal arrays.  this does not affect
  # strings because those are not mutated in place and they are not (currently) frozen
  # in immutable properties (even though they really, really should be).
  context "when passed immutable node property arrays" do
    let(:node) { Chef::Node.new }

    before do
      node.default["foo"] = %w{one two three}
    end

    it "allows mutation of the package_name array" do
      @resource.package_name node["foo"]
      expect(@resource.package_name).not_to be_a_kind_of(Chef::Node::ImmutableArray)
      expect { @resource.package_name[0] = "four" }.not_to raise_error
      expect(@resource.package_name).to eql(%w{four two three})
    end

    it "allows mutation of the version array" do
      @resource.version node["foo"]
      expect(@resource.version).not_to be_a_kind_of(Chef::Node::ImmutableArray)
      expect { @resource.version[0] = "four" }.not_to raise_error
      expect(@resource.version).to eql(%w{four two three})
    end

    it "allows mutation of the arch array" do
      @resource.arch node["foo"]
      expect(@resource.arch).not_to be_a_kind_of(Chef::Node::ImmutableArray)
      expect { @resource.arch[0] = "four" }.not_to raise_error
      expect(@resource.arch).to eql(%w{four two three})
    end

  end
end

describe Chef::Resource::YumPackage, "arch" do
  before(:each) do
    @resource = Chef::Resource::YumPackage.new("foo")
  end

  it "sets the arch variable to whatever is passed in" do
    @resource.arch("i386")
    expect(@resource.arch).to eql("i386")
  end
end

describe Chef::Resource::YumPackage, "flush_cache" do
  before(:each) do
    @resource = Chef::Resource::YumPackage.new("foo")
  end

  it "should default the flush timing to false" do
    flush_hash = { before: false, after: false }
    expect(@resource.flush_cache).to eq(flush_hash)
  end

  it "should allow you to set the flush timing with an array" do
    flush_array = [ :before, :after ]
    flush_hash = { before: true, after: true }
    @resource.flush_cache(flush_array)
    expect(@resource.flush_cache).to eq(flush_hash)
  end

  it "should allow you to set the flush timing with a hash" do
    flush_hash = { before: true, after: true }
    @resource.flush_cache(flush_hash)
    expect(@resource.flush_cache).to eq(flush_hash)
  end

  it "should allow 'true' for flush_cache" do
    @resource.flush_cache(true)
    expect(@resource.flush_cache).to eq({ before: true, after: true })
  end

  it "should allow 'false' for flush_cache" do
    @resource.flush_cache(false)
    expect(@resource.flush_cache).to eq({ before: false, after: false })
  end

  it "should allow ':before' for flush_cache" do
    @resource.flush_cache(:before)
    expect(@resource.flush_cache).to eq({ before: true, after: false })
  end

  it "should allow ':after' for flush_cache" do
    @resource.flush_cache(:after)
    expect(@resource.flush_cache).to eq({ before: false, after: true })
  end
end

describe Chef::Resource::YumPackage, "allow_downgrade" do
  before(:each) do
    @resource = Chef::Resource::YumPackage.new("foo")
  end

  it "should allow you to specify whether allow_downgrade is true or false" do
    expect { @resource.allow_downgrade true }.not_to raise_error
    expect { @resource.allow_downgrade false }.not_to raise_error
    expect { @resource.allow_downgrade "monkey" }.to raise_error(ArgumentError)
  end
end

describe Chef::Resource::YumPackage, "yum_binary" do
  let(:resource) { Chef::Resource::YumPackage.new("foo") }

  it "should allow you to specify the yum_binary" do
    resource.yum_binary "/usr/bin/yum-something"
    expect(resource.yum_binary).to eql("/usr/bin/yum-something")
  end
end
