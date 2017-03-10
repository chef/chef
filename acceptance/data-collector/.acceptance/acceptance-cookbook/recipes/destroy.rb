log "Running 'destroy' recipe from the acceptance-cookbook in directory '#{node['chef-acceptance']['suite-dir']}'"
kitchen "destroy"
