puts "CHEF UTILS THINKS WE ARE ON UBUNTU" if ubuntu?
puts "CHEF UTILS THINKS WE ARE ON RHEL" if rhel?
puts "CHEF UTILS THINKS WE ARE ON MACOS" if macos?
puts "CHEF UTILS THINKS WE ARE ON WINDOWS" if windows?

#
# ubuntu cookbook overrides
#

default["ubuntu"]["include_source_packages"] = true
default["ubuntu"]["components"] = "main restricted universe multiverse"

#
# openssh cookbook overrides
#

# turn off old protocols client-side
default["openssh"]["client"]["host_based_authentication"] = "no"
# allow typical ssh v2 rsa/dsa/ecdsa key auth client-side
default["openssh"]["client"]["pubkey_authentication"] = "yes"
# allow password auth client-side (we can ssh 'to' hosts that require passwords)
default["openssh"]["client"]["password_authentication"] = "yes"
# turn off kerberos client-side
default["openssh"]["client"]["gssapi_authentication"] = "no"
default["openssh"]["client"]["check_host_ip"] = "no"
# everyone turns strict host key checking off anyway
default["openssh"]["client"]["strict_host_key_checking"] = "no"
# force protocol 2
default["openssh"]["client"]["protocol"] = "2"

# it is mostly important that the aes*-ctr ciphers appear first in this list, the cbc ciphers are for compatibility
default["openssh"]["server"]["ciphers"] = "aes256-ctr,aes192-ctr,aes128-ctr,aes256-cbc,aes192-cbc,aes128-cbc,3des-cbc"
# DNS causes long timeouts when connecting clients have busted DNS
default["openssh"]["server"]["use_dns"] = "no"
default["openssh"]["server"]["syslog_facility"] = "AUTH"
# only allow access via ssh pubkeys, all other mechanisms including passwords are turned off for all users
default["openssh"]["server"]["pubkey_authentication"] = "yes"
default["openssh"]["server"]["password_authentication"] = "no"
default["openssh"]["server"]["host_based_authentication"] = "no"
default["openssh"]["server"]["gssapi_authentication"] = "no"
default["openssh"]["server"]["permit_root_login"] = "without-password"
default["openssh"]["server"]["ignore_rhosts"] = "yes"
default["openssh"]["server"]["permit_empty_passwords"] = "no"
default["openssh"]["server"]["challenge_response_authentication"] = "no"
default["openssh"]["server"]["kerberos_authentication"] = "no"
# tcp keepalives are useful to keep connections up through VPNs and firewalls
default["openssh"]["server"]["tcp_keepalive"] = "yes"
default["openssh"]["server"]["max_start_ups"] = "10"
# PAM (i think) already prints the motd on login
default["openssh"]["server"]["print_motd"] = "no"
# force only protocol 2 connections
default["openssh"]["server"]["protocol"] = "2"
# allow tunnelling x-applications back to the client
default["openssh"]["server"]["x11_forwarding"] = "yes"

#
# chef-client cookbook overrides
#

# always wait at least 30 mins (1800 secs) between daemonized chef-client runs
default["chef_client"]["interval"] = 1800
# wait an additional random interval of up to 30 mins (1800 secs) between daemonized runs
default["chef_client"]["splay"] = 1800
# only log what we change
default["chef_client"]["config"]["verbose_logging"] = false

default["chef_client"]["chef_license"] = "accept-no-persist"

#
# nscd cookbook overrides
#

default["nscd"]["server_user"] = "nobody" unless platform_family?("suse") # this breaks SLES 15
