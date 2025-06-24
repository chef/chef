# Reference recipes/_openssl.rb test to 'generate and sign a certificate with the CA'
# This ensures that the generated certificate is valid.

if os.windows?
  openssl_paths = Dir.glob("C:/hab/pkgs/core/openssl/*/*/bin/openssl.exe").sort
  openssl_bin = openssl_paths.last
  ca_file = "C:\\ssl_test\\my_ca.crt"
  cert_file = "C:\\ssl_test\\my_signed_cert.crt"

  # Currently community test kitchen is still used to run kitchen tests on windows, so we need to use omnibus path there
  # We will to do this until test-kitchen-enterprise supports other platforms and drivers.
  if !openssl_bin || !File.exist?(openssl_bin)
    openssl_bin = "C:\\opscode\\chef\\embedded\\bin\\openssl.exe"
  end
else
  ca_file = "/etc/ssl_test/my_ca.crt"
  cert_file = "/etc/ssl_test/my_signed_cert.crt"
  begin
    # This will work only on dokker containers which use Habitat packages
    openssl_bin = `hab pkg exec chef/chef-infra-client which openssl`.strip
    puts "**** Using dynamically resolved OpenSSL: #{openssl_bin} ****"
  rescue
    # This is for VMs which still use omnibus packages
    if !openssl_bin || !File.exist?(openssl_bin)
      openssl_bin = "/opt/chef/embedded/bin/openssl"
    end
  end
  # openssl_paths = Dir.glob("/hab/pkgs/core/openssl/*/*/bin/openssl").sort
  # puts "**** openssl paths: #{openssl_paths.inspect} ****"
  # openssl_bin = openssl_paths.last

  # ca_file = "/etc/ssl_test/my_ca.crt"
  # cert_file = "/etc/ssl_test/my_signed_cert.crt"

  # # Currently community test kitchen is still used to run kitchen tests on linux VMs, so we need to use omnibus path there
  # # We will to do this until test-kitchen-enterprise supports other platforms and drivers.
  # if !openssl_bin || !File.exist?(openssl_bin)
  #   openssl_bin = "/opt/chef/embedded/bin/openssl"
  # end
end

cmd = "#{openssl_bin} verify -CAfile #{ca_file} #{cert_file}"
describe command(cmd) do
  its("stdout") { should match /my_signed_cert.*OK/ }
  its("stderr") { should be_empty }
end
