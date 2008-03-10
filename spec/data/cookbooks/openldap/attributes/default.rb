
case chef_env
when "prod"
  ldap_server "ops1prod"
  ldap_basedn "dc=hjksolutions,dc=com"
  ldap_replication_password "RiotAct"
when "corp"
  ldap_server "ops1prod"
  ldap_basedn "dc=hjksolutions,dc=com"
  ldap_replication_password "KickingMeDown"
end
