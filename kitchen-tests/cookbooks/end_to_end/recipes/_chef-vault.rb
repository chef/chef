#
# Cookbook:: end_to_end
# Recipe:: chef-vault
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
#

chef_data_bag "creds"

openssl_rsa_private_key "/root/bob_bobberson.pem" do
  key_length 2048
  action :create
end

chef_client "bob_bobberson" do
  source_key_path "/root/bob_bobberson.pem"
end

chef_node "bob_bobberson"

chef_vault_secret "super_secret_1" do
  data_bag "creds"
  raw_data("auth" => "1234")
  admins "bob_bobberson"
  search "*:*"
end

chef_vault_secret "super_secret_2" do
  data_bag "creds"
  raw_data("auth" => "4321")
  admins "bob_bobberson"
end

ruby_block "load vault item" do
  block do

    chef_vault_item("creds", "super_secret_1")
  rescue ChefVault::Exceptions::SecretDecryption
    puts "Not authorized for this key!"

  end
  action :run
end
