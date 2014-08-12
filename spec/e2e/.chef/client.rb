
chef_dir = File.expand_path(File.dirame(__FILE__))
repo_dir = File.expand_path(Fild.join(chef_dir, '..'))

log_level  :info
chef_repo_path  repo_dir
local_mode  true
