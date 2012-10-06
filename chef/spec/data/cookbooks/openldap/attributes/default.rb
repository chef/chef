chef_env ||= nil
case chef_env
when "prod"
  default[:ldap_server] = "ops1prod"
  default[:ldap_basedn] = "dc=hjksolutions,dc=com"
  default[:ldap_replication_password] = "yes"
when "corp"
  default[:ldap_server] = "ops1prod"
  default[:ldap_basedn] = "dc=hjksolutions,dc=com"
  default[:ldap_replication_password] = "yougotit"
else

  default[:ldap_server] = "ops1prod"
  default[:ldap_basedn] = "dc=hjksolutions,dc=com"
  default[:ldap_replication_password] = "forsure" 
end
