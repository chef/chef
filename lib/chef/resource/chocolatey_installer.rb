require "cgi" unless defined?(CGI)
require "uri" unless defined?(URI)

class Chef
  class Resource
    class ChocolateyInstaller < Chef::Resource
      provides :chocolatey_installer

      description "Use the chocolatey_installer resource to ensure that Chocolatey itself is installed to your specification. Use the Chocolatey Feature resource to customize your install. Then use the Chocolatey Package resource to install packages on Windows via Chocolatey."
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
            download_url "c:\\foo\\foo.nupkg"
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
        description: "A custom URL or path to a Chocolatey package or install script, for use in air-gapped environments or when hosting your own Chocolatey server. Accepts HTTPS URLs, local drive paths (e.g. C:\\packages\\chocolatey.nupkg), and UNC paths to SMB shares (e.g. \\\\server\\share\\chocolatey.nupkg). If not provided, Chocolatey is installed from the official Chocolatey community repository. This sets the value of $env:ChocolateyDownloadUrl so the Chocolatey installer fetches the package from your specified location. If the value points to a PowerShell script (ending in .ps1), that script will be downloaded and executed directly. If it points to a Chocolatey package (.nupkg or similar), the file contents are extracted and the bundled installer is executed."

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

      property :proxy_password, String, sensitive: true,
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

      def download_url_path
        return download_url if download_url.match?(%r{^[a-zA-Z]:[\\/]}) || download_url.start_with?("\\\\")

        ::URI.parse(download_url).path
      rescue URI::InvalidURIError
        download_url
      end

      def download_url_script?
        ::File.extname(download_url_path).casecmp(".ps1") == 0
      end

      def download_destination
        filename = ::File.basename(::CGI.unescape(download_url_path.to_s))
        filename = "chocolatey.nupkg" if filename.empty? || ["/", "\\", "."].include?(filename)

        Chef::Util::PathHelper.join(ChefConfig::Config.etc_chef_dir(windows: true), filename)
      end

      def define_resource_requirements
        requirements.assert(:install, :upgrade).each do |a|
          a.assertion do
            # Both proxy_user and proxy_password must be provided together or not at all.
            # The assertion must return true when the state is valid (both set or both nil).
            new_resource.proxy_user.nil? == new_resource.proxy_password.nil?
          end
          a.failure_message(Chef::Exceptions::ValidationFailed, "You must specify both a proxy_user and a proxy_password")
          a.whyrun("Assuming that if you have configured a 'proxy_user' you must also supply a 'proxy_password'")
        end
      end

      action :install, description: "Installs Chocolatey package manager" do
        # Validate download_url before setting any env vars or attempting PowerShell execution.
        # Blocks URLs with a recognizable but wrong file extension (.html, .exe, etc.).
        # URLs with NO extension (OData-style package API endpoints such as
        # https://server/api/v2/package/chocolatey/2.7.3) are allowed through — the extension
        # check is skipped when the URL path has no extension so that NuGet/Artifactory/Nexus
        # feeds work without requiring a local pre-download.
        if new_resource.download_url
          ext = ::File.extname(new_resource.download_url_path).downcase
          # Block only when a recognizable but wrong file extension is present.
          # Exemptions: no extension (OData/API endpoints), .ps1, .nupkg, or
          # a pure-digit segment (e.g. ".3" from a version path like /chocolatey/2.7.3).
          if !ext.empty? && !ext.match?(/^\.\d+$/) && ext != '.ps1' && ext != '.nupkg'
            raise Chef::Exceptions::ValidationFailed,
              "download_url must point to a .ps1 PowerShell install script or a .nupkg Chocolatey package. Got: #{new_resource.download_url}"
          end
        end

        if new_resource.download_url
          powershell_exec("Set-Item -path env:ChocolateyDownloadUrl -Value '#{new_resource.download_url}'")
        end

        if new_resource.chocolatey_version
          powershell_exec("Set-Item -path env:ChocolateyVersion -Value '#{new_resource.chocolatey_version}'")
        end

        if new_resource.use_native_unzip
          powershell_exec("Set-Item -path env:ChocolateyUseWindowsCompression -Value true")
        end

        if new_resource.ignore_proxy
          powershell_exec("Set-Item -path env:ChocolateyIgnoreProxy -Value true")
        end

        if new_resource.proxy_url
          powershell_exec("Set-Item -path env:ChocolateyProxyLocation -Value '#{new_resource.proxy_url}'")
        end

        if new_resource.proxy_user && new_resource.proxy_password
          powershell_exec("Set-Item -path env:ChocolateyProxyUser -Value '#{new_resource.proxy_user}'; Set-Item -path env:ChocolateyProxyPassword -Value '#{new_resource.proxy_password}'")
        end

        # Handle custom download URLs appropriately based on file type
        converge_if_changed do
          if new_resource.download_url
            Chef::Log.info("Using custom download URL for Chocolatey installation: #{new_resource.download_url}")
            # If it's a PowerShell script, download and execute it directly
            if download_url_script?
              powershell_exec("[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('#{new_resource.download_url}'))").error!
            else
              # nupkg or archive: fully air-gapped environment support.
              # A Chocolatey .nupkg is a ZIP archive containing tools/chocolateyInstall.ps1,
              # which is the actual bootstrapper. Download (if remote), extract, and run it.
              is_filesystem_path = new_resource.download_url.match?(%r{^[a-zA-Z]:[\\/]}) || new_resource.download_url.start_with?("\\\\")
              nupkg_path = is_filesystem_path ? new_resource.download_url : download_destination

              unless is_filesystem_path
                if new_resource.proxy_url && !new_resource.ignore_proxy && new_resource.proxy_user && new_resource.proxy_password
                  ps_download = <<~DLPS
                    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                    $proxyCredential = New-Object System.Management.Automation.PSCredential('#{new_resource.proxy_user}', (ConvertTo-SecureString '#{new_resource.proxy_password}' -AsPlainText -Force))
                    Invoke-WebRequest '#{new_resource.download_url}' -UseBasicParsing -Proxy '#{new_resource.proxy_url}' -ProxyCredential $proxyCredential -OutFile '#{nupkg_path}'
                  DLPS
                  powershell_exec(ps_download).error!
                else
                  proxy_param = (new_resource.proxy_url && !new_resource.ignore_proxy) ? " -Proxy '#{new_resource.proxy_url}'" : ""
                  powershell_exec("[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-WebRequest '#{new_resource.download_url}' -UseBasicParsing#{proxy_param} -OutFile '#{nupkg_path}'").error!
                end
                Chef::Log.info("Downloaded Chocolatey package from #{new_resource.download_url} to #{nupkg_path}")
              end

              ps_code = <<~PS
                # Pre-steps equivalent to those in Chocolatey's install.ps1
                # We need to enable TLS 1.2 support so we set the SecurityProtocol property with a "bitwise or" operation.
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                if (-not $env:ChocolateyInstall) {
                  $env:ChocolateyInstall = Join-Path $env:ALLUSERSPROFILE 'chocolatey'
                  [Environment]::SetEnvironmentVariable('ChocolateyInstall', $env:ChocolateyInstall, 'Machine')
                }
                if (-not (Test-Path $env:ChocolateyInstall)) { New-Item -ItemType Directory -Path $env:ChocolateyInstall -Force | Out-Null }

                $nupkgPath = '#{nupkg_path}'
                $extractPath = Join-Path $env:TEMP 'chocolatey_nupkg_extract'
                if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
                $zipPath = Join-Path $env:TEMP 'chocolatey_nupkg.zip'
                Copy-Item $nupkgPath $zipPath
                Expand-Archive $zipPath $extractPath -Force
                Remove-Item $zipPath -Force
                $installScript = Join-Path $extractPath 'tools\\chocolateyInstall.ps1'
                if (-not (Test-Path $installScript)) { throw "Could not find chocolateyInstall.ps1 in the extracted Chocolatey package at $extractPath" }
                & $installScript
              PS
              powershell_exec(ps_code).error!
            end
          else
            powershell_exec("Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))").error!
          end
        end
      end

      action :upgrade, description: "Upgrades the Chocolatey package manager" do
        proposed_version = if new_resource.chocolatey_version
                             Gem::Version.new(new_resource.chocolatey_version)
                           end

        if new_resource.download_url
          powershell_exec("Set-Item -path env:ChocolateyDownloadUrl -Value '#{new_resource.download_url}'")
        end

        if new_resource.chocolatey_version
          powershell_exec("Set-Item -path env:ChocolateyVersion -Value '#{new_resource.chocolatey_version}'")
        end

        if new_resource.use_native_unzip
          powershell_exec("Set-Item -path env:ChocolateyUseWindowsCompression -Value true")
        end

        if new_resource.ignore_proxy
          powershell_exec("Set-Item -path env:ChocolateyIgnoreProxy -Value true")
        end

        if new_resource.proxy_url
          powershell_exec("Set-Item -path env:ChocolateyProxyLocation -Value '#{new_resource.proxy_url}'")
        end

        if new_resource.proxy_user && new_resource.proxy_password
          powershell_exec("Set-Item -path env:ChocolateyProxyUser -Value '#{new_resource.proxy_user}'; Set-Item -path env:ChocolateyProxyPassword -Value '#{new_resource.proxy_password}'")
        end

        if proposed_version && existing_version < proposed_version
          powershell_exec("Set-Item -path env:ChocolateyVersion -Value '#{proposed_version}'")
        else
          powershell_exec("Remove-Item -path env:ChocolateyVersion -ErrorAction SilentlyContinue")
        end

        converge_by("upgrade choco version") do
          powershell_exec("choco upgrade Chocolatey -y").result
        end
      end

      action :uninstall, description: "Uninstall Chocolatey package manager" do
        # rubocop:disable Style/StringLiteralsInInterpolation
        path = "#{ENV['ALLUSERSPROFILE']}\\chocolatey\\bin"
        # rubocop:enable Style/StringLiteralsInInterpolation
        if File.exist?(path)
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
              $path = ($path.Split(';') | Where-Object { $_ -ine "#{path}" }) -join ";"
              [System.Environment]::SetEnvironmentVariable(
                  'PATH',
                  $path,
                  'Machine'
              )
            CODE
            powershell_exec(powershell_code).error!
          end
        else
          Chef::Log.warn("Chocolatey is already uninstalled.")
        end
      end
    end
  end
end
