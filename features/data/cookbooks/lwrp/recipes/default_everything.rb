lwrp :default do
  message "Default everything"
  action :print_message

  # TODO: should we provide an implementation of the provider method for lwps that converts the provided string or symbol to the appropriate class, as well as allow for a class arg?
  provider Chef::Provider::Lwrp
end
