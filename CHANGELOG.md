# Chef Client Changelog

## Unreleased

* Including a recipe from a cookbook not in the dependency graph logs
  a MissingCookbookDependency warning. Fixes CHEF-4367.
* Improves syntax check speed for Ruby 1.9+, especially when using bundler.
* Send X-Remote-Request-Id header in order to be able to correlate actions during a single run.
* Fix for CHEF-5048.
* Fix for CHEF-5052.
* Fix for CHEF-5018.
* Add --validator option to `knife client create` to be able to create validator clients via knife.
* Add --delete-validators option to `knife client delete` in order to prevent accidental deletion of validator clients.
* Add --delete-validators option to `knife client bulk delete` in order to prevent accidental deletion of validator clients.
* Add -r / --runlist option to chef-client which permanently sets or changes the run_list of a node.
* CHEF-5030: clean up debian ifconfig provider code
* CHEF-5001: spec tests for multiple rollbacks
* Added ohai7 'machinename' attribute as source of `node_name` information
* CHEF-4773: add ruby-shadow support to Mac and FreeBSD distros
* Service Provider for MacOSX now supports `enable` and `disable`
* CHEF-5086: Add reboot_pending? helper to DSL
* Upgrade ohai to 7.0.0.rc.0
* Make the initial bootstrap message more user friendly (CHEF-5102)
* Correctly handle exceptions in formatters when exception.message is nil (CHEF-4743)
* Fix convergence message in deploy provider (CHEF-4929)
* Make group resource idempotent when gid is specified as a string. (CHEF-4927)
* Non-dupable elements are now handled when duping attribute arrays. (CHEF-4799)
* ruby-shadow is not installed on cygwin platform anymore. (CHEF-4946)
* Upgrade chef-zero to 2.0, remove native-compiled puma as chef dependency. (CHEF-4901/CHEF-5005)
* Don't honor splay when sent USR1 signal.
* Don't set log_level in client.rb by default (CHEF-3698)
* Add IBM PowerKVM to Platform map. (CHEF-5135)
* Cookbook metadata now allows boolean and numeric attributes.
* Knife ssh uses cloud port attribute when available.
* Client info and debug logs now contain cookbook versions in addition to cookbook names.

## Last Release: 11.10.0 (02/06/2014)

http://docs.opscode.com/release/11-10/release_notes.html
