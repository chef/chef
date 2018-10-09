# Author:: S.Cavallo (smcavallo@hotmail.com)
# Copyright 2014-2018, Chef Software, Inc. <legal@chef.io>
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
require 'chef/provider/package'
require 'chef/provider/package/snap'
require 'json'

describe Chef::Provider::Package::Snap do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:package) { "hello" }
  let(:source) { "/tmp/hello_20.snap" }
  let(:new_resource) do
    new_resource = Chef::Resource::SnapPackage.new(package)
    new_resource.source source
    new_resource
  end
  let(:provider) { Chef::Provider::Package::Snap.new(new_resource, run_context) }
  let(:snap_status) do
    stdout = <<~SNAP_S
      path:    "/tmp/hello_20.snap"
      name:    hello
      summary: GNU Hello, the "hello world" snap
      version: 2.10 -
    SNAP_S
    status = double(stdout: stdout, stderr: "", exitstatus: 0)
    allow(status).to receive(:error!).with(no_args).and_return(false)
    status
  end

  before(:each) do
    allow(provider).to receive(:shell_out_compacted!).with("snap", "info", source, timeout: 900).and_return(snap_status)
  end

  # Example output from https://github.com/snapcore/snapd/wiki/REST-API
  find_result_success = JSON.parse({"type" => "sync", "status-code" => 200, "status" => "OK", "result" => [{"id" => "mVyGrEwiqSi5PugCwyH7WgpoQLemtTd6", "title" => "hello", "summary" => "GNU Hello, the \"hello world\" snap", "description" => "GNU hello prints a friendly greeting. This is part of the snapcraft tour at https://snapcraft.io/", "download-size" => 65536, "name" => "hello", "publisher" => {"id" => "canonical", "username" => "canonical", "display-name" => "Canonical", "validation" => "verified"}, "developer" => "canonical", "status" => "available", "type" => "app", "version" => "2.10", "channel" => "stable", "ignore-validation" => false, "revision" => "20", "confinement" => "strict", "private" => false, "devmode" => false, "jailmode" => false, "contact" => "mailto:snaps@canonical.com", "license" => "GPL-3.0", "channels" => {"latest/beta" => {"revision" => "29", "confinement" => "strict", "version" => "2.10.1", "channel" => "beta", "epoch" => "0", "size" => 65536}, "latest/candidate" => {"revision" => "20", "confinement" => "strict", "version" => "2.10", "channel" => "candidate", "epoch" => "0", "size" => 65536}, "latest/edge" => {"revision" => "34", "confinement" => "strict", "version" => "2.10.42", "channel" => "edge", "epoch" => "0", "size" => 65536}, "latest/stable" => {"revision" => "20", "confinement" => "strict", "version" => "2.10", "channel" => "stable", "epoch" => "0", "size" => 65536}}, "tracks" => ["latest"]}], "sources" => ["store"], "suggested-currency" => "USD"}.to_json)
  find_result_fail = JSON.parse({"type" => "error", "status-code" => 404, "status" => "Not Found", "result" => {"message" => "snap not found", "kind" => "snap-not-found", "value" => "hello2"}}.to_json)
  get_by_name_result_success = JSON.parse({"type" => "sync", "status-code" => 200, "status" => "OK", "result" => {"id" => "CRrJViJiSuDcCkU31G0xpNRVNaj4P960", "summary" => "Universal Command Line Interface for Amazon Web Services", "description" => "This package provides a unified command line interface to Amazon Web\nServices.\n", "installed-size" => 15851520, "name" => "aws-cli", "publisher" => {"id" => "S7iQ7mKDXBDliQqRcgefvc2TKXIH9pYk", "username" => "aws", "display-name" => "Amazon Web Services", "validation" => "verified"}, "developer" => "aws", "status" => "active", "type" => "app", "version" => "1.15.71", "channel" => "", "tracking-channel" => "stable", "ignore-validation" => false, "revision" => "135", "confinement" => "classic", "private" => false, "devmode" => false, "jailmode" => false, "apps" => [{"snap" => "aws-cli", "name" => "aws"}], "contact" => "", "mounted-from" => "/var/lib/snapd/snaps/aws-cli_135.snap", "install-date" => "2018-09-17T20:39:38.516Z"}}.to_json)
  get_by_name_result_fail = JSON.parse({"type" => "error", "status-code" => 404, "status" => "Not Found", "result" => {"message" => "snap not installed", "kind" => "snap-not-found", "value" => "aws-cliasdfasdf"}}.to_json)
  async_result_success = JSON.parse({
                                        "type" => "async",
                                        "status-code" => 202,
                                        "status" => "Accepted",
                                        "change" => "401"
                                    }.to_json)
  result_fail = JSON.parse({
                               "type" => "error",
                               "status-code" => 401,
                               "status" => "Unauthorized",
                               "result" => {
                                   "message" => "access denied",
                                   "kind" => "login-required",
                               }
                           }.to_json)

  change_id_result = JSON.parse({"type" => "sync", "status-code" => 200, "status" => "OK", "result" => {"id" => "15", "kind" => "install-snap", "summary" => "Install snap \"hello\"", "status" => "Done", "tasks" => [{"id" => "165", "kind" => "prerequisites", "summary" => "Ensure prerequisites for \"hello\" are available", "status" => "Done", "progress" => {"label" => "", "done" => 1, "total" => 1}, "spawn-time" => "2018-09-22T20:25:25.22104314Z", "ready-time" => "2018-09-22T20:25:25.231090966Z"}, {"id" => "166", "kind" => "download-snap", "summary" => "Download snap \"hello\" (20) from channel \"stable\"", "status" => "Done", "progress" => {"label" => "", "done" => 1, "total" => 1}, "spawn-time" => "2018-09-22T20:25:25.221070859Z", "ready-time" => "2018-09-22T20:25:25.24321909Z"}, {"id" => "167", "kind" => "validate-snap", "summary" => "Fetch and check assertions for snap \"hello\" (20)", "status" => "Done", "progress" => {"label" => "", "done" => 1, "total" => 1}, "spawn-time" => "2018-09-22T20:25:25.221080163Z", "ready-time" => "2018-09-22T20:25:25.55308904Z"}, {"id" => "168", "kind" => "mount-snap", "summary" => "Mount snap \"hello\" (20)", "status" => "Done", "progress" => {"label" => "", "done" => 1, "total" => 1}, "spawn-time" => "2018-09-22T20:25:25.221082984Z", "ready-time" => "2018-09-22T20:25:25.782452658Z"}, {"id" => "169", "kind" => "copy-snap-data", "summary" => "Copy snap \"hello\" data", "status" => "Done", "progress" => {"label" => "", "done" => 1, "total" => 1}, "spawn-time" => "2018-09-22T20:25:25.221085677Z", "ready-time" => "2018-09-22T20:25:25.790911883Z"}, {"id" => "170", "kind" => "setup-profiles", "summary" => "Setup snap \"hello\" (20) security profiles", "status" => "Done", "progress" => {"label" => "", "done" => 1, "total" => 1}, "spawn-time" => "2018-09-22T20:25:25.221088261Z", "ready-time" => "2018-09-22T20:25:25.972796111Z"}, {"id" => "171", "kind" => "link-snap", "summary" => "Make snap \"hello\" (20) available to the system", "status" => "Done", "progress" => {"label" => "", "done" => 1, "total" => 1}, "spawn-time" => "2018-09-22T20:25:25.221090669Z", "ready-time" => "2018-09-22T20:25:25.986931331Z"}, {"id" => "172", "kind" => "auto-connect", "summary" => "Automatically connect eligible plugs and slots of snap \"hello\"", "status" => "Done", "progress" => {"label" => "", "done" => 1, "total" => 1}, "spawn-time" => "2018-09-22T20:25:25.221093357Z", "ready-time" => "2018-09-22T20:25:25.996914144Z"}, {"id" => "173", "kind" => "set-auto-aliases", "summary" => "Set automatic aliases for snap \"hello\"", "status" => "Done", "progress" => {"label" => "", "done" => 1, "total" => 1}, "spawn-time" => "2018-09-22T20:25:25.221097651Z", "ready-time" => "2018-09-22T20:25:26.009155888Z"}, {"id" => "174", "kind" => "setup-aliases", "summary" => "Setup snap \"hello\" aliases", "status" => "Done", "progress" => {"label" => "", "done" => 1, "total" => 1}, "spawn-time" => "2018-09-22T20:25:25.221100379Z", "ready-time" => "2018-09-22T20:25:26.021062388Z"}, {"id" => "175", "kind" => "run-hook", "summary" => "Run install hook of \"hello\" snap if present", "status" => "Done", "progress" => {"label" => "", "done" => 1, "total" => 1}, "spawn-time" => "2018-09-22T20:25:25.221103116Z", "ready-time" => "2018-09-22T20:25:26.031383884Z"}, {"id" => "176", "kind" => "start-snap-services", "summary" => "Start snap \"hello\" (20) services", "status" => "Done", "progress" => {"label" => "", "done" => 1, "total" => 1}, "spawn-time" => "2018-09-22T20:25:25.221110251Z", "ready-time" => "2018-09-22T20:25:26.039564637Z"}, {"id" => "177", "kind" => "run-hook", "summary" => "Run configure hook of \"hello\" snap if present", "status" => "Done", "progress" => {"label" => "", "done" => 1, "total" => 1}, "spawn-time" => "2018-09-22T20:25:25.221115952Z", "ready-time" => "2018-09-22T20:25:26.05069451Z"}], "ready" => true, "spawn-time" => "2018-09-22T20:25:25.221130149Z", "ready-time" => "2018-09-22T20:25:26.050696298Z", "data" => {"snap-names" => ["hello"]}}}.to_json)

  get_conf_success  = JSON.parse({"type" => "sync", "status-code" => 200, "status" => "OK", "result" =>{"address" =>"0.0.0.0","allow-privileged" =>true,"anonymous-auth" => false}}.to_json)

  describe "#define_resource_requirements" do

    before do
      allow_any_instance_of(Chef::Provider::Package::Snap).to receive(:call_snap_api).with('GET', "/v2/snaps/#{package}").and_return(get_by_name_result_success)
    end

    it "should raise an exception if a source is supplied but not found when :install" do
      allow(::File).to receive(:exist?).with(source).and_return(false)
      expect { provider.run_action(:install) }.to raise_error(Chef::Exceptions::Package)
    end

    it "should raise an exception if a source is supplied but not found when :upgrade" do
      allow(::File).to receive(:exist?).with(source).and_return(false)
      expect { provider.run_action(:upgrade) }.to raise_error(Chef::Exceptions::Package)
    end
  end

  describe "when using a local file source" do
    let(:source) { '/tmp/hello_20.snap' }

    before do
      allow_any_instance_of(Chef::Provider::Package::Snap).to receive(:call_snap_api).with('GET', "/v2/snaps/#{package}").and_return(get_by_name_result_success)
    end

    it "should create a current resource with the name of the new_resource" do
      provider.load_current_resource
      expect(provider.current_resource.package_name).to eq("hello")
    end

    describe "gets the candidate version from the source package" do

      def check_version(version)
        provider.load_current_resource
        expect(provider.current_resource.package_name).to eq("hello")
        expect(provider.get_current_versions).to eq(["1.15.71"])
        expect(provider.candidate_version).to eq([version])
      end

      it "checks the installed and local candidate versions" do
        check_version("2.10")
      end
    end
  end

  describe "when using the snap store" do
    let(:source) { nil }
    describe "gets the candidate version from the snap store" do
      before do
        allow_any_instance_of(Chef::Provider::Package::Snap).to receive(:call_snap_api).with('GET', "/v2/find?name=#{package}").and_return(find_result_success)
        allow_any_instance_of(Chef::Provider::Package::Snap).to receive(:call_snap_api).with('GET', "/v2/snaps/#{package}").and_return(get_by_name_result_success)
      end

      def check_version(version)
        provider.load_current_resource
        expect(provider.current_resource.package_name).to eq("hello")
        expect(provider.get_current_versions).to eq(["1.15.71"])
        expect(provider.candidate_version).to eq([version])
      end

      it "checks the installed and store candidate versions" do
        check_version("2.10")
      end

    end

    describe "fails to get the candidate version from the snap store" do
      before do
        allow_any_instance_of(Chef::Provider::Package::Snap).to receive(:call_snap_api).with('GET', "/v2/find?name=#{package}").and_return(find_result_fail)
        allow_any_instance_of(Chef::Provider::Package::Snap).to receive(:call_snap_api).with('GET', "/v2/snaps/#{package}").and_return(get_by_name_result_fail)
      end

      it "throws an error if candidate version not found" do
        provider.load_current_resource
        expect{provider.candidate_version}.to raise_error(Chef::Exceptions::Package)
      end

      it "does not throw an error if installed version not found" do
        provider.load_current_resource
        expect(provider.get_current_versions).to eq([nil])
      end
    end
  end

  describe "when calling async operations" do

    it "should should throw if the async response is an error" do
      expect { provider.send(:get_id_from_async_response, result_fail) }.to raise_error
    end

    it "should get the id from an async response" do
      result = provider.send(:get_id_from_async_response, async_result_success)
      expect(result).to eq("401")
    end

    it "should wait for change completion" do
      result = provider.send(:get_id_from_async_response, async_result_success)
      expect(result).to eq("401")
    end
  end

  describe Chef::Provider::Package::Snap do

    it "should post the correct json" do
      snap_names = ['hello']
      action = 'install'
      channel = 'stable'
      options = {}
      revision = nil
      actual = provider.send(:generate_snap_json, snap_names, action, channel, options, revision)

      expect(actual).to eq({"action" => "install", "snaps" => ["hello"], "channel" => "stable"})
    end

  end
end
