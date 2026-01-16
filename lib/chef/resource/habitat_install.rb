#
#  Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
require_relative "../http/simple"
require_relative "../resource"
class Chef
  class Resource
    class HabitatInstall < Chef::Resource
      provides :habitat_install, target_mode: true
      target_mode support: :full

      description "Use the **habitat_install** resource to install Chef Habitat."
      introduced "17.3"
      examples <<~DOC
      **Installation Without a Resource Name**

      ```ruby
      habitat_install
      ```

      **Installation specifying a habitat builder URL**

      ```ruby
      habitat_install 'install habitat' do
        bldr_url 'http://localhost'
      end
      ```

      **Installation specifying version and habitat builder URL**

      ```ruby
      habitat_install 'install habitat' do
        bldr_url 'http://localhost'
        hab_version '1.5.50'
      end
      ```
      DOC

      property :name, String, default: "install habitat",
        description: "Name of the resource block. This has no impact other than logging."

      property :install_url, String, default: "https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.sh",
        description: "URL to the install script, default is from the [habitat repo](https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.sh) ."

      property :bldr_url, String,
        description: "Optional URL to an alternate Habitat Builder."

      property :create_user, [true, false], default: true,
        description: "Creates the `hab` system user."

      property :tmp_dir, String,
        description: "Sets TMPDIR environment variable for location to place temp files. Note: This is required if `/tmp` and `/var/tmp` are mounted `noexec`."

      property :license, String, equal_to: ["accept"],
        description: "Specifies acceptance of habitat license when set to `accept`."

      property :hab_version, String,
        description: "Specify the version of `Habitat` you would like to install."

      action :install, description: "Installs Habitat. Does nothing if the `hab` binary is found in the default location for the system (`/bin/hab` on Linux, `/usr/local/bin/hab` on macOS, `C:/habitat/hab.exe` on Windows)" do
        if ::TargetIO::File.exist?(hab_path)
          cmd = shell_out!([hab_path, "--version"].flatten.compact.join(" "))
          version = %r{hab (\d*\.\d*\.\d[^\/]*)}.match(cmd.stdout)[1]
          return if version == new_resource.hab_version
        end

        if windows?
          # Retrieve version information
          uri = "https://packages.chef.io/files"
          package_name = "hab-x86_64-windows"
          habfile = "#{Chef::Config[:file_cache_path]}/#{package_name}.zip"

          # TODO: Figure out how to properly validate the shasum for windows. Doesn't seem it's published
          # as a .sha265sum like for the linux .tar.gz
          download = "#{uri}/stable/habitat/latest/hab-x86_64-windows.zip"

          remote_file habfile do
            source download
          end

          archive_file "#{package_name}.zip" do
            path habfile
            destination "#{Chef::Config[:file_cache_path]}/habitat"
            action :extract
            not_if { ::TargetIO::Dir.exist?("c:\\habitat") }
          end

          directory "c:\\habitat" do
            notifies :run, "powershell_script[installing from archive]", :immediately
          end

          powershell_script "installing from archive" do
            code <<-EOH
      Move-Item -Path #{Chef::Config[:file_cache_path]}/habitat/hab-*/* -Destination C:/habitat -Force
            EOH
            action :nothing
          end

          # TODO: This won't self heal if missing until the next upgrade
          windows_path "C:\\habitat" do
            action :add
          end
        else
          package %w{curl tar gzip}

          if new_resource.create_user
            group "hab"

            user "hab" do
              gid "hab"
              system true
            end
          end

          remote_file ::File.join(Chef::Config[:file_cache_path], "hab-install.sh") do
            source new_resource.install_url
            sensitive true
            mode 0755
          end

          execute "installing with hab-install.sh" do
            command hab_command
            environment(
              {
                "HAB_BLDR_URL" => "bldr_url",
                "TMPDIR" => "tmp_dir",
              }.each_with_object({}) do |(var, property), env|
                env[var] = new_resource.send(property.to_sym) if new_resource.send(property.to_sym)
              end
            )
          end
        end
        execute "hab license accept" if new_resource.license == "accept"
      end

      # TODO: Work out cleanest method to implement upgrade that will support effortless installs as well as standard chef-client
      # action :upgrade do
      #   if platform_family?('windows')
      #     # Retrieve version information
      #     uri = 'https://packages.chef.io/files'
      #     package_name = 'hab-x86_64-windows'
      #     zipfile = "#{Chef::Config[:file_cache_path]}/#{package_name}.zip"

      #     # TODO: Figure out how to properly validate the shasum for windows. Doesn't seem it's published
      #     # as a .sha265sum like for the linux .tar.gz
      #     download = "#{uri}/stable/habitat/latest/hab-x86_64-windows.zip"

      #     remote_file zipfile do
      #       source download
      #     end

      #     if Chef::VERSION.to_i < 15
      #       ruby_block "#{package_name}.zip" do
      #         block do
      #           require 'zip'
      #           Zip::File.open(zipfile) do |zip_file|
      #             zip_file.each do |f|
      #               fpath = "#{Chef::Config[:file_cache_path]}/habitat/" + f.name
      #               zip_file.extract(f, fpath) # unless ::File.exist?(fpath)
      #             end
      #           end
      #         end
      #         action :run
      #       end
      #     else
      #       archive_file "#{package_name}.zip" do
      #         path zipfile
      #         destination "#{Chef::Config[:file_cache_path]}/habitat"
      #         action :extract
      #       end
      #     end

      #     powershell_script 'installing from archive' do
      #       code <<-EOH
      #       Move-Item -Path #{Chef::Config[:file_cache_path]}/habitat/hab-*/* -Destination C:/habitat -Force
      #       EOH
      #     end

      #     # TODO: This won't self heal if missing until the next upgrade
      #     if Chef::VERSION.to_i < 14
      #       env 'PATH_c-habitat' do
      #         key_name 'PATH'
      #         delim ';' # this was missing
      #         value 'C:\habitat'
      #         action :modify
      #       end
      #     else
      #       windows_path 'C:\habitat' do
      #         action :add
      #       end
      #     end
      #   else
      #     remote_file ::File.join(Chef::Config[:file_cache_path], 'hab-install.sh') do
      #       source new_resource.install_url
      #       sensitive true
      #     end

      #     execute 'installing with hab-install.sh' do
      #       command hab_command
      #       environment(
      #         {
      #           'HAB_BLDR_URL' => 'bldr_url',
      #           'TMPDIR' => 'tmp_dir',
      #         }.each_with_object({}) do |(var, property), env|
      #           env[var] = new_resource.send(property.to_sym) if new_resource.send(property.to_sym)
      #         end
      #       )
      #       not_if { ::File.exist?('/bin/hab') }
      #     end
      #   end
      # end

      action_class do
        use "../resource/habitat/habitat_shared"

        def hab_path
          if macos?
            "/usr/local/bin/hab"
          elsif windows?
            "C:/habitat/hab.exe"
          else
            "/bin/hab"
          end
        end

        def hab_command
          cmd = "#{Chef::Config[:file_cache_path]}/hab-install.sh"
          cmd << " -v #{new_resource.hab_version} " if new_resource.hab_version
          cmd
        end
      end
    end
  end
end
