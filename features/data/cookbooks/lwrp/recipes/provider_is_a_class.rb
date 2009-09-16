lwrp :provider_is_a_class do
  message "Provider is a class"
  action :print_message

  provider Chef::Provider::Lwrp
end
