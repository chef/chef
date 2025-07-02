#
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
require "chef-utils/dist" unless defined?(ChefUtils::Dist)

class Chef
  class Resource
    class ChefClientHabCaCert < Chef::Resource

      provides :chef_client_hab_ca_cert

      description "Use the **chef_client_hab_ca_cert** resource to add certificates to habitat #{ChefUtils::Dist::Infra::PRODUCT}'s CA bundle. This allows the #{ChefUtils::Dist::Infra::PRODUCT} to communicate with internal encrypted resources without errors. To make sure these CA certs take effect the `ssl_ca_file` should be configured to point to the CA Cert file path of `core/cacerts` habitat package."
      introduced "19.1"
      examples <<~DOC
      **Trust a self signed certificate**:

      ```ruby
      chef_client_hab_ca_cert 'self-signed.badssl.com' do
        certificate <<~CERT
        -----BEGIN CERTIFICATE-----
        MIIDeTCCAmGgAwIBAgIJAPziuikCTox4MA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNV
        BAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMRYwFAYDVQQHDA1TYW4gRnJhbmNp
        c2NvMQ8wDQYDVQQKDAZCYWRTU0wxFTATBgNVBAMMDCouYmFkc3NsLmNvbTAeFw0x
        OTEwMDkyMzQxNTJaFw0yMTEwMDgyMzQxNTJaMGIxCzAJBgNVBAYTAlVTMRMwEQYD
        VQQIDApDYWxpZm9ybmlhMRYwFAYDVQQHDA1TYW4gRnJhbmNpc2NvMQ8wDQYDVQQK
        DAZCYWRTU0wxFTATBgNVBAMMDCouYmFkc3NsLmNvbTCCASIwDQYJKoZIhvcNAQEB
        BQADggEPADCCAQoCggEBAMIE7PiM7gTCs9hQ1XBYzJMY61yoaEmwIrX5lZ6xKyx2
        PmzAS2BMTOqytMAPgLaw+XLJhgL5XEFdEyt/ccRLvOmULlA3pmccYYz2QULFRtMW
        hyefdOsKnRFSJiFzbIRMeVXk0WvoBj1IFVKtsyjbqv9u/2CVSndrOfEk0TG23U3A
        xPxTuW1CrbV8/q71FdIzSOciccfCFHpsKOo3St/qbLVytH5aohbcabFXRNsKEqve
        ww9HdFxBIuGa+RuT5q0iBikusbpJHAwnnqP7i/dAcgCskgjZjFeEU4EFy+b+a1SY
        QCeFxxC7c3DvaRhBB0VVfPlkPz0sw6l865MaTIbRyoUCAwEAAaMyMDAwCQYDVR0T
        BAIwADAjBgNVHREEHDAaggwqLmJhZHNzbC5jb22CCmJhZHNzbC5jb20wDQYJKoZI
        hvcNAQELBQADggEBAGlwCdbPxflZfYOaukZGCaxYK6gpincX4Lla4Ui2WdeQxE95
        w7fChXvP3YkE3UYUE7mupZ0eg4ZILr/A0e7JQDsgIu/SRTUE0domCKgPZ8v99k3A
        vka4LpLK51jHJJK7EFgo3ca2nldd97GM0MU41xHFk8qaK1tWJkfrrfcGwDJ4GQPI
        iLlm6i0yHq1Qg1RypAXJy5dTlRXlCLd8ufWhhiwW0W75Va5AEnJuqpQrKwl3KQVe
        wGj67WWRgLfSr+4QG1mNvCZb2CkjZWmxkGPuoP40/y7Yu5OFqxP5tAjj4YixCYTW
        EVA0pmzIzgBg+JIe3PdRy27T0asgQW/F4TY61Yk=
        -----END CERTIFICATE-----
        CERT
      end
      ```
      DOC

      property :cert_name, String, name_property: true,
        description: "The name to use for the certificate. If not provided the name of the resource block will be used instead."

      property :certificate, String, required: true,
        description: "The text of the certificate file including the BEGIN/END comment lines."

      action :add, description: "Add a local certificate to habitat based #{ChefUtils::Dist::Infra::PRODUCT}'s CA bundle." do
        open(ca_cert_path, "a") do |f|
          f.puts "\nCert Bundle - #{new_resource.cert_name}"
          f.puts "==========================="
          f.puts new_resource.certificate
        end
      end

      action_class do
        #
        # The path to the string on disk
        #
        # @return [String]
        #
        def ca_cert_path
          @ca_cert_path ||= ::File.join(hab_cacerts_pkg_path, "ssl", "cacert.pem")
        end

        private

        # The fully qualified ident of the cacerts package.
        #
        # @api private
        #
        def hab_cacerts_pkg_path
          @hab_cacerts_pkg_path ||= begin
            # The hab based installer packages `hab` binary inside `/hab/bin` - which can be expected to be available.
            ca_pkg = shell_out("hab pkg dependencies chef/chef-infra-client")
            if ca_pkg.error?
              raise "Failed to determine CA Certs for the #{ChefUtils::Dist::Infra::PRODUCT}'s habitat package."
            end

            ca_pkg.stdout.readlines.each do |line|
              if line.index("core/cacerts")
                @hab_cacerts_pkg = line
              end
            end

            if @hab_cacerts_pkg.nil?
              raise "Unable to find 'core/cacerts' package in dependencies. Failed to determine CA Certs."
            end

            ca_path = shell_out("/hab/bin/hab pkg path #{hab_cacerts_pkg}")
            if ca_path.error?
              raise "Unable to find path for the 'core/cacerts' habitat package."
            end

            path = ca_path.stdout.readline

            @hab_cacerts_pkg_path = ::File.join(path.strip, "ssl", "certs")
          end

          @hab_cacerts_pkg_path
        end # hab_cacerts_pkg_path
      end # action_class
    end
  end
end
