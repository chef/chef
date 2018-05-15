# ssl-serve.rb
# USAGE: ruby ssl-serve.rb
#
# ssl-serve is a script that serves a local directory over SSL.
# You can use it to test various HTTP behaviors in chef, like chef-client's
# `-j` and `-c` options and remote_file with https connections.
#
require "pp"
require "openssl"
require "webrick"
require "webrick/https"

$ssl = true

CHEF_SPEC_DATA = File.expand_path("../../data", __FILE__)
cert_text = File.read(File.expand_path("ssl/chef-rspec.cert", CHEF_SPEC_DATA))
cert = OpenSSL::X509::Certificate.new(cert_text)
key_text = File.read(File.expand_path("ssl/chef-rspec.key", CHEF_SPEC_DATA))
key = OpenSSL::PKey::RSA.new(key_text)

server_opts = {}
if $ssl
  server_opts.merge!( { :SSLEnable => true,
                        :SSLVerifyClient => OpenSSL::SSL::VERIFY_NONE,
                        :SSLCertificate => cert,
                        :SSLPrivateKey => key })
end

# 5 == debug, 3 == warning
LOGGER = WEBrick::Log.new(STDOUT, 5)
DEFAULT_OPTIONS = {
  :server => "webrick",
  :Port => 9000,
  :Host => "localhost",
  :environment => :none,
  :Logger => LOGGER,
  :DocumentRoot => File.expand_path("#{Dir.tmpdir}/chef-118-sampledata")
  #:AccessLog => [] # Remove this option to enable the access log when debugging.
}

webrick_opts = DEFAULT_OPTIONS.merge(server_opts)
pp :webrick_opts => webrick_opts

server = WEBrick::HTTPServer.new(webrick_opts)
trap("INT") { server.shutdown }

server.start
