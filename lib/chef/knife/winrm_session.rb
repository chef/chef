#
# Author:: Steven Murawski <smurawski@chef.io>
# Copyright:: Copyright (c) 2015-2016 Chef Software, Inc.
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

require_relative "../knife"
require_relative "../application"
require "winrm"
require "winrm-elevated"

class Chef
  class Knife
    class WinrmSession
      attr_reader :host, :endpoint, :port, :output, :error, :exit_code

      def initialize(options)
        configure_proxy

        @host = options[:host]
        @port = options[:port]
        @user = options[:user]
        @shell_args = [ options[:shell] ]
        @shell_args << { codepage: options[:codepage] } if options[:shell] == :cmd
        url = "#{options[:host]}:#{options[:port]}/wsman"
        scheme = options[:transport] == :ssl ? "https" : "http"
        @endpoint = "#{scheme}://#{url}"

        opts = {
          user: @user,
          password: options[:password],
          basic_auth_only: options[:basic_auth_only],
          disable_sspi: options[:disable_sspi],
          no_ssl_peer_verification: options[:no_ssl_peer_verification],
          ssl_peer_fingerprint: options[:ssl_peer_fingerprint],
          endpoint: endpoint,
          transport: options[:transport],
        }
        options[:transport] == :kerberos ? opts.merge!({ service: options[:service], realm: options[:realm] }) : opts.merge!({ ca_trust_path: options[:ca_trust_path] })
        opts[:operation_timeout] = options[:operation_timeout] if options[:operation_timeout]
        Chef::Log.debug("WinRM::WinRMWebService options: #{opts}")
        Chef::Log.debug("Endpoint: #{endpoint}")
        Chef::Log.debug("Transport: #{options[:transport]}")

        @winrm_session = WinRM::Connection.new(opts)
        @winrm_session.logger = Chef::Log

        transport = @winrm_session.send(:transport)
        http_client = transport.instance_variable_get(:@httpcli)
        Chef::HTTP::DefaultSSLPolicy.new(http_client.ssl_config).set_custom_certs
      end

      def relay_command(command)
        session_result = WinRM::Output.new
        @winrm_session.shell(*@shell_args) do |shell|
          shell.username = @user.split("\\").last if shell.respond_to?(:username)
          session_result = shell.run(command) do |stdout, stderr|
            print_data(@host, stdout) if stdout
            print_data(@host, stderr, :red) if stderr
          end
        end
        @exit_code = session_result.exitcode
        session_result
      rescue WinRM::WinRMHTTPTransportError, WinRM::WinRMAuthorizationError => e
        @exit_code = 401
        raise e
      end

      private

      def print_data(host, data, color = :cyan)
        if data =~ /\n/
          data.split(/\n/).each { |d| print_data(host, d, color) }
        elsif !data.nil?
          print Chef::Knife::Winrm.ui.color(host, color)
          puts " #{data}"
        end
      end

      def configure_proxy
        if Chef::Config.respond_to?(:export_proxies)
          Chef::Config.export_proxies
        else
          Chef::Application.new.configure_proxy_environment_variables
        end
      end
    end
  end
end
