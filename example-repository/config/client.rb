#
# Chef Client Config File
#
# Will be overwritten
#

log_level        :info
log_location     STDOUT
file_store_path  "/var/chef/file_store"
file_cache_path  "/var/chef/cache"
ssl_verify_mode  :verify_none
registration_url "http://127.0.0.1:4000"
openid_url       "http://127.0.0.1:4001"
template_url     "http://127.0.0.1:4000"
remotefile_url   "http://127.0.0.1:4000"
search_url       "http://127.0.0.1:4000"



