# Reference recipes/_openssl.rb test to 'generate and sign a certificate with the CA'
# This ensures that the generated certificate is valid.
describe command("/opt/chef/embedded/bin/openssl verify -CAfile /etc/ssl_test/my_ca.crt /etc/ssl_test/my_signed_cert.crt") do
  its("stdout") { should match /my_signed_cert.*OK/ }
  its("stderr") { should be_empty }
end
