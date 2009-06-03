supportdir = File.expand_path(File.join(File.dirname(__FILE__), ".."))
tmpdir = File.expand_path(File.join(File.dirname(__FILE__), "..", "tmp"))

log_level          :debug
log_location       STDOUT
file_cache_path    File.join(tmpdir, "cache")
ssl_verify_mode    :verify_none
registration_url   "http://127.0.0.1:4000"
openid_url         "http://127.0.0.1:4001"
template_url       "http://127.0.0.1:4000"
remotefile_url     "http://127.0.0.1:4000"
search_url         "http://127.0.0.1:4000"
role_url          "http://127.0.0.1:4000"
cookbook_path      File.join(supportdir, "cookbooks")
openid_store_path  File.join(tmpdir, "openid", "store")
openid_cstore_path File.join(tmpdir, "openid", "cstore")
search_index_path  File.join(tmpdir, "search_index")
role_path          File.join(supportdir, "roles")
validation_token   'ceelo'
couchdb_database   'chef_integration'

Chef::Log::Formatter.show_time = true
