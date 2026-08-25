# Verifies recipes/_openssl.rb: the built-in openssl_* resources produced their
# key/cert material on disk.
base = "C:\\chef_arm_test\\ssl"

%w{dhparam.pem rsakey.pem eckey.pem mycert.crt my_ca.crt my_signed_cert.crt}.each do |generated_file|
  describe file("#{base}\\#{generated_file}") do
    it { should exist }
    its("size") { should > 0 }
  end
end

describe file("#{base}\\mycert.crt") do
  its("content") { should match(/BEGIN CERTIFICATE/) }
end

describe file("#{base}\\my_signed_cert.crt") do
  its("content") { should match(/BEGIN CERTIFICATE/) }
end
