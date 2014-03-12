# Chef Client Changelog

## Unreleased

* Improves syntax check speed for Ruby 1.9+, especially when using bundler.
* Send X-Remote-Request-Id header in order to be able to correlate actions during a single run.
* Fix for CHEF-5048.
* Fix for CHEF-5052.
* Fix for CHEF-5018.
* Add --validator option to `knife client create` to be able to create validator clients via knife.
* Add --force option to `knife client delete` in order to prevent accidental deletion of validator clients.
* Add -r / --runlist option to chef-client which permanently sets or changes the run_list of a node.
* CHEF-5030: clean up debian ifconfig provider code
* CHEF-5001: spec tests for multiple rollbacks
* Added ohai7 'machinename' attribute as source of `node_name` information
* CHEF-4773: add ruby-shadow support to Mac and FreeBSD distros
* Service Provider for MacOSX now supports `enable` and `disable`
* CHEF-5086: Add reboot_pending? helper to DSL
* Upgrade ohai to 7.0.0.rc.0
* Make the initial bootstrap message more user friendly (CHEF-5102)

## Last Release: 11.10.0 (02/06/2014)

http://docs.opscode.com/release/11-10/release_notes.html
