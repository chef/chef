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

describe Chef::Provider::Subversion do

  before do
    @resource = Chef::Resource::Subversion.new("my app")
    @resource.repository "http://svn.example.org/trunk/"
    @resource.destination "/my/deploy/dir"
    @resource.revision "12345"
    @resource.svn_arguments(false)
    @resource.svn_info_args(false)
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @provider = Chef::Provider::Subversion.new(@resource, @run_context)
  end

  it "converts resource attributes to options for run_command and popen4" do
    @provider.run_options.should == {}
    @resource.user 'deployninja'
    @provider.run_options.should == {:user => "deployninja"}
  end

  context "determining the revision of the currently deployed code" do

    before do
      @stdout = mock("stdout")
      @stderr = mock("stderr")
      @exitstatus = mock("exitstatus")
    end

    it "sets the revision to nil if there isn't any deployed code yet" do
      ::File.should_receive(:exist?).with("/my/deploy/dir/.svn").and_return(false)
      @provider.find_current_revision.should be_nil
    end

    it "determines the current revision if there's a checkout with svn data available" do
      example_svn_info =  "Path: .\n" +
                          "URL: http://svn.example.org/trunk/myapp\n" +
                          "Repository Root: http://svn.example.org\n" +
                          "Repository UUID: d62ff500-7bbc-012c-85f1-0026b0e37c24\n" +
                          "Revision: 11739\nNode Kind: directory\n" +
                          "Schedule: normal\n" +
                          "Last Changed Author: codeninja\n" +
                          "Last Changed Rev: 11410\n" + # Last Changed Rev is preferred to Revision
                          "Last Changed Date: 2009-03-25 06:09:56 -0600 (Wed, 25 Mar 2009)\n\n"
      ::File.should_receive(:exist?).at_least(1).times.with("/my/deploy/dir/.svn").and_return(true)
      ::File.should_receive(:directory?).with("/my/deploy/dir").and_return(true)
      ::Dir.should_receive(:chdir).with("/my/deploy/dir").and_yield
      @stdout.stub!(:string).and_return(example_svn_info)
      @stderr.stub!(:string).and_return("")
      @exitstatus.stub!(:exitstatus).and_return(0)
      expected_command = ["svn info", {:cwd=>"/my/deploy/dir"}]
      @provider.should_receive(:popen4).with(*expected_command).
                                        and_yield("no-pid", "no-stdin", @stdout,@stderr).
                                        and_return(@exitstatus)
      @provider.find_current_revision.should eql("11410")
    end

    it "gives nil as the current revision if the deploy dir isn't a SVN working copy" do
      example_svn_info = "svn: '/tmp/deploydir' is not a working copy\n"
      ::File.should_receive(:exist?).with("/my/deploy/dir/.svn").and_return(true)
      ::File.should_receive(:directory?).with("/my/deploy/dir").and_return(true)
      ::Dir.should_receive(:chdir).with("/my/deploy/dir").and_yield
      @stdout.stub!(:string).and_return(example_svn_info)
      @stderr.stub!(:string).and_return("")
      @exitstatus.stub!(:exitstatus).and_return(1)
      @provider.should_receive(:popen4).and_yield("no-pid", "no-stdin", @stdout,@stderr).
                                        and_return(@exitstatus)
      @provider.find_current_revision.should be_nil
    end

    it "finds the current revision when loading the current resource state" do
      # note: the test is kinda janky, but it provides regression coverage for CHEF-2092
      @resource.instance_variable_set(:@action, :sync)
      @provider.should_receive(:find_current_revision).and_return("12345")
      @provider.load_current_resource
      @provider.current_resource.revision.should == "12345"
    end
  end

  it "creates the current_resource object and sets its revision to the current deployment's revision as long as we're not exporting" do
    @provider.stub!(:find_current_revision).and_return("11410")
    @provider.new_resource.instance_variable_set :@action, [:checkout]
    @provider.load_current_resource
    @provider.current_resource.name.should eql(@resource.name)
    @provider.current_resource.revision.should eql("11410")
  end

  context "resolving revisions to an integer" do

    before do
      @stdout = mock("stdout")
      @stderr = mock("stderr")
      @resource.svn_info_args "--no-auth-cache"
    end

    it "returns the revision number as is if it's already an integer" do
      @provider.revision_int.should eql("12345")
    end

    it "queries the server and resolves the revision if it's not an integer (i.e. 'HEAD')" do
      example_svn_info =  "Path: .\n" +
                          "URL: http://svn.example.org/trunk/myapp\n" +
                          "Repository Root: http://svn.example.org\n" +
                          "Repository UUID: d62ff500-7bbc-012c-85f1-0026b0e37c24\n" +
                          "Revision: 11739\nNode Kind: directory\n" +
                          "Schedule: normal\n" +
                          "Last Changed Author: codeninja\n" +
                          "Last Changed Rev: 11410\n" + # Last Changed Rev is preferred to Revision
                          "Last Changed Date: 2009-03-25 06:09:56 -0600 (Wed, 25 Mar 2009)\n\n"
      exitstatus = mock("exitstatus")
      exitstatus.stub!(:exitstatus).and_return(0)
      @resource.revision "HEAD"
      @stdout.stub!(:string).and_return(example_svn_info)
      @stderr.stub!(:string).and_return("")
      expected_command = ["svn info http://svn.example.org/trunk/ --no-auth-cache  -rHEAD", {:cwd=>Dir.tmpdir}]
      @provider.should_receive(:popen4).with(*expected_command).
                                        and_yield("no-pid","no-stdin",@stdout,@stderr).
                                        and_return(exitstatus)
      @provider.revision_int.should eql("11410")
    end

    it "returns a helpful message if data from `svn info` can't be parsed" do
      example_svn_info =  "some random text from an error message\n"
      exitstatus = mock("exitstatus")
      exitstatus.stub!(:exitstatus).and_return(0)
      @resource.revision "HEAD"
      @stdout.stub!(:string).and_return(example_svn_info)
      @stderr.stub!(:string).and_return("")
      @provider.should_receive(:popen4).and_yield("no-pid","no-stdin",@stdout,@stderr).
                                        and_return(exitstatus)
      lambda {@provider.revision_int}.should raise_error(RuntimeError, "Could not parse `svn info` data: some random text from an error message")

    end

    it "responds to :revision_slug as an alias for revision_sha" do
      @provider.should respond_to(:revision_slug)
    end

  end

  it "generates a checkout command with default options" do
    @provider.checkout_command.should eql("svn checkout -q  -r12345 http://svn.example.org/trunk/ /my/deploy/dir")
  end

  it "generates a checkout command with authentication" do
    @resource.svn_username "deployNinja"
    @resource.svn_password "vanish!"
    @provider.checkout_command.should eql("svn checkout -q --username deployNinja --password vanish!  " +
                                          "-r12345 http://svn.example.org/trunk/ /my/deploy/dir")
  end

  it "generates a checkout command with arbitrary options" do
    @resource.svn_arguments "--no-auth-cache"
    @provider.checkout_command.should eql("svn checkout --no-auth-cache -q  -r12345 "+
                                          "http://svn.example.org/trunk/ /my/deploy/dir")
  end

  it "generates a sync command with default options" do
    @provider.sync_command.should eql("svn update -q  -r12345 /my/deploy/dir")
  end

  it "generates an export command with default options" do
    @provider.export_command.should eql("svn export --force -q  -r12345 http://svn.example.org/trunk/ /my/deploy/dir")
  end

  it "doesn't try to find the current revision when loading the resource if running an export" do
    @provider.new_resource.instance_variable_set :@action, [:export]
    @provider.should_not_receive(:find_current_revision)
    @provider.load_current_resource
  end

  it "doesn't try to find the current revision when loading the resource if running a force export" do
    @provider.new_resource.instance_variable_set :@action, [:force_export]
    @provider.should_not_receive(:find_current_revision)
    @provider.load_current_resource
  end

  it "runs an export with the --force option" do
    ::File.stub!(:directory?).with("/my/deploy").and_return(true)
    expected_cmd = "svn export --force -q  -r12345 http://svn.example.org/trunk/ /my/deploy/dir"
    @provider.should_receive(:run_command).with(:command => expected_cmd)
    @provider.run_action(:force_export)
    @resource.should be_updated
  end

  it "runs the checkout command for action_checkout" do
    ::File.stub!(:directory?).with("/my/deploy").and_return(true)
    expected_cmd = "svn checkout -q  -r12345 http://svn.example.org/trunk/ /my/deploy/dir"
    @provider.should_receive(:run_command).with(:command => expected_cmd)
    @provider.run_action(:checkout)
    @resource.should be_updated
  end

  it "raises an error if the svn checkout command would fail because the enclosing directory doesn't exist" do
    lambda {@provider.run_action(:sync)}.should raise_error(Chef::Exceptions::MissingParentDirectory)
  end

  it "should not checkout if the destination exists or is a non empty directory" do
    ::File.stub!(:exist?).with("/my/deploy/dir/.svn").and_return(false)
    ::File.stub!(:exist?).with("/my/deploy/dir").and_return(true)
    ::File.stub!(:directory?).with("/my/deploy").and_return(true)
    ::Dir.stub!(:entries).with("/my/deploy/dir").and_return(['.','..','foo','bar'])
    @provider.should_not_receive(:checkout_command)
    @provider.run_action(:checkout)
    @resource.should_not be_updated
  end

  it "runs commands with the user and group specified in the resource" do
    ::File.stub!(:directory?).with("/my/deploy").and_return(true)
    @resource.user "whois"
    @resource.group "thisis"
    expected_cmd = "svn checkout -q  -r12345 http://svn.example.org/trunk/ /my/deploy/dir"
    @provider.should_receive(:run_command).with(:command => expected_cmd, :user => "whois", :group => "thisis")
    @provider.run_action(:checkout)
    @resource.should be_updated
  end

  it "does a checkout for action_sync if there's no deploy dir" do
    ::File.stub!(:directory?).with("/my/deploy").and_return(true)
    ::File.should_receive(:exist?).with("/my/deploy/dir/.svn").twice.and_return(false)
    @provider.should_receive(:action_checkout)
    @provider.run_action(:sync)
  end

  it "does a checkout for action_sync if the deploy dir exists but is empty" do
    ::File.stub!(:directory?).with("/my/deploy").and_return(true)
    ::File.should_receive(:exist?).with("/my/deploy/dir/.svn").twice.and_return(false)
    @provider.should_receive(:action_checkout)
    @provider.run_action(:sync) 
  end

  it "runs the sync_command on action_sync if the deploy dir exists and isn't empty" do
    ::File.stub!(:directory?).with("/my/deploy").and_return(true)
    ::File.should_receive(:exist?).with("/my/deploy/dir/.svn").and_return(true)
    @provider.stub!(:find_current_revision).and_return("11410")
    @provider.stub!(:current_revision_matches_target_revision?).and_return(false)
    expected_cmd = "svn update -q  -r12345 /my/deploy/dir"
    @provider.should_receive(:run_command).with(:command => expected_cmd)
    @provider.run_action(:sync)
    @resource.should be_updated
  end

  it "does not fetch any updates if the remote revision matches the current revision" do
    ::File.stub!(:directory?).with("/my/deploy").and_return(true)
    ::File.should_receive(:exist?).with("/my/deploy/dir/.svn").and_return(true)
    @provider.stub!(:find_current_revision).and_return('12345')
    @provider.stub!(:current_revision_matches_target_revision?).and_return(true)
    @provider.run_action(:sync)
    @resource.should_not be_updated
  end

  it "runs the export_command on action_export" do
    ::File.stub!(:directory?).with("/my/deploy").and_return(true)
    expected_cmd = "svn export --force -q  -r12345 http://svn.example.org/trunk/ /my/deploy/dir"
    @provider.should_receive(:run_command).with(:command => expected_cmd)
    @provider.run_action(:export)
    @resource.should be_updated
  end

end
