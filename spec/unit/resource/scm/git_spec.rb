#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
require_relative "scm"

describe Chef::Resource::Git do

  static_provider_resolution(
    resource: Chef::Resource::Git,
    provider: Chef::Provider::Git,
    name: :git,
    action: :sync
  )

  let(:resource) { Chef::Resource::Git.new("fakey_fakerton") }

  it_behaves_like "an SCM resource"

  it "takes the depth as an integer for shallow clones" do
    resource.depth 5
    expect(resource.depth).to eq(5)
    expect { resource.depth "five" }.to raise_error(ArgumentError)
  end

  it "defaults to nil depth for a full clone" do
    expect(resource.depth).to be_nil
  end

  it "takes a boolean for #enable_submodules" do
    resource.enable_submodules true
    expect(resource.enable_submodules).to be_truthy
    expect { resource.enable_submodules "lolz" }.to raise_error(ArgumentError)
  end

  it "defaults to not enabling submodules" do
    expect(resource.enable_submodules).to be_falsey
  end

  it "takes a boolean for #enable_checkout" do
    resource.enable_checkout true
    expect(resource.enable_checkout).to be_truthy
    expect { resource.enable_checkout "lolz" }.to raise_error(ArgumentError)
  end

  it "defaults to enabling checkout" do
    expect(resource.enable_checkout).to be_truthy
  end

  it "takes a string for the remote" do
    resource.remote "opscode"
    expect(resource.remote).to eql("opscode")
    expect { resource.remote 1337 }.to raise_error(ArgumentError)
  end

  it "defaults to ``origin'' for the remote" do
    expect(resource.remote).to eq("origin")
  end

  it "takes a string for the ssh wrapper" do
    resource.ssh_wrapper "with_ssh_fu"
    expect(resource.ssh_wrapper).to eql("with_ssh_fu")
  end

  it "defaults to nil for the ssh wrapper" do
    expect(resource.ssh_wrapper).to be_nil
  end

  it "uses aliases revision as branch" do
    resource.branch "HEAD"
    expect(resource.revision).to eql("HEAD")
  end

  it "aliases revision as reference" do
    resource.reference "v1.0 tag"
    expect(resource.revision).to eql("v1.0 tag")
  end

  it "the destination property is the name_property" do
    expect(resource.destination).to eql("fakey_fakerton")
  end

  it "sets the default action as :sync" do
    expect(resource.action).to eql([:sync])
  end

  it "supports :checkout, :diff, :export, :log, :sync actions" do
    expect { resource.action :checkout }.not_to raise_error
    expect { resource.action :diff }.not_to raise_error
    expect { resource.action :export }.not_to raise_error
    expect { resource.action :log }.not_to raise_error
    expect { resource.action :sync }.not_to raise_error
  end

end
