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
  begin
    openssl_pkg_path = `hab pkg path core/openssl 2>/dev/null`.strip
    puts "**** Hab OpenSSL pkg path: #{openssl_pkg_path} ****"
    if !openssl_pkg_path.empty?
      # Found the path, now build the full binary path
      openssl_bin = File.join(openssl_pkg_path, "bin", "openssl")
      puts "**** Using OpenSSL from Habitat package: #{openssl_bin} ****"
      # Verify the binary exists and is executable
      if !File.exist?(openssl_bin) || !File.executable?(openssl_bin)
        puts "**** OpenSSL binary from Habitat not found or not executable ****"
        openssl_bin = nil
      end
    end
  rescue => e
    puts "**** Error finding OpenSSL from Habitat: #{e.message} ****"
    openssl_bin = nil
  end

  ca_file = "/etc/ssl_test/my_ca.crt"
  cert_file = "/etc/ssl_test/my_signed_cert.crt"

  # Currently community test kitchen is still used to run kitchen tests on linux VMs, so we need to use omnibus path there
  # We will to do this until test-kitchen-enterprise supports other platforms and drivers.
  if !openssl_bin || !File.exist?(openssl_bin)
    openssl_bin = "/opt/chef/embedded/bin/openssl"
  end
end

cmd = "#{openssl_bin} verify -CAfile #{ca_file} #{cert_file}"
describe command(cmd) do
  its("stdout") { should match /my_signed_cert.*OK/ }
  its("stderr") { should be_empty }
end
