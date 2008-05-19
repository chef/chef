#
# Example Chef Solo Config

cookbook_path File.join(File.dirname(__FILE__), "cookbooks")
node_path     File.join(File.dirname(__FILE__), "nodes")
search_index_path File.join(File.dirname(__FILE__), "..", "search_index")
log_level     :info

Chef::Log::Formatter.show_time = false
