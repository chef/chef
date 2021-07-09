#
# Author:: Joshua Timberman (<jtimberman@chef.io>)
# Copyright:: Copyright (c) Chef Software Inc.
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

require_relative "../resource"

class Chef
  class Resource
    class DmgPackage < Chef::Resource
      unified_mode true

      provides(:dmg_package) { true }

      description "Use the **dmg_package** resource to install a package from a .dmg file. The resource will retrieve the dmg file from a remote URL, mount it using macOS' `hdidutil`, copy the application (.app directory) to the specified destination (`/Applications`), and detach the image using `hdiutil`. The dmg file will be stored in the `Chef::Config[:file_cache_path]`."
      introduced "14.0"
      examples <<~DOC
        **Install Google Chrome via the DMG package**:

        ```ruby
        dmg_package 'Google Chrome' do
          dmg_name 'googlechrome'
          source   'https://dl-ssl.google.com/chrome/mac/stable/GGRM/googlechrome.dmg'
          checksum '7daa2dc5c46d9bfb14f1d7ff4b33884325e5e63e694810adc58f14795165c91a'
          action   :install
        end
        ```

        **Install VirtualBox from the .mpkg**:

        ```ruby
        dmg_package 'Virtualbox' do
          source 'http://dlc.sun.com.edgesuite.net/virtualbox/4.0.8/VirtualBox-4.0.8-71778-OSX.dmg'
          type   'mpkg'
        end
        ```

        **Install pgAdmin and automatically accept the EULA**:

        ```ruby
        dmg_package 'pgAdmin3' do
          source   'http://wwwmaster.postgresql.org/redir/198/h/pgadmin3/release/v1.12.3/osx/pgadmin3-1.12.3.dmg'
          checksum '9435f79d5b52d0febeddfad392adf82db9df159196f496c1ab139a6957242ce9'
          accept_eula true
        end
        ```
      DOC

      property :app, String,
        description: "The name of the application as it appears in the `/Volumes` directory if it differs from the resource block's name.",
        name_property: true

      property :source, String,
        description: "The remote URL that is used to download the `.dmg` file, if specified."

      property :file, String,
        description: "The absolute path to the `.dmg` file on the local system."

      property :owner, [String, Integer],
        description: "The user that should own the package installation."

      property :destination, String,
        description: "The directory to copy the `.app` into.",
        default: "/Applications"

      property :checksum, String,
        description: "The sha256 checksum of the `.dmg` file to download."

      property :volumes_dir, String,
        description: "The directory under `/Volumes` where the `dmg` is mounted if it differs from the name of the `.dmg` file.",
        default: lazy { app }, default_description: "The value passed for the application name."

      property :dmg_name, String,
        description: "The name of the `.dmg` file if it differs from that of the app, or if the name has spaces.",
        desired_state: false,
        default: lazy { app }, default_description: "The value passed for the application name."

      property :type, String,
        description: "The type of package.",
        equal_to: %w{app pkg mpkg},
        default: "app", desired_state: false

      property :package_id, String,
        description: "The package ID that is registered with `pkgutil` when a `pkg` or `mpkg` is installed."

      property :dmg_passphrase, String,
        description: "Specify a passphrase to be used to decrypt the `.dmg` file during the mount process.",
        desired_state: false

      property :accept_eula, [TrueClass, FalseClass],
        description: "Specify whether to accept the EULA. Certain dmg files require acceptance of EULA before mounting.",
        default: false, desired_state: false

      property :headers, Hash,
        description: "Allows custom HTTP headers (like cookies) to be set on the `remote_file` resource.",
        desired_state: false

      property :allow_untrusted, [TrueClass, FalseClass],
        description: "Allow installation of packages that do not have trusted certificates.",
        default: false, desired_state: false

      load_current_value do |new_resource|
        if ::File.directory?("#{new_resource.destination}/#{new_resource.app}.app")
          Chef::Log.info "#{new_resource.app} is already installed. To upgrade, remove \"#{new_resource.destination}/#{new_resource.app}.app\""
        elsif shell_out("pkgutil --pkg-info '#{new_resource.package_id}'").exitstatus == 0
          Chef::Log.info "#{new_resource.app} is already installed. To upgrade, try \"sudo pkgutil --forget '#{new_resource.package_id}'\""
        else
          current_value_does_not_exist! # allows us to check for current_resource.nil? below
        end
      end

      action :install, description: "Installs the application." do
        if current_resource.nil?
          if new_resource.source
            remote_file dmg_file do
              source new_resource.source
              headers new_resource.headers if new_resource.headers
              checksum new_resource.checksum if new_resource.checksum
            end
          end

          unless dmg_attached?
            converge_by "attach #{dmg_file}" do
              raise "This DMG package requires EULA acceptance. Add 'accept_eula true' to dmg_package resource to accept the EULA during installation." if software_license_agreement? && !new_resource.accept_eula

              attach_cmd = new_resource.accept_eula ? "yes | " : ""
              attach_cmd << "/usr/bin/hdiutil attach #{passphrase_cmd} '#{dmg_file}' -nobrowse -mountpoint '/Volumes/#{new_resource.volumes_dir}'"

              shell_out!(attach_cmd, env: { "PAGER" => "true" })
            end
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
          @dmg_file ||= if new_resource.file.nil?
                          "#{Chef::Config[:file_cache_path]}/#{new_resource.dmg_name}.dmg"
                        else
                          new_resource.file
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
