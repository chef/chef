lwrp :default do
  message "Default everything"
  action :print_message

  provider Chef::Provider::Lwrp
end
