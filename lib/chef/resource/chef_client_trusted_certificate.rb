#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
    class ChefClientTrustedCertificate < Chef::Resource

      provides :chef_client_trusted_certificate

      description "Use the **chef_client_trusted_certificate** resource to add certificates to #{ChefUtils::Dist::Infra::PRODUCT}'s trusted certificate directory. This allows the #{ChefUtils::Dist::Infra::PRODUCT} to communicate with internal encrypted resources without errors."
      introduced "16.5"
      examples <<~DOC
      **Trust a self signed certificate**:

      ```ruby
      chef_client_trusted_certificate 'self-signed.badssl.com' do
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
        description: "The name to use for the certificate file on disk. If not provided the name of the resource block will be used instead."

      property :certificate, String, required: [:add],
        description: "The text of the certificate file including the BEGIN/END comment lines."

      action :add, description: "Add a trusted certificate to #{ChefUtils::Dist::Infra::PRODUCT}'s trusted certificate directory" do
        unless ::Dir.exist?(Chef::Config[:trusted_certs_dir])
          directory Chef::Config[:trusted_certs_dir] do
            mode "0640"
            recursive true
          end
        end

        file cert_path do
          content new_resource.certificate
          mode "0640"
          sensitive new_resource.sensitive
        end
      end

      action :remove, description: "Remove a trusted certificate from #{ChefUtils::Dist::Infra::PRODUCT}'s trusted certificate directory" do
        file cert_path do
          action :delete
        end
      end

      action_class do
        #
        # The path to the string on disk
        #
        # @return [String]
        #
        def cert_path
          path = ::File.join(Chef::Config[:trusted_certs_dir], new_resource.cert_name)
          path << ".pem" unless path.end_with?(".pem")
          path
        end
      end
    end
  end
end
