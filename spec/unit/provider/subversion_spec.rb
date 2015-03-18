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
    expect(@provider.run_options).to eq({})
    @resource.user 'deployninja'
    expect(@provider.run_options).to eq({:user => "deployninja"})
  end

  context "determining the revision of the currently deployed code" do

    before do
      @stdout = double("stdout")
      @stderr = double("stderr")
      @exitstatus = double("exitstatus")
    end

    it "sets the revision to nil if there isn't any deployed code yet" do
      expect(::File).to receive(:exist?).with("/my/deploy/dir/.svn").and_return(false)
      expect(@provider.find_current_revision).to be_nil
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
      expect(::File).to receive(:exist?).at_least(1).times.with("/my/deploy/dir/.svn").and_return(true)
      expect(::File).to receive(:directory?).with("/my/deploy/dir").and_return(true)
      expect(::Dir).to receive(:chdir).with("/my/deploy/dir").and_yield
      allow(@stdout).to receive(:string).and_return(example_svn_info)
      allow(@stderr).to receive(:string).and_return("")
      allow(@exitstatus).to receive(:exitstatus).and_return(0)
      expected_command = ["svn info", {:cwd=>"/my/deploy/dir"}]
      expect(@provider).to receive(:popen4).with(*expected_command).
                                        and_yield("no-pid", "no-stdin", @stdout,@stderr).
                                        and_return(@exitstatus)
      expect(@provider.find_current_revision).to eql("11410")
    end

    it "gives nil as the current revision if the deploy dir isn't a SVN working copy" do
      example_svn_info = "svn: '/tmp/deploydir' is not a working copy\n"
      expect(::File).to receive(:exist?).with("/my/deploy/dir/.svn").and_return(true)
      expect(::File).to receive(:directory?).with("/my/deploy/dir").and_return(true)
      expect(::Dir).to receive(:chdir).with("/my/deploy/dir").and_yield
      allow(@stdout).to receive(:string).and_return(example_svn_info)
      allow(@stderr).to receive(:string).and_return("")
      allow(@exitstatus).to receive(:exitstatus).and_return(1)
      expect(@provider).to receive(:popen4).and_yield("no-pid", "no-stdin", @stdout,@stderr).
                                        and_return(@exitstatus)
      expect(@provider.find_current_revision).to be_nil
    end

    it "finds the current revision when loading the current resource state" do
      # note: the test is kinda janky, but it provides regression coverage for CHEF-2092
      @resource.instance_variable_set(:@action, :sync)
      expect(@provider).to receive(:find_current_revision).and_return("12345")
      @provider.load_current_resource
      expect(@provider.current_resource.revision).to eq("12345")
    end
  end

  it "creates the current_resource object and sets its revision to the current deployment's revision as long as we're not exporting" do
    allow(@provider).to receive(:find_current_revision).and_return("11410")
    @provider.new_resource.instance_variable_set :@action, [:checkout]
    @provider.load_current_resource
    expect(@provider.current_resource.name).to eql(@resource.name)
    expect(@provider.current_resource.revision).to eql("11410")
  end

  context "resolving revisions to an integer" do

    before do
      @stdout = double("stdout")
      @stderr = double("stderr")
      @resource.svn_info_args "--no-auth-cache"
    end

    it "returns the revision number as is if it's already an integer" do
      expect(@provider.revision_int).to eql("12345")
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
      exitstatus = double("exitstatus")
      allow(exitstatus).to receive(:exitstatus).and_return(0)
      @resource.revision "HEAD"
      allow(@stdout).to receive(:string).and_return(example_svn_info)
      allow(@stderr).to receive(:string).and_return("")
      expected_command = ["svn info http://svn.example.org/trunk/ --no-auth-cache  -rHEAD", {:cwd=>Dir.tmpdir}]
      expect(@provider).to receive(:popen4).with(*expected_command).
                                        and_yield("no-pid","no-stdin",@stdout,@stderr).
                                        and_return(exitstatus)
      expect(@provider.revision_int).to eql("11410")
    end

    it "returns a helpful message if data from `svn info` can't be parsed" do
      example_svn_info =  "some random text from an error message\n"
      exitstatus = double("exitstatus")
      allow(exitstatus).to receive(:exitstatus).and_return(0)
      @resource.revision "HEAD"
      allow(@stdout).to receive(:string).and_return(example_svn_info)
      allow(@stderr).to receive(:string).and_return("")
      expect(@provider).to receive(:popen4).and_yield("no-pid","no-stdin",@stdout,@stderr).
                                        and_return(exitstatus)
      expect {@provider.revision_int}.to raise_error(RuntimeError, "Could not parse `svn info` data: some random text from an error message")

    end

    it "responds to :revision_slug as an alias for revision_sha" do
      expect(@provider).to respond_to(:revision_slug)
    end

  end

  it "generates a checkout command with default options" do
    expect(@provider.checkout_command).to eql("svn checkout -q  -r12345 http://svn.example.org/trunk/ /my/deploy/dir")
  end

  it "generates a checkout command with authentication" do
    @resource.svn_username "deployNinja"
    @resource.svn_password "vanish!"
    expect(@provider.checkout_command).to eql("svn checkout -q --username deployNinja --password vanish!  " +
                                          "-r12345 http://svn.example.org/trunk/ /my/deploy/dir")
  end

  it "generates a checkout command with arbitrary options" do
    @resource.svn_arguments "--no-auth-cache"
    expect(@provider.checkout_command).to eql("svn checkout --no-auth-cache -q  -r12345 "+
                                          "http://svn.example.org/trunk/ /my/deploy/dir")
  end

  it "generates a sync command with default options" do
    expect(@provider.sync_command).to eql("svn update -q  -r12345 /my/deploy/dir")
  end

  it "generates an export command with default options" do
    expect(@provider.export_command).to eql("svn export --force -q  -r12345 http://svn.example.org/trunk/ /my/deploy/dir")
  end

  it "doesn't try to find the current revision when loading the resource if running an export" do
    @provider.new_resource.instance_variable_set :@action, [:export]
    expect(@provider).not_to receive(:find_current_revision)
    @provider.load_current_resource
  end

  it "doesn't try to find the current revision when loading the resource if running a force export" do
    @provider.new_resource.instance_variable_set :@action, [:force_export]
    expect(@provider).not_to receive(:find_current_revision)
    @provider.load_current_resource
  end

  it "runs an export with the --force option" do
    allow(::File).to receive(:directory?).with("/my/deploy").and_return(true)
    expected_cmd = "svn export --force -q  -r12345 http://svn.example.org/trunk/ /my/deploy/dir"
    expect(@provider).to receive(:shell_out!).with(expected_cmd, {})
    @provider.run_action(:force_export)
    expect(@resource).to be_updated
  end

  it "runs the checkout command for action_checkout" do
    allow(::File).to receive(:directory?).with("/my/deploy").and_return(true)
    expected_cmd = "svn checkout -q  -r12345 http://svn.example.org/trunk/ /my/deploy/dir"
    expect(@provider).to receive(:shell_out!).with(expected_cmd, {})
    @provider.run_action(:checkout)
    expect(@resource).to be_updated
  end

  it "raises an error if the svn checkout command would fail because the enclosing directory doesn't exist" do
    expect {@provider.run_action(:sync)}.to raise_error(Chef::Exceptions::MissingParentDirectory)
  end

  it "should not checkout if the destination exists or is a non empty directory" do
    allow(::File).to receive(:exist?).with("/my/deploy/dir/.svn").and_return(false)
    allow(::File).to receive(:exist?).with("/my/deploy/dir").and_return(true)
    allow(::File).to receive(:directory?).with("/my/deploy").and_return(true)
    allow(::Dir).to receive(:entries).with("/my/deploy/dir").and_return(['.','..','foo','bar'])
    expect(@provider).not_to receive(:checkout_command)
    @provider.run_action(:checkout)
    expect(@resource).not_to be_updated
  end

  it "runs commands with the user and group specified in the resource" do
    allow(::File).to receive(:directory?).with("/my/deploy").and_return(true)
    @resource.user "whois"
    @resource.group "thisis"
    expected_cmd = "svn checkout -q  -r12345 http://svn.example.org/trunk/ /my/deploy/dir"
    expect(@provider).to receive(:shell_out!).with(expected_cmd, {user: "whois", group: "thisis"})
    @provider.run_action(:checkout)
    expect(@resource).to be_updated
  end

  it "does a checkout for action_sync if there's no deploy dir" do
    allow(::File).to receive(:directory?).with("/my/deploy").and_return(true)
    expect(::File).to receive(:exist?).with("/my/deploy/dir/.svn").twice.and_return(false)
    expect(@provider).to receive(:action_checkout)
    @provider.run_action(:sync)
  end

  it "does a checkout for action_sync if the deploy dir exists but is empty" do
    allow(::File).to receive(:directory?).with("/my/deploy").and_return(true)
    expect(::File).to receive(:exist?).with("/my/deploy/dir/.svn").twice.and_return(false)
    expect(@provider).to receive(:action_checkout)
    @provider.run_action(:sync)
  end

  it "runs the sync_command on action_sync if the deploy dir exists and isn't empty" do
    allow(::File).to receive(:directory?).with("/my/deploy").and_return(true)
    expect(::File).to receive(:exist?).with("/my/deploy/dir/.svn").and_return(true)
    allow(@provider).to receive(:find_current_revision).and_return("11410")
    allow(@provider).to receive(:current_revision_matches_target_revision?).and_return(false)
    expected_cmd = "svn update -q  -r12345 /my/deploy/dir"
    expect(@provider).to receive(:shell_out!).with(expected_cmd, {})
    @provider.run_action(:sync)
    expect(@resource).to be_updated
  end

  it "does not fetch any updates if the remote revision matches the current revision" do
    allow(::File).to receive(:directory?).with("/my/deploy").and_return(true)
    expect(::File).to receive(:exist?).with("/my/deploy/dir/.svn").and_return(true)
    allow(@provider).to receive(:find_current_revision).and_return('12345')
    allow(@provider).to receive(:current_revision_matches_target_revision?).and_return(true)
    @provider.run_action(:sync)
    expect(@resource).not_to be_updated
  end

  it "runs the export_command on action_export" do
    allow(::File).to receive(:directory?).with("/my/deploy").and_return(true)
    expected_cmd = "svn export --force -q  -r12345 http://svn.example.org/trunk/ /my/deploy/dir"
    expect(@provider).to receive(:shell_out!).with(expected_cmd, {})
    @provider.run_action(:export)
    expect(@resource).to be_updated
  end

end
