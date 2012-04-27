#
# Author:: David Balatero (<dbalatero@gmail.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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

describe Chef::Provider::Package::Macports do
  include SpecHelpers::Providers::Package

  let(:package_name) { 'zsh' }
  let(:pid) { 2342 }

  describe "#load_current_resource" do
    it "should create a current resource with the name of the new_resource" do
      provider.should_receive(:current_installed_version).and_return(nil)
      provider.should_receive(:macports_candidate_version).and_return("4.2.7")

      provider.load_current_resource
      provider.current_resource.name.should == "zsh"
    end

    it "should create a current resource with the version if the package is installed" do
      provider.should_receive(:macports_candidate_version).and_return("4.2.7")
      provider.should_receive(:current_installed_version).and_return("4.2.7")

      provider.load_current_resource
      provider.candidate_version.should == "4.2.7"
    end

    it "should create a current resource with a nil version if the package is not installed" do
      provider.should_receive(:current_installed_version).and_return(nil)
      provider.should_receive(:macports_candidate_version).and_return("4.2.7")
      provider.load_current_resource
      provider.current_resource.version.should be_nil
    end

    it "should set a candidate version if one exists" do
      provider.should_receive(:current_installed_version).and_return(nil)
      provider.should_receive(:macports_candidate_version).and_return("4.2.7")
      provider.load_current_resource
      provider.candidate_version.should == "4.2.7"
    end
  end

  describe "#current_installed_version" do
    context 'with installed package' do
      let(:stdout) { <<-EOF }
The following ports are currently installed:
  openssl @0.9.8k_0 (active)
EOF

      it "should return the current version if the package is installed" do
        should_shell_out!
        provider.current_installed_version.should == "0.9.8k_0"
      end
    end

    context 'without installed package' do
      let(:stdout) { "       \n" }

      it "should return nil if a package is not currently installed" do
        should_shell_out!
        provider.current_installed_version.should be_nil
      end
    end
  end

  describe "#macports_candidate_version" do
    context 'with candidate version' do
      let(:stdout) { "version: 4.2.7\n" }

      it "should return the latest available version of a given package" do
        should_shell_out!
        provider.macports_candidate_version.should == "4.2.7"
      end
    end

    context 'without candidate version' do
      let(:stdout) { "Error: port fadsfadsfads not found\n" }

      it "should return nil if there is no version for a given package" do
        should_shell_out!
        provider.macports_candidate_version.should be_nil
      end
    end
  end

  describe "#install_package" do
    it "should run the port install command with the correct version" do
      current_resource.should_receive(:version).and_return("4.1.6")
      provider.current_resource = current_resource
      provider.should_receive(:shell_out_with_systems_locale!).with("port install zsh @4.2.7")

      provider.install_package("zsh", "4.2.7")
    end

    it "should not do anything if a package already exists with the same version" do
      current_resource.should_receive(:version).and_return("4.2.7")
      provider.current_resource = current_resource
      provider.should_not_receive(:shell_out_with_systems_locale!)

      provider.install_package("zsh", "4.2.7")
    end

    it "should add options to the port command when specified" do
      current_resource.should_receive(:version).and_return("4.1.6")
      provider.current_resource = current_resource
      new_resource.stub!(:options).and_return("-f")
      provider.should_receive(:shell_out_with_systems_locale!).with("port -f install zsh @4.2.7")

      provider.install_package("zsh", "4.2.7")
    end
  end

  describe "#purge_package" do
    it "should run the port uninstall command with the correct version" do
      provider.should_receive(:shell_out_with_systems_locale!).with("port uninstall zsh @4.2.7")
      provider.purge_package("zsh", "4.2.7")
    end

    it "should purge the currently active version if no explicit version is passed in" do
      provider.should_receive(:shell_out_with_systems_locale!).with("port uninstall zsh")
      provider.purge_package("zsh", nil)
    end

    it "should add options to the port command when specified" do
      new_resource.stub!(:options).and_return("-f")
      provider.should_receive(:shell_out_with_systems_locale!).with("port -f uninstall zsh @4.2.7")
      provider.purge_package("zsh", "4.2.7")
    end
  end

  describe "#remove_package" do
    it "should run the port deactivate command with the correct version" do
      provider.should_receive(:shell_out_with_systems_locale!).with("port deactivate zsh @4.2.7")
      provider.remove_package("zsh", "4.2.7")
    end

    it "should remove the currently active version if no explicit version is passed in" do
      provider.should_receive(:shell_out_with_systems_locale!).with("port deactivate zsh")
      provider.remove_package("zsh", nil)
    end

    it "should add options to the port command when specified" do
      new_resource.stub!(:options).and_return("-f")
      provider.should_receive(:shell_out_with_systems_locale!).with( "port -f deactivate zsh @4.2.7")
      provider.remove_package("zsh", "4.2.7")
    end
  end

  describe "#upgrade_package" do
    it "should run the port upgrade command with the correct version" do
      current_resource.should_receive(:version).at_least(:once).and_return("4.1.6")
      provider.current_resource = current_resource
      provider.should_receive(:shell_out_with_systems_locale!).with("port upgrade zsh @4.2.7")

      provider.upgrade_package("zsh", "4.2.7")
    end

    it "should not run the port upgrade command if the version is already installed" do
      current_resource.should_receive(:version).at_least(:once).and_return("4.2.7")
      provider.current_resource = current_resource
      provider.should_not_receive(:run_command_with_systems_locale!)

      provider.upgrade_package("zsh", "4.2.7")
    end

    it "should call install_package if the package isn't currently installed" do
      current_resource.should_receive(:version).at_least(:once).and_return(nil)
      provider.current_resource = current_resource
      provider.should_receive(:install_package).and_return(true)

      provider.upgrade_package("zsh", "4.2.7")
    end

    it "should add options to the port command when specified" do
      new_resource.stub!(:options).and_return("-f")
      current_resource.should_receive(:version).at_least(:once).and_return("4.1.6")
      provider.current_resource = current_resource

      provider.should_receive(:shell_out_with_systems_locale!).with("port -f upgrade zsh @4.2.7")

      provider.upgrade_package("zsh", "4.2.7")
    end
  end
end
