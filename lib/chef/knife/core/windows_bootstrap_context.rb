#
# Author:: Seth Chisamore (<schisamo@chef.io>)
# Copyright:: Copyright (c) 2011-2016 Chef Software, Inc.
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

require "chef/knife/core/bootstrap_context"
require "chef/util/path_helper"

class Chef
  class Knife
    module Core
      # Instances of BootstrapContext are the context objects (i.e., +self+) for
      # bootstrap templates. For backwards compatability, they +must+ set the
      # following instance variables:
      # * @config   - a hash of knife's config values
      # * @run_list - the run list for the node to boostrap
      #
      class WindowsBootstrapContext < BootstrapContext

        def initialize(config, run_list, chef_config, secret = nil)
          @config       = config
          @run_list     = run_list
          @chef_config  = chef_config
          @secret       = secret
          # Compatibility with Chef 12 and Chef 11 versions
          begin
            # Pass along the secret parameter for Chef 12
            super(config, run_list, chef_config, secret)
          rescue ArgumentError
            # The Chef 11 base class only has parameters for initialize
            super(config, run_list, chef_config)
          end
        end

        def validation_key
          if File.exist?(File.expand_path(@chef_config[:validation_key]))
            IO.read(File.expand_path(@chef_config[:validation_key]))
          else
            false
          end
        end

        def secret
          escape_and_echo(@config[:secret])
        end

        def trusted_certs_script
          @trusted_certs_script ||= trusted_certs_content
        end

        def config_content
          client_rb = <<~CONFIG
            chef_server_url  "#{@chef_config[:chef_server_url]}"
            validation_client_name "#{@chef_config[:validation_client_name]}"
            file_cache_path   "c:/chef/cache"
            file_backup_path  "c:/chef/backup"
            cache_options     ({:path => "c:/chef/cache/checksums", :skip_expires => true})
          CONFIG
          if @config[:chef_node_name]
            client_rb << %Q{node_name "#{@config[:chef_node_name]}"\n}
          else
            client_rb << "# Using default node name (fqdn)\n"
          end

          if @chef_config[:config_log_level]
            client_rb << %Q{log_level :#{@chef_config[:config_log_level]}\n}
          else
            client_rb << "log_level        :auto\n"
          end

          client_rb << "log_location       #{get_log_location}"

          # We configure :verify_api_cert only when it's overridden on the CLI
          # or when specified in the knife config.
          if !@config[:node_verify_api_cert].nil? || knife_config.key?(:verify_api_cert)
            value = @config[:node_verify_api_cert].nil? ? knife_config[:verify_api_cert] : @config[:node_verify_api_cert]
            client_rb << %Q{verify_api_cert #{value}\n}
          end

          # We configure :ssl_verify_mode only when it's overridden on the CLI
          # or when specified in the knife config.
          if @config[:node_ssl_verify_mode] || knife_config.key?(:ssl_verify_mode)
            value = case @config[:node_ssl_verify_mode]
                    when "peer"
                      :verify_peer
                    when "none"
                      :verify_none
                    when nil
                      knife_config[:ssl_verify_mode]
                    else
                      nil
                    end

            if value
              client_rb << %Q{ssl_verify_mode :#{value}\n}
            end
          end

          if @config[:ssl_verify_mode]
            client_rb << %Q{ssl_verify_mode :#{knife_config[:ssl_verify_mode]}\n}
          end

          if knife_config[:bootstrap_proxy]
            client_rb << "\n"
            client_rb << %Q{http_proxy        "#{knife_config[:bootstrap_proxy]}"\n}
            client_rb << %Q{https_proxy       "#{knife_config[:bootstrap_proxy]}"\n}
            client_rb << %Q{no_proxy          "#{knife_config[:bootstrap_no_proxy]}"\n} if knife_config[:bootstrap_no_proxy]
          end

          if knife_config[:bootstrap_no_proxy]
            client_rb << %Q{no_proxy       "#{knife_config[:bootstrap_no_proxy]}"\n}
          end

          if @config[:secret]
            client_rb << %Q{encrypted_data_bag_secret "c:/chef/encrypted_data_bag_secret"\n}
          end

          unless trusted_certs_script.empty?
            client_rb << %Q{trusted_certs_dir "c:/chef/trusted_certs"\n}
          end

          if Chef::Config[:fips]
            client_rb << <<~CONFIG
              fips true
              chef_version = ::Chef::VERSION.split(".")
              unless chef_version[0].to_i > 12 || (chef_version[0].to_i == 12 && chef_version[1].to_i >= 8)
                raise "FIPS Mode requested but not supported by this client"
              end
            CONFIG
          end

          escape_and_echo(client_rb)
        end

        def get_log_location
          if @chef_config[:config_log_location].equal?(:win_evt)
            %Q{:#{@chef_config[:config_log_location]}\n}
          elsif @chef_config[:config_log_location].equal?(:syslog)
            raise "syslog is not supported for log_location on Windows OS\n"
          elsif @chef_config[:config_log_location].equal?(STDOUT)
            "STDOUT\n"
          elsif @chef_config[:config_log_location].equal?(STDERR)
            "STDERR\n"
          elsif @chef_config[:config_log_location].nil? || @chef_config[:config_log_location].empty?
            "STDOUT\n"
          elsif @chef_config[:config_log_location]
            %Q{"#{@chef_config[:config_log_location]}"\n}
          else
            "STDOUT\n"
          end
        end

        def start_chef
          bootstrap_environment_option = bootstrap_environment.nil? ? "" : " -E #{bootstrap_environment}"
          start_chef = "SET \"PATH=%SystemRoot%\\system32;%SystemRoot%;%SystemRoot%\\System32\\Wbem;%SYSTEMROOT%\\System32\\WindowsPowerShell\\v1.0\\;C:\\ruby\\bin;C:\\opscode\\chef\\bin;C:\\opscode\\chef\\embedded\\bin\"\n"
          start_chef << "chef-client -c c:/chef/client.rb -j c:/chef/first-boot.json#{bootstrap_environment_option}\n"
        end

        def latest_current_windows_chef_version_query
          installer_version_string = nil
          if @config[:prerelease]
            installer_version_string = "&prerelease=true"
          else
            chef_version_string = if knife_config[:bootstrap_version]
                                    knife_config[:bootstrap_version]
                                  else
                                    Chef::VERSION.split(".").first
                                  end

            installer_version_string = "&v=#{chef_version_string}"

            # If bootstrapping a pre-release version add the prerelease query string
            if chef_version_string.split(".").length > 3
              installer_version_string << "&prerelease=true"
            end
          end

          installer_version_string
        end

        def win_wget
          # I tried my best to figure out how to properly url decode and switch / to \
          # but this is VBScript - so I don't really care that badly.
          win_wget = <<~WGET
            url = WScript.Arguments.Named("url")
            path = WScript.Arguments.Named("path")
            proxy = null
            '* Vaguely attempt to handle file:// scheme urls by url unescaping and switching all
            '* / into \.  Also assume that file:/// is a local absolute path and that file://<foo>
            '* is possibly a network file path.
            If InStr(url, "file://") = 1 Then
            url = Unescape(url)
            If InStr(url, "file:///") = 1 Then
            sourcePath = Mid(url, Len("file:///") + 1)
            Else
            sourcePath = Mid(url, Len("file:") + 1)
            End If
            sourcePath = Replace(sourcePath, "/", "\\")

            Set objFSO = CreateObject("Scripting.FileSystemObject")
            If objFSO.Fileexists(path) Then objFSO.DeleteFile path
            objFSO.CopyFile sourcePath, path, true
            Set objFSO = Nothing

            Else
            Set objXMLHTTP = CreateObject("MSXML2.ServerXMLHTTP")
            Set wshShell = CreateObject( "WScript.Shell" )
            Set objUserVariables = wshShell.Environment("USER")

            rem http proxy is optional
            rem attempt to read from HTTP_PROXY env var first
            On Error Resume Next

            If NOT (objUserVariables("HTTP_PROXY") = "") Then
            proxy = objUserVariables("HTTP_PROXY")

            rem fall back to named arg
            ElseIf NOT (WScript.Arguments.Named("proxy") = "") Then
            proxy = WScript.Arguments.Named("proxy")
            End If

            If NOT isNull(proxy) Then
            rem setProxy method is only available on ServerXMLHTTP 6.0+
            Set objXMLHTTP = CreateObject("MSXML2.ServerXMLHTTP.6.0")
            objXMLHTTP.setProxy 2, proxy
            End If

            On Error Goto 0

            objXMLHTTP.open "GET", url, false
            objXMLHTTP.send()
            If objXMLHTTP.Status = 200 Then
            Set objADOStream = CreateObject("ADODB.Stream")
            objADOStream.Open
            objADOStream.Type = 1
            objADOStream.Write objXMLHTTP.ResponseBody
            objADOStream.Position = 0
            Set objFSO = Createobject("Scripting.FileSystemObject")
            If objFSO.Fileexists(path) Then objFSO.DeleteFile path
            Set objFSO = Nothing
            objADOStream.SaveToFile path
            objADOStream.Close
            Set objADOStream = Nothing
            End If
            Set objXMLHTTP = Nothing
            End If
          WGET
          escape_and_echo(win_wget)
        end

        def win_wget_ps
          win_wget_ps = <<~WGET_PS
            param(
               [String] $remoteUrl,
               [String] $localPath
            )

            $ProxyUrl = $env:http_proxy;
            $webClient = new-object System.Net.WebClient;

            if ($ProxyUrl -ne '') {
              $WebProxy = New-Object System.Net.WebProxy($ProxyUrl,$true)
              $WebClient.Proxy = $WebProxy
            }

            $webClient.DownloadFile($remoteUrl, $localPath);
          WGET_PS

          escape_and_echo(win_wget_ps)
        end

        def install_chef
          # The normal install command uses regular double quotes in
          # the install command, so request such a string from install_command
          install_command('"') + "\n" + fallback_install_task_command
        end

        def bootstrap_directory
          "C:\\chef"
        end

        def local_download_path
          "%TEMP%\\chef-client-latest.msi"
        end

        def msi_url(machine_os = nil, machine_arch = nil, download_context = nil)
          # The default msi path has a number of url query parameters - we attempt to substitute
          # such parameters in as long as they are provided by the template.

          if @config[:install].nil? || @config[:msi_url].empty?
            url = "https://www.chef.io/chef/download?p=windows"
            url += "&pv=#{machine_os}" unless machine_os.nil?
            url += "&m=#{machine_arch}" unless machine_arch.nil?
            url += "&DownloadContext=#{download_context}" unless download_context.nil?
            url += latest_current_windows_chef_version_query
          else
            @config[:msi_url]
          end
        end

        def first_boot
          escape_and_echo(super.to_json)
        end

        # escape WIN BATCH special chars
        # and prefixes each line with an
        # echo
        def escape_and_echo(file_contents)
          file_contents.gsub(/^(.*)$/, 'echo.\1').gsub(/([(<|>)^])/, '^\1')
        end

        private

        def install_command(executor_quote)
          if @config[:install_as_service]
            "msiexec /qn /log #{executor_quote}%CHEF_CLIENT_MSI_LOG_PATH%#{executor_quote} /i #{executor_quote}%LOCAL_DESTINATION_MSI_PATH%#{executor_quote} ADDLOCAL=#{executor_quote}ChefClientFeature,ChefServiceFeature#{executor_quote}"
          else
            "msiexec /qn /log #{executor_quote}%CHEF_CLIENT_MSI_LOG_PATH%#{executor_quote} /i #{executor_quote}%LOCAL_DESTINATION_MSI_PATH%#{executor_quote}"
          end
        end

        # Returns a string for copying the trusted certificates on the workstation to the system being bootstrapped
        # This string should contain both the commands necessary to both create the files, as well as their content
        def trusted_certs_content
          content = ""
          if @chef_config[:trusted_certs_dir]
            Dir.glob(File.join(Chef::Util::PathHelper.escape_glob_dir(@chef_config[:trusted_certs_dir]), "*.{crt,pem}")).each do |cert|
              content << "> #{bootstrap_directory}/trusted_certs/#{File.basename(cert)} (\n" +
                escape_and_echo(IO.read(File.expand_path(cert))) + "\n)\n"
            end
          end
          content
        end

        def client_d_content
          content = ""
          if @chef_config[:client_d_dir] && File.exist?(@chef_config[:client_d_dir])
            root = Pathname(@chef_config[:client_d_dir])
            root.find do |f|
              relative = f.relative_path_from(root)
              if f != root
                file_on_node = "#{bootstrap_directory}/client.d/#{relative}".tr("/", "\\")
                if f.directory?
                  content << "mkdir #{file_on_node}\n"
                else
                  content << "> #{file_on_node} (\n" +
                    escape_and_echo(IO.read(File.expand_path(f))) + "\n)\n"
                end
              end
            end
          end
          content
        end

        def fallback_install_task_command
          # This command will be executed by schtasks.exe in the batch
          # code below. To handle tasks that contain arguments that
          # need to be double quoted, schtasks allows the use of single
          # quotes that will later be converted to double quotes
          command = install_command("'")
          <<~EOH
            @set MSIERRORCODE=!ERRORLEVEL!
            @if ERRORLEVEL 1 (
                @echo WARNING: Failed to install Chef Client MSI package in remote context with status code !MSIERRORCODE!.
                @echo WARNING: This may be due to a defect in operating system update KB2918614: http://support.microsoft.com/kb/2918614
                @set OLDLOGLOCATION="%CHEF_CLIENT_MSI_LOG_PATH%-fail.log"
                @move "%CHEF_CLIENT_MSI_LOG_PATH%" "!OLDLOGLOCATION!" > NUL
                @echo WARNING: Saving installation log of failure at !OLDLOGLOCATION!
                @echo WARNING: Retrying installation with local context...
                @schtasks /create /f  /sc once /st 00:00:00 /tn chefclientbootstraptask /ru SYSTEM /rl HIGHEST /tr \"cmd /c #{command} & sleep 2 & waitfor /s %computername% /si chefclientinstalldone\"

                @if ERRORLEVEL 1 (
                    @echo ERROR: Failed to create Chef Client installation scheduled task with status code !ERRORLEVEL! > "&2"
                ) else (
                    @echo Successfully created scheduled task to install Chef Client.
                    @schtasks /run /tn chefclientbootstraptask
                    @if ERRORLEVEL 1 (
                        @echo ERROR: Failed to execut Chef Client installation scheduled task with status code !ERRORLEVEL!. > "&2"
                    ) else (
                        @echo Successfully started Chef Client installation scheduled task.
                        @echo Waiting for installation to complete -- this may take a few minutes...
                        waitfor chefclientinstalldone /t 600
                        if ERRORLEVEL 1 (
                            @echo ERROR: Timed out waiting for Chef Client package to install
                        ) else (
                            @echo Finished waiting for Chef Client package to install.
                        )
                        @schtasks /delete /f /tn chefclientbootstraptask > NUL
                    )
                )
            ) else (
                @echo Successfully installed Chef Client package.
            )
          EOH
        end
      end
    end
  end
end
