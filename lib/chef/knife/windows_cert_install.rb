# Author:: Mukta Aphale (<mukta.aphale@clogeny.com>)
# Copyright:: Copyright (c) 2014-2016 Chef Software, Inc.
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
require "chef-utils" unless defined?(ChefUtils::CANARY)

class Chef
  class Knife
    class WindowsCertInstall < Knife

      banner "knife windows cert install CERT [CERT] (options)"

      option :cert_passphrase,
        short: "-cp PASSWORD",
        long: "--cert-passphrase PASSWORD",
        description: "Passphrase for certificate."

      def get_cert_passphrase
        config[:cert_passphrase] || ui.ask("Enter given certificate's passphrase (empty for no passphrase): ", echo: false)
      end

      def run
        STDOUT.sync = STDERR.sync = true

        unless ChefUtils.windows?
          ui.error "Certificate can be installed on Windows system only"
          exit 1
        end

        if @name_args.empty?
          ui.error "Please specify the certificate path. e.g-  'knife windows cert install <path>"
          exit 1
        end
        file_path = @name_args.first
        cert_passphrase = get_cert_passphrase

        begin
          ui.info "Adding certificate to the Windows Certificate Store..."
          result = `powershell.exe -Command " '#{cert_passphrase}' | certutil -importPFX '#{file_path}' AT_KEYEXCHANGE"`
          if $?.exitstatus == 0
            ui.info "Certificate added to Certificate Store"
          else
            ui.info "Error adding the certificate. Use -VV option for details"
          end
          Chef::Log.debug "#{result}"
        rescue => e
          puts "ERROR: + #{e}"
        end
      end
    end
  end
end
