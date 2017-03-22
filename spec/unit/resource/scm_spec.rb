#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Author:: Tyler Cloke (<tyler@chef.io>)
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

describe Chef::Resource::Scm do

  before(:each) do
    @resource = Chef::Resource::Scm.new("my awesome app")
  end

  it "should be a SCM resource" do
    expect(@resource).to be_a_kind_of(Chef::Resource::Scm)
  end

  it "supports :checkout, :export, :sync, :diff, and :log actions" do
    expect(@resource.allowed_actions).to include(:checkout)
    expect(@resource.allowed_actions).to include(:export)
    expect(@resource.allowed_actions).to include(:sync)
    expect(@resource.allowed_actions).to include(:diff)
    expect(@resource.allowed_actions).to include(:log)
  end

  it "takes the destination path as a string" do
    @resource.destination "/path/to/deploy/dir"
    expect(@resource.destination).to eql("/path/to/deploy/dir")
  end

  it "takes a string for the repository URL" do
    @resource.repository "git://github.com/opscode/chef.git"
    expect(@resource.repository).to eql("git://github.com/opscode/chef.git")
  end

  it "takes a string for the revision" do
    @resource.revision "abcdef"
    expect(@resource.revision).to eql("abcdef")
  end

  it "defaults to the ``HEAD'' revision" do
    expect(@resource.revision).to eql("HEAD")
  end

  it "takes a string for the user to run as" do
    @resource.user "dr_deploy"
    expect(@resource.user).to eql("dr_deploy")
  end

  it "also takes an integer for the user to run as" do
    @resource.user 0
    expect(@resource.user).to eql(0)
  end

  it "takes a string for the group to run as, defaulting to nil" do
    expect(@resource.group).to be_nil
    @resource.group "opsdevs"
    expect(@resource.group).to eq("opsdevs")
  end

  it "also takes an integer for the group to run as" do
    @resource.group 23
    expect(@resource.group).to eq(23)
  end

  it "has a svn_username String attribute" do
    @resource.svn_username "moartestsplz"
    expect(@resource.svn_username).to eql("moartestsplz")
  end

  it "has a svn_password String attribute" do
    @resource.svn_password "taftplz"
    expect(@resource.svn_password).to eql("taftplz")
  end

  it "has a svn_arguments String attribute" do
    @resource.svn_arguments "--more-taft plz"
    expect(@resource.svn_arguments).to eql("--more-taft plz")
  end

  it "has a svn_info_args String attribute" do
    expect(@resource.svn_info_args).to be_nil
    @resource.svn_info_args("--no-moar-plaintext-creds yep")
    expect(@resource.svn_info_args).to eq("--no-moar-plaintext-creds yep")
  end

  it "takes the depth as an integer for shallow clones" do
    @resource.depth 5
    expect(@resource.depth).to eq(5)
    expect { @resource.depth "five" }.to raise_error(ArgumentError)
  end

  it "defaults to nil depth for a full clone" do
    expect(@resource.depth).to be_nil
  end

  it "takes a boolean for #enable_submodules" do
    @resource.enable_submodules true
    expect(@resource.enable_submodules).to be_truthy
    expect { @resource.enable_submodules "lolz" }.to raise_error(ArgumentError)
  end

  it "defaults to not enabling submodules" do
    expect(@resource.enable_submodules).to be_falsey
  end

  it "takes a boolean for #enable_checkout" do
    @resource.enable_checkout true
    expect(@resource.enable_checkout).to be_truthy
    expect { @resource.enable_checkout "lolz" }.to raise_error(ArgumentError)
  end

  it "defaults to enabling checkout" do
    expect(@resource.enable_checkout).to be_truthy
  end

  it "takes a string for the remote" do
    @resource.remote "opscode"
    expect(@resource.remote).to eql("opscode")
    expect { @resource.remote 1337 }.to raise_error(ArgumentError)
  end

  it "defaults to ``origin'' for the remote" do
    expect(@resource.remote).to eq("origin")
  end

  it "takes a string for the ssh wrapper" do
    @resource.ssh_wrapper "with_ssh_fu"
    expect(@resource.ssh_wrapper).to eql("with_ssh_fu")
  end

  it "defaults to nil for the ssh wrapper" do
    expect(@resource.ssh_wrapper).to be_nil
  end

  it "defaults to nil for the environment" do
    expect(@resource.environment).to be_nil
  end

  describe "when it has a timeout attribute" do
    let(:ten_seconds) { 10 }
    before { @resource.timeout(ten_seconds) }
    it "stores this timeout" do
      expect(@resource.timeout).to eq(ten_seconds)
    end
  end
  describe "when it has no timeout attribute" do
    it "should have no default timeout" do
      expect(@resource.timeout).to be_nil
    end
  end

  describe "when it has repository, revision, user, and group" do
    before do
      @resource.destination("hell")
      @resource.repository("apt")
      @resource.revision("1.2.3")
      @resource.user("root")
      @resource.group("super_adventure_club")
    end

    it "describes its state" do
      state = @resource.state_for_resource_reporter
      expect(state[:revision]).to eq("1.2.3")
    end

    it "returns the destination as its identity" do
      expect(@resource.identity).to eq("hell")
    end
  end

  describe "when it has a environment attribute" do
    let(:test_environment) { { "CHEF_ENV" => "/tmp" } }
    before { @resource.environment(test_environment) }
    it "stores this environment" do
      expect(@resource.environment).to eq(test_environment)
    end
  end
end
