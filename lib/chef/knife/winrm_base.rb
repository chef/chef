#
# Author:: Seth Chisamore (<schisamo@chef.io>)
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

require_relative "../knife"

class Chef
  class Knife
    module WinrmBase

      # It includes supported WinRM authentication protocol.
      WINRM_AUTH_PROTOCOL_LIST ||= %w{basic negotiate kerberos}.freeze

      # :nodoc:
      # Would prefer to do this in a rational way, but can't be done b/c of
      # Mixlib::CLI's design :(
      def self.included(includer)
        includer.class_eval do

          deps do
            require_relative "../encrypted_data_bag_item"
            require "kconv"
            require "readline"
            require_relative "../json_compat"
          end

          option :winrm_user,
            short: "-x USERNAME",
            long: "--winrm-user USERNAME",
            description: "The WinRM username",
            default: "Administrator"

          option :winrm_password,
            short: "-P PASSWORD",
            long: "--winrm-password PASSWORD",
            description: "The WinRM password"

          option :winrm_shell,
            long: "--winrm-shell SHELL",
            description: "The WinRM shell type. If set to 'elevated' the command runs in PowerShell via a scheduled task",
            default: :cmd,
            in: %w{cmd powershell elevated},
            proc: Proc.new { |shell| shell.to_sym }

          option :winrm_transport,
            short: "-w TRANSPORT",
            long: "--winrm-transport TRANSPORT",
            description: "The WinRM transport type",
            in: %w{ssl plaintext},
            default: "plaintext"

          option :winrm_port,
            short: "-p PORT",
            long: "--winrm-port PORT",
            description: "The WinRM port, by default this is '5985' for 'plaintext' and '5986' for 'ssl' winrm transport"

          option :kerberos_keytab_file,
            short: "-T KEYTAB_FILE",
            long: "--keytab-file KEYTAB_FILE",
            description: "The Kerberos keytab file used for authentication"

          option :kerberos_realm,
            short: "-R KERBEROS_REALM",
            long: "--kerberos-realm KERBEROS_REALM",
            description: "The Kerberos realm used for authentication"

          option :kerberos_service,
            short: "-S KERBEROS_SERVICE",
            long: "--kerberos-service KERBEROS_SERVICE",
            description: "The Kerberos service used for authentication"

          option :ca_trust_file,
            short: "-f CA_TRUST_FILE",
            long: "--ca-trust-file CA_TRUST_FILE",
            description: "The Certificate Authority (CA) trust file used for SSL transport"

          option :winrm_ssl_verify_mode,
            long: "--winrm-ssl-verify-mode SSL_VERIFY_MODE",
            description: "The WinRM peer verification mode",
            default: :verify_peer,
            in: %w{verify_peer verify_none},
            proc: Proc.new { |verify_mode| verify_mode.to_sym }

          option :ssl_peer_fingerprint,
            long: "--ssl-peer-fingerprint FINGERPRINT",
            description: "SSL Cert Fingerprint to bypass normal cert chain checks"

          option :winrm_authentication_protocol,
            long: "--winrm-authentication-protocol AUTHENTICATION_PROTOCOL",
            description: "The authentication protocol used during WinRM communication. Default is 'negotiate'.",
            in: WINRM_AUTH_PROTOCOL_LIST,
            default: "negotiate"

          option :session_timeout,
            long: "--session-timeout Minutes",
            description: "The timeout for the client for the maximum length of the WinRM session",
            default: 30

          option :winrm_codepage,
            long: "--winrm-codepage Codepage",
            description: "The codepage to use for the WinRM command shell",
            default: 65001
        end
      end
    end
  end
end
