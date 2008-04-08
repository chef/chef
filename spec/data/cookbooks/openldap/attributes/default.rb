chef_env ||= nil
case chef_env
when "prod"
  ldap_server "ops1prod"
  ldap_basedn "dc=hjksolutions,dc=com"
  ldap_replication_password "yes"
when "corp"
  ldap_server "ops1prod"
  ldap_basedn "dc=hjksolutions,dc=com"
  ldap_replication_password "yougotit"
else
  ldap_server "ops1prod"
  ldap_basedn "dc=hjksolutions,dc=com"
  ldap_replication_password "forsure" 
end
