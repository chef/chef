# Diagnostic script: bare ruby, no chef requires.
# Tests OpenSSL SHA256 before and after fips_mode=true to confirm
# whether the failure is inherent to the hab runtime env or chef-specific.
require "openssl"

puts "OpenSSL version:       #{OpenSSL::OPENSSL_LIBRARY_VERSION}"
puts "FIPS mode (before):    #{OpenSSL.fips_mode}"
puts "OPENSSL_CONF env:      #{ENV["OPENSSL_CONF"].inspect}"

begin
  puts "SHA256 before fips=true: #{OpenSSL::Digest::SHA256.hexdigest("test")}"
rescue => e
  puts "SHA256 FAILED before fips=true: #{e.class}: #{e.message}"
end

OpenSSL.fips_mode = true
puts "FIPS mode (after set): #{OpenSSL.fips_mode}"

begin
  puts "SHA256 after fips=true:  #{OpenSSL::Digest::SHA256.hexdigest("test")}"
rescue => e
  puts "SHA256 FAILED after fips=true: #{e.class}: #{e.message}"
end

begin
  puts "MD5 after fips=true (should fail): #{OpenSSL::Digest::MD5.hexdigest("test")}"
rescue => e
  puts "MD5 BLOCKED (expected): #{e.class}: #{e.message}"
end

begin
  puts "Loaded providers: #{OpenSSL::Provider.provider_names.inspect}"
rescue => e
  puts "Could not list providers: #{e.message}"
end
