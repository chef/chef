lwrp :overridden_provider_load_current_resource do
  message "meep meep"
  action :print_message

  provider Chef::Provider::LwrpLwpOverriddenLoadCurrentResource
end
