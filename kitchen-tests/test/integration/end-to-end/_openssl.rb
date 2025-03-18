# Reference recipes/_openssl.rb test to 'generate and sign a certificate with the CA'
# This ensures that the generated certificate is valid.
cmd = if os.windows?
        "C:\\opscode\\chef\\embedded\\bin\\openssl.exe verify -CAfile C:\\ssl_test\\my_ca.crt C:\\ssl_test\\my_signed_cert.crt"
      else
        "/opt/chef/embedded/bin/openssl verify -CAfile /etc/ssl_test/my_ca.crt /etc/ssl_test/my_signed_cert.crt"
      end
describe command(cmd) do
  its("stdout") { should match /my_signed_cert.*OK/ }
  its("stderr") { should be_empty }
end
