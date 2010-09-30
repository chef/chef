supportdir = File.expand_path(File.join(File.dirname(__FILE__), ".."))
tmpdir = File.expand_path(File.join(File.dirname(__FILE__), "..", "tmp"))

log_level        :error
log_location     STDOUT
file_cache_path  File.join(tmpdir, "cache")
ssl_verify_mode  :verify_none
registration_url "http://127.0.0.1:4000"
template_url     "http://127.0.0.1:4000"
remotefile_url   "http://127.0.0.1:4000"
search_url       "http://127.0.0.1:4000"
role_url         "http://127.0.0.1:4000"
client_url       "http://127.0.0.1:4000"
chef_server_url  "http://127.0.0.1:4000"
validation_client_name "validator"
systmpdir = File.expand_path(File.join(Dir.tmpdir, "chef_integration"))
validation_key   File.join(systmpdir, "validation.pem")
client_key       File.join(systmpdir, "client.pem")
cache_type "BasicFile"
cache_options({:path => File.join(tmpdir, "checksum_cache")})

Ohai::Config[:disabled_plugins] << 'darwin::system_profiler' << 'darwin::kernel' << 'darwin::ssh_host_key' << 'network_listeners'
Ohai::Config[:disabled_plugins ]<< 'darwin::uptime' << 'darwin::filesystem' << 'dmi' << 'lanuages' << 'perl' << 'python' << 'java'
