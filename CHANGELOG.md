# Chef Client Changelog

## Unreleased:

* Removed dependencies on the 'json' gem, replaced with ffi-yajl.  Use Chef::JSONCompat library for parsing and printing.
* [Issue 2027](https://github.com/opscode/chef/issues/2027) Allow recipe using `dsc_script` opportunity to install Powershell 4 or higher

## Last Release: 11.16.4

* Windows omnibus installer security updates for redistributed bash.exe / sh.exe
  vulnerabilities ("Shellshock") CVE-2014-6271, CVE-2014-6271, CVE-2014-6278,
  CVE-2014-7186, CVE-2014-7187.
* Fix bug on Windows where using the env resource on path could render the path unusable.
* Chef Client now retries when it gets 50X from Chef Server.
* Chef Client 11.16.4 can use the policyfiles generated with Chef DK 0.3.0.

## Release: 11.16.2

* [**Phil Dibowitz**](https://github.com/jaymzh):
  Fix a regression in whyrun_safe_ruby_block.

## Release: 11.16.0

* Fix a bug in user dscl provider to enable managing password and other properties at the same time.
* Add `dsc_script` resource to Chef for PowerShell DSC support on Windows

## Release: 11.14.6:

* Modify action for env raises Chef::Exceptions::Env exception on Windows (Chef Issues 1754)
* Fix RPM package version detection (Issue 1554)
* Fix a bug in reporting not to post negative duration values.
* Add password setting support for Mac 10.7, 10.8 and 10.9 to the dscl user provider.
* ChefSpec can find freebsd_package resource correctly when a package resource is declared on Freebsd.
* http_proxy and related config vars no longer clobber already set ENV vars
* all http_proxy configs now set lowercase + uppercase versions of ENV vars
* https_proxy/ftp_proxy support setting `http://` URLs (and whatever mix and match makes sense)

## Release: 11.14.2

* [**Phil Dibowitz**](https://github.com/jaymzh):
  SIGTERM will once-more kill a non-daemonized chef-client (CHEF-5172)
* [**Pierre Ynard**](https://github.com/linkfanel):
  chef-service-manager should run as a non-interactive service (CHEF-5150)
* [**Tensibai Zhaoying**](https://github.com/Tensibai):
  Fix file:// URI support in remote\_file on windows (CHEF-4472)
* [**John Dyer**](https://github.com/johntdyer):
  Catch HTTPServerException for 404 in remote_file retry (CHEF-5116)
* [**Pavel Yudin**](https://github.com/Kasen):
  Providers are now set correctly on CloudLinux. (CHEF-5182)
* [**Joe Richards**](https://github.com/viyh):
  Made -E option to work with single lettered environments. (CHEF-3075)
* [**Jimmy McCrory**](https://github.com/JimmyMcCrory):
  Added a 'knife node environment set' command. (CHEF-1910)
* [**Hongbin Lu**](https://github.com/hongbin):
  Made bootstrap report authentication exceptions. (CHEF-5161)
* [**Richard Manyanza**](https://github.com/liseki):
  Made `freebsd_package` resource use the brand new "pkgng" package
  manager when available.(CHEF-4637)
* [**Nikhil Benesch**](https://github.com/benesch):
  Implemented a threaded download queue for synchronizing cookbooks. (CHEF-4423)
* [**Chulki Lee**](https://github.com/chulkilee):
  Raise an error when source is accidently passed to apt_package (CHEF-5113)
* [**Cam Cope**](https://github.com/ccope):
  Add an open_timeout when opening an http connection (CHEF-5152)
* [**Sander van Harmelen**](https://github.com/svanharmelen):
  Allow environment variables set on Windows to be used immediately (CHEF-5174)
* [**Luke Amdor**](https://github.com/rubbish):
  Add an option to configure the chef-zero port (CHEF-5228)
* [**Ricardo Signes**](https://github.com/rjbs):
  Added support for the usermod provider on OmniOS
* [**Anand Suresh**](https://github.com/anandsuresh):
  Only modify password when one has been specified. (CHEF-5327)
* [**Stephan Renatus**](https://github.com/srenatus):
  Add exception when JSON parsing fails. (CHEF-5309)
* [**Xabier de Zuazo**](https://github.com/zuazo):
  OK to exclude space in dependencies in metadata.rb. (CHEF-4298)
* [**Łukasz Jagiełło**](https://github.com/ljagiello):
  Allow cookbook names with leading underscores. (CHEF-4562)
* [**Michael Bernstein**](https://github.com/mrb):
  Add Code Climate badge to README.
* [**Phil Sturgeon**](https://github.com/philsturgeon):
  Documentation that -E is not respected by knife ssh [search]. (CHEF-4778)
* [**Stephan Renatus**](https://github.com/srenatus):
  Fix resource_spec.rb.
* [**Sander van Harmelen**](https://github.com/svanharmelen):
  Ensure URI compliant urls. (CHEF-5261)
* [**Robby Dyer**](https://github.com/robbydyer):
  Correctly detect when rpm_package does not exist in upgrade action. (CHEF-5273)
* [**Sergey Sergeev**](https://github.com/zhirafovod):
  Hide sensitive data output on chef-client error (CHEF-5098)
* [**Mark Vanderwiel**](https://github.com/kramvan1):
  Add config option :yum-lock-timeout for yum-dump.py
* [**Peter Fern**](https://github.com/pdf):
  Convert APT package resource to use `provides :package`, add timeout parameter.
* [**Xabier de Zuazo**](https://github.com/zuazo):
  Fix Chef::User#list API error when inflate=true. (CHEF-5328)
* [**Raphaël Valyi**](https://github.com/rvalyi):
  Use git resource status checking to reduce shell_out system calls.
* [**Eric Krupnik**](https://github.com/ekrupnik):
  Added .project to git ignore list.
* [**Ryan Cragun**](https://github.com/ryancragun):
  Support override_runlist CLI option in shef/chef-shell. (CHEF-5314)
* [**Cam Cope**](https://github.com/ccope):
  Fix updating user passwords on Solaris. (CHEF-5247)
* [**Ben Somers**](https://github.com/bensomers):
  Enable storage of roles in subdirectories for chef-solo. (CHEF-4193)
* [**Robert Tarrall**](https://github.com/tarrall):
  Fix Upstart provider with parameters. (CHEF-5265)
* [**Klaas Jan Wierenga**](https://github.com/kjwierenga):
  Don't pass on default HTTP port(80) in Host header. (CHEF-5355)
* [**MarkGibbons**](https://github.com/MarkGibbons):
  Allow for undefined solaris services in the service resource. (CHEF-5347)
* [**Allan Espinosa**](https://github.com/aespinosa):
  Properly knife bootstrap on ArchLinux. (CHEF-5366)
* [**Matt Hoyle**](https://github.com/deployable):
  Made windows service resource to handle transitory states. (CHEF-5319, CHEF-4791)
* [**Brett cave**](https://github.com/brettcave):
  Add Dir.pwd as fallback for default user_home if home directory is not set. (CHEF-5365)
* [**Caleb Tennis**](https://github.com/ctennis):
  Add support for automatically using the Systemd service provider when available. (CHEF-3637)
* [**Matt Hoyle**](https://github.com/deployable):
  Add timeout for Chef::Provider::Service::Windows. (CHEF-1165)
* [**Jesse Hu**](https://github.com/jessehu):
  knife[:attribute] in knife.rb should not override --attribute (CHEF-5158)
* [**Vasiliy Tolstov**](https://github.com/vtolstov):
  Added the initial exherbo linux support for Chef providers.



* Fix knife cookbook site share on windows (CHEF-4994)
* YAJL Allows Invalid JSON File Sending To The Server (CHEF-4899)
* YAJL Silently Ingesting Invalid JSON and "Normalizing" Incorrectly (CHEF-4565)
* Update rpm provider checking regex to allow for special characters (CHEF-4893)
* Allow for spaces in selinux controlled directories (CHEF-5095)
* Windows batch resource run action fails: " TypeError: can't convert nil into String" (CHEF-5287)
* Log resource always triggers notifications (CHEF-4028)
* Prevent tracing? from throwing an exception when first starting chef-shell.
* Use Upstart provider on Ubuntu 13.10+. (CHEF-5276)
* Cleaned up mount provider superclass
* Added "knife serve" to bring up local mode as a server
* Print nested LWRPs with indentation in doc formatter output
* Make local mode stable enough to run chef-pedant
* Wrap code in block context when syntax checking so `return` is valid
  (CHEF-5199)
* Quote git resource rev\_pattern to prevent glob matching files (CHEF-4940)
* Fix OS X service provider actions that don't require the service label
  to work when there is no plist. (CHEF-5223)
* User resource now only prints the name during why-run runs. (CHEF-5180)
* Set --run-lock-timeout to wait/bail if another client has the runlock (CHEF-5074)
* remote\_file's source attribute does not support DelayedEvaluators (CHEF-5162)
* `option` attribute of mount resource now supports lazy evaluation. (CHEF-5163)
* `force_unlink` now only unlinks if the file already exists. (CHEF-5015)
* `chef_gem` resource now uses omnibus gem binary. (CHEF-5092)
* chef-full template gets knife options to override install script url, add wget/curl cli options, and custom install commands (CHEF-4697)
* knife now bootstraps node with the latest current version of chef-client. (CHEF-4911)
* Add config options for attribute whitelisting in node.save. (CHEF-3811)
* Use user's .chef as a fallback cache path if /var/chef is not accessible. (CHEF-5259)
* Fixed Ruby 2.0 Windows compatibility issues around ruby-wmi gem by replacing it with wmi-lite gem.
* Set proxy environment variables if preset in config. (CHEF-4712)
* Automatically enable verify_api_cert when running chef-client in local-mode. (Chef Issues 1464)
* Add helper to warn for broken [windows] paths. (CHEF-5322)
* Send md5 checksummed data for registry key if data type is binary, dword, or qword. (Chef-5323)
* Add warning if host resembles winrm command and knife-windows is not present.
* Use FFI binders to attach :SendMessageTimeout to avoid DL deprecation warning. (ChefDK Issues 69)
* Use 'guest' user on AIX for RSpec tests. (OC-9954)
* Added DelayedEvaluator support in LWRP using the `lazy {}` key
* Fixed a bug where nested resources that inherited from Resource::LWRPBase
  would not share the same actions/default_action as their parent

## Last Release: 11.12.8
* Fix OS X service provider actions that don't require the service label
  to work when there is no plist. (CHEF-5223)
* CHEF-5211: 'knife configure --initial' fails to load 'os' and 'hostname'
  ohai plugins properly
* Fix the order of middlewares in HTTP::Simple (CHEF-5198).
* Wrap code in block context when syntax checking so `return` is valid (CHEF-5199).
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
* guard_interpreter attribute: use powershell\_script, other script resources in guards (CHEF-4553)
* Fix for CHEF-5169: add require for chef/config_fetcher
* SIGTERM will once-more kill a non-daemonized chef-client (CHEF-5172)
