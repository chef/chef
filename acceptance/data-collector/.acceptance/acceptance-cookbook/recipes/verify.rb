log "Running 'verify' recipe from the acceptance-cookbook in directory '#{node['chef-acceptance']['suite-dir']}'"
kitchen "verify"
