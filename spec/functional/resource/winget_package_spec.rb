# if winget not installed yet, install it

#
# Author:: John McCrae (<john.mccrae@progress.com>)
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
require "chef/mixin/powershell_exec"
require "chef/mixin/shell_out"

describe Chef::Resource::WingetPackage, :requires_root, :windows_only do
  include Chef::Mixin::PowershellExec
  include Chef::Mixin::ShellOut

  let(:my_package_name) { ["pennywise"] }
  let(:my_other_package_name) { "AWS Command Line Interface v2" }
  let(:my_package_list) { ["1Password", "MicroK8s"] }
  let(:my_source_name) { "ChefTest" }
  let(:my_url ) { "https://testingchef.blob.core.windows.net/files/" }
  let(:my_scope) { "machine" }
  let(:my_location) { "C:\\Program Files\\Foo\\aws_cli" }
  let(:my_override) { nil }
  let(:my_force) { true }

  # let(:resource) do
  #   Chef::RunContext.new(Chef::Node.new, {}, Chef::EventDispatch::Dispatcher.new)
  # end

  let(:run_context) do
    node = Chef::Node.new
    node.consume_external_attrs(OHAI_SYSTEM.data, {}) # node[:languages][:powershell][:version]
    node.automatic["os"] = "windows"
    node.automatic["platform"] = "windows"
    node.automatic["platform_version"] = "6.1"
    node.automatic["kernel"][:machine] = :x86_64 # Only 64-bit architecture is supported
    empty_events = Chef::EventDispatch::Dispatcher.new
    Chef::RunContext.new(node, {}, empty_events)
  end

  subject do
    new_resource = Chef::Resource::WingetPackage.new("Winget", run_context)
    new_resource
  end

  def package_source_exists?
    powershell_exec!(ps_package_sources_cmd).result
  end

  def ps_package_sources_cmd
    <<-CMD
      $hash = new-object System.Collections.Hashtable
      [System.Collections.ArrayList]$sources = Invoke-Expression "winget source list"
      $sources += $sources.Remove("Name   Argument")
      $sources += $sources.Remove("-------------------------------------------------------")

      foreach($source in $sources){
        $break = $($source -replace '\s+', ' ').split()
        $key = $break[0]
        $value = $break[1]
        $hash.Add($key, $value)
      }

      foreach($key in $hash.Keys){
        if($key -contains "#{my_source_name}"){
          return $true
        }
        else{
          return $false
        }
      }
    CMD
  end

  def ps_get_app_installer_bundle
    <<-CMD
      $url = "https://testingchef.blob.core.windows.net/sources/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.appxbundle"
      New-Item -ItemType Directory -Force -Path C:\\chef_download\\
      $download_path = "C:\\chef_download\\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.appxbundle"
      Invoke-WebRequest -Uri $url -OutFile $download_path
      Import-Module Appx
      Add-AppxPackage -Path $download_path
    CMD
  end

  def ps_package_is_installed?(package_name:)
    <<-CMD
      $ErrorActionPreference = 'SilentlyContinue'
      $result = get-command -Name "#{package_name}"
      if ([string]::IsNullOrEmpty($result)){
          return $false
      }
      else {
          return $true
      }
    CMD
  end

  # before do
  #   ps_get_app_installer_bundle
  # end

  # after { "winget source reset --force" }

  # context "manage package sources" do
  #   it "adds a new package source" do
  #     windows_package_manager "loading a new package source" do
  #       source_name my_source_name
  #       url my_url
  #       action :register
  #     end.should_be_updated
  #     expect(package_source_exists?).to be true
  #   end

  #   it "removes a package source" do
  #     windows_package_manager "loading a new package source" do
  #       source_name my_source_name
  #       action :unregister
  #     end
  #     expect(package_source_exists?).to be false
  #   end
  # end

  describe "adding packages to a windows node" do
    context "manage packages" do
      it "does not add a package that is already installed" do
        subject.package_name my_package_name
        subject.run_action(:install)
        expect(subject.updated_by_last_action?).to be false
        # winget_package "loading a new package" do
        #   package_name my_package_name
        #   action :install
        # end.should_be_updated
        expect(powershell_exec!(ps_package_is_installed?(package_name:'7z.exe')).result).to be true
      end
    end
  end

    # it "adds more than one package" do
    #   puts "My Package Class is : #{my_package_list.class}"
    #   # my_package_list.each do |item|
    #   my_package_list.each do |item|
    #     windows_package_manager "install packages from an array" do
    #       source_name item
    #       action :install
    #     end.should_be_updated
    #   end
    #   expect(my_package_list).to be(Array)
    # end

    # it "adds a package to the local node with extended settings" do
    #   windows_package_manager "loading a new package with parameters" do
    #     package_name my_other_package_name
    #     scope my_scope
    #     location my_location
    #     force my_force
    #     action :install
    #   end.should_be_updated
    #   # expect
    # end

end
