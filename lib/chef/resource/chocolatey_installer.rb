class Chef
  class Resource
    class ChocolateyInstaller < Chef::Resource
      provides :chocolatey_installer

      description "Use the chocolatey_installer resource to ensure that Chocolatey itself is installed to your specification. Use the Chocolatey Feature resource to customize your install. Then use the Chocolatey Package resource to install pacakges on Windows via Chocolatey."
      introduced "18.3"
      examples <<~DOC
          **Install Chocolatey**

          ```ruby
          chocolatey_installer 'latest' do
            action :install
          end
          ```

          **Uninstall Chocolatey**

          ```ruby
          chocolatey_installer 'Some random verbiage' do
            action :uninstall
          end
          ```

          **Install Chocolatey with Parameters**

          ```ruby
          chocolatey_installer 'latest' do
            action :install
            download_url "https://www.contoso.com/foo"
            chocolatey_version '2.12.24'
          end
          ```

          ```ruby
          chocolatey_installer 'latest' do
            action :install
            download_url "c:\\foo\foo.nupkg"
            chocolatey_version '2.12.24'
          end
          ```

          **Upgrade Chocolatey with Parameters**

          ```ruby
          chocolatey_installer 'latest' do
            action :upgrade
            chocolatey_version '2.12.24'
          end
          ```
      DOC

      allowed_actions :install, :uninstall, :upgrade

      property :download_url, String,
        description: "The URL to download Chocolatey from. This sets the value of $env:ChocolateyDownloadUrl and causes the installer to choose an alternate download location. If this is not set, instals falls back to the official Chocolatey community repository to download the Chocolatey package. It can also be used for offline installation by providing a path to a Chocolatey.nupkg."

      property :chocolatey_version, String,
        description: "Specifies a target version of Chocolatey to install. By default, the latest stable version is installed. This will use the value in $env:ChocolateyVersion by default, if that environment variable is present. This parameter is ignored if download_url is set."

      property :use_native_unzip, [TrueClass, FalseClass], default: false,
        description: "If set, uses built-in Windows decompression tools instead of 7zip when unpacking the downloaded nupkg. This will be set by default if use_native_unzip is set to a value other than 'false' or '0'. This parameter will be ignored in PS 5+ in favour of using the Expand-Archive built in PowerShell cmdlet directly."

      property :ignore_proxy, [TrueClass, FalseClass], default: false,
        description: "If set, ignores any configured proxy. This will override any proxy environment variables or parameters. This will be set by default if ignore_proxy is set to a value other than 'false' or '0'."

      property :proxy_url, String,
        description: "Specifies the proxy URL to use during the download."

      property :proxy_user, String,
        description: "The username to use to build a proxy credential with. Will be consumed by the proxy_credential property if both this property and proxy_password are set"

      property :proxy_password, String,
        description: "The password to use to build a proxy credential with. Will be consumed by the proxy_credential property if both this property and proxy_user are set"

      load_current_value do
        current_state = is_choco_installed?
        current_value_does_not_exist! if current_state == false
        current_state
      end

      def is_choco_installed?
        ::File.exist?("#{ENV["ALLUSERSPROFILE"]}\\chocolatey\\bin\\choco.exe")
      end

      def get_choco_version
        powershell_exec("choco --version").result
      end

      def existing_version
        Gem::Version.new(get_choco_version)
      end

      def define_resource_requirements
        requirements.assert(:install, :upgrade).each do |a|
          a.assertion do
            # This is an exclusive OR - XOR - we're trying to coax an error out if one, but not both,
            # parameters are empty.
            new_resource.proxy_user.nil? != new_resource.proxy_password.nil?
          end
          a.failure_message(Chef::Exceptions::ValidationFailed, "You must specify both a proxy_user and a proxy_password")
          a.whyrun("Assuming that if you have configured a 'proxy_user' you must also supply a 'proxy_password'")
        end
      end

      action :install, description: "Installs Chocolatey package manager" do
        if new_resource.download_url
          powershell_exec("Set-Item -path env:ChocolateyDownloadUrl -Value #{new_resource.download_url}")
        end

        if new_resource.chocolatey_version
          powershell_exec("Set-Item -path env:ChocolateyVersion -Value #{new_resource.chocolatey_version}")
        end

        if new_resource.use_native_unzip
          powershell_exec("Set-Item -path env:ChocolateyUseWindowsCompression -Value true")
        end

        if new_resource.ignore_proxy
          powershell_exec("Set-Item -path env:ChocolateyIgnoreProxy -Value true")
        end

        if new_resource.proxy_url
          powershell_exec("Set-Item -path env:ChocolateyProxyLocation -Value #{new_resource.proxy_url}")
        end

        if new_resource.proxy_user && new_resource.proxy_password
          powershell_exec("Set-Item -path env:ChocolateyProxyUser -Value #{new_resource.proxy_user}; Set-Item -path env:ChocolateyProxyPassword -Value #{new_resource.proxy_password}")
        end

        # note that Invoke-Expression is being called on the downloaded script (outer parens),
        # not triggering the script download (inner parens)
        converge_if_changed do
          powershell_exec("Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))").error!
        end
      end

      action :upgrade, description: "Upgrades the Chocolatey package manager" do
        if new_resource.chocolatey_version
          proposed_version = Gem::Version.new(new_resource.chocolatey_version)
        else
          proposed_version = nil
        end

        if new_resource.download_url
          powershell_exec("Set-Item -path env:ChocolateyDownloadUrl -Value #{new_resource.download_url}")
        end

        if new_resource.chocolatey_version
          powershell_exec("Set-Item -path env:ChocolateyVersion -Value #{new_resource.chocolatey_version}")
        end

        if new_resource.use_native_unzip
          powershell_exec("Set-Item -path env:ChocolateyUseWindowsCompression -Value true")
        end

        if new_resource.ignore_proxy
          powershell_exec("Set-Item -path env:ChocolateyIgnoreProxy -Value true")
        end

        if new_resource.proxy_url
          powershell_exec("Set-Item -path env:ChocolateyProxyLocation -Value #{new_resource.proxy_url}")
        end

        if new_resource.proxy_user && new_resource.proxy_password
          powershell_exec("Set-Item -path env:ChocolateyProxyUser -Value #{new_resource.proxy_user}; Set-Item -path env:ChocolateyProxyPassword -Value #{new_resource.proxy_password}")
        end

        if proposed_version && existing_version < proposed_version
          powershell_exec("Set-Item -path env:ChocolateyVersion -Value #{proposed_version}")
        else
          powershell_exec("Remove-Item -path env:ChocolateyVersion")
        end

        converge_by("upgrade choco version") do
          powershell_exec("choco upgrade Chocolatey -y").result
        end
      end

      action :uninstall, description: "Uninstall Chocolatey package manager" do
        path = "c:\\programdata\\chocolatey\\bin"
        if File.exists?(path)
          converge_by("Uninstall Choco") do
            powershell_code = <<~CODE
              Remove-Item $env:ALLUSERSPROFILE\\chocolatey -Recurse -Force
              [Environment]::SetEnvironmentVariable("ChocolateyLastPathUpdate", $null ,"User")
              [Environment]::SetEnvironmentVariable("ChocolateyToolsLocation", $null ,"User")
              [Environment]::SetEnvironmentVariable("ChocolateyInstall", $null ,"Machine")
              $path = [System.Environment]::GetEnvironmentVariable(
                  'PATH',
                  'Machine'
              )
              $path = ($path.Split(';') | Where-Object { $_ -ne "#{path}" }) -join ";"
              [System.Environment]::SetEnvironmentVariable(
                  'PATH',
                  $path,
                  'Machine'
              )
            CODE
            powershell_exec(powershell_code).error!
          end
        end
        Chef::Log.warn("Chocolatey is already uninstalled.")
      end
    end
  end
end