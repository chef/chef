#
# Author:: Richard Lavey (richard.lavey@calastone.com)
#
# Copyright:: 2015-2017, Calastone Ltd.
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
    class WindowsCertificateBinding < Chef::Resource
      unified_mode true

      provides :windows_certificate_binding
      description "Use the **windows_certificate_binding** resource to bind a certificate from the Windows Certificate Store to a port to enable TLS communication."
      introduced "17.2"
      examples <<~DOC
      **Bind a certificate from the personal store matching the subject 'me.acme.com' to the default HTTPS port**
      ```ruby
      windows_certificate_binding 'me.acme.com'
      ```

      **Bind to a custom app ID instead of using the IIS default**
      ```ruby
      windows_certificate_binding 'me.acme.com' do
        app_id "{12345678-e14b-4a21-b022-59fc669b0914}"
      end
      ```

      **Bind to a port other than 443**
      ```ruby
      windows_certificate_binding 'me.acme.com' do
        port 4334
      end
      ```

      **Bind a certificate from the CA store using the hash as the identifier**
      ```ruby
      windows_certificate_binding "me.acme.com" do
          cert_name "d234567890a23f567c901e345bc8901d34567890"
          name_kind :hash
          store_name 'CA'x
      end
      ```
      DOC

      property :cert_name, String, name_property: true, description: "The thumbprint(hash) or subject that identifies the certificate to be bound."

      property :name_kind, Symbol, equal_to: %i{hash subject}, default: :subject, description: "The type of identifer to match the `cert_name` to. ``:hash` to match by a certificate hash or `:subject` to match by the certificate subject."

      property :address, String, default: "0.0.0.0", description: "The address to bind the certificate to. This can be an IPv4 IP `1.2.3.4`, IPv6 IP `[::1]`, or a hostname `example.com`.", default_description: "`0.0.0.0`: all IPv4 addresses"

      property :port, Integer, default: 443, description: "The port to bind the certificate to."

      property :app_id, String, default: "{4dc3e181-e14b-4a21-b022-59fc669b0914}", description: "The GUID that defines the application that owns the binding.", default_description: "{4dc3e181-e14b-4a21-b022-59fc669b0914} (the IIS GUID)"

      property :store_name, String, default: "MY", equal_to: ["TRUSTEDPUBLISHER", "CLIENTAUTHISSUER", "REMOTE DESKTOP", "ROOT", "TRUSTEDDEVICES", "WEBHOSTING", "CA", "AUTHROOT", "TRUSTEDPEOPLE", "MY", "SMARTCARDROOT", "TRUST"], description: "The certificate store to load the certificate from.", default_description: "`MY`: The personal certificate store of the running user."

      property :exists, [true, false]

      def netsh_command
        # account for Window's wacky File System Redirector
        # http://msdn.microsoft.com/en-us/library/aa384187(v=vs.85).aspx
        # especially important for 32-bit processes (like Ruby) on a
        # 64-bit instance of Windows.
        if ::File.exist?("#{ENV["WINDIR"]}\\sysnative\\netsh.exe")
          "#{ENV["WINDIR"]}\\sysnative\\netsh.exe"
        elsif ::File.exist?("#{ENV["WINDIR"]}\\system32\\netsh.exe")
          "#{ENV["WINDIR"]}\\system32\\netsh.exe"
        else
          "netsh.exe"
        end
      end

      load_current_value do |desired|
        mode = desired.address.match(/(\d+\.){3}\d+|\[.+\]/).nil? ? "hostnameport" : "ipport"
        cmd = shell_out("#{netsh_command} http show sslcert #{mode}=#{desired.address}:#{desired.port}")
        Chef::Log.debug "netsh reports: #{cmd.stdout}"

        address desired.address
        port desired.port
        store_name desired.store_name
        app_id desired.app_id

        if cmd.exitstatus == 0
          m = cmd.stdout.scan(/Certificate Hash\s+:\s?([A-Fa-f0-9]{40})/)
          raise "Failed to extract hash from command output #{cmd.stdout}" if m.empty?

          cert_name m[0][0]
          name_kind :hash
          exists true
        else
          exists false
        end
      end

      action :create do
        hash = new_resource.name_kind == :subject ? hash_from_subject : new_resource.cert_name

        if current_resource.exists
          needs_change = (hash.casecmp(current_resource.cert_name) != 0)

          if needs_change
            converge_by("Changing #{current_resource.address}:#{current_resource.port}") do
              delete_binding
              add_binding hash
            end
          else
            Chef::Log.debug("#{new_resource.address}:#{new_resource.port} already bound to #{hash} - nothing to do")
          end
        else
          converge_by("Binding #{new_resource.address}:#{new_resource.port}") do
            add_binding hash
          end
        end
      end

      action :delete do
        if current_resource.exists
          converge_by("Deleting #{current_resource.address}:#{current_resource.port}") do
            delete_binding
          end
        else
          Chef::Log.debug("#{current_resource.address}:#{current_resource.port} not bound - nothing to do")
        end
      end

      action_class do
        def add_binding(hash)
          cmd = "#{netsh_command} http add sslcert"
          mode = address_mode(current_resource.address)
          cmd << " #{mode}=#{current_resource.address}:#{current_resource.port}"
          cmd << " certhash=#{hash}"
          cmd << " appid=#{current_resource.app_id}"
          cmd << " certstorename=#{current_resource.store_name}"
          check_hash hash

          shell_out!(cmd)
        end

        def delete_binding
          mode = address_mode(current_resource.address)
          shell_out!("#{netsh_command} http delete sslcert #{mode}=#{current_resource.address}:#{current_resource.port}")
        end

        def check_hash(hash)
          p = powershell_out!("Test-Path \"cert:\\LocalMachine\\#{current_resource.store_name}\\#{hash}\"")

          unless p.stderr.empty? && p.stdout =~ /True/i
            raise "A Cert with hash of #{hash} doesn't exist in keystore LocalMachine\\#{current_resource.store_name}"
          end

          nil
        end

        def hash_from_subject
          # escape wildcard subject name (*.acme.com)
          subject = new_resource.cert_name.sub(/\*/, "`*")
          ps_script = "& { gci cert:\\localmachine\\#{new_resource.store_name} | where { $_.subject -like '*#{subject}*' } | select -first 1 -expandproperty Thumbprint }"

          Chef::Log.debug "Running PS script #{ps_script}"
          p = powershell_out!(ps_script)

          raise "#{ps_script} failed with #{p.stderr}" if !p.stderr.nil? && !p.stderr.empty?
          raise "Couldn't find thumbprint for subject #{new_resource.cert_name}" if p.stdout.nil? || p.stdout.empty?

          # seem to get a UTF-8 string with BOM returned sometimes! Strip any such BOM
          hash = p.stdout.strip
          hash[0].ord == 239 ? hash.force_encoding("UTF-8").delete!("\xEF\xBB\xBF".force_encoding("UTF-8")) : hash
        end

        def address_mode(address)
          address.match(/(\d+\.){3}\d+|\[.+\]/).nil? ? "hostnameport" : "ipport"
        end
      end
    end
  end
end
