#
# Author:: Bryan McLellan <btm@loftninjas.org>
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

require_relative "../mixin/uris"
require_relative "package"
require_relative "../provider/package/windows"
require_relative "../win32/error" if RUBY_PLATFORM.match?(/mswin|mingw|windows/)
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class WindowsPackage < Chef::Resource::Package
      include Chef::Mixin::Uris

      provides(:windows_package) { true }
      provides :package, os: "windows"

      description <<~DESC
        Use the **windows_package** resource to manage packages on the Microsoft Windows platform.
        The **windows_package** resource supports these installer formats:
          * Microsoft Installer Package (MSI)
          * Nullsoft Scriptable Install System (NSIS)
          * Inno Setup (inno)
          * Wise
          * InstallShield
          * Custom installers such as installing a non-.msi file that embeds an .msi-based installer

        To enable idempotence of the `:install` action or to enable the `:remove` action with no source property specified,
        `package_name` MUST be an exact match of the name used by the package installer. The names of installed packages
        Windows knows about can be found in **Add/Remove programs**, in the output of `ohai packages`, or in the
        `DisplayName` property in one of the following in the Windows registry:

        * `HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall`
        * `HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall`
        * `HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall`

        Note: If there are multiple versions of a package installed with the same display name, all of those packages will
        be removed unless a version is provided in the **version** property or unless it can be discovered in the installer
        file specified by the **source** property.
      DESC

      introduced "11.12"
      examples <<~DOC
      **Install a package**:

      ```ruby
      windows_package '7zip' do
        action :install
        source 'C:\\7z920.msi'
      end
      ```

      **Specify a URL for the source attribute**:

      ```ruby
      windows_package '7zip' do
        source 'http://www.7-zip.org/a/7z938-x64.msi'
      end
      ```

      **Specify path and checksum**:

      ```ruby
      windows_package '7zip' do
        source 'http://www.7-zip.org/a/7z938-x64.msi'
        checksum '7c8e873991c82ad9cfcdbdf45254ea6101e9a645e12977dcd518979e50fdedf3'
      end
      ```

      **Modify remote_file resource attributes**:

      The windows_package resource may specify a package at a remote location using the remote_file_attributes property. This uses the remote_file resource to download the contents at the specified URL and passes in a Hash that modifies the properties of the remote_file resource.

      ```ruby
      windows_package '7zip' do
        source 'http://www.7-zip.org/a/7z938-x64.msi'
        remote_file_attributes ({
          :path => 'C:\\7zip.msi',
          :checksum => '7c8e873991c82ad9cfcdbdf45254ea6101e9a645e12977dcd518979e50fdedf3'
        })
      end
      ```

      **Download a nsis (Nullsoft) package resource**:

      ```ruby
      windows_package 'Mercurial 3.6.1 (64-bit)' do
        source 'https://www.mercurial-scm.org/release/windows/Mercurial-3.6.1-x64.exe'
        checksum 'febd29578cb6736163d232708b834a2ddd119aa40abc536b2c313fc5e1b5831d'
      end
      ```

      **Download a custom package**:

      ```ruby
      windows_package 'Microsoft Visual C++ 2005 Redistributable' do
        source 'https://download.microsoft.com/download/6/B/B/6BB661D6-A8AE-4819-B79F-236472F6070C/vcredist_x86.exe'
        installer_type :custom
        options '/Q'
      end
      ```
      DOC

      allowed_actions :install, :remove

      def initialize(name, run_context = nil)
        super
        @source ||= source(@package_name) if @package_name.downcase.end_with?(".msi")
      end

      property :package_name, String,
        description: "An optional property to set the package name if it differs from the resource block's name.",
        identity: true

      # we don't redefine the version property as a string here since we store the current value
      # of version and that may be an array if multiple versions of a package are present on the system

      # windows can't take array options yet
      property :options, String,
        description: "One (or more) additional options that are passed to the command."

      # Unique to this resource
      property :installer_type, Symbol,
        equal_to: %i{custom inno installshield msi nsis wise},
        description: "A symbol that specifies the type of package. Possible values: :custom (such as installing a non-.msi file that embeds an .msi-based installer), :inno (Inno Setup), :installshield (InstallShield), :msi (Microsoft Installer Package (MSI)), :nsis (Nullsoft Scriptable Install System (NSIS)), :wise (Wise)."

      property :timeout, [ String, Integer ], default: 600,
        default_description: "600 (seconds)",
        description: "The amount of time (in seconds) to wait before timing out.",
        desired_state: false

      # In the past we accepted return code 127 for an unknown reason and 42 because of a bug
      # we accept 3010 which means success, but a reboot is necessary
      property :returns, [ String, Integer, Array ], default: [ 0, 3010 ],
        desired_state: false,
        description: "A comma-delimited list of return codes that indicate the success or failure of the package command that was run.",
        default_description: "0 (success) and 3010 (success where a reboot is necessary)"

      property :source, String,
        coerce: (proc do |s|
          unless s.nil?
            uri_scheme?(s) ? s : Chef::Util::PathHelper.canonical_path(s, false)
          end
        end),
        default_description: "The resource block's name", # this property is basically a name_property but not really so we need to spell it out
        description: "The path to a package in the local file system or the URL of a remote file that will be downloaded."

      property :checksum, String,
        desired_state: false, coerce: (proc(&:downcase)),
        description: "The SHA-256 checksum of the file. Use to prevent a file from being re-downloaded. When the local file matches the checksum, #{ChefUtils::Dist::Infra::PRODUCT} does not download it. Use when a URL is specified by the `source` property."

      property :remote_file_attributes, Hash,
        desired_state: false,
        description: "If the source package to install is at a remote location, this property allows you to define a hash of properties which will be used by the underlying **remote_file** resource used to fetch the source."
    end
  end
end
