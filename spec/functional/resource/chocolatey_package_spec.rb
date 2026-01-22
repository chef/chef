#
# Author:: Matt Wrock (<matt@mattwrock.com>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
  let(:package_source) { File.join(CHEF_SPEC_ASSETS, "chocolatey_feed") }
  let(:package_list) do
    if provider.query_command == "list"
      # using result of query_command because that indicates which "search" command to use
      # which coincides with the package list output
      proc { shell_out!("choco search -lo #{Array(package_name).join(" ")}").stdout.chomp }
    else
      proc { shell_out!("choco list #{Array(package_name).join(" ")}").stdout.chomp }
    end
  end

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

  # This bit of magic ensures that we pass a mixed-case Path var in the env to chocolatey and not PATH
  # (both ENV["PATH"] and ENV["Path"] are the same thing in ruby-on-windows, and the first created key
  # is the one that is actually passed to a subprocess, and choco demands it be Path)
  #
  # This is not a no-op.
  #
  # I don't know how to tell what state we were in to begin with, so we cannot restore.  Nothing else
  # seems to care.
  #
  before(:all) do
    ENV["Path"] = ENV.delete("Path")
  end

  after(:each) do
    provider.instance_variable_set(:@get_choco_version, nil)
  end

  context "installing a package" do
    after { remove_package }

    it "installs the latest version" do
      subject.run_action(:install)
      expect(package_list.call).to match(/^#{package_name}|2.0.0$/)
    end

    it "does not install if already installed" do
      subject.run_action(:install)
      subject.run_action(:install)
      expect(subject).not_to be_updated_by_last_action
    end

    it "installs version given" do
      subject.version "1.0.0"
      subject.run_action(:install)
      expect(package_list.call).to match(/^#{package_name}|1.0.0$/)
    end

    it "installs new version if one is already installed" do
      subject.version "1.0.0"
      subject.run_action(:install)
      expect(package_list.call).to match(/^#{package_name}|1.0.0$/)

      subject.version "2.0.0"
      subject.run_action(:install)
      expect(package_list.call).to match(/^#{package_name}|2.0.0$/)
    end

    context "installing multiple packages" do
      let(:package_name) { %w{test-A test-B} }

      it "installs both packages" do
        subject.run_action(:install)
        expect(package_list.call).to match(/^test-A|2.0.0\r\ntest-B|1.0.0$/)
      end
    end

    it "raises if package is not found" do
      subject.package_name "blah"
      expect { subject.run_action(:install) }.to raise_error Chef::Exceptions::Package
    end

    it "installs with an option as a string" do
      subject.options "--force --confirm"
      subject.run_action(:install)
      expect(package_list.call).to match(/^#{package_name}|2.0.0$/)
    end

    it "installs with multiple options as a string" do
      subject.options "--force --confirm"
      subject.run_action(:install)
      expect(package_list.call).to match(/^#{package_name}|2.0.0$/)
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
      expect(package_list.call).to match(/^#{package_name}|2.0.0$/)
    end
  end

  context "upgrading a package" do
    after { remove_package }

    it "upgrades to a specific version" do
      subject.version "1.0.0"
      subject.run_action(:install)
      expect(package_list.call).to match(/^#{package_name}|1.0.0$/)

      subject.version "1.5.0"
      subject.run_action(:upgrade)
      expect(package_list.call).to match(/^#{package_name}|1.5.0$/)
    end

    it "upgrades to the latest version if no version given" do
      subject.version "1.0.0"
      subject.run_action(:install)
      expect(package_list.call).to match(/^#{package_name}|1.0.0$/)

      subject2 = Chef::Resource::ChocolateyPackage.new("test-A", run_context)
      subject2.source package_source
      subject2.run_action(:upgrade)
      expect(package_list.call).to match(/^#{package_name}|2.0.0$/)
    end
  end

  context "removing a package" do
    it "removes an installed package" do
      subject.run_action(:install)
      remove_package
      expect(package_list.call).to match(/0 packages installed/)
    end
  end

  def remove_package
    pkg_to_remove = Chef::Resource::ChocolateyPackage.new(package_name, run_context)
    pkg_to_remove.source = package_source
    pkg_to_remove.run_action(:remove)
  end
end
