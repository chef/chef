# Diagnostic script: require chef, then call init_openssl.
# Tests SHA256 at each stage to pinpoint where the failure is introduced.
require "openssl"

puts "FIPS mode before require chef: #{OpenSSL.fips_mode}"
begin
  puts "SHA256 before require chef: #{OpenSSL::Digest::SHA256.hexdigest("test")}"
rescue => e
  puts "SHA256 FAILED before require chef: #{e.class}: #{e.message}"
end

require "chef"
puts "FIPS mode after require chef (before init_openssl): #{OpenSSL.fips_mode}"
begin
  puts "SHA256 after require chef: #{OpenSSL::Digest::SHA256.hexdigest("test")}"
rescue => e
  puts "SHA256 FAILED after require chef: #{e.class}: #{e.message}"
end

Chef::Config.init_openssl
puts "FIPS mode after init_openssl: #{OpenSSL.fips_mode}"
begin
  puts "SHA256 after init_openssl: #{OpenSSL::Digest::SHA256.hexdigest("test")}"
rescue => e
  puts "SHA256 FAILED after init_openssl: #{e.class}: #{e.message}"
end
