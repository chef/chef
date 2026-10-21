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
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
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

      it "can install Chocolatey with a custom PS1 download URL" do
        resource.download_url = "https://some.custom.url/install.ps1"
        expect { resource.action :install }.not_to raise_error
      end

      def run_install_capturing_commands(name, url)
        resource = Chef::Resource::ChocolateyInstaller.new(name, run_context)
        resource.download_url = url
        install_provider = resource.provider_for_action(:install)

        commands = []
        shell_out = instance_double("Mixlib::ShellOut", error!: nil)

        allow(resource).to receive(:provider_for_action).with(:install).and_return(install_provider)
        allow(resource).to receive(:is_choco_installed?).and_return(false)
        allow(install_provider).to receive(:powershell_exec) do |command|
          commands << command
          shell_out
        end
        allow(Chef::Log).to receive(:info)

        resource.run_action(:install)
        commands
      end

      it "sets ChocolateyDownloadUrl and executes a custom .ps1 URL directly" do
        commands = run_install_capturing_commands("fakey_fakerton_custom_ps1", "https://some.custom.url/install.ps1")

        expect(commands).to include("Set-Item -path env:ChocolateyDownloadUrl -Value 'https://some.custom.url/install.ps1'")
        expect(commands.any? { |c| c.include?("Invoke-Expression") && c.include?("install.ps1") }).to be true
      end

      it "uses a local drive path directly without downloading, then extracts and installs" do
        commands = run_install_capturing_commands("fakey_fakerton_local_path", 'C:\packages\chocolatey.2.0.0.nupkg')

        expect(commands.none? { |c| c.include?("Invoke-WebRequest") }).to be true
        expect(commands.any? { |c| c.include?("Expand-Archive") && c.include?("chocolateyInstall.ps1") && c.include?('C:\packages\chocolatey.2.0.0.nupkg') }).to be true
      end

      it "uses a UNC path directly without downloading, then extracts and installs" do
        commands = run_install_capturing_commands("fakey_fakerton_unc_path", '\\\\fileserver\\packages\\chocolatey.2.0.0.nupkg')

        expect(commands.none? { |c| c.include?("Invoke-WebRequest") }).to be true
        expect(commands.any? { |c| c.include?("Expand-Archive") && c.include?("chocolateyInstall.ps1") && c.include?('\\\\fileserver\\packages\\chocolatey.2.0.0.nupkg') }).to be true
      end

      it "downloads, extracts, and installs from a nupkg URL for air-gapped environments" do
        url = "https://some.custom.url/packages/chocolatey.2.0.0.nupkg"
        expected_destination = Chef::Util::PathHelper.join(ChefConfig::Config.etc_chef_dir(windows: true), "chocolatey.2.0.0.nupkg")
        commands = run_install_capturing_commands("fakey_fakerton_custom_download", url)

        expect(commands).to include("Set-Item -path env:ChocolateyDownloadUrl -Value '#{url}'")
        expect(commands.any? { |c| c.include?("Invoke-WebRequest") && c.include?(url) && c.include?("-UseBasicParsing") && c.include?(expected_destination) }).to be true
        expect(commands.any? { |c| c.include?("Expand-Archive") && c.include?("chocolateyInstall.ps1") }).to be true
      end
    end
  end

  describe "download_url extension validation" do
    def build_resource_with_url(url, ctx)
      r = Chef::Resource::ChocolateyInstaller.new("test_url_validation_#{url.to_s.hash.abs}", ctx)
      r.download_url = url if url
      p = r.provider_for_action(:install)
      allow(r).to receive(:provider_for_action).with(:install).and_return(p)
      allow(r).to receive(:is_choco_installed?).and_return(false)
      allow(p).to receive(:powershell_exec).and_return(double("shell_out", error!: nil, result: nil))
      r
    end

    it "raises ValidationFailed for a URL with a clearly wrong file extension" do
      r = build_resource_with_url("https://some.server/packages/chocolatey.html", run_context)
      expect { r.run_action(:install) }.to raise_error(Chef::Exceptions::ValidationFailed, /\.ps1.*\.nupkg/)
    end

    it "does not raise ValidationFailed for an OData-style URL with no file extension" do
      r = build_resource_with_url("https://some.server/api/v2/package/chocolatey/2.7.3", run_context)
      expect { r.run_action(:install) }.not_to raise_error
    end

    it "does not raise ValidationFailed for a bare domain URL with no extension" do
      r = build_resource_with_url("https://some.server/", run_context)
      expect { r.run_action(:install) }.not_to raise_error
    end

    it "does not raise ValidationFailed for a valid .nupkg URL" do
      r = build_resource_with_url("https://some.server/chocolatey.2.7.3.nupkg", run_context)
      expect { r.run_action(:install) }.not_to raise_error
    end

    it "does not raise ValidationFailed for a valid .ps1 URL" do
      r = build_resource_with_url("https://some.server/install.ps1", run_context)
      expect { r.run_action(:install) }.not_to raise_error
    end

    it "does not raise ValidationFailed when no download_url is set" do
      r = build_resource_with_url(nil, run_context)
      expect { r.run_action(:install) }.not_to raise_error
    end
  end

  describe "custom download path helpers" do
    it "detects PowerShell scripts from the URL path" do
      resource = Chef::Resource::ChocolateyInstaller.new("fakey_fakerton_custom_script", run_context)
      resource.download_url = "https://some.custom.url/install.ps1?token=abc123"

      expect(resource.download_url_script?).to be true
    end

    it "falls back to a package filename when the URL path has no basename" do
      resource = Chef::Resource::ChocolateyInstaller.new("fakey_fakerton_custom_path", run_context)
      resource.download_url = "https://some.custom.url/"

      expect(resource.download_destination).to eq(Chef::Util::PathHelper.join(ChefConfig::Config.etc_chef_dir(windows: true), "chocolatey.nupkg"))
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

  describe "PowerShell quoting of user-supplied values" do
    def capture_commands(resource, action)
      provider = resource.provider_for_action(action)
      commands = []
      allow(resource).to receive(:provider_for_action).with(action).and_return(provider)
      allow(resource).to receive(:is_choco_installed?).and_return(false)
      allow(provider).to receive(:powershell_exec) do |command|
        commands << command
        double("shell_out", error!: nil, result: nil)
      end
      allow(Chef::Log).to receive(:info)
      resource.run_action(action)
      commands
    end

    it "doubles embedded single quotes so values cannot break out of the literal" do
      r = Chef::Resource::ChocolateyInstaller.new("quote_test", run_context)
      r.proxy_url = "http://proxy:3128/'; calc.exe; '"
      r.proxy_user = "us'er"
      r.proxy_password = "pa'ss; Remove-Item C:\\ -Recurse #"
      r.chocolatey_version = "2.0.0'; calc; '"
      commands = capture_commands(r, :install)

      expect(commands).to include("Set-Item -path env:ChocolateyProxyLocation -Value 'http://proxy:3128/''; calc.exe; '''")
      expect(commands).to include("Set-Item -path env:ChocolateyProxyUser -Value 'us''er'; Set-Item -path env:ChocolateyProxyPassword -Value 'pa''ss; Remove-Item C:\\ -Recurse #'")
      expect(commands).to include("Set-Item -path env:ChocolateyVersion -Value '2.0.0''; calc; '''")
    end

    it "also doubles typographic single quotes, which PowerShell treats as quotes" do
      r = Chef::Resource::ChocolateyInstaller.new("quote_test_unicode", run_context)
      r.proxy_url = "http://proxy/\u2019; calc; \u2018"
      commands = capture_commands(r, :install)

      expect(commands).to include("Set-Item -path env:ChocolateyProxyLocation -Value 'http://proxy/\u2019\u2019; calc; \u2018\u2018'")
    end

    it "quotes the download url, destination and proxy settings in the nupkg download" do
      r = Chef::Resource::ChocolateyInstaller.new("quote_test_download", run_context)
      r.download_url = "https://some.server/choco'.nupkg"
      r.proxy_url = "http://proxy:3128"
      r.proxy_user = "u'ser"
      r.proxy_password = "p'w"
      commands = capture_commands(r, :install)

      download = commands.find { |c| c.include?("Invoke-WebRequest") }
      expect(download).to include("Invoke-WebRequest 'https://some.server/choco''.nupkg'")
      expect(download).to include("PSCredential('u''ser', (ConvertTo-SecureString 'p''w' -AsPlainText -Force))")
    end

    it "quotes a local nupkg path in the extraction script" do
      r = Chef::Resource::ChocolateyInstaller.new("quote_test_local", run_context)
      r.download_url = "C:\\pack'ages\\chocolatey.nupkg"
      commands = capture_commands(r, :install)

      expect(commands.any? { |c| c.include?("$nupkgPath = 'C:\\pack''ages\\chocolatey.nupkg'") }).to be true
    end

    it "extracts into a unique per-run directory rather than a fixed TEMP path" do
      r = Chef::Resource::ChocolateyInstaller.new("extract_dir_test", run_context)
      r.download_url = "C:\\packages\\chocolatey.nupkg"
      script = capture_commands(r, :install).find { |c| c.include?("Expand-Archive") }

      expect(script).to include("[guid]::NewGuid()")
      expect(script).not_to include("chocolatey_nupkg_extract")
    end
  end

  describe "proxy credential requirements" do
    it "raises when only proxy_user is set" do
      r = Chef::Resource::ChocolateyInstaller.new("proxy_half_user", run_context)
      r.proxy_user = "someone"
      allow(r).to receive(:is_choco_installed?).and_return(true)
      expect { r.run_action(:install) }.to raise_error(Chef::Exceptions::ValidationFailed, /proxy_user and a proxy_password/)
    end

    it "raises when only proxy_password is set" do
      r = Chef::Resource::ChocolateyInstaller.new("proxy_half_pw", run_context)
      r.proxy_password = "secret"
      allow(r).to receive(:is_choco_installed?).and_return(true)
      expect { r.run_action(:install) }.to raise_error(Chef::Exceptions::ValidationFailed, /proxy_user and a proxy_password/)
    end

    it "does not raise when neither or both are set" do
      both = Chef::Resource::ChocolateyInstaller.new("proxy_both", run_context)
      both.proxy_user = "someone"
      both.proxy_password = "secret"
      neither = Chef::Resource::ChocolateyInstaller.new("proxy_neither", run_context)
      [both, neither].each do |r|
        provider = r.provider_for_action(:install)
        allow(r).to receive(:provider_for_action).with(:install).and_return(provider)
        allow(r).to receive(:is_choco_installed?).and_return(true)
        allow(provider).to receive(:powershell_exec).and_return(double("shell_out", error!: nil))
        expect { r.run_action(:install) }.not_to raise_error
      end
    end
  end

  describe "sensitive property masking" do
    it "marks proxy_password as sensitive" do
      expect(Chef::Resource::ChocolateyInstaller.properties[:proxy_password].sensitive?).to be true
    end
  end
end
