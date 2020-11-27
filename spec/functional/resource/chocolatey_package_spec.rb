#
# Author:: Matt Wrock (<matt@mattwrock.com>)
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
require "chef/mixin/shell_out"

describe Chef::Resource::ChocolateyPackage, :windows_only, :choco_installed do
  include Chef::Mixin::ShellOut

  let(:package_name) { "test-A" }
  let(:package_list) { proc { shell_out!("choco list -lo -r #{Array(package_name).join(" ")}").stdout.chomp } }
  let(:package_source) { File.join(CHEF_SPEC_ASSETS, "chocolatey_feed") }

  let(:run_context) do
    Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
  end

  subject do
    new_resource = Chef::Resource::ChocolateyPackage.new("test choco package", run_context)
    new_resource.package_name package_name
    new_resource.source package_source
    new_resource
  end

  let(:provider) do
    provider = subject.provider_for_action(subject.action)
    provider
  end

  context "installing a package" do
    after { remove_package }

    it "installs the latest version" do
      subject.run_action(:install)
      expect(package_list.call).to eq("#{package_name}|2.0")
    end

    it "does not install if already installed" do
      subject.run_action(:install)
      subject.run_action(:install)
      expect(subject).not_to be_updated_by_last_action
    end

    it "installs version given" do
      subject.version "1.0"
      subject.run_action(:install)
      expect(package_list.call).to eq("#{package_name}|1.0")
    end

    it "installs new version if one is already installed" do
      subject.version "1.0"
      subject.run_action(:install)
      expect(package_list.call).to eq("#{package_name}|1.0")

      subject.version "2.0"
      subject.run_action(:install)
      expect(package_list.call).to eq("#{package_name}|2.0")
    end

    context "installing multiple packages" do
      let(:package_name) { %w{test-A test-B} }

      it "installs both packages" do
        subject.run_action(:install)
        expect(package_list.call).to eq("test-A|2.0\r\ntest-B|1.0")
      end
    end

    it "raises if package is not found" do
      subject.package_name "blah"
      expect { subject.run_action(:install) }.to raise_error Chef::Exceptions::Package
    end

    it "installs with an option as a string" do
      subject.options "--force --confirm"
      subject.run_action(:install)
      expect(package_list.call).to eq("#{package_name}|2.0")
    end

    it "installs with multiple options as a string" do
      subject.options "--force --confirm"
      subject.run_action(:install)
      expect(package_list.call).to eq("#{package_name}|2.0")
    end

    context "when multiple options passed as string" do
      before do
        subject.options "--force --confirm"
        subject.source nil
      end

      it "splits a string into an array of options" do
        expect(provider.send(:cmd_args)).to eq(["--force", "--confirm"])
      end

      it "calls command_line_to_argv_w_helper method" do
        expect(provider).to receive(:command_line_to_argv_w_helper).with(subject.options).and_return(["--force", "--confirm"])
        provider.send(:cmd_args)
      end
    end

    context "when multiple options passed as array" do
      it "Does not call command_line_to_argv_w_helper method" do
        subject.options [ "--force", "--confirm" ]
        expect(provider).not_to receive(:command_line_to_argv_w_helper)
        provider.send(:cmd_args)
      end
    end

    it "installs with multiple options as an array" do
      subject.options [ "--force", "--confirm" ]
      subject.run_action(:install)
      expect(package_list.call).to eq("#{package_name}|2.0")
    end
  end

  context "upgrading a package" do
    after { remove_package }

    it "upgrades to a specific version" do
      subject.version "1.0"
      subject.run_action(:install)
      expect(package_list.call).to eq("#{package_name}|1.0")

      subject.version "1.5"
      subject.run_action(:upgrade)
      expect(package_list.call).to eq("#{package_name}|1.5")
    end

    it "upgrades to the latest version if no version given" do
      subject.version "1.0"
      subject.run_action(:install)
      expect(package_list.call).to eq("#{package_name}|1.0")

      subject2 = Chef::Resource::ChocolateyPackage.new("test-A", run_context)
      subject2.source package_source
      subject2.run_action(:upgrade)
      expect(package_list.call).to eq("#{package_name}|2.0")
    end
  end

  context "removing a package" do
    it "removes an installed package" do
      subject.run_action(:install)
      remove_package
      expect(package_list.call).to eq("")
    end
  end

  def remove_package
    pkg_to_remove = Chef::Resource::ChocolateyPackage.new(package_name, run_context)
    pkg_to_remove.source = package_source
    pkg_to_remove.run_action(:remove)
  end
end
