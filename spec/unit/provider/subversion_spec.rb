#
# Author:: Daniel DeLeo (<dan@kallistec.com>)
# Copyright:: Copyright (c) Chef Software Inc.
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

describe Chef::Provider::Subversion do

  before do
    @resource = Chef::Resource::Subversion.new("my app")
    @resource.repository "http://svn.example.org/trunk/"
    @resource.destination "/my/deploy/dir"
    @resource.revision "12345"
    @resource.svn_arguments(false)
    @resource.svn_info_args(false)
    @resource.svn_binary "svn"
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @provider = Chef::Provider::Subversion.new(@resource, @run_context)
    @original_env = ENV.to_hash
    # Generated command lines would include any environmental proxies
    ENV.delete("http_proxy")
    ENV.delete("https_proxy")
  end

  after do
    ENV.clear
    ENV.update(@original_env)
  end

  it "converts resource properties to options for shell_out" do
    expect(@provider.run_options).to eq({})
    @resource.user "deployninja"
    expect(@provider).to receive(:get_homedir).and_return("/home/deployninja")
    expect(@provider.run_options).to eq({ user: "deployninja", environment: { "HOME" => "/home/deployninja" } })
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
      example_svn_info = "Path: .\n" +
        "URL: http://svn.example.org/trunk/myapp\n" +
        "Repository Root: http://svn.example.org\n" +
        "Repository UUID: d62ff500-7bbc-012c-85f1-0026b0e37c24\n" +
        "Revision: 11739\nNode Kind: directory\n" +
        "Schedule: normal\n" +
        "Last Changed Author: codeninja\n" +
        "Last Changed Rev: 11410\n" + # Last Changed Rev is preferred to Revision
        "Last Changed Date: 2009-03-25 06:09:56 -0600 (Wed, 25 Mar 2009)\n\n"
      expect(::File).to receive(:exist?).at_least(1).times.with("/my/deploy/dir/.svn").and_return(true)
      expected_command = ["svn info", { cwd: "/my/deploy/dir", returns: [0, 1] }]
      expect(@provider).to receive(:shell_out!).with(*expected_command)
        .and_return(double("ShellOut result", stdout: example_svn_info, stderr: ""))
      expect(@provider.find_current_revision).to eql("11410")
    end

    it "gives nil as the current revision if the deploy dir isn't a SVN working copy" do
      example_svn_info = "svn: '/tmp/deploydir' is not a working copy\n"
      expect(::File).to receive(:exist?).with("/my/deploy/dir/.svn").and_return(true)
      expected_command = ["svn info", { cwd: "/my/deploy/dir", returns: [0, 1] }]
      expect(@provider).to receive(:shell_out!).with(*expected_command)
        .and_return(double("ShellOut result", stdout: example_svn_info, stderr: ""))
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
      example_svn_info = "Path: .\n" +
        "URL: http://svn.example.org/trunk/myapp\n" +
        "Repository Root: http://svn.example.org\n" +
        "Repository UUID: d62ff500-7bbc-012c-85f1-0026b0e37c24\n" +
        "Revision: 11739\nNode Kind: directory\n" +
        "Schedule: normal\n" +
        "Last Changed Author: codeninja\n" +
        "Last Changed Rev: 11410\n" + # Last Changed Rev is preferred to Revision
        "Last Changed Date: 2009-03-25 06:09:56 -0600 (Wed, 25 Mar 2009)\n\n"
      @resource.revision "HEAD"
      expected_command = ["svn info http://svn.example.org/trunk/ --no-auth-cache  -rHEAD", { cwd: "/my/deploy/dir", returns: [0, 1] }]
      expect(@provider).to receive(:shell_out!).with(*expected_command)
        .and_return(double("ShellOut result", stdout: example_svn_info, stderr: ""))
      expect(@provider.revision_int).to eql("11410")
    end

    it "returns a helpful message if data from `svn info` can't be parsed" do
      example_svn_info =  "some random text from an error message\n"
      @resource.revision "HEAD"
      expected_command = ["svn info http://svn.example.org/trunk/ --no-auth-cache  -rHEAD", { cwd: "/my/deploy/dir", returns: [0, 1] }]
      expect(@provider).to receive(:shell_out!).with(*expected_command)
        .and_return(double("ShellOut result", stdout: example_svn_info, stderr: ""))
      expect { @provider.revision_int }.to raise_error(RuntimeError, "Could not parse `svn info` data: some random text from an error message\n")

    end

    it "responds to :revision_slug as an alias for revision_sha" do
      expect(@provider).to respond_to(:revision_slug)
    end

  end

  it "generates a checkout command with default options" do
    expect(@provider.checkout_command).to eql("svn checkout -q   -r12345 http://svn.example.org/trunk/ /my/deploy/dir")
  end

  it "generates a checkout command with authentication" do
    @resource.svn_username "deployNinja"
    @resource.svn_password "vanish!"
    expect(@provider.checkout_command).to eql("svn checkout -q --username deployNinja --password vanish!   " +
                                          "-r12345 http://svn.example.org/trunk/ /my/deploy/dir")
  end

  it "generates a checkout command with arbitrary options" do
    @resource.svn_arguments "--no-auth-cache"
    expect(@provider.checkout_command).to eql("svn checkout --no-auth-cache -q   -r12345 " + "http://svn.example.org/trunk/ /my/deploy/dir")
  end

  it "generates a sync command with default options" do
    expect(@provider.sync_command).to eql("svn update -q   -r12345 /my/deploy/dir")
  end

  it "generates an export command with default options" do
    expect(@provider.export_command).to eql("svn export --force -q   -r12345 http://svn.example.org/trunk/ /my/deploy/dir")
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
    expected_cmd = "svn export --force -q   -r12345 http://svn.example.org/trunk/ /my/deploy/dir"
    expect(@provider).to receive(:shell_out!).with(expected_cmd, {})
    @provider.run_action(:force_export)
    expect(@resource).to be_updated
  end

  it "runs the checkout command for action_checkout" do
    allow(::File).to receive(:directory?).with("/my/deploy").and_return(true)
    expected_cmd = "svn checkout -q   -r12345 http://svn.example.org/trunk/ /my/deploy/dir"
    expect(@provider).to receive(:shell_out!).with(expected_cmd, {})
    @provider.run_action(:checkout)
    expect(@resource).to be_updated
  end

  it "raises an error if the svn checkout command would fail because the enclosing directory doesn't exist" do
    expect { @provider.run_action(:sync) }.to raise_error(Chef::Exceptions::MissingParentDirectory)
  end

  it "should not checkout if the destination exists or is a non empty directory" do
    allow(::File).to receive(:exist?).with("/my/deploy/dir/.svn").and_return(false)
    allow(::File).to receive(:exist?).with("/my/deploy/dir").and_return(true)
    allow(::File).to receive(:directory?).with("/my/deploy").and_return(true)
    allow(::Dir).to receive(:entries).with("/my/deploy/dir").and_return([".", "..", "foo", "bar"])
    expect(@provider).not_to receive(:checkout_command)
    @provider.run_action(:checkout)
    expect(@resource).not_to be_updated
  end

  it "runs commands with the user and group specified in the resource" do
    allow(::File).to receive(:directory?).with("/my/deploy").and_return(true)
    @resource.user "whois"
    @resource.group "thisis"
    expected_cmd = "svn checkout -q   -r12345 http://svn.example.org/trunk/ /my/deploy/dir"
    expect(@provider).to receive(:get_homedir).and_return("/home/whois")
    expect(@provider).to receive(:shell_out!).with(expected_cmd, { user: "whois", group: "thisis", environment: { "HOME" => "/home/whois" } })
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
    expected_cmd = "svn update -q   -r12345 /my/deploy/dir"
    expect(@provider).to receive(:shell_out!).with(expected_cmd, {})
    @provider.run_action(:sync)
    expect(@resource).to be_updated
  end

  it "does not fetch any updates if the remote revision matches the current revision" do
    allow(::File).to receive(:directory?).with("/my/deploy").and_return(true)
    expect(::File).to receive(:exist?).with("/my/deploy/dir/.svn").and_return(true)
    allow(@provider).to receive(:find_current_revision).and_return("12345")
    allow(@provider).to receive(:current_revision_matches_target_revision?).and_return(true)
    @provider.run_action(:sync)
    expect(@resource).not_to be_updated
  end

  it "runs the export_command on action_export" do
    allow(::File).to receive(:directory?).with("/my/deploy").and_return(true)
    expected_cmd = "svn export --force -q   -r12345 http://svn.example.org/trunk/ /my/deploy/dir"
    expect(@provider).to receive(:shell_out!).with(expected_cmd, {})
    @provider.run_action(:export)
    expect(@resource).to be_updated
  end

  context "selects the correct svn binary" do
    it "selects 'svn' as the binary by default" do
      @resource.svn_binary nil
      allow(ChefUtils).to receive(:windows?) { false }
      expect(@provider).to receive(:svn_binary).and_return("svn")
      expect(@provider.export_command).to eql(
        "svn export --force -q   -r12345 http://svn.example.org/trunk/ /my/deploy/dir"
      )
    end

    it "selects an svn binary with an exe extension on windows" do
      @resource.svn_binary nil
      allow(ChefUtils).to receive(:windows?) { true }
      expect(@provider).to receive(:svn_binary).and_return("svn.exe")
      expect(@provider.export_command).to eql(
        "svn.exe export --force -q   -r12345 http://svn.example.org/trunk/ /my/deploy/dir"
      )
    end

    it "uses a custom svn binary as part of the svn command" do
      @resource.svn_binary "teapot"
      expect(@provider).to receive(:svn_binary).and_return("teapot")
      expect(@provider.export_command).to eql(
        "teapot export --force -q   -r12345 http://svn.example.org/trunk/ /my/deploy/dir"
      )
    end

    it "wraps custom svn binary with quotes if it contains whitespace" do
      @resource.svn_binary "c:/program files (x86)/subversion/svn.exe"
      expect(@provider).to receive(:svn_binary).and_return("c:/program files (x86)/subversion/svn.exe")
      expect(@provider.export_command).to eql(
        '"c:/program files (x86)/subversion/svn.exe" export --force -q   -r12345 http://svn.example.org/trunk/ /my/deploy/dir'
      )
    end

  end

  shared_examples_for "proxied configuration" do
    it "generates a checkout command with a http proxy" do
      expect(@provider.checkout_command).to eql("svn checkout -q" +
        "  --config-option servers:global:http-proxy-host=somehost --config-option servers:global:http-proxy-port=1" +
        "  -r12345 #{repository_url} /my/deploy/dir" )
    end
  end

  describe "when proxy environment variables exist" do
    let(:http_proxy_uri) { "http://somehost:1" }
    let(:http_no_proxy) { "svn.example.org" }

    before(:all) do
      @original_env = ENV.to_hash
    end

    after(:all) do
      ENV.clear
      ENV.update(@original_env)
    end

    context "http_proxy is specified" do
      let(:repository_url) { "http://svn.example.org/trunk/" }

      before do
        ENV["http_proxy"] = http_proxy_uri
      end

      it_should_behave_like "proxied configuration"
    end

    context "https_proxy is specified" do
      let(:repository_url) { "https://svn.example.org/trunk/" }

      before do
        ENV["http_proxy"] = nil
        ENV["https_proxy"] = http_proxy_uri
        @resource.repository "https://svn.example.org/trunk/"
      end

      it_should_behave_like "proxied configuration"
    end

    context "when no_proxy is specified" do
      before do
        ENV["http_proxy"] = http_proxy_uri
        ENV["no_proxy"] = http_no_proxy
      end

      it "generates a checkout command with default options" do
        expect(@provider.checkout_command).to eql("svn checkout -q   -r12345 http://svn.example.org/trunk/ /my/deploy/dir")
      end
    end
  end
end
