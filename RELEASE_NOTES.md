# Chef Client Release Notes:

## Removed Rest-Client dependency

- cookbooks that previously were able to use rest-client directly will now need to install it via `chef_gem "rest-client"`.
- cookbooks that were broken because of the version of rest-client that chef used will now be able to track and install whatever
  version that they depend on.

## Chef local mode port ranges

- to avoid crashes, by default, Chef will now scan a port range and take the first available port from 8889-9999.
- to change this behavior, you can pass --chef-zero-port=PORT_RANGE (for example, 10,20,30 or 10000-20000) or modify Chef::Config.chef_zero.port to be a port string, an enumerable of ports, or a single port number.

## Knife now logs to stderr

Informational messages from knife are now sent to stderr, allowing you to pipe the output of knife to other commands without having to filter these messages out.
