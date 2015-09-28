
chef_dir = File.expand_path(File.dirname(__FILE__))
repo_dir = File.expand_path(File.join(chef_dir, '..'))

log_level       :info
chef_repo_path  repo_dir
local_mode      true
cache_path      "#{ENV['HOME']}/.cache/chef"

audit_mode :enabled