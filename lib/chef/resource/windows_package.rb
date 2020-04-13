#
# Author:: Bryan McLellan <btm@loftninjas.org>
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

require_relative "../mixin/uris"
require_relative "package"
require_relative "../provider/package/windows"
require_relative "../win32/error" if RUBY_PLATFORM =~ /mswin|mingw|windows/
require_relative "../dist"

class Chef
  class Resource
    class WindowsPackage < Chef::Resource::Package
      include Chef::Mixin::Uris

      provides(:windows_package) { true }
      provides :package, os: "windows"

      description "Use the windows_package resource to manage packages on the Microsoft Windows platform. The windows_package resource supports these installer formats:\n\n Microsoft Installer Package (MSI)\n Nullsoft Scriptable Install System (NSIS)\n Inno Setup (inno)\n Wise\n InstallShield\n Custom installers such as installing a non-.msi file that embeds an .msi-based installer\n"
      introduced "11.12"

      allowed_actions :install, :remove

      def initialize(name, run_context = nil)
        super
        @source ||= source(@package_name) if @package_name.downcase.end_with?(".msi")
      end

      # windows can't take array options yet
      property :options, String,
        description: "One (or more) additional options that are passed to the command."

      # Unique to this resource
      property :installer_type, Symbol,
        equal_to: %i{custom inno installshield msi nsis wise},
        description: "A symbol that specifies the type of package. Possible values: :custom (such as installing a non-.msi file that embeds an .msi-based installer), :inno (Inno Setup), :installshield (InstallShield), :msi (Microsoft Installer Package (MSI)), :nsis (Nullsoft Scriptable Install System (NSIS)), :wise (Wise)."

      property :timeout, [ String, Integer ], default: 600,
        default_description: "600 (seconds)",
        description: "The amount of time (in seconds) to wait before timing out."

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
        description: "The path to a package in the local file system. The location of the package may be at a URL. \n"

      property :checksum, String,
        desired_state: false, coerce: (proc { |c| c.downcase }),
        description: "The SHA-256 checksum of the file. Use to prevent a file from being re-downloaded. When the local file matches the checksum, #{Chef::Dist::PRODUCT} does not download it. Use when a URL is specified by the source property."

      property :remote_file_attributes, Hash,
        desired_state: false,
        description: "If the source package to install is at a remote location this property allows you to define a hash of properties and their value which will be used by the underlying remote_file resource, which fetches the source."
    end
  end
end
