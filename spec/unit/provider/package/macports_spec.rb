#
# Author:: David Balatero (<dbalatero@gmail.com>)
# Copyright:: Copyright 2009-2016, Chef Software Inc.
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

describe Chef::Provider::Package::Macports do
  before(:each) do
    @node = Chef::Node.new
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, {}, @events)
    @new_resource = Chef::Resource::Package.new("zsh")
    @current_resource = Chef::Resource::Package.new("zsh")

    @provider = Chef::Provider::Package::Macports.new(@new_resource, @run_context)
    allow(Chef::Resource::Package).to receive(:new).and_return(@current_resource)

    # @status = double(:stdout => "", :exitstatus => 0)
    # @stdin = StringIO.new
    # @stdout = StringIO.new
    # @stderr = StringIO.new
    # @pid = 2342
  end

  describe "load_current_resource" do
    it "should create a current resource with the name of the new_resource" do
      expect(@provider).to receive(:current_installed_version).and_return(nil)
      expect(@provider).to receive(:macports_candidate_version).and_return("4.2.7")

      @provider.load_current_resource
      expect(@provider.current_resource.name).to eq("zsh")
    end

    it "should create a current resource with the version if the package is installed" do
      expect(@provider).to receive(:macports_candidate_version).and_return("4.2.7")
      expect(@provider).to receive(:current_installed_version).and_return("4.2.7")

      @provider.load_current_resource
      expect(@provider.candidate_version).to eq("4.2.7")
    end

    it "should create a current resource with a nil version if the package is not installed" do
      expect(@provider).to receive(:current_installed_version).and_return(nil)
      expect(@provider).to receive(:macports_candidate_version).and_return("4.2.7")
      @provider.load_current_resource
      expect(@provider.current_resource.version).to be_nil
    end

    it "should set a candidate version if one exists" do
      expect(@provider).to receive(:current_installed_version).and_return(nil)
      expect(@provider).to receive(:macports_candidate_version).and_return("4.2.7")
      @provider.load_current_resource
      expect(@provider.candidate_version).to eq("4.2.7")
    end
  end

  describe "current_installed_version" do
    it "should return the current version if the package is installed" do
      stdout = <<EOF
The following ports are currently installed:
  openssl @0.9.8k_0 (active)
EOF

      status = double(:stdout => stdout, :exitstatus => 0)
      expect(@provider).to receive(:shell_out).and_return(status)
      expect(@provider.current_installed_version).to eq("0.9.8k_0")
    end

    it "should return nil if a package is not currently installed" do
      status = double(:stdout => "       \n", :exitstatus => 0)
      expect(@provider).to receive(:shell_out).and_return(status)
      expect(@provider.current_installed_version).to be_nil
    end
  end

  describe "macports_candidate_version" do
    it "should return the latest available version of a given package" do
      status = double(:stdout => "version: 4.2.7\n", :exitstatus => 0)
      expect(@provider).to receive(:shell_out).and_return(status)
      expect(@provider.macports_candidate_version).to eq("4.2.7")
    end

    it "should return nil if there is no version for a given package" do
      status = double(:stdout => "Error: port fadsfadsfads not found\n", :exitstatus => 0)
      expect(@provider).to receive(:shell_out).and_return(status)
      expect(@provider.macports_candidate_version).to be_nil
    end
  end

  describe "install_package" do
    it "should run the port install command with the correct version" do
      expect(@current_resource).to receive(:version).and_return("4.1.6")
      @provider.current_resource = @current_resource
      expect(@provider).to receive(:shell_out!).with("port", "install", "zsh", "@4.2.7", timeout: 900)

      @provider.install_package("zsh", "4.2.7")
    end

    it "should not do anything if a package already exists with the same version" do
      expect(@current_resource).to receive(:version).and_return("4.2.7")
      @provider.current_resource = @current_resource
      expect(@provider).not_to receive(:shell_out!)

      @provider.install_package("zsh", "4.2.7")
    end

    it "should add options to the port command when specified" do
      expect(@current_resource).to receive(:version).and_return("4.1.6")
      @provider.current_resource = @current_resource
      @new_resource.options("-f")
      expect(@provider).to receive(:shell_out!).with("port", "-f", "install", "zsh", "@4.2.7", timeout: 900)

      @provider.install_package("zsh", "4.2.7")
    end
  end

  describe "purge_package" do
    it "should run the port uninstall command with the correct version" do
      expect(@provider).to receive(:shell_out!).with("port", "uninstall", "zsh", "@4.2.7", timeout: 900)
      @provider.purge_package("zsh", "4.2.7")
    end

    it "should purge the currently active version if no explicit version is passed in" do
      expect(@provider).to receive(:shell_out!).with("port", "uninstall", "zsh", timeout: 900)
      @provider.purge_package("zsh", nil)
    end

    it "should add options to the port command when specified" do
      @new_resource.options("-f")
      expect(@provider).to receive(:shell_out!).with("port", "-f", "uninstall", "zsh", "@4.2.7", timeout: 900)
      @provider.purge_package("zsh", "4.2.7")
    end
  end

  describe "remove_package" do
    it "should run the port deactivate command with the correct version" do
      expect(@provider).to receive(:shell_out!).with("port", "deactivate", "zsh", "@4.2.7", timeout: 900)
      @provider.remove_package("zsh", "4.2.7")
    end

    it "should remove the currently active version if no explicit version is passed in" do
      expect(@provider).to receive(:shell_out!).with("port", "deactivate", "zsh", timeout: 900)
      @provider.remove_package("zsh", nil)
    end

    it "should add options to the port command when specified" do
      @new_resource.options("-f")
      expect(@provider).to receive(:shell_out!).with("port", "-f", "deactivate", "zsh", "@4.2.7", timeout: 900)
      @provider.remove_package("zsh", "4.2.7")
    end
  end

  describe "upgrade_package" do
    it "should run the port upgrade command with the correct version" do
      expect(@current_resource).to receive(:version).at_least(:once).and_return("4.1.6")
      @provider.current_resource = @current_resource

      expect(@provider).to receive(:shell_out!).with("port", "upgrade", "zsh", "@4.2.7", timeout: 900)

      @provider.upgrade_package("zsh", "4.2.7")
    end

    it "should not run the port upgrade command if the version is already installed" do
      expect(@current_resource).to receive(:version).at_least(:once).and_return("4.2.7")
      @provider.current_resource = @current_resource
      expect(@provider).not_to receive(:shell_out!)

      @provider.upgrade_package("zsh", "4.2.7")
    end

    it "should call install_package if the package isn't currently installed" do
      expect(@current_resource).to receive(:version).at_least(:once).and_return(nil)
      @provider.current_resource = @current_resource
      expect(@provider).to receive(:install_package).and_return(true)

      @provider.upgrade_package("zsh", "4.2.7")
    end

    it "should add options to the port command when specified" do
      @new_resource.options("-f")
      expect(@current_resource).to receive(:version).at_least(:once).and_return("4.1.6")
      @provider.current_resource = @current_resource

      expect(@provider).to receive(:shell_out!).with("port", "-f", "upgrade", "zsh", "@4.2.7", timeout: 900)

      @provider.upgrade_package("zsh", "4.2.7")
    end
  end
end
