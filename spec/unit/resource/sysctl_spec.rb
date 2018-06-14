#
# Copyright:: Copyright 2018, Chef Software, Inc.
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

describe Chef::Resource::Sysctl do
  include ::ChefSpec::API
  step_into :sysctl
  platform "ubuntu"

  stubs_for_current_resource("sysctl[fakey_fakerton]") do |res|
    allow(res).to receive_shell_out("sysctl -n -e fakey_fakerton")
  end

  before do
    allow(File).to receive(:exist?).and_call_original
  end

  context "with a simple sysctl" do
    recipe do
      sysctl "fakey_fakerton" do
        value "teapot"
      end
    end

    stubs_for_provider("sysctl[fakey_fakerton]") do |prov|
      expect(prov).to receive_shell_out('sysctl -w "fakey_fakerton=teapot"')
    end

    it { is_expected.to apply_sysctl("fakey_fakerton").with(value: "teapot") }
    it { is_expected.to render_file("/etc/sysctl.d/99-chef-fakey_fakerton.conf").with_content("fakey_fakerton = teapot") }
    it { is_expected.to run_execute("Load sysctl values").with_command("sysctl -p") }
  end

  context "with an array value" do
    recipe do
      sysctl "fakey_fakerton" do
        value [1, 2, 3]
      end
    end

    stubs_for_provider("sysctl[fakey_fakerton]") do |prov|
      expect(prov).to receive_shell_out('sysctl -w "fakey_fakerton=1 2 3"')
    end

    it { is_expected.to apply_sysctl("fakey_fakerton").with(value: "1 2 3") }
    it { is_expected.to render_file("/etc/sysctl.d/99-chef-fakey_fakerton.conf").with_content("fakey_fakerton = 1 2 3") }
  end

  context "with an integer value" do
    recipe do
      sysctl "fakey_fakerton" do
        value 1
      end
    end

    stubs_for_provider("sysctl[fakey_fakerton]") do |prov|
      expect(prov).to receive_shell_out('sysctl -w "fakey_fakerton=1"')
    end

    it { is_expected.to apply_sysctl("fakey_fakerton").with(value: "1") }
    it { is_expected.to render_file("/etc/sysctl.d/99-chef-fakey_fakerton.conf").with_content("fakey_fakerton = 1") }
  end

  context "with a float value" do
    recipe do
      sysctl "fakey_fakerton" do
        value 1.1
      end
    end

    stubs_for_provider("sysctl[fakey_fakerton]") do |prov|
      expect(prov).to receive_shell_out('sysctl -w "fakey_fakerton=1.1"')
    end

    it { is_expected.to apply_sysctl("fakey_fakerton").with(value: "1.1") }
    it { is_expected.to render_file("/etc/sysctl.d/99-chef-fakey_fakerton.conf").with_content("fakey_fakerton = 1.1") }
  end

  context "with ignore_error" do
    recipe do
      sysctl "fakey_fakerton" do
        value "teapot"
        ignore_error true
      end
    end

    stubs_for_provider("sysctl[fakey_fakerton]") do |prov|
      expect(prov).to receive_shell_out('sysctl -e -w "fakey_fakerton=teapot"')
    end

    it { is_expected.to run_execute("Load sysctl values").with_command("sysctl -e -p") }
  end

  context "with action :remove" do
    recipe do
      sysctl "fakey_fakerton" do
        action :remove
      end
    end

    context "with an existing file" do
      before { allow(File).to receive(:exist?).with("/etc/sysctl.d/99-chef-fakey_fakerton.conf").and_return(true) }
      it { is_expected.to delete_file("/etc/sysctl.d/99-chef-fakey_fakerton.conf") }
      it { is_expected.to run_execute("Load sysctl values").with_command("sysctl -p") }
    end

    context "without an existing file" do
      before { allow(File).to receive(:exist?).with("/etc/sysctl.d/99-chef-fakey_fakerton.conf").and_return(false) }
      it { is_expected.to_not delete_file("/etc/sysctl.d/99-chef-fakey_fakerton.conf") }
      it { is_expected.to_not run_execute("Load sysctl values") }
    end

  end
end
