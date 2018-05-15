#
# Author:: Mal Graty (<mal.graty@googlemail.com>)
# Copyright:: Copyright 2014-2017, Chef Software, Inc
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

describe Chef::Resource::File::Verification::SystemdUnit do
  let(:command) { "#{systemd_analyze_path} verify %{path}" }
  let(:opts) { { :future => true } }
  let(:parent_resource) { Chef::Resource.new("llama") }
  let(:systemd_analyze_path) { "/usr/bin/systemd-analyze" }
  let(:systemd_dir) { "/etc/systemd/system" }
  let(:temp_path) { "/tmp" }
  let(:unit_name) { "sysstat-collect.timer" }
  let(:unit_path) { "#{systemd_dir}/#{unit_name}" }
  let(:unit_temp_path) { "#{systemd_dir}/.chef-#{unit_name}" }
  let(:unit_test_path) { "#{temp_path}/#{unit_name}" }

  describe "verification registration" do
    it "registers itself for later use" do
      expect(Chef::Resource::File::Verification.lookup(:systemd_unit)).to eq(Chef::Resource::File::Verification::SystemdUnit)
    end
  end

  describe "#initialize" do
    before(:each) do
      allow_any_instance_of(Chef::Resource::File::Verification::SystemdUnit).to receive(:which)
        .with("systemd-analyze")
        .and_return(systemd_analyze_path)
    end

    it "overwrites the @command variable with the verification command" do
      v = Chef::Resource::File::Verification::SystemdUnit.new(parent_resource, :systemd_unit, {})
      expect(v.instance_variable_get(:@command)).to eql(command)
    end
  end

  describe "#verify" do
    context "with the systemd-analyze binary available" do
      before(:each) do
        allow_any_instance_of(Chef::Resource::File::Verification::SystemdUnit).to receive(:which)
          .with("systemd-analyze")
          .and_return(systemd_analyze_path)

        allow(parent_resource).to receive(:path)
          .and_return(unit_path)
        allow(Dir).to receive(:mktmpdir)
          .with("chef-systemd-unit") { |&b| b.call temp_path }
        allow(FileUtils).to receive(:cp)
          .with(unit_temp_path, unit_test_path)
      end

      it "copies the temp file to secondary location under correct name" do
        v = Chef::Resource::File::Verification::SystemdUnit.new(parent_resource, :systemd_unit, {})

        expect(FileUtils).to receive(:cp).with(unit_temp_path, unit_test_path)
        expect(v).to receive(:verify_command).with(unit_test_path, opts)

        v.verify(unit_temp_path, opts)
      end

      it "returns the value given by #verify_command" do
        v = Chef::Resource::File::Verification::SystemdUnit.new(parent_resource, :systemd_unit, {})

        expect(v).to receive(:verify_command)
          .with(unit_test_path, opts)
          .and_return("foo")

        expect(v.verify(unit_temp_path, opts)).to eql("foo")
      end
    end

    context "with the systemd-analyze binary unavailable" do
      before(:each) do
        allow_any_instance_of(Chef::Resource::File::Verification::SystemdUnit).to receive(:which)
          .with("systemd-analyze")
          .and_return(false)
      end

      it "skips verification" do
        v = Chef::Resource::File::Verification::SystemdUnit.new(parent_resource, :systemd_unit, {})

        expect(v).to_not receive(:verify_command)

        expect(v.verify(unit_temp_path)).to eq(true)
      end
    end
  end
end
