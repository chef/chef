lwrp_lwr_non_default :non_default_lwr do
  message "Non-default resource"
  action :print_message

  provider Chef::Provider::Lwrp
end
