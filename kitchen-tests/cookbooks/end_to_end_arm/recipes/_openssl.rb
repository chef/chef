#
# Cookbook:: end_to_end_arm
# Recipe:: _openssl
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
#
# The openssl_* resources already generate their own key/cert material, so
# they need no pre-staged files -- included here as a sampling of the
# built-in openssl resources working on Windows ARM64.
#

base = "C:\\chef_arm_test\\ssl"

directory base do
  recursive true
end

openssl_dhparam "#{base}\\dhparam.pem" do
  key_length 1024
  action :create
end

openssl_rsa_private_key "#{base}\\rsakey.pem" do
  key_length 2048
  action :create
end

openssl_ec_private_key "#{base}\\eckey.pem" do
  key_curve "prime256v1"
  action :create
end

# Generate new key and self-signed certificate
openssl_x509 "#{base}\\mycert.crt" do
  common_name "mycert.example.com"
  org "Test Kitchen Example"
  org_unit "Kitchens"
  country "UK"
  subject_alt_name ["IP:127.0.0.1", "DNS:localhost.localdomain"]
end

# Generate a CA certificate
openssl_x509 "#{base}\\my_ca.crt" do
  common_name "CA"
  expire 3650
  extensions(
    "keyUsage" => {
      "values" => %w{keyCertSign keyEncipherment digitalSignature cRLSign},
      "critical" => true,
    }
  )
end

# Generate and sign a certificate with the CA generated above
openssl_x509_certificate "#{base}\\my_signed_cert.crt" do
  common_name "mysignedcert.example.com"
  ca_key_file "#{base}\\my_ca.key"
  ca_cert_file "#{base}\\my_ca.crt"
  expire 365
  extensions(
    "keyUsage" => {
      "values" => %w{keyEncipherment digitalSignature},
      "critical" => true,
    },
    "extendedKeyUsage" => {
      "values" => %w{serverAuth},
      "critical" => false,
    }
  )
  subject_alt_name ["IP:127.0.0.1", "DNS:localhost.localdomain"]
end
