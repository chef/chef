#
# Example Chef Server Config

cookbook_path File.join(File.dirname(__FILE__), "..", "examples", "config", "cookbooks")
node_path     File.join(File.dirname(__FILE__), "..", "examples", "config", "nodes")
file_store_path File.join(File.dirname(__FILE__), "..", "examples", "store")
log_level     :debug

openid_providers [ "localhost:4001", "openid.hjksolutions.com" ]

Chef::Log::Formatter.show_time = false
