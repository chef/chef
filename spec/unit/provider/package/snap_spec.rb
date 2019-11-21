# Author:: S.Cavallo (smcavallo@hotmail.com)
# Copyright 2014-2018, Chef Software Inc. <legal@chef.io>
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
require "chef/provider/package"
require "chef/provider/package/snap"
require "json"

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
  find_result_success = JSON.parse(File.read(File.join(CHEF_SPEC_DATA, "snap_package", "find_result_success.json")))
  find_result_fail = JSON.parse(File.read(File.join(CHEF_SPEC_DATA, "snap_package", "find_result_failure.json")))
  get_by_name_result_success = JSON.parse(File.read(File.join(CHEF_SPEC_DATA, "snap_package", "get_by_name_result_success.json")))
  get_by_name_result_fail = JSON.parse(File.read(File.join(CHEF_SPEC_DATA, "snap_package", "get_by_name_result_failure.json")))
  async_result_success = JSON.parse(File.read(File.join(CHEF_SPEC_DATA, "snap_package", "async_result_success.json")))
  result_fail = JSON.parse(File.read(File.join(CHEF_SPEC_DATA, "snap_package", "result_failure.json")))
  refresh_result_fail = JSON.parse(File.read(File.join(CHEF_SPEC_DATA, "snap_package", "refresh_result_failure.json")))
  change_id_result = JSON.parse(File.read(File.join(CHEF_SPEC_DATA, "snap_package", "change_id_result.json")))
  get_conf_success = JSON.parse(File.read(File.join(CHEF_SPEC_DATA, "snap_package", "get_conf_success.json")))

  describe "#define_resource_requirements" do

    before do
      allow_any_instance_of(Chef::Provider::Package::Snap).to receive(:call_snap_api).with("GET", "/v2/snaps/#{package}").and_return(get_by_name_result_success)
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
    let(:source) { "/tmp/hello_20.snap" }

    before do
      allow_any_instance_of(Chef::Provider::Package::Snap).to receive(:call_snap_api).with("GET", "/v2/snaps/#{package}").and_return(get_by_name_result_success)
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

      it "generates multipart form data" do
        expected = <<~SNAP_S
          Host:
          Content-Type: multipart/form-data; boundary=foo
          Content-Length: 20480

          --foo
          Content-Disposition: form-data; name="action"

          install
          --foo
          Content-Disposition: form-data; name="devmode"

          true
          --foo
          Content-Disposition: form-data; name="snap"; filename="hello-world_27.snap"

          <20480 bytes of snap file data>
          --foo
        SNAP_S

        options = {}
        options["devmode"] = true
        path = "hello-world_27.snap"
        content_length = "20480"

        result = provider.send(:generate_multipart_form_data, "foo", "install", options, path, content_length)

        expect(result).to eq(expected)

      end

    end
  end

  describe "when using the snap store" do
    let(:source) { nil }
    describe "gets the candidate version from the snap store" do
      before do
        allow_any_instance_of(Chef::Provider::Package::Snap).to receive(:call_snap_api).with("GET", "/v2/find?name=#{package}").and_return(find_result_success)
        allow_any_instance_of(Chef::Provider::Package::Snap).to receive(:call_snap_api).with("GET", "/v2/snaps/#{package}").and_return(get_by_name_result_success)
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
        allow_any_instance_of(Chef::Provider::Package::Snap).to receive(:call_snap_api).with("GET", "/v2/find?name=#{package}").and_return(find_result_fail)
        allow_any_instance_of(Chef::Provider::Package::Snap).to receive(:call_snap_api).with("GET", "/v2/snaps/#{package}").and_return(get_by_name_result_fail)
      end

      it "throws an error if candidate version not found" do
        provider.load_current_resource
        expect { provider.candidate_version }.to raise_error(Chef::Exceptions::Package)
      end

      it "does not throw an error if installed version not found" do
        provider.load_current_resource
        expect(provider.get_current_versions).to eq([nil])
      end
    end
  end

  describe "when calling async operations" do

    it "should should throw if the async response is an error" do
      expect { provider.send(:get_id_from_async_response, result_fail) }.to raise_error(RuntimeError)
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
      snap_names = ["hello"]
      action = "install"
      channel = "stable"
      options = []
      revision = nil
      actual = provider.send(:generate_snap_json, action, channel, options, revision)

      expect(actual).to eq("{\"action\":\"install\",\"channel\":\"stable\"}")
    end
  end

  describe "when source is not supplied" do
    let(:source) { nil }
    before do
      allow_any_instance_of(Chef::Provider::Package::Snap).to receive(:call_snap_api).with("GET", "/v2/find?name=#{package}").and_return(find_result_success)
      allow_any_instance_of(Chef::Provider::Package::Snap).to receive(:call_snap_api).with("GET", "/v2/snaps/#{package}").and_return(get_by_name_result_success)
      allow_any_instance_of(Chef::Provider::Package::Snap).to receive(:call_snap_api).with("GET", "/v2/changes/401").and_return(change_id_result)
      allow(provider).to receive(:get_installed_package_version_by_name).and_return(nil)
      allow(provider).to receive(:get_latest_package_version).and_return("2.10")
    end

    describe "#action_install" do
      before do
        allow_any_instance_of(Chef::Provider::Package::Snap).to receive(:call_snap_api).with("POST", "/v2/snaps/#{package}", "{\"action\":\"install\",\"channel\":\"stable\"}").and_return(async_result_success)
        provider.load_current_resource
      end

      context "When package is not installed" do
        it "calls install_package method" do
          expect(provider).to receive(:install_package)
          provider.run_action(:install)
        end

        it "does not raise an exception" do
          expect { provider.run_action(:install) }.not_to raise_error
        end
      end

      context "When package is installed" do
        it "does not call install_package method" do
          allow(provider).to receive(:get_installed_package_version_by_name).and_return("2.10")
          expect(provider).not_to receive(:install_package)
          provider.run_action(:install)
        end

        it "does not raise an exception" do
          expect { provider.run_action(:install) }.not_to raise_error
        end
      end
    end

    describe "#action_upgrade" do
      context "When package is installed" do
        before do
          allow_any_instance_of(Chef::Provider::Package::Snap).to receive(:call_snap_api).with("POST", "/v2/snaps/#{package}", "{\"action\":\"refresh\",\"channel\":\"stable\"}").and_return(async_result_success)
          allow(provider).to receive(:get_current_versions).and_return("1.5")
          allow(provider).to receive(:candidate_version).and_return("2.10")
          provider.load_current_resource
        end

        it "calls upgrade_package" do
          expect(provider).to receive(:upgrade_package)
          provider.run_action(:upgrade)
        end

        it "does not raise an exception" do
          expect { provider.run_action(:upgrade) }.not_to raise_error
        end
      end

      context "When package is not installed" do
        before do
          allow_any_instance_of(Chef::Provider::Package::Snap).to receive(:call_snap_api).with("POST", "/v2/snaps/#{package}", "{\"action\":\"refresh\",\"channel\":\"stable\"}").and_return(refresh_result_fail)
          allow(provider).to receive(:get_current_versions).and_return(nil)
          provider.load_current_resource
        end

        it "does not call upgrade_package" do
          expect(provider).to receive(:upgrade_package)
          provider.run_action(:upgrade)
        end

        it "raises an exception" do
          expect { provider.run_action(:upgrade) }.to raise_error(RuntimeError)
        end
      end
    end

    describe "#action_remove" do
      context "When package is installed" do
        before do
          allow_any_instance_of(Chef::Provider::Package::Snap).to receive(:call_snap_api).with("POST", "/v2/snaps/#{package}", "{\"action\":\"remove\"}").and_return(async_result_success)
          allow(provider).to receive(:get_installed_package_version_by_name).and_return("2.10")
          provider.load_current_resource
        end

        it "calls remove_package" do
          expect(provider).to receive(:remove_package)
          provider.run_action(:remove)
        end

        it "does not raise an exception" do
          expect { provider.run_action(:remove) }.not_to raise_error
        end
      end

      context "When package is not installed" do
        it "does not call remove_package" do
          provider.load_current_resource
          expect(provider).not_to receive(:remove_package)
          expect { provider.run_action(:remove) }.not_to raise_error
        end

        it "does not raise an exception" do
          provider.load_current_resource
          expect { provider.run_action(:remove) }.not_to raise_error
        end
      end
    end
  end
end
