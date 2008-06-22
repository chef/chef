#
# Example Chef Server Config

cookbook_path File.join(File.dirname(__FILE__), "..", "examples", "config", "cookbooks")
node_path     File.join(File.dirname(__FILE__), "..", "examples", "config", "nodes")
file_store_path File.join(File.dirname(__FILE__), "..", "examples", "store")
openid_store_path File.join(File.dirname(__FILE__), "..", "examples", "openid-db")
openid_cstore_path File.join(File.dirname(__FILE__), "..", "examples", "openid-cstore")
log_level     :debug
merb_log_path File.join(File.dirname(__FILE__), "..", "examples", "logs")

openid_providers [ "localhost:4001", "openid.hjksolutions.com" ]

Chef::Log::Formatter.show_time = false
