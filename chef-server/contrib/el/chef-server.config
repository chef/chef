#
# Chef Server Config File
#

log_level          :info
ssl_verify_mode    :verify_none
registration_url   "http://cserver:4000"
openid_url         "http://cserver:4001"
template_url       "http://cserver:4000"
remotefile_url     "http://cserver:4000"
search_url         "http://cserver:4000"
cookbook_path      [ "/var/lib/chef/site-cookbooks", "/var/lib/chef/cookbooks" ]

merb_root          "/var/lib/chef/merb"
node_path          "/etc/chef/node"
file_store_path    "/var/lib/chef/store"
search_index_path  "/var/lib/chef/search_index"
openid_store_path  "/var/lib/chef/openid/db"
openid_cstore_path "/var/lib/chef/openid/cstore"
file_cache_path    "/var/lib/chef/cache"

Chef::Log::Formatter.show_time = false
