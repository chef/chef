#
# Cookbook:: end_to_end_arm
# Recipe:: _chef_client
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
#

chef_client_config "default" do
  chef_license "accept"
  chef_server_url "https://localhost/organizations/test"
  file_backup_path "C:/chef/backup"
  log_location "C:/chef/log/client.log"
  ohai_optional_plugins %i{Passwd Lspci Sysctl}
  ohai_disabled_plugins %i{Sessions Interrupts}
  rubygems_url "https://rubygems.org/"
end

# This verifies that chef_client_trusted_certificate correctly installs a
# certificate into Chef's trusted_certs_dir and that the SSL trust chain
# works end-to-end (set_custom_certs -> OpenSSL::X509::Store -> TLS
# handshake). The certificate and HTTPS server are generated inline so
# nothing needs to be pre-staged as a cookbook file.
require "openssl"
require "webrick"
require "webrick/https"

key = OpenSSL::PKey::RSA.new(2048)
cert = OpenSSL::X509::Certificate.new
cert.version = 2
cert.serial = 1
cert.subject = OpenSSL::X509::Name.parse("/CN=localhost")
cert.issuer = cert.subject
cert.public_key = key.public_key
cert.not_before = Time.now
cert.not_after = Time.now + 3600

ef = OpenSSL::X509::ExtensionFactory.new
ef.subject_certificate = cert
ef.issuer_certificate = cert
cert.add_extension(ef.create_extension("subjectAltName", "DNS:localhost,IP:127.0.0.1", false))
cert.sign(key, OpenSSL::Digest.new("SHA256"))

cert_pem = cert.to_pem

server = WEBrick::HTTPServer.new(
  Port: 9444,
  SSLEnable: true,
  SSLCertificate: cert,
  SSLPrivateKey: key,
  Logger: WEBrick::Log.new(File::NULL),
  AccessLog: []
)
server.mount_proc("/index.html") { |_req, res| res.body = "trusted cert test OK" }
Thread.new { server.start }

chef_client_trusted_certificate "localhost" do
  certificate cert_pem
end

# The test can't reliably guess trusted_certs_dir/file_cache_path (they
# depend on how this node's client.rb was generated), so report the actual
# resolved values to a known file instead of hardcoding an assumed path.
::File.open("C:\\chef_arm_test\\chef_client_config_paths.txt", "w") do |f|
  f.puts "trusted_certs_dir=#{Chef::Config[:trusted_certs_dir]}"
  f.puts "file_cache_path=#{Chef::Config[:file_cache_path]}"
end

remote_file ::File.join(Chef::Config[:file_cache_path], "arm_index.html") do
  source "https://localhost:9444/index.html"
  notifies :run, "ruby_block[stop local https server for arm test]", :immediately
end

ruby_block "stop local https server for arm test" do
  block { server.shutdown }
  action :nothing
end
