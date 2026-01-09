# Reference recipes/_openssl.rb test to 'generate and sign a certificate with the CA'
# This ensures that the generated certificate is valid.
cmd = if os.windows?
puts "Running OpenSSL verify command on Windows"
        openssl_path = if File.exist?("C:\\ssl_test\\openssl_path.txt")
                         File.read("C:\\ssl_test\\openssl_path.txt").strip
                       else
                         "C:\\opscode\\chef\\embedded\\bin\\openssl.exe"
                       end
        "#{openssl_path} verify -CAfile C:\\ssl_test\\my_ca.crt C:\\ssl_test\\my_signed_cert.crt"
      else
        "/opt/chef/embedded/bin/openssl verify -CAfile /etc/ssl_test/my_ca.crt /etc/ssl_test/my_signed_cert.crt"
      end
puts "Executing command: #{cmd}"

ca_crt_path = "path/to/your/file.txt"
signed_cert_path = "path/to/your/signed_cert.crt"

if File.exist?(openssl_path)
  puts "Openssl exists at: #{openssl_path}"
else
  puts "Openssl is missing"
end

if File.exist?(ca_crt_path)
  puts "CA certificate exists at: #{ca_crt_path}"
else
  puts "CA certificate is missing"
end

if File.exist?(signed_cert_path)
  puts "Signed certificate exists at: #{signed_cert_path}"
else
  puts "Signed certificate is missing"
end

output = command(cmd).stdout
puts "OpenSSL verify command output: #{output}"

errors = command(cmd).stderr
puts "OpenSSL verify command errors: #{errors}"

describe command(cmd) do
  its("stdout") { should match /my_signed_cert.*OK/ }
  its("stderr") { should be_empty }
end
