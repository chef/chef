lwrp :non_default_provider do
  message "Non-default provider"
  action :print_message

  provider Chef::Provider::LwrpLwpNonDefault
end
