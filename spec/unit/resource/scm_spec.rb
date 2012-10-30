#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Author:: Tyler Cloke (<tyler@opscode.com>)
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

require 'spec_helper'

describe Chef::Resource::Scm do

  before(:each) do
    @resource = Chef::Resource::Scm.new("my awesome app")
  end

  it "should be a SCM resource" do
    @resource.should be_a_kind_of(Chef::Resource::Scm)
  end

  it "supports :checkout, :export, :sync, :diff, and :log actions" do
    @resource.allowed_actions.should include(:checkout)
    @resource.allowed_actions.should include(:export)
    @resource.allowed_actions.should include(:sync)
    @resource.allowed_actions.should include(:diff)
    @resource.allowed_actions.should include(:log)
  end

  it "takes the destination path as a string" do
    @resource.destination "/path/to/deploy/dir"
    @resource.destination.should eql("/path/to/deploy/dir")
  end

  it "takes a string for the repository URL" do
    @resource.repository "git://github.com/opscode/chef.git"
    @resource.repository.should eql("git://github.com/opscode/chef.git")
  end

  it "takes a string for the revision" do
    @resource.revision "abcdef"
    @resource.revision.should eql("abcdef")
  end

  it "defaults to the ``HEAD'' revision" do
    @resource.revision.should eql("HEAD")
  end

  it "takes a string for the user to run as" do
    @resource.user "dr_deploy"
    @resource.user.should eql("dr_deploy")
  end

  it "also takes an integer for the user to run as" do
    @resource.user 0
    @resource.user.should eql(0)
  end

  it "takes a string for the group to run as, defaulting to nil" do
    @resource.group.should be_nil
    @resource.group "opsdevs"
    @resource.group.should == "opsdevs"
  end

  it "also takes an integer for the group to run as" do
    @resource.group 23
    @resource.group.should == 23
  end

  it "has a svn_username String attribute" do
    @resource.svn_username "moartestsplz"
    @resource.svn_username.should eql("moartestsplz")
  end

  it "has a svn_password String attribute" do
    @resource.svn_password "taftplz"
    @resource.svn_password.should eql("taftplz")
  end

  it "has a svn_arguments String attribute" do
    @resource.svn_arguments "--more-taft plz"
    @resource.svn_arguments.should eql("--more-taft plz")
  end

  it "has a svn_info_args String attribute" do
    @resource.svn_info_args.should be_nil
    @resource.svn_info_args("--no-moar-plaintext-creds yep")
    @resource.svn_info_args.should == "--no-moar-plaintext-creds yep"
  end

  it "takes the depth as an integer for shallow clones" do
    @resource.depth 5
    @resource.depth.should == 5
    lambda {@resource.depth "five"}.should raise_error(ArgumentError)
  end

  it "defaults to nil depth for a full clone" do
    @resource.depth.should be_nil
  end

  it "takes a boolean for #enable_submodules" do
    @resource.enable_submodules true
    @resource.enable_submodules.should be_true
    lambda {@resource.enable_submodules "lolz"}.should raise_error(ArgumentError)
  end

  it "defaults to not enabling submodules" do
    @resource.enable_submodules.should be_false
  end

  it "takes a string for the remote" do
    @resource.remote "opscode"
    @resource.remote.should eql("opscode")
    lambda {@resource.remote 1337}.should raise_error(ArgumentError)
  end

  it "defaults to ``origin'' for the remote" do
    @resource.remote.should == "origin"
  end

  it "takes a string for the ssh wrapper" do
    @resource.ssh_wrapper "with_ssh_fu"
    @resource.ssh_wrapper.should eql("with_ssh_fu")
  end

  it "defaults to nil for the ssh wrapper" do
    @resource.ssh_wrapper.should be_nil
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
      state = @resource.state
      state[:revision].should == "1.2.3"
    end

    it "returns the destination as its identity" do
      @resource.identity.should == "hell"
    end
  end

end
