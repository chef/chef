supportdir = File.expand_path(File.join(File.dirname(__FILE__), ".."))
tmpdir = File.expand_path(File.join(File.dirname(__FILE__), "..", "tmp"))

log_level        :error
log_location     STDOUT
file_cache_path  File.join(tmpdir, "cache")
ssl_verify_mode  :verify_none
registration_url "http://127.0.0.1:4000"
openid_url       "http://127.0.0.1:4001"
template_url     "http://127.0.0.1:4000"
remotefile_url   "http://127.0.0.1:4000"
search_url       "http://127.0.0.1:4000"
role_url          "http://127.0.0.1:4000"
couchdb_database   'chef_integration'
