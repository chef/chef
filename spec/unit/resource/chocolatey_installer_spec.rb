#
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

describe Chef::Resource::ChocolateyInstaller do
  include RecipeDSLHelper

  let(:resource) { Chef::Resource::ChocolateyInstaller.new("fakey_fakerton") }
  let(:config) do
    <<-CONFIG
      <?xml version="1.0" encoding="utf-8"?>
      <chocolatey xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <config>
          <add key="containsLegacyPackageInstalls" value="true" description="Install has packages installed prior to 0.9.9 series." />
        </config>
        <sources>
          <source id="chocolatey" value="https://chocolatey.org/api/v2/" disabled="false" bypassProxy="false" selfService="false" adminOnly="false" priority="0" />
        </sources>
        <features>
          <feature name="checksumFiles" enabled="true" setExplicitly="false" description="Checksum files when pulled in from internet (based on package)." />
        </features>
        <apiKeys />
      </chocolatey>
    CONFIG
  end

  # we save off the ENV and set ALLUSERSPROFILE so these specs will work on *nix and non-C drive Windows installs
  before(:each) do
    @original_env = ENV.to_hash
    ENV["ALLUSERSPROFILE"] = "C:\\ProgramData"
  end

  after(:each) do
    ENV.clear
    ENV.update(@original_env)
  end

  describe "Basic Resource Settings" do
    context "on windows", :windows_only do
      it "supports :install, :uninstall, :upgrade actions" do
        expect { resource.action :install }.not_to raise_error
        expect { resource.action :uninstall }.not_to raise_error
        expect { resource.action :upgrade }.not_to raise_error
      end
    end
  end

  describe "Basic chocolatey settings" do
    context "on windows", :windows_only do
      it "has a resource name of :chocolatey_installer" do
        expect(resource.resource_name).to eql(:chocolatey_installer)
      end

      it "sets the default action as :install" do
        expect(resource.action).to eql([:install])
      end

      it "supports :install and :uninstall actions" do
        expect { resource.action :install }.not_to raise_error
        expect { resource.action :uninstall }.not_to raise_error
      end

      it "does not support bologna install options" do
        expect { resource.action :foo }.to raise_error(Chef::Exceptions::ValidationFailed)
      end
    end
  end

  describe "Installing chocolatey" do
    context "on windows", :windows_only do
      it "can install Chocolatey with parameters" do
        resource.chocolatey_version = "1.4.0"
        expect { resource.action :install }.not_to raise_error
      end

      it "logs a warning if a chocolatey install cannot be found" do
        allow(::File).to receive(:exist?).with('C:\ProgramData\chocolatey\bin\choco.exe').and_return(false)
        expect { Chef::Log.warn("Chocolatey is already uninstalled.") }.not_to output.to_stderr
      end
    end
  end

  describe "Chocolatey is idempotent because" do
    context "on windows", :windows_only do
      it "it does not install choco again if it is already installed" do
        install_choco
        chocolatey_installer "install" do
          action :install
        end.should_not_be_updated
      end
    end
  end

  describe "upgrading choco versions" do

    context "on windows", :windows_only do
      describe "when the versions do not match" do
        it "upgrades if the proposed version is newer" do
          allow(resource).to receive(:get_choco_version).and_return(Gem::Version.new("1.2.2"))
          allow(resource).to receive(:chocolatey_version).and_return(Gem::Version.new("4.2.2"))
          expect { resource.action :upgrade }.not_to raise_error
          allow(resource).to receive(:get_choco_version).and_return(Gem::Version.new("4.2.2"))
          expect(resource.get_choco_version).to eql(Gem::Version.new("4.2.2"))
        end
      end
      describe "when the versions match" do
        it "does not upgrade if the old version is identical" do
          allow(resource).to receive(:get_choco_version).and_return(Gem::Version.new("2.2.2"))
          allow(resource).to receive(:chocolatey_version).and_return(Gem::Version.new("2.2.2"))
          expect { resource.action :upgrade }.not_to raise_error
          expect(resource).not_to be_updated
        end
      end
    end
  end

  describe "Uninstalling chocolatey" do
    context "on windows", :windows_only do
      it "doesn't error out uninstalling chocolatey if chocolatey is not installed" do
        allow(::File).to receive(:exist?).with('C:\ProgramData\chocolatey\bin\choco.exe').and_return(false)
        expect { resource.action :uninstall }.not_to raise_error
      end
    end
  end

  def install_choco
    require "chef-powershell"
    include ChefPowerShell::ChefPowerShellModule::PowerShellExec
    powershell_code = <<-CODE
      Set-ExecutionPolicy Bypass -Scope Process -Force;
      [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
      iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    CODE
    powershell_exec(powershell_code)
  end
end
