# Starting with Chef 12 reloading an LWRP shouldn't reload the file anymore

action :buck_stops_here do
  log "This should be overwritten by ../lwrp_override/buck_passer.rb"
end
