#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
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
describe Chef::Provider::Git do

  before(:each) do
    STDOUT.stub!(:tty?).and_return(true)
    Chef::Log.level = :info

    @current_resource = Chef::Resource::Git.new("web2.0 app")
    @current_resource.revision("d35af14d41ae22b19da05d7d03a0bafc321b244c")

    @resource = Chef::Resource::Git.new("web2.0 app")
    @resource.repository "git://github.com/opscode/chef.git"
    @resource.destination "/my/deploy/dir"
    @resource.revision "d35af14d41ae22b19da05d7d03a0bafc321b244c"
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @provider = Chef::Provider::Git.new(@resource, @run_context)
    @provider.current_resource = @current_resource
  end

  context "determining the revision of the currently deployed checkout" do

    before do
      @stdout = mock("standard out")
      @stderr = mock("standard error")
      @exitstatus = mock("exitstatus")
    end

    it "sets the current revision to nil if the deploy dir does not exist" do
      ::File.should_receive(:exist?).with("/my/deploy/dir/.git").and_return(false)
      @provider.find_current_revision.should be_nil
    end

    it "determines the current revision when there is one" do
      ::File.should_receive(:exist?).with("/my/deploy/dir/.git").and_return(true)
      @stdout = "9b4d8dc38dd471246e7cfb1c3c1ad14b0f2bee13\n"
      @provider.should_receive(:shell_out!).with('git rev-parse HEAD', {:cwd => '/my/deploy/dir', :returns => [0,128]}).and_return(mock("ShellOut result", :stdout => @stdout))
      @provider.find_current_revision.should eql("9b4d8dc38dd471246e7cfb1c3c1ad14b0f2bee13")
    end

    it "gives the current revision as nil when there is no current revision" do
      ::File.should_receive(:exist?).with("/my/deploy/dir/.git").and_return(true)
      @stderr = "fatal: Not a git repository (or any of the parent directories): .git"
      @stdout = ""
      @provider.should_receive(:shell_out!).with('git rev-parse HEAD', :cwd => '/my/deploy/dir', :returns => [0,128]).and_return(mock("ShellOut result", :stdout => "", :stderr => @stderr))
      @provider.find_current_revision.should be_nil
    end
  end

  it "creates a current_resource with the currently deployed revision when a clone exists in the destination dir" do
    @provider.stub!(:find_current_revision).and_return("681c9802d1c62a45b490786c18f0b8216b309440")
    @provider.load_current_resource
    @provider.current_resource.name.should eql(@resource.name)
    @provider.current_resource.revision.should eql("681c9802d1c62a45b490786c18f0b8216b309440")
  end

  it "keeps the node and resource passed to it on initialize" do
    @provider.node.should equal(@node)
    @provider.new_resource.should equal(@resource)
  end

  context "resolving revisions to a SHA" do

    before do
      @git_ls_remote = "git ls-remote git://github.com/opscode/chef.git "
    end

    it "returns resource.revision as is if revision is already a full SHA" do
      @provider.target_revision.should eql("d35af14d41ae22b19da05d7d03a0bafc321b244c")
    end

    it "converts resource.revision from a tag to a SHA" do
      @resource.revision "v1.0"
      @stdout = "503c22a5e41f5ae3193460cca044ed1435029f53\trefs/heads/0.8-alpha\n"
      @provider.should_receive(:shell_out!).with(@git_ls_remote + "v1.0", {:log_tag=>"git[web2.0 app]", :log_level=>:debug}).and_return(mock("ShellOut result", :stdout => @stdout))
      @provider.target_revision.should eql("503c22a5e41f5ae3193460cca044ed1435029f53")
    end

    it "raises an invalid remote reference error if you try to deploy from ``origin'' and assertions are run" do
      @resource.revision "origin/"
      @provider.action = :checkout
      @provider.define_resource_requirements 
      ::File.stub!(:directory?).with("/my/deploy").and_return(true)
      lambda {@provider.process_resource_requirements}.should raise_error(Chef::Exceptions::InvalidRemoteGitReference)
    end

    it "raises an unresolvable git reference error if the revision can't be resolved to any revision and assertions are run" do
      @resource.revision "FAIL, that's the revision I want"
      @provider.action = :checkout
      @provider.should_receive(:shell_out!).and_return(mock("ShellOut result", :stdout => "\n"))
      @provider.define_resource_requirements 
      lambda { @provider.process_resource_requirements }.should raise_error(Chef::Exceptions::UnresolvableGitReference)
    end

    it "does not raise an error if the revision can't be resolved when assertions are not run" do
      @resource.revision "FAIL, that's the revision I want"
      @provider.should_receive(:shell_out!).and_return(mock("ShellOut result", :stdout => "\n"))
      @provider.target_revision.should == nil
    end

    it "does not raise an error when the revision is valid and assertions are run." do 
      @resource.revision "v1.0"
      @stdout = "503c22a5e41f5ae3193460cca044ed1435029f53\trefs/heads/0.8-alpha\n"
      @provider.should_receive(:shell_out!).with(@git_ls_remote + "v1.0", {:log_tag=>"git[web2.0 app]", :log_level=>:debug}).and_return(mock("ShellOut result", :stdout => @stdout))
      @provider.action = :checkout
      ::File.stub!(:directory?).with("/my/deploy").and_return(true)
      @provider.define_resource_requirements 
      lambda { @provider.process_resource_requirements }.should_not raise_error(RuntimeError)
    end

    it "gives the latest HEAD revision SHA if nothing is specified" do
      @stdout =<<-SHAS
28af684d8460ba4793eda3e7ac238c864a5d029a\tHEAD
503c22a5e41f5ae3193460cca044ed1435029f53\trefs/heads/0.8-alpha
28af684d8460ba4793eda3e7ac238c864a5d029a\trefs/heads/master
c44fe79bb5e36941ce799cee6b9de3a2ef89afee\trefs/tags/0.5.2
14534f0e0bf133dc9ff6dbe74f8a0c863ff3ac6d\trefs/tags/0.5.4
d36fddb4291341a1ff2ecc3c560494e398881354\trefs/tags/0.5.6
9e5ce9031cbee81015de680d010b603bce2dd15f\trefs/tags/0.6.0
9b4d8dc38dd471246e7cfb1c3c1ad14b0f2bee13\trefs/tags/0.6.2
014a69af1cdce619de82afaf6cdb4e6ac658fede\trefs/tags/0.7.0
fa8097ff666af3ce64761d8e1f1c2aa292a11378\trefs/tags/0.7.2
44f9be0b33ba5c10027ddb030a5b2f0faa3eeb8d\trefs/tags/0.7.4
d7b9957f67236fa54e660cc3ab45ffecd6e0ba38\trefs/tags/0.7.8
b7d19519a1c15f1c1a324e2683bd728b6198ce5a\trefs/tags/0.7.8^{}
ebc1b392fe7e8f0fbabc305c299b4d365d2b4d9b\trefs/tags/chef-server-package
SHAS
      @resource.revision ''
      @provider.should_receive(:shell_out!).with(@git_ls_remote, {:log_tag=>"git[web2.0 app]", :log_level=>:debug}).and_return(mock("ShellOut result", :stdout => @stdout))
      @provider.target_revision.should eql("28af684d8460ba4793eda3e7ac238c864a5d029a")
    end
  end

  it "responds to :revision_slug as an alias for target_revision" do
    @provider.should respond_to(:revision_slug)
  end

  it "runs a clone command with default git options" do
    @resource.user "deployNinja"
    @resource.ssh_wrapper "do_it_this_way.sh"
    expected_cmd = "git clone  git://github.com/opscode/chef.git /my/deploy/dir"
    @provider.should_receive(:shell_out!).with(expected_cmd, :user => "deployNinja",
                                                :environment =>{"GIT_SSH"=>"do_it_this_way.sh"}, :log_level => :info, :log_tag => "git[web2.0 app]", :live_stream => STDOUT)

    @provider.clone
  end

  it "runs a clone command with escaped destination" do
    @resource.user "deployNinja"
    @resource.destination "/Application Support/with/space"
    @resource.ssh_wrapper "do_it_this_way.sh"
    expected_cmd = "git clone  git://github.com/opscode/chef.git /Application\\ Support/with/space"
    @provider.should_receive(:shell_out!).with(expected_cmd, :user => "deployNinja",
                                                :environment =>{"GIT_SSH"=>"do_it_this_way.sh"}, :log_level => :info, :log_tag => "git[web2.0 app]", :live_stream => STDOUT)
    @provider.clone
  end

  it "compiles a clone command using --depth for shallow cloning" do
    @resource.depth 5
    expected_cmd = 'git clone --depth 5 git://github.com/opscode/chef.git /my/deploy/dir'
    @provider.should_receive(:shell_out!).with(expected_cmd, {:log_level => :info, :log_tag => "git[web2.0 app]", :live_stream => STDOUT})
    @provider.clone
  end

  it "compiles a clone command with a remote other than ``origin''" do
    @resource.remote "opscode"
    expected_cmd = 'git clone -o opscode git://github.com/opscode/chef.git /my/deploy/dir'
    @provider.should_receive(:shell_out!).with(expected_cmd, {:log_level => :info, :log_tag => "git[web2.0 app]", :live_stream => STDOUT})
    @provider.clone
  end

  it "runs a checkout command with default options" do
    expected_cmd = 'git checkout -b deploy d35af14d41ae22b19da05d7d03a0bafc321b244c'
    @provider.should_receive(:shell_out!).with(expected_cmd, :cwd => "/my/deploy/dir", :log_level => :debug, :log_tag => "git[web2.0 app]")
    @provider.checkout
  end

  it "runs an enable_submodule command" do
    @resource.enable_submodules true
    expected_cmd = "git submodule update --init --recursive"
    @provider.should_receive(:shell_out!).with(expected_cmd, :cwd => "/my/deploy/dir", :log_level => :info, :log_tag => "git[web2.0 app]", :live_stream => STDOUT)
    @provider.enable_submodules
  end

  it "does nothing for enable_submodules if resource.enable_submodules #=> false" do
    @provider.should_not_receive(:shell_out!)
    @provider.enable_submodules
  end

  it "runs a sync command with default options" do
    expected_cmd = "git fetch origin && git fetch origin --tags && git reset --hard d35af14d41ae22b19da05d7d03a0bafc321b244c"
    @provider.should_receive(:shell_out!).with(expected_cmd, :cwd=> "/my/deploy/dir", :log_level => :debug, :log_tag => "git[web2.0 app]")
    @provider.fetch_updates
  end

  it "runs a sync command with the user and group specified in the resource" do
    @resource.user("whois")
    @resource.group("thisis")
    expected_cmd = "git fetch origin && git fetch origin --tags && git reset --hard d35af14d41ae22b19da05d7d03a0bafc321b244c"
    @provider.should_receive(:shell_out!).with(expected_cmd, :cwd => "/my/deploy/dir",
                                                :user => "whois", :group => "thisis", :log_level => :debug, :log_tag => "git[web2.0 app]")
    @provider.fetch_updates
  end

  it "configures remote tracking branches when remote is not ``origin''" do
    @resource.remote "opscode"
    conf_tracking_branches =  "git config remote.opscode.url git://github.com/opscode/chef.git && " +
                              "git config remote.opscode.fetch +refs/heads/*:refs/remotes/opscode/*"
    @provider.should_receive(:shell_out!).with(conf_tracking_branches, :cwd => "/my/deploy/dir", :log_tag => "git[web2.0 app]", :log_level => :debug)
    fetch_command = "git fetch opscode && git fetch opscode --tags && git reset --hard d35af14d41ae22b19da05d7d03a0bafc321b244c"
    @provider.should_receive(:shell_out!).with(fetch_command, :cwd => "/my/deploy/dir", :log_level => :debug, :log_tag => "git[web2.0 app]")
    @provider.fetch_updates
  end

  it "raises an error if the git clone command would fail because the enclosing directory doesn't exist" do
    @provider.stub!(:shell_out!)
    lambda {@provider.run_action(:sync)}.should raise_error(Chef::Exceptions::MissingParentDirectory)
  end

  it "does a checkout by cloning the repo and then enabling submodules" do
    # will be invoked in load_current_resource 
    ::File.stub!(:exist?).with("/my/deploy/dir/.git").and_return(false)

    ::File.stub!(:exist?).with("/my/deploy/dir").and_return(true)
    ::File.stub!(:directory?).with("/my/deploy").and_return(true)
    ::Dir.stub!(:entries).with("/my/deploy/dir").and_return(['.','..'])
    @provider.should_receive(:clone)
    @provider.should_receive(:checkout)
    @provider.should_receive(:enable_submodules)
    @provider.run_action(:checkout)
    # Even though an actual run will cause an update to occur, the fact that we've stubbed out
    # the actions above will prevent updates from registering
    # @resource.should be_updated
  end

  # REGRESSION TEST: on some OSes, the entries from an empty directory will be listed as
  # ['..', '.'] but this shouldn't change the behavior
  it "does a checkout by cloning the repo and then enabling submodules when the directory entries are listed as %w{.. .}" do
    ::File.stub!(:exist?).with("/my/deploy/dir/.git").and_return(false)
    ::File.stub!(:exist?).with("/my/deploy/dir").and_return(false)
    ::File.stub!(:directory?).with("/my/deploy").and_return(true)
    ::Dir.stub!(:entries).with("/my/deploy/dir").and_return(['..','.'])
    @provider.should_receive(:clone)
    @provider.should_receive(:checkout)
    @provider.should_receive(:enable_submodules)
    @provider.run_action(:checkout)
   # @resource.should be_updated
  end

  it "should not checkout if the destination exists or is a non empty directory" do
    # will be invoked in load_current_resource 
    ::File.stub!(:exist?).with("/my/deploy/dir/.git").and_return(false)

    ::File.stub!(:exist?).with("/my/deploy/dir").and_return(true)
    ::File.stub!(:directory?).with("/my/deploy").and_return(true)
    ::Dir.stub!(:entries).with("/my/deploy/dir").and_return(['.','..','foo','bar'])
    @provider.should_not_receive(:clone)
    @provider.should_not_receive(:checkout)
    @provider.should_not_receive(:enable_submodules)
    @provider.run_action(:checkout)
    @resource.should_not be_updated
  end

  it "syncs the code by updating the source when the repo has already been checked out" do
    ::File.should_receive(:exist?).with("/my/deploy/dir/.git").and_return(true)
    ::File.stub!(:directory?).with("/my/deploy").and_return(true)
    @provider.should_receive(:find_current_revision).exactly(2).and_return('d35af14d41ae22b19da05d7d03a0bafc321b244c')
    @provider.should_not_receive(:fetch_updates)
    @provider.run_action(:sync)
    @resource.should_not be_updated
  end

  it "marks the resource as updated when the repo is updated and gets a new version" do
    ::File.should_receive(:exist?).with("/my/deploy/dir/.git").and_return(true)
    ::File.stub!(:directory?).with("/my/deploy").and_return(true)
    # invoked twice - first time from load_current_resource
    @provider.should_receive(:find_current_revision).exactly(2).and_return('d35af14d41ae22b19da05d7d03a0bafc321b244c')
    @provider.stub!(:target_revision).and_return('28af684d8460ba4793eda3e7ac238c864a5d029a')
    @provider.should_receive(:fetch_updates)
    @provider.should_receive(:enable_submodules)
    @provider.run_action(:sync)
   # @resource.should be_updated
  end

  it "does not fetch any updates if the remote revision matches the current revision" do
    ::File.should_receive(:exist?).with("/my/deploy/dir/.git").and_return(true)
    ::File.stub!(:directory?).with("/my/deploy").and_return(true)
    @provider.stub!(:find_current_revision).and_return('d35af14d41ae22b19da05d7d03a0bafc321b244c')
    @provider.stub!(:target_revision).and_return('d35af14d41ae22b19da05d7d03a0bafc321b244c')
    @provider.should_not_receive(:fetch_updates)
    @provider.run_action(:sync)
    @resource.should_not be_updated
  end

  it "clones the repo instead of fetching it if the deploy directory doesn't exist" do
    ::File.stub!(:directory?).with("/my/deploy").and_return(true)
    ::File.should_receive(:exist?).with("/my/deploy/dir/.git").exactly(2).and_return(false)
    @provider.should_receive(:action_checkout)
    @provider.should_not_receive(:shell_out!)
    @provider.run_action(:sync)
   # @resource.should be_updated
  end

  it "clones the repo instead of fetching updates if the deploy directory is empty" do
    ::File.should_receive(:exist?).with("/my/deploy/dir/.git").exactly(2).and_return(false)
    ::File.stub!(:directory?).with("/my/deploy").and_return(true)
    ::File.stub!(:directory?).with("/my/deploy/dir").and_return(true)
    @provider.stub!(:sync_command).and_return("huzzah!")
    @provider.should_receive(:action_checkout)
    @provider.should_not_receive(:shell_out!).with("huzzah!", :cwd => "/my/deploy/dir")
    @provider.run_action(:sync)
    #@resource.should be_updated
  end

  it "does an export by cloning the repo then removing the .git directory" do
    @provider.should_receive(:action_checkout)
    FileUtils.should_receive(:rm_rf).with(@resource.destination + "/.git")
    @provider.run_action(:export)
    @resource.should be_updated
  end

end
