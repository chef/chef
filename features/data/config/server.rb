supportdir = File.expand_path(File.join(File.dirname(__FILE__), ".."))
tmpdir = File.expand_path(File.join(File.dirname(__FILE__), "..", "tmp"))

log_level              :debug
log_location           STDOUT
file_cache_path        File.join(tmpdir, "cache")
ssl_verify_mode        :verify_none
registration_url       "http://127.0.0.1:4000"
openid_url             "http://127.0.0.1:4000"
template_url           "http://127.0.0.1:4000"
remotefile_url         "http://127.0.0.1:4000"
search_url             "http://127.0.0.1:4000"
role_url               "http://127.0.0.1:4000"
chef_server_url        "http://127.0.0.1:4000"
client_url             "http://127.0.0.1:4000"
cookbook_path          [File.join(tmpdir, "cookbooks"), File.join(supportdir, "cookbooks")]
cookbook_tarball_path  File.join(tmpdir, "cookbook-tarballs")
openid_store_path      File.join(tmpdir, "openid", "store")
openid_cstore_path     File.join(tmpdir, "openid", "cstore")
search_index_path      File.join(tmpdir, "search_index")
role_path              File.join(supportdir, "roles")
signing_ca_path        File.join(tmpdir, "ca")
couchdb_database       'chef_integration'

systmpdir = File.expand_path(File.join(Dir.tmpdir, "chef_integration"))

validation_client_name "validator"
validation_key   File.join(systmpdir, "validation.pem")
client_key       File.join(systmpdir, "client.pem")
web_ui_client_name "chef-webui"
web_ui_key File.join(systmpdir, "webui.pem")

solr_jetty_path File.join(supportdir, "solr", "jetty")
solr_heap_size "250M"
solr_data_path File.join(supportdir, "solr", "data")
solr_home_path File.join(supportdir, "solr", "home")
solr_heap_size "256M"

Chef::Log::Formatter.show_time = true

cache_options({ :path => File.join(tmpdir, "server-checksums") })
