lwrp_lwr_overridden_initialize :overridden_resource_initialize do
  message "meep meep"
  action :print_message

  provider Chef::Provider::Lwrp
end
