class Chef
  class Resource
    class ChocolateyInstaller < Chef::Resource
      provides :chocolatey_installer

      description "Use the Chocolatey Installer resource to ensure that Choco is installed to your specification. Use the Chocolatey Feature resource to customize your install"
      introduced "18.1"
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
      DOC

      allowed_actions :install, :uninstall

      property :download_url, String,
        description: "The URL to download Chocolatey from. This defaults to the value of $env:chocolateyDownloadUrl, if it is set, and otherwise falls back to the official Chocolatey community repository to download the Chocolatey package. It can be used for offline installation by providing a path to a Chocolatey.nupkg."

      property :chocolatey_version, String,
        description: "Specifies a target version of Chocolatey to install. By default, the latest stable version is installed. This will use the value in $env:chocolateyVersion by default, if that environment variable is present. This parameter is ignored if download_url is set."

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
        current_state = fetch_choco_installer
        current_value_does_not_exist! if current_state == false
        current_state
      end

      def fetch_choco_installer
        ::File.exist?("#{ENV["ALLUSERSPROFILE"]}\\chocolatey\\bin\\choco.exe")
      end

      def define_resource_requirements
        [ new_resource.proxy_user, new_resource.proxy_password ].each do
          requirements.assert(:install) do |a|
            a.assertion do
              (!new_resource.proxy_user.nil? && new_resource.proxy_password.nil?) || (new_resource.proxy_user.nil? && !new_resource.proxy_password.nil?)
            end
            a.failure_message(Chef::Exceptions::ValidationFailed, "You must specify both a proxy_user and a proxy_password")
            a.whyrun("Assuming that if you have configured a 'proxy_user' you must also supply a 'proxy_password'")
          end
        end
      end

      action :install, description: "Installs Chocolatey package manager" do
        unless new_resource.download_url.nil?
          "Set-Item -path env:chocolateyDownloadUrl -Value #{new_resource.download_url}"
        end

        unless new_resource.chocolatey_version.nil?
          "Set-Item -path env:chocolateyVersion -Value #{new_resource.chocolatey_version}"
        end

        if new_resource.use_native_unzip == true
          "Set-Item -path env:chocolateyUseWindowsCompression -Value true"
        end

        if new_resource.ignore_proxy == true
          "Set-Item -path env:chocolateyIgnoreProxy -Value true"
        end

        unless new_resource.proxy_url.nil?
          "Set-Item -path env:chocolateyProxyLocation -Value #{new_resource.proxy_url}"
        end

        if !new_resource.proxy_user.nil? && !new_resource.proxy_password.nil?
          "Set-Item -path env:chocolateyProxyUser -Value #{new_resource.proxy_user}; Set-Item -path env:chocolateyProxyPassword -Value #{new_resource.proxy_password}"
        # elsif (!new_resource.proxy_user.nil? && new_resource.proxy_password.nil?) || (new_resource.proxy_user.nil? && !new_resource.proxy_password.nil?)
        #   Chef::Log.error("Both a Proxy User and a Proxy Password must be set or neither can be set")
        end

        converge_if_changed do
          # the '-bor' parameter below is a Bitwise Or of 2 bytes that is used to create the correct Security Protocol offset with and results in creating TLS 1.2
          powershell_code = <<-CODE
            Set-ExecutionPolicy Bypass -Scope Process -Force;
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
            iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
          CODE
          powershell_exec(powershell_code).result
        end
      end

      action :uninstall, description: "Uninstall Chocolatey package manager" do
        converge_by("Uninstall Choco") do
          path = 'c:\programdata\chocolatey\bin' # rubocop:disable Style/StringLiterals
          powershell_code = <<~CODE
            Remove-Item $env:ALLUSERSPROFILE\\chocolatey -Recurse -Force
            [Environment]::SetEnvironmentVariable("ChocolateyLastPathUpdate", $null ,"User")
            [Environment]::SetEnvironmentVariable("ChocolateyToolsLocation", $null ,"User")
            [Environment]::SetEnvironmentVariable("ChocolateyInstall", $null ,"Machine")
            $path = [System.Environment]::GetEnvironmentVariable(
                'PATH',
                'Machine'
            )
            $path = ($path.Split(';') | Where-Object { $_ -ne #{path} }) -join ";"
            [System.Environment]::SetEnvironmentVariable(
                'PATH',
                $path,
                'Machine'
            )
          CODE
          powershell_exec(powershell_code).result
        end
      end
    end
  end
end
