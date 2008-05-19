#
# Example Chef Solo Config

cookbook_path File.join(File.dirname(__FILE__), "..", "..", "..", "examples", "config", "cookbooks")
node_path     File.join(File.dirname(__FILE__), "..", "..", "..", "examples", "config", "nodes")
file_store_path File.join(File.dirname(__FILE__), "..", "..", "..", "examples", "store")
log_level     :debug

Chef::Log::Formatter.show_time = false
