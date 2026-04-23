# This test verifies that the chef_client_trusted_certificate resource correctly
# installs a certificate into Chef's trusted_certs_dir and that the SSL trust
# chain works end-to-end (set_custom_certs -> OpenSSL::X509::Store -> TLS handshake).

require "openssl"
require "webrick"
require "webrick/https"

# Generate a self-signed certificate for localhost
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
  Port: 9443,
  SSLEnable: true,
  SSLCertificate: cert,
  SSLPrivateKey: key,
  Logger: WEBrick::Log.new(File::NULL),
  AccessLog: []
)
server.mount_proc("/index.html") { |_req, res| res.body = "trusted cert test OK" }
Thread.new { server.start }

# Trust our self-signed cert via the Chef resource (exercises chef_client_trusted_certificate -> file write)
chef_client_trusted_certificate "localhost" do
  certificate cert_pem
end

# Fetch from the local HTTPS server — this exercises the full SSL trust chain:
# trusted_certs_dir -> set_custom_certs -> OpenSSL::X509::Store -> TLS peer verification
remote_file ::File.join(Chef::Config[:file_cache_path], "index.html") do
  source "https://localhost:9443/index.html"
  notifies :run, "ruby_block[stop local https server]", :immediately
end

ruby_block "stop local https server" do
  block { server.shutdown }
  action :nothing
end
