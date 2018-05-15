log "Running 'provision' recipe from the acceptance-cookbook in directory '#{node['chef-acceptance']['suite-dir']}'"
kitchen "converge"
