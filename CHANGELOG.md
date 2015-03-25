## Unreleased

## 12.2.0
* Update policyfile API usage to match forthcoming Chef Server release
* `knife ssh` now has an --exit-on-error option that allows users to
  fail-fast rather than moving on to the next machine.
* migrate macosx, windows, openbsd, and netbsd resources to dynamic resolution
* migrate cron and mdadm resources to dynamic resolution
* [Issue 3096](https://github.com/chef/chef/issues/3096) Fix OpenBSD package provider installation issues
* New `dsc_resource` resource to invoke Powershell DSC resources

## 12.1.2
* [Issue 3022](https://github.com/chef/chef/issues/3022): Homebrew Cask install fails
  FIXME (remove on 12.2.0 release): 3022 was only merged to 12-stable and #3077 or its descendant should fix this 
* [Issue 3059](https://github.com/chef/chef/issues/3059): Chef 12.1.1 yum_package silently fails
* [Issue 3078](https://github.com/chef/chef/issues/3078): Compat break in audit-mode changes

## 12.1.1
* [**Phil Dibowitz**](https://github.com/jaymzh):
  [Issue 3008](https://github.com/chef/chef/issues/3008) Allow people to pass in `source` to package
* [Issue 3011](https://github.com/chef/chef/issues/3011) `package` provider base should include 
  `Chef::Mixin::Command` as there are still providers that use it.
* [**Ranjib Dey**](https://github.com/ranjib):
  [Issue 3019](https://github.com/chef/chef/issues/3019) Fix data fetching when explicit attributes are passed

## 12.1.0

* [**Andre Elizondo**](https://github.com/andrewelizondo)
  Typo fixes
* [**Vasiliy Tolstov**](https://github.com/vtolstov):
  cleanup cookbook path from stale files (when using chef-solo with a tarball url)
* [**Nathan Cerny**](https://github.com/ncerny):
  Fix rubygems provider to use https instead of http.
* [**Anshul Sharma**](https://github.com/justanshulsharma)
  removed securerandom patch
* [**Scott Bonds**](https://github.com/bonds)
  add package support for OpenBSD
* [**Lucy Wyman**](https://github.com/lucywyman)
  Added support for handling empty version strings to rubygems provider.
* [**Yulian Kuncheff**](https://github.com/Daegalus)
  Correctly set the pre-release identifier during knife bootstrap.
* [**Anshul Sharma**](https://github.com/justanshulsharma)
  `knife node run_list remove` now accepts run_list options in the same form as add
* [**Veres Lajos**](https://github.com/vlajos)
  Typo fixes
* [**Tim Smith**](https://github.com/tas50)
  Typo fixes
* [Pull 2505](https://github.com/opscode/chef/pull/2505) Make Chef handle URIs in a case-insensitive manner
* [**Phil Dibowitz**](https://github.com/jaymzh):
  Drop SSL warnings now that we have a safe default
* [Pull 2684](https://github.com/chef/chef/pull/2684) Remove ole_initialize/uninitialize which cause problems with Ruby >= 2
* [**BinaryBabel**](https://github.com/binarybabel)
  Make knife cookbook site share prefer gnutar when packaging
* [**Dave Eddy**](https://github.com/bahamas10)
  Support arrays for not_if and only_if
* [**Scott Bonds**](https://github.com/bonds)
  Add service provider for OpenBSD
* [**Alex Slynko**](https://github.com/alex-slynko-wonga)
  Change env provider to preserve ordering
* [**Rob Redpath**](https://github.com/robredpath)
  Add --lockfile opt for chef-client and chef-solo
* [**Josh Murphy**](https://github.com/jdmurphy)
  Check cookbooks exist in path(s) before attempting to upload them with --all
* [**Vasiliy Tolstov**](https://github.com/vtolstov)
  add ability to fetch recipes like in chef-solo when using local-mode
* [**Jan**](https://github.com/habermann24)
  FIX data_bag_item.rb:161: warning: circular argument reference - data_bag
* [**David Radcliffe**](https://github.com/dwradcliffe)
  add banner for knife serve command
* [**Yukihiko Sawanobori**](https://github.com/sawanoboly)
  use Chef::JSONCompat.parse for file_contents
* [**Xabier de Zuazo**] (https://github.com/zuazo)
  Remove some simple Ruby 1.8 and 1.9 code
* [**Xabier de Zuazo**] (https://github.com/zuazo)
  Remove all RSpec test filters related to Ruby 1.8 and 1.9
* [**Xabier de Zuazo**] (https://github.com/zuazo)
  Fix knife cookbook upload messages
* [**David Crowder**] (https://github.com/david-crowder)
  refactor to use shell_out in rpm provider
* [**Phil Dibowitz**](https://github.com/jaymzh):
  Multi-package support
* [**Naotoshi Seo**](https://github.com/sonots):
  Support HTTP/FTP source on rpm_package
  add json_attribs option for chef-apply command
  allow_downgrade in rpm_package
* [**AJ Christensen**](https://github.com/fujin):
  Isolate/fix the no-fork fault. [Issue 2709](https://github.com/chef/chef/issues/2709)
* [**Cory Stephenson**](https://github.com/Aevin1387):
  Remove comments of a service being enabled/disabled in FreeBSD. [Fixes #1791](https://github.com/chef/chef/issues/1791)
* [**Will Albenzi**](https://github.com/walbenzi):
  CHEF-4591: Knife commands to manipulate env_run_list on nodes
* [**Jon Cowie**](https://github.com/jonlives):
  CHEF-2911: Fix yum_package provider to respect version requirements in package name and version attribute
* [**Anshul Sharma**](https://github.com/justanshulsharma):
  * Node::Attribute to_s should print merged attributes [Issue 1526](https://github.com/chef/chef/issues/1562)
  * Access keys attribute in `knife show` list incorrect information [Issue 1974](https://github.com/chef/chef/issues/1974)
  * Guard interpreter loading incorrect resource [Issue 2683](https://github.com/chef/chef/issues/2683)

### Chef Contributions
* ruby 1.9.3 support is dropped
* Update Chef to use RSpec 3.2
* Cleaned up script and execute provider + specs
* Added deprecation warnings around the use of command attribute in script resources
* Audit mode feature added - see the RELEASE_NOTES for details
* shell_out now sets `LANGUAGE` and `LANG` to the `Chef::Config[:internal_locale]` in addition to `LC_ALL` forcing
* chef_gem supports a compile_time flag and will warn if it is not set (behavior will change in the future)
* suppress CHEF-3694 warnings on the most trivial resource cloning
* fixed bugs in the deep_merge_cache logic introduced in 12.0.0 around `node['foo']` vs `node[:foo]` vs. `node.foo`
* add `include_recipe "::recipe"` sugar to reference a recipe in the current cookbook
* Add --proxy-auth option to `knife raw`
* added Chef::Org model class for Chef Organizations in Chef 12 Server
* `powershell_script` should now correctly get the exit code for scripts that it runs. See [Issue 2348](https://github.com/chef/chef/issues/2348)
* Useradd functional tests fail randomly
* Add comments to trusted_certs_content
* fixes a bug where providers would not get defined if a top-level ruby constant with the same name was already defined (ark cookbook, chrome cookbook)
* Fix a bug in `reboot`, `ips_package`, `paludis_package`, `windows_package` resources where `action :nothing` was not permitted
* Use Chef::ApiClient#from_hash in `knife client create` to avoid json_class requirement. [Issue 2542](https://github.com/chef/chef/issues/2542)
* Add support for policyfile native API (preview). These APIs are unstable, and you may be forced to delete data uploaded to them in a
  future release, so only use them for demonstration purposes.
* Deprecation warning for 'knife cookbook test'
* dsc_script should now correctly honor timeout. See [Issue 2831](https://github.com/chef/chef/issues/2831)
* Added an `imports` attribute to dsc_script. This attribute allows you to specify DSC resources that need to be imported for your script.
* Fixed error where guard resources (using :guard_interpreter) were not ran in `why_run` mode [Issue 2694](https://github.com/chef/chef/issues/2694)
* Add `verify` method to File resource per RFC027
* Move supermarket.getchef.com to supermarket.chef.io
* Check with AccessCheck for permission to write to directory on Windows
* Add declare_resource/build_resource comments, fix faulty ||=
* Knife bootstrap creates a client and ships it to the node to implement validatorless bootstraps
* Knife bootstrap can use the client it creates to setup chef-vault items for the node
* windows service now has a configurable timeout

## 12.0.3
* [**Phil Dibowitz**](https://github.com/jaymzh):
[Issue 2594](https://github.com/opscode/chef/issues/2594) Restore missing require in `digester`.

## 12.0.2
* [Issue 2578](https://github.com/opscode/chef/issues/2578) Check that `installed` is not empty for `keg_only` formula in Homebrew provider
* [Issue 2609](https://github.com/opscode/chef/issues/2609) Resolve the circular dependency between ProviderResolver and Resource.
* [Issue 2596](https://github.com/opscode/chef/issues/2596) Fix nodes not writing to disk
* [Issue 2580](https://github.com/opscode/chef/issues/2580) Make sure the relative paths are preserved when using link resource.
* [Pull 2630](https://github.com/opscode/chef/pull/2630) Improve knife's SSL error messaging
* [Issue 2606](https://github.com/opscode/chef/issues/2606) chef 12 ignores default_release for apt_package
* [Issue 2602](https://github.com/opscode/chef/issues/2602) Fix `subscribes` resource notifications.
* [Issue 2578](https://github.com/opscode/chef/issues/2578) Check that `installed` is not empty for `keg_only` formula in Homebrew provider.
* [**gh2k**](https://github.com/gh2k):
  [Issue 2625](https://github.com/opscode/chef/issues/2625) Fix missing `shell_out!` for `windows_package` resource
* [**BackSlasher**](https://github.com/BackSlasher):
  [Issue 2634](https://github.com/opscode/chef/issues/2634) Fix `option ':command' is not a valid option` error in subversion provider.
* [**Seth Vargo**](https://github.com/sethvargo):
  [Issue 2345](https://github.com/opscode/chef/issues/2345) Allow knife to install cookbooks with metadata.json.

## 12.0.1

* [Issue 2552](https://github.com/opscode/chef/issues/2552) Create constant for LWRP before calling `provides`
* [Issue 2545](https://github.com/opscode/chef/issues/2545) `path` attribute of `execute` resource is restored to provide backwards compatibility with Chef 11.
* [Issue 2565](https://github.com/opscode/chef/issues/2565) Fix `Chef::Knife::Core::BootstrapContext` constructor for knife-windows compat.
* [Issue 2566](https://github.com/opscode/chef/issues/2566) Make sure Client doesn't raise error when interval is set on Windows.
* [Issue 2560](https://github.com/opscode/chef/issues/2560) Fix `uninitialized constant Windows::Constants` in `windows_eventlog`.
* [Issue 2563](https://github.com/opscode/chef/issues/2563) Make sure the Chef Client rpm packages are signed with GPG keys correctly.

## 12.0.0

* [**Jesse Hu**](https://github.com/jessehu):
  retry on HTTP 50X Error when calling Chef REST API
* [**Nolan Davidson**](https://github.com/nsdavidson):
  The chef-apply command now prints usage information when called without arguments
* [**Kazuki Saito**](https://github.com/sakazuki):
  CHEF-4933: idempotency fixes for ifconfig provider
* [**Kirill Shirinkin**](https://github.com/Fodoj):
  The knife bootstrap command expands the path of the secret-file
* [**Malte Swart**](https://github.com/mswart):
  [CHEF-4101] DeepMerge - support overwriting hash values with nil
* [**James Belchamber**](https://github.com/JamesBelchamber):
  Mount provider remount action now honours options
* [**Mark Gibbons**](https://github.com/MarkGibbons):
  Fix noauto support in Solaris Mount Provider
* [**Jordan Evans**](https://github.com/jordane):
  support version constraints in value_for_platform
* [**Yukihiko Sawanobori**](https://github.com/sawanoboly):
  Add environment resource attribute to scm resources
* [**Grzesiek Kolodziejczyk**](https://github.com/grk):
  Use thread-safe OpenSSL::Digest instead of Digest
* [**Grzesiek Kolodziejczyk**](https://github.com/grk):
  Chef::Digester converted to thread-safe Singleton mixin.
* [**Vasiliy Tolstov**](https://github.com/vtolstov):
  Reload systemd service only if it's running, otherwise start.
* [**Chris Jerdonek**](https://github.com/cjerdonek):
  knife diagnostic messages sent to stdout instead of stderr
* [**Xabier de Zuazo**](https://github.com/zuazo):
  Remove the unused StreamingCookbookUploader class (CHEF-4586)
* [**Jacob Vosmaer**](https://github.com/jacobvosmaer):
  Fix creation of non-empty FreeBSD groups (#1698)
* [**Nathan Huff**](https://github.com/nhuff):
  Check local repository for ips package installs (#1703)
* [**Sean Clemmer**](https://github.com/sczizzo):
  Fix "cron" resource handling of special strings (e.g. @reboot, @yearly) (#1708)
* [**Phil Dibowitz**](https://github.com/jaymzh):
  'group' provider on OSX properly uses 'dscl' to determine existing groups
* [**Hugo Lopes Tavares**](https://github.com/hltbra):
  Catch StandardError in Chef::ResourceReporter#post_reporting_data (Issue 1550).
* [**Daniel O'Connor**](https://github.com/CloCkWeRX):
  Fix regex causing DuplicateRole error (Issue 1739).
* [**Xeron**](https://github.com/xeron):
  Ability to specify an array for data_bag_path. (CHEF-3399, CHEF-4753)
* [**Jordan**](https://github.com/jordane):
  Use Systemd for recent Fedora and RHEL 7.
* [**Xabier de Zuazo**](https://github.com/zuazo):
  Encrypted data bags should use different HMAC key and include the IV in the HMAC (CHEF-5356).
* [**Pierre Ynard**](https://github.com/linkfanel):
  Don't modify variable passed to env resource when updating.
* [**Chris Aumann**](https://github.com/chr4):
  Add "force" attribute to resource/user, pass "-f" to userdel. (Issue 1601)
* [**Brian Cobb**](https://github.com/bcobb):
  Chef::VersionConstraint#to_s should accurately reflect constraint's behavior.
* [**Kevin Graham**](https://github.com/kgraham):
  Do not override ShellOut:live_stream if already set.
* [**Mike Heijmans**](https://github.com/parabuzzle):
  Change knife option --force to --delete-validators. (Issue 1652)
* [**Pavel Yudin**](https://github.com/Kasen):
  Add Parallels Cloud Server (PCS) platform support.
* [**tbe**](https://github.com/tbe):
  Minor fixes for the Paludis package provider:
  * only search for non-masked packages,
  * increase command timeout length for package installation.
* [**sawanoboly**](https://github.com/sawanoboly):
  Use shared_path for deploy resource.
* [**Victor Hahn**](https://github.com/victorhahncastell):
  Add template syntax check to files in the templates/ dir only.
* [**Jordan**](https://github.com/jordane):
  Allow git provider to checkout existing branch names.
* [**Eric Herot**](https://github.com/eherot):
  Add whitespace boundaries to some mount point references in mount provider.
* [**Dave Eddy**](https://github.com/bahamas10):
  Improve the regex for /etc/rc.conf for the FreeBSD service provider
* [**Stanislav Bogatyrev**](https://github.com/realloc):
  Fetch recipe_url before loading json_attribs in chef-solo (CHEF-5075)
* [**Mal Graty**](https://github.com/mal):
  Workaround for a breaking change in git's shallow-clone behavior. (Issue 1563)
* [**Dave Eddy**](https://github.com/bahamas10):
  Fix version detection in FreeBSD pkgng provider. (PR 1980)
* [**Dan Rathbone**](https://github.com/rathers):
  Fixed gem_package resource to be able to upgrade gems when version is not set.
* [**Jean Mertz**](https://github.com/JeanMertz):
  Made Chef Client load library folder recursively.
* [**Eric Saxby**](https://github.com/sax):
  Made Chef Client read the non-root crontab entries as the user specified in the resource.
* [**sawanoboly**](https://github.com/sawanoboly):
  Added `--dry-run` option to `knife cookbook site share` which displays the files that are to be uploaded to Supermarket.
* [**Sander van Harmelen**](https://github.com/svanharmelen):
  Fixed `Chef::HTTP` to be able to follow relative redirects.
* [**Cory Stephenson**](https://github.com/Aevin1387):
  Fixed FreeBSD port package provider to interpret FreeBSD version 10 correctly.
* [**Brett Chalupa**](https://github.com/brettchalupa):
  Added `source_url` and `issues_url` options to metadata to be used by Supermarket.
* [**Anshul Sharma**](https://github.com/justanshulsharma):
  Fixed Chef Client to use the `:client_name` instead of `:node_name` during initial client registration.
* [**tbe**](https://github.com/tbe):
  Fixed Paludis package provider to be able to interpret the package category.
* [**David Workman**](https://github.com/workmad3):
  Added a more clear error message to chef-apply when no recipe is given.
* [**Joe Nuspl**](https://github.com/nvwls):
  Added support for `sensitive` property to the execute resource.
* [**Nolan Davidson**](https://github.com/nsdavidson):
  Added an error message to prevent unintentional running of `exec()` in recipes.
* [**wacky612**](https://github.com/wacky612):
  Fixed a bug in pacman package provider that was preventing the installation of `bind` package.
* [**Ionuț Arțăriși**](https://github.com/mapleoin):
  Changed the default service provider to systemd on SLES versions 12 and higher.
* [**Ionuț Arțăriși**](https://github.com/mapleoin):
  Changed the default group provider to gpasswd on SLES versions 12 and higher.
* [**Noah Kantrowitz**](https://github.com/coderanger):
  Implemented [RFC017 - File Specificity Overhaul](https://github.com/opscode/chef-rfc/blob/master/rfc017-file-specificity.md).
* [**James Bence**](https://github.com/jbence):
  Improved the reliability of Git provider by making it to be more specific when selecting tags.
* [**Jean Mertz**](https://github.com/JeanMertz):
  Changed knife upload not to validate the ruby files under files & templates directories.
* [**Alex Pop**](https://github.com/alexpop):
  Made `knife cookbook create` to display the directory of the cookbook that is being created.
* [**Alex Pop**](https://github.com/alexpop):
  Fixed the information debug output for the configuration file being used when running knife.
* [**Martin Smith**](https://github.com/martinb3):
  Changed `knife cookbook site share` to make category an optional parameter when uploading cookbooks.
    It is still required when the cookbook is being uploaded for the first time but on the consequent
    uploads existing category of the cookbook will be used.
* [**Nicolas DUPEUX**](https://github.com/vaxvms):
  Added JSON output to `knife status` command. `--medium` and `--long` output formatting parameters are now supported in knife status.
* [**Trevor North**](https://github.com/trvrnrth):
  Removed dead code from `knife ssh`.
* [**Nicolas Szalay**](https://github.com/rottenbytes):
  Fixed a bug preventing mounting of cgroup type devices in the mount provider.
* [**Anshul Sharma**](https://github.com/justanshulsharma):
  Fixed inconsistent globbing in `knife from file` command.
* [**Nicolas Szalay**](https://github.com/rottenbytes):
  Made user prompts in knife more beautiful by adding a space after Y/N prompts.
* [**Ivan Larionov**](https://github.com/xeron):
  Made empty run_list to produce an empty array when using node.to_hash.
* [**Siddheshwar More**](https://github.com/siddheshwar-more):
  Fixed a bug in knife bootstrap that caused config options to override command line options.
* [**Thiago Oliveira**](https://github.com/chilicheech):
  Fixed a bug in Mac OSX group provider and made it idempotent.
* [**liseki**](https://github.com/liseki):
  Fixed a bug in why-run mode for freebsd service resources without configured init scripts.
* [**liseki**](https://github.com/liseki):
  Fixed a bug in freebsd service providers to load the status correctly.


### Chef Contributions

* ruby 1.9.3 support is dropped
* Added RFC-023 Chef 12 Attribute Changes (https://github.com/opscode/chef-rfc/blob/master/rfc023-chef-12-attributes-changes.md)
* Added os/platform_family options to provides syntax on the Chef::Resource DSL
* Added provides methods to the Chef::Provider DSL
* Added supported?(resource, action) class method to all Providers for late-evaluation if a provider can handle a
  resource
* Added ProviderResolver feature to handle late resolution of providers based on what kinds of support is in the
  base operating system.
* Partial Deprecation of Chef::Platform provider mapping.  The static mapping will be removed as Chef-12 progresses
  and the hooks will be completely dropped in Chef-13.
* Default `guard_interpreter` for `powershell_script` resource set to `:powershell_script`, for `batch` to `:batch`
* Recipe definition now returns the retval of the definition
* Add support for Windows 10 to version helper.
* `dsc_script` resource should honor configuration parameters when `configuration_data_script` is not set (Issue #2209)
* Ruby has been updated to 2.1.3 along with rubygems update to 2.4.2
* Removed shelling out to erubis/ruby for syntax checks (>= 1.9 has been able
  to do this in the ruby vm itself for awhile now and we've dropped 1.8.7 which
  could not do this and had to shell_out)
* Report the request and response when a non-200 error code happens
* [FEATURE] Upgrade `knife upload` and `knife download` to download
  **everything** in an organization, now including the organization definition
  itself (`knife download /org.json`) and the invitations and member list
  (`knife download /invitations.json` and `knife download /members.json`).
  Should be compatible with knife-ec-backup.
* Make default Windows paths more backslashy
* `knife` now prefers to load `config.rb` in preference to `knife.rb`;
`knife.rb` will be used if `config.rb` is not found.
* Fixed Config[:cache_path] to use path_join()
* Updated chef-zero to 3.0, so that client tests can be run against Enterprise
  Chef as well as Open Source.
* knife cookbook site download/list/search/share/show/unshare now uses
  supermerket.getchef.com urls
* added Chef::ResourceCollection#insert_at API to the ResourceCollection
* http_proxy and related config vars no longer clobber already set ENV vars
* all http_proxy configs now set lowercase + uppercase versions of ENV vars
* https_proxy/ftp_proxy support setting `http://` URLs (and whatever mix and match makes sense)
* End-to-end tests for Ubuntu 12.04
* Only run end-to-end tests when secure environment variables are present.
* Remove recipe DSL from base provisioner (Issue 1446).
* Enable client-side key generation by default. (Issue 1711)
* CookbookSiteStreamingUploader now uses ssl_verify_mode config option (Issue 1518).
* chef/json_compat now throws its own exceptions not JSON gem exceptions
* Modify action for env raises Chef::Exceptions::Env exception on Windows (Chef Issues 1754)
* Fix a bug in the experimental Policyfile mode that caused errors when
  using templates.
* Disable JSON encoding of request body when non-JSON content type is
  specified.
* Clean up FileVendor and CookbookUploader internal APIs
* log resource now marks itself as supporting why-run
* http_request no longer appends "?message=" query string to GET and HEAD requests
* added shell_out commands directly to the recipe DSL
* cookbook synchronizer deletes old files from cookbooks
* do not clear file cache when override run list is set (CHEF-3684)
* ruby 1.8.7/1.9.1/1.9.2 support is dropped
* set no_lazy_load to true (CHEF-4961)
* set file_stating_uses_destdir config option default to true (CHEF-5040)
* remove dependency on rest-client gem
* Add method shell_out_with_systems_locale to ShellOut.
* chef-repo rake tasks are deprecated; print relevant information for
  each one.
* Fix RPM package version detection (Issue 1554)
* Don't override :default provider map if :default passed as platform (OC-11667).
* Fix SuSE package removal failure (Issue 1732).
* Enable Travis to run Test Kitchen with Kitchen EC2.
* Fix a bug in reporting not to post negative duration values.
* Add password setting support for Mac 10.7, 10.8 and 10.9 to the dscl user provider.
* ChefSpec can find freebsd_package resource correctly when a package resource is declared on Freebsd.
* Autodetect/decrypt encrypted data bag items with data_bag_item dsl method. (Issue 1837, Issue 1849)
* windows_user: look up username instead of resource name (Issue #1705)
* Remove the unused bootstrap templates that install chef from rubygems
* Remove the Chef 10 functionality from bootstrap.
* Deprecate --distro / --template_file options in favor of --boostrap-template
* Add `:node_ssl_verify_mode` & `:node_verify_api_cert` options to bootstrap
  to be able to configure these settings on the bootstrapped node.
* Add partial_search dsl method to Chef::Search::Query, add result filtering to search.
* Transfer trusted certificates under :trusted_certs_dir during bootstrap.
* Set :ssl_verify_mode to :verify_peer by default.
* Add homebrew provider for package resource, use it by default on OS X (Issue #1709)
* Add escape_glob method to PathHelper, update glob operations.
* Verify x509 properties of certificates in the :trusted_certs_dir during knife ssl check.
* Disable unforked interval chef-client runs.
* Removed dependencies on the 'json' gem, replaced with ffi-yajl.  Use Chef::JSONCompat library for parsing and printing.
* Restore the deprecation logic of #valid_actions in LWRPs until Chef 13.
* Now that we don't allow unforked chef-client interval runs, remove the reloading of previously defined LWRPs.
* Use shell_out to determine Chef::Config[:internal_locale], fix CentOS locale detection bug.
* `only_if` and `not_if` attributes of `execute` resource now inherits the parent resource's
  attributes when set to a `String`.
* Retain the original value of `retries` for resources and display the original value when the run fails.
* Added service provider for AIX.
* The Windows env provider will delete elements even if they are only in ENV (and not in the registry)
* Allow events to be logged to Windows Event Log
* Fixed bug in env resource where a value containing the delimiter could never correctly match the existing values
* More intelligent service check for systemd on Ubuntu 14.10.

## 11.16.4

* Windows omnibus installer security updates for redistributed bash.exe / sh.exe
  vulnerabilities ("Shellshock") CVE-2014-6271, CVE-2014-6271, CVE-2014-6278,
  CVE-2014-7186, CVE-2014-7187.
* Fix bug on Windows where using the env resource on path could render the path unusable.
* Chef Client now retries when it gets 50X from Chef Server.
* Chef Client 11.16.4 can use the policyfiles generated with Chef DK 0.3.0.

## 11.16.2

* [**Phil Dibowitz**](https://github.com/jaymzh):
  Fix a regression in whyrun_safe_ruby_block.

## 11.16.0

* Fix a bug in user dscl provider to enable managing password and other properties at the same time.
* Add `dsc_script` resource to Chef for PowerShell DSC support on Windows

## 11.14.6:

* Modify action for env raises Chef::Exceptions::Env exception on Windows (Chef Issues 1754)
* Fix RPM package version detection (Issue 1554)
* Fix a bug in reporting not to post negative duration values.
* Add password setting support for Mac 10.7, 10.8 and 10.9 to the dscl user provider.
* ChefSpec can find freebsd_package resource correctly when a package resource is declared on Freebsd.
* http_proxy and related config vars no longer clobber already set ENV vars
* all http_proxy configs now set lowercase + uppercase versions of ENV vars
* https_proxy/ftp_proxy support setting `http://` URLs (and whatever mix and match makes sense)

## 11.14.2

* [**Jess Mink**](https://github.com/jmink):
  Symlinks to directories should be swingable on windows (CHEF-3960)
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
  Raise an error when source is accidentally passed to apt_package (CHEF-5113)
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
* Raise error if a guard_interpreter is specified and a block is passed to a guard (conditional)
* Allow specifying a guard_interpreter after a conditional on a resource (Fixes #1943)
* Windows package type should be a symbol (Fixes #1997)
