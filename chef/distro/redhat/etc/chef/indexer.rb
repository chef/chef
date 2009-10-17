#
# Chef Server Config File
#

log_level          :info
search_index_path  "/var/lib/chef/search_index"

Chef::Log::Formatter.show_time = false

pid_file           "/var/run/chef/chef-indexer.pid"
