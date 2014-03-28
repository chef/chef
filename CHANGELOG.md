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
* Cookbook metadata now allows boolean and numeric attributes. (CHEF-4075)
* Knife ssh uses cloud port attribute when available. (CHEF-4962)
* Client info and debug logs now contain cookbook versions in addition to cookbook names. (CHEF-4643)
* ShellOut mixin now exposes a method to capture the live stream during command execution. (CHEF-5017)
* Service provider is now aware of maintenance state on Solaris. (CHEF-4990)
* Refactor Chef::Util::FileEdit to indicate the purpose of the former file_edited, now unwritten_changes?. (CHEF-3714)
* Fixed FileEdit#insert_line_if_no_match to match multiple times. (CHEF-4173)
* Hide passwords in error messages from the Subversion resource. (CHEF-4680)
* The dpkg package provider now supports epoch versions. (CHEF-1752)
* Multiple missing dependencies are now listed on knife cookbook upload. (CHEF-4851)
* Add a public file_edited? method to Chef::Util::FileEdit. (CHEF-3714)
* Package provider defaults to IPS provider on Solaris 5.11+ (CHEF-5037)
* Chef::REST works with frozen options. (CHEF-5064)
* Service provider now uses Systemd on ArchLinux. (CHEF-4905)
* Support knife node run_list add --before. (CHEF-3812)
* Don't destructively merge subhashes in hash_only_merge!. (CHEF-4918)
* Display correct host name in knife ssh error message (CHEF-5029)
* Knife::UI#confirm now has a default_choice option. (CHEF-5057)
* Add knife 'ssl check' and 'ssl fetch' commands for debugging SSL errors. (CHEF-4711)
* Usermod group provider is only used on OpenSuse. (OHAI-339)
* Add knife 'ssl check' and 'ssl fetch' commands for debugging SSL errors (CHEF-4711)
* Cron resource accepts a weekday attribute as a symbol. (CHEF-4848)
* Cron resource accepts special strings, e.g. @reboot (CHEF-2816)
* Call WIN32OLE.ole_initialize before using WMI (CHEF-4888)
* Fix TypeError when calling dup on un-dupable objects in DeepMerge
* Add optional client-side generation of client keys during registration (CHEF-4373)
* Restore warning for the overlay feature in `knife cookbook upload`,
  which was accidentally removed in 11.0.0.
* Don't save the run_list during `node.save` when running with override run list. (CHEF-4443)
* Enable Content-Length validation for Chef::HTTP::Simple and fix issues around it. (CHEF-5041, CHEF-5100)
* Windows MSI Package Provider (CHEF-5087)
* Fix mount resource when device is a relative symlink (CHEF-4957)
* Increase bootstrap log_level when knife -V -V is set (CHEF-3610)
* Knife cookbook test should honor chefignore (CHEF-4203)
* Fix ImmutableMash and ImmutableArray to_hash and to_a methods (CHEF-5132)

## Last Release: 11.10.0 (02/06/2014)

http://docs.opscode.com/release/11-10/release_notes.html
