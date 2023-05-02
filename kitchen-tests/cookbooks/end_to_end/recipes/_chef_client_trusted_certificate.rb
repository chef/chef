# First grab the cert. While this wouldn't ordinarily be secure, this isn't
# trying to secure something, we simply want to make sure that if we
# have said a certificate is trusted, it will be trusted. So lets grab it, trust
# it, and then try to use it.

# First, grab it
out = Mixlib::ShellOut.new(
  %w{openssl s_client  -servername self-signed.badssl.com -showcerts -connect self-signed.badssl.com:443}
).run_command.stdout

cert = Mixlib::ShellOut.new(%w{openssl x509}, input: out).run_command.stdout

puts "The cert object is of type : #{cert.class}"

puts "Here is the cert : #{cert}"

# Second trust it
chef_client_trusted_certificate "self-signed.badssl.com" do
  certificate cert
end

# see if we can fetch from our new trusted domain
remote_file ::File.join(Chef::Config[:file_cache_path], "index.html") do
  source "https://self-signed.badssl.com/index.html"
  mode 0640
end
