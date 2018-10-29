#
# Author:: Joshua Timberman (<jtimberman@chef.io>)
# Copyright:: 2011-2018, Chef Software, Inc.
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

require "chef/resource"

class Chef
  class Resource
    class DmgPackage < Chef::Resource
      resource_name :dmg_package
      provides(:dmg_package) { true }

      description "Use the dmg_package resource to install a dmg 'package'. The resource will retrieve the dmg file from a remote URL, mount it using OS X's hdidutil, copy the application (.app directory) to the specified destination (/Applications), and detach the image using hdiutil. The dmg file will be stored in the Chef::Config[:file_cache_path]."
      introduced "14.0"

      property :app, String,
               description: "The name of the application used by default for the /Volumes directory and the .app directory copied to /Applications.",
               name_property: true

      property :source, String,
               description: "The remote URL for the dmg to download if specified."

      property :file, String,
               description: "The local dmg full file path."

      property :owner, String,
               description: "The owner that should own the package installation."

      property :destination, String,
               description: "The directory to copy the .app into.",
               default: "/Applications"

      property :checksum, String,
               description: "The sha256 checksum of the dmg to download."

      property :volumes_dir, String,
               description: "The Directory under /Volumes where the dmg is mounted as not all dmgs are mounted into a /Volumes location matching the name of the dmg.",
               default: lazy { |r| r.app }

      property :dmg_name, String,
               description: "The name of the dmg if it is not the same as app, or if the name has spaces.",
               desired_state: false,
               default: lazy { |r| r.app }

      property :type, String,
               description: "The type of package.",
               equal_to: %w{app pkg mpkg},
               default: "app", desired_state: false

      property :package_id, String,
               description: "The package id registered with pkgutil when a pkg or mpkg is installed."

      property :dmg_passphrase, String,
               description: "Specify a passphrase to use to unencrypt the dmg while mounting.",
               desired_state: false

      property :accept_eula, [TrueClass, FalseClass],
               description: "Specify whether to accept the EULA. Certain dmgs require acceptance of EULA before mounting.",
               default: false, desired_state: false

      property :headers, Hash,
               description: "Allows custom HTTP headers (like cookies) to be set on the remote_file resource.",
               desired_state: false

      property :allow_untrusted, [TrueClass, FalseClass],
               description: "Allow installation of packages that do not have trusted certificates.",
               default: false, desired_state: false

      load_current_value do |new_resource|
        if ::File.directory?("#{new_resource.destination}/#{new_resource.app}.app")
          Chef::Log.info "Already installed; to upgrade, remove \"#{new_resource.destination}/#{new_resource.app}.app\""
        elsif shell_out("pkgutil --pkgs='#{new_resource.package_id}'").exitstatus == 0
          Chef::Log.info "Already installed; to upgrade, try \"sudo pkgutil --forget '#{new_resource.package_id}'\""
        else
          current_value_does_not_exist! # allows us to check for current_resource.nil? below
        end
      end

      action :install do
        description "Installs the application."

        if current_resource.nil?
          if new_resource.source
            remote_file dmg_file do
              source new_resource.source
              headers new_resource.headers if new_resource.headers
              checksum new_resource.checksum if new_resource.checksum
            end
          end

          ruby_block "attach #{dmg_file}" do
            block do
              raise "This DMG package requires EULA acceptance. Add 'accept_eula true' to dmg_package resource to accept the EULA during installation." if software_license_agreement? && !new_resource.accept_eula
              accept_eula_cmd = new_resource.accept_eula ? "echo Y | echo Y | PAGER=true " : ""
              shell_out!("#{accept_eula_cmd} /usr/bin/hdiutil attach #{passphrase_cmd} '#{dmg_file}' -nobrowse -mountpoint '/Volumes/#{new_resource.volumes_dir}' -quiet", env: { "PAGER" => "true" })
            end
            not_if { dmg_attached? }
          end

          case new_resource.type
          when "app"
            execute "rsync --force --recursive --links --perms --executability --owner --group --times '/Volumes/#{new_resource.volumes_dir}/#{new_resource.app}.app' '#{new_resource.destination}'" do
              user new_resource.owner if new_resource.owner
            end

            file "#{new_resource.destination}/#{new_resource.app}.app/Contents/MacOS/#{new_resource.app}" do
              mode "0755"
              ignore_failure true
            end
          when "mpkg", "pkg"
            install_cmd = "installation_file=$(ls '/Volumes/#{new_resource.volumes_dir}' | grep '.#{new_resource.type}$') && sudo installer -pkg \"/Volumes/#{new_resource.volumes_dir}/$installation_file\" -target /"
            install_cmd += " -allowUntrusted" if new_resource.allow_untrusted

            execute install_cmd do
              # Prevent cfprefsd from holding up hdiutil detach for certain disk images
              environment("__CFPREFERENCES_AVOID_DAEMON" => "1")
            end
          end

          execute "/usr/bin/hdiutil detach '/Volumes/#{new_resource.volumes_dir}' || /usr/bin/hdiutil detach '/Volumes/#{new_resource.volumes_dir}' -force"
        end
      end

      action_class do
        # @return [String] the path to the dmg file
        def dmg_file
          @dmg_file ||= begin
            if new_resource.file.nil?
              "#{Chef::Config[:file_cache_path]}/#{new_resource.dmg_name}.dmg"
            else
              new_resource.file
            end
          end
        end

        # @return [String] the hdiutil flag for handling DMGs with a password
        def passphrase_cmd
          @passphrase_cmd ||= new_resource.dmg_passphrase ? "-passphrase #{new_resource.dmg_passphrase}" : ""
        end

        # @return [Boolean] does the DMG require a software license agreement
        def software_license_agreement?
          # example hdiutil imageinfo output: http://rubular.com/r/0xvOaA6d8B
          /Software License Agreement: true/.match?(shell_out!("/usr/bin/hdiutil imageinfo #{passphrase_cmd} '#{dmg_file}'").stdout)
        end

        # @return [Boolean] is the dmg file currently attached?
        def dmg_attached?
          # example hdiutil imageinfo output: http://rubular.com/r/CDcqenkixg
          /image-path.*#{dmg_file}/.match?(shell_out!("/usr/bin/hdiutil info #{passphrase_cmd}").stdout)
        end
      end
    end
  end
end
