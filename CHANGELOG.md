<!-- usage documentation: http://expeditor-docs.es.chef.io/configuration/changelog/ -->
This changelog lists individual merged pull requests to Chef Infra Client and geared towards developers. For a list of significant changes per release see the [Chef Infra Client Release Notes](https://docs.chef.io/release_notes_client/).

<!-- latest_release 17.3.0 -->
## [v17.3.0](https://github.com/chef/chef/tree/v17.3.0) (2021-06-15)

#### Merged Pull Requests
- Add windows_defender and windows_defender_exclusion resources [#11702](https://github.com/chef/chef/pull/11702) ([tas50](https://github.com/tas50))
<!-- latest_release -->

<!-- release_rollup since=17.2.29 -->
### Changes not yet released to stable

#### Merged Pull Requests
- Add windows_defender and windows_defender_exclusion resources [#11702](https://github.com/chef/chef/pull/11702) ([tas50](https://github.com/tas50)) <!-- 17.3.0 -->
- Add the x25519 gem to knife [#11706](https://github.com/chef/chef/pull/11706) ([lamont-granquist](https://github.com/lamont-granquist)) <!-- 17.2.38 -->
- windows_printer: Install drivers, allow skipping port creation, and load state properly [#11665](https://github.com/chef/chef/pull/11665) ([tas50](https://github.com/tas50)) <!-- 17.2.37 -->
- Handle source_line being nil gracefully [#11691](https://github.com/chef/chef/pull/11691) ([fuegas](https://github.com/fuegas)) <!-- 17.2.36 -->
- Enable slow resource reporting in our kitchen tests [#11698](https://github.com/chef/chef/pull/11698) ([tas50](https://github.com/tas50)) <!-- 17.2.35 -->
- Minor improvements for our self documented resources [#11697](https://github.com/chef/chef/pull/11697) ([tas50](https://github.com/tas50)) <!-- 17.2.34 -->
- Add macos_ruby? helper and wire to the macos? helper [#11693](https://github.com/chef/chef/pull/11693) ([lamont-granquist](https://github.com/lamont-granquist)) <!-- 17.2.33 -->
- Bump inspec-core-bin to 4.37.25 [#11686](https://github.com/chef/chef/pull/11686) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot])) <!-- 17.2.32 -->
- Add 17.2 release notes [#11669](https://github.com/chef/chef/pull/11669) ([tas50](https://github.com/tas50)) <!-- 17.2.30 -->
- Add testing of installing knife into the client [#11682](https://github.com/chef/chef/pull/11682) ([tas50](https://github.com/tas50)) <!-- 17.2.31 -->
<!-- release_rollup -->

<!-- latest_stable_release -->
## [v17.2.29](https://github.com/chef/chef/tree/v17.2.29) (2021-06-09)

#### Merged Pull Requests
- Fix markdown code blocks [#11567](https://github.com/chef/chef/pull/11567) ([tas50](https://github.com/tas50))
- More minor docs fixes [#11568](https://github.com/chef/chef/pull/11568) ([tas50](https://github.com/tas50))
- Make sure we have description fields in actions and fix periods [#11573](https://github.com/chef/chef/pull/11573) ([tas50](https://github.com/tas50))
- Add additional action descriptions for docs [#11575](https://github.com/chef/chef/pull/11575) ([tas50](https://github.com/tas50))
- Remove extraneous double mixin for the require. [#11581](https://github.com/chef/chef/pull/11581) ([Dylan-M](https://github.com/Dylan-M))
- Update validation on the ResetLockoutCount to limit it to LockoutDuration rather than limiting it to 30 minutes [#11583](https://github.com/chef/chef/pull/11583) ([chef-davin](https://github.com/chef-davin))
- Enables kernel2 habitat package builds/promotions [#11588](https://github.com/chef/chef/pull/11588) ([collinmcneese](https://github.com/collinmcneese))
- Updated the hostname resource to remove WMI support and use PowerShell… [#11584](https://github.com/chef/chef/pull/11584) ([johnmccrae](https://github.com/johnmccrae))
- Fix failing Test Kitchen tests in GitHub actions [#11589](https://github.com/chef/chef/pull/11589) ([tas50](https://github.com/tas50))
- Remove comment no longer relevant [#11595](https://github.com/chef/chef/pull/11595) ([deivid-rodriguez](https://github.com/deivid-rodriguez))
- Add introduced fields to the hostname resource [#11608](https://github.com/chef/chef/pull/11608) ([tas50](https://github.com/tas50))
- Adds promotion of kernel2 package to current channel in expeditor config [#11605](https://github.com/chef/chef/pull/11605) ([collinmcneese](https://github.com/collinmcneese))
- pass homebrew_path, owner props to homebrew_tap if installing cask [#11607](https://github.com/chef/chef/pull/11607) ([mattlqx](https://github.com/mattlqx))
- Additional dist constants used in chef-cli and InSpec [#11594](https://github.com/chef/chef/pull/11594) ([ramereth](https://github.com/ramereth))
- Do not set sensitive true for SSL certificate [#11578](https://github.com/chef/chef/pull/11578) ([jasonwbarnett](https://github.com/jasonwbarnett))
- Properly generate the docs markdown notes sections [#11601](https://github.com/chef/chef/pull/11601) ([tas50](https://github.com/tas50))
- Make sure we can run dep update on 2+ branches [#11610](https://github.com/chef/chef/pull/11610) ([tas50](https://github.com/tas50))
- Update InSpec to 4.37.17 and bump omnibus [#11611](https://github.com/chef/chef/pull/11611) ([tas50](https://github.com/tas50))
- Bump ffi to 1.15.1 [#11612](https://github.com/chef/chef/pull/11612) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- inspec_waiver_file_entry: Autoload yaml and use dist file [#11552](https://github.com/chef/chef/pull/11552) ([tas50](https://github.com/tas50))
- Bump the knife ffi dep [#11618](https://github.com/chef/chef/pull/11618) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump inspec-core-bin to 4.37.20 [#11632](https://github.com/chef/chef/pull/11632) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Bump chef/chefstyle to 082bbaf73d76000724f8d8ae3ba7f89c9123ad3f [#11635](https://github.com/chef/chef/pull/11635) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Add a slow resources report to chef-client [#11642](https://github.com/chef/chef/pull/11642) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump all deps to the latest [#11643](https://github.com/chef/chef/pull/11643) ([tas50](https://github.com/tas50))
- Make sure we load ohai in knife configure correctly [#11647](https://github.com/chef/chef/pull/11647) ([tas50](https://github.com/tas50))
- Support recipes that and in .yaml as well as .yml [#11629](https://github.com/chef/chef/pull/11629) ([marcparadise](https://github.com/marcparadise))
- Fix Chef::Handler specs and slow report behavior [#11648](https://github.com/chef/chef/pull/11648) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix incorrect require_relative causing failures in `knife org user add` [#11649](https://github.com/chef/chef/pull/11649) ([marcparadise](https://github.com/marcparadise))
- Add tests to verify knife command load &amp; execution [#11653](https://github.com/chef/chef/pull/11653) ([marcparadise](https://github.com/marcparadise))
- Bump inspec-core-bin to 4.37.23 [#11655](https://github.com/chef/chef/pull/11655) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Updated the Windows Pagefile resource to use PowerShell over WMI, added a corresponding test file [#11636](https://github.com/chef/chef/pull/11636) ([johnmccrae](https://github.com/johnmccrae))
- windows_printer: use powershell_exec to delete the printer instead of slower/double logging powershell_script [#11663](https://github.com/chef/chef/pull/11663) ([tas50](https://github.com/tas50))
- Cleanup windows_printer_port and allow updating the port [#11662](https://github.com/chef/chef/pull/11662) ([tas50](https://github.com/tas50))
- Cleanup the zypper_repository resource + support multiple GPG Keys [#11660](https://github.com/chef/chef/pull/11660) ([tas50](https://github.com/tas50))
- Add ed25519 gem back to the omnibus install [#11664](https://github.com/chef/chef/pull/11664) ([tas50](https://github.com/tas50))
- windows_firewall_rule: allow for multiple remote addresses [#11657](https://github.com/chef/chef/pull/11657) ([johnmccrae](https://github.com/johnmccrae))
- Improve the automatically generated docs [#11670](https://github.com/chef/chef/pull/11670) ([tas50](https://github.com/tas50))
- Update omnibus-software to the latest [#11673](https://github.com/chef/chef/pull/11673) ([tas50](https://github.com/tas50))
- Support attribute block/allow list in data collector [#11674](https://github.com/chef/chef/pull/11674) ([marcparadise](https://github.com/marcparadise))
<!-- latest_stable_release -->

## [v17.1.35](https://github.com/chef/chef/tree/v17.1.35) (2021-05-11)

#### Merged Pull Requests
- Fix building knife and make it require Ruby 2.7 [#11463](https://github.com/chef/chef/pull/11463) ([tas50](https://github.com/tas50))
- Fix location and resource_name of unified_mode deprecation message [#11469](https://github.com/chef/chef/pull/11469) ([lamont-granquist](https://github.com/lamont-granquist))
- Make deprecation warning message more explicit [#11470](https://github.com/chef/chef/pull/11470) ([lamont-granquist](https://github.com/lamont-granquist))
- Loosen the chef deps in knife and remove the Gemfile.lock [#11471](https://github.com/chef/chef/pull/11471) ([tas50](https://github.com/tas50))
- use int64 on x64 architecture for LPARAM and LONG_PTR types [#11472](https://github.com/chef/chef/pull/11472) ([mwrock](https://github.com/mwrock))
- Remove Chef Sugar from CI testing matrix [#11475](https://github.com/chef/chef/pull/11475) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump inspec-core-bin to 4.36.4 [#11474](https://github.com/chef/chef/pull/11474) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Update URLs in our Compliance Phase errors [#11480](https://github.com/chef/chef/pull/11480) ([tas50](https://github.com/tas50))
- Yum func spec modernization [#11483](https://github.com/chef/chef/pull/11483) ([lamont-granquist](https://github.com/lamont-granquist))
- Make CLI one of the default reporters for Compliance Phase [#11481](https://github.com/chef/chef/pull/11481) ([tas50](https://github.com/tas50))
- move knife spec tests into the knife gem dir [#11275](https://github.com/chef/chef/pull/11275) ([marcparadise](https://github.com/marcparadise))
- Bump omnibus from `79c80e0` to `1d97cd9` in /omnibus [#11478](https://github.com/chef/chef/pull/11478) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Fix yum provider blocking and flushing [#11486](https://github.com/chef/chef/pull/11486) ([lamont-granquist](https://github.com/lamont-granquist))
- Update omnibus to unbreak builds [#11489](https://github.com/chef/chef/pull/11489) ([tas50](https://github.com/tas50))
- Remove RHEL5 support from yum_package provider [#11492](https://github.com/chef/chef/pull/11492) ([lamont-granquist](https://github.com/lamont-granquist))
- Remove the ruby-prof gem from omnibus packages [#11491](https://github.com/chef/chef/pull/11491) ([tas50](https://github.com/tas50))
- Remove profile-ruby tests [#11493](https://github.com/chef/chef/pull/11493) ([tas50](https://github.com/tas50))
- Bump chef/chefstyle to 7f3a6e65b45e62446291840315f32afa95b80959 [#11498](https://github.com/chef/chef/pull/11498) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Enable deprecation warnings in our specs [#11499](https://github.com/chef/chef/pull/11499) ([tas50](https://github.com/tas50))
- Resolve File.exists? in directory provider [#11502](https://github.com/chef/chef/pull/11502) ([tas50](https://github.com/tas50))
- Bump chef/ohai to 947a97d47daa1dce6aa7b91f2057b15451805b25 [#11503](https://github.com/chef/chef/pull/11503) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Fix systemd service state detection [#11497](https://github.com/chef/chef/pull/11497) ([ramereth](https://github.com/ramereth))
- Remove knife deps from the chef gemspec [#11488](https://github.com/chef/chef/pull/11488) ([tas50](https://github.com/tas50))
- Add back windows deps to omnibus [#11509](https://github.com/chef/chef/pull/11509) ([tas50](https://github.com/tas50))
- Bump chef/ohai to 17.1 [#11511](https://github.com/chef/chef/pull/11511) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Fix bug causing systemd units to always re-enable and re-start [#11512](https://github.com/chef/chef/pull/11512) ([gene1wood](https://github.com/gene1wood))
- Fix edit_resource usage in unified_mode [#11519](https://github.com/chef/chef/pull/11519) ([lamont-granquist](https://github.com/lamont-granquist))
- Suppress unified mode deprecation warning for deprecated resources [#11520](https://github.com/chef/chef/pull/11520) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump inspec-core-bin to 4.37.0 [#11525](https://github.com/chef/chef/pull/11525) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- windows_security_policy: Add AuditPolicyChange and LockoutDuration capabilities [#11533](https://github.com/chef/chef/pull/11533) ([johnmccrae](https://github.com/johnmccrae))
- DNF provider update [#11535](https://github.com/chef/chef/pull/11535) ([lamont-granquist](https://github.com/lamont-granquist))
- Update Hostname resource to account for newer versions of PowerShell being standard [#11537](https://github.com/chef/chef/pull/11537) ([johnmccrae](https://github.com/johnmccrae))
- Use buffered i/o for yum and disable repos in testing [#11538](https://github.com/chef/chef/pull/11538) ([lamont-granquist](https://github.com/lamont-granquist))
- Add introduced to the new hostname properties [#11539](https://github.com/chef/chef/pull/11539) ([tas50](https://github.com/tas50))
- Fix a typo setting up cookbook_name value in templates [#11540](https://github.com/chef/chef/pull/11540) ([tas50](https://github.com/tas50))
- Run Linux dokken tests in GitHub Actions [#11515](https://github.com/chef/chef/pull/11515) ([tas50](https://github.com/tas50))
- Test more platforms in Dokken / GH Actions [#11546](https://github.com/chef/chef/pull/11546) ([tas50](https://github.com/tas50))
- Fix 2 typos in code and slim our cspell exceptions down [#11541](https://github.com/chef/chef/pull/11541) ([tas50](https://github.com/tas50))
- Treat 32bit-on-64bit the same as 32bit [#11547](https://github.com/chef/chef/pull/11547) ([lamont-granquist](https://github.com/lamont-granquist))
- Build RHEL 8 packages on RHEL 8 boxes [#11544](https://github.com/chef/chef/pull/11544) ([tas50](https://github.com/tas50))
- Silence `bundle install` warning when installing gems for cookbooks [#11551](https://github.com/chef/chef/pull/11551) ([nvwls](https://github.com/nvwls))
- Remove comment no longer relevant [#11550](https://github.com/chef/chef/pull/11550) ([deivid-rodriguez](https://github.com/deivid-rodriguez))
- Creating the `inspec_waiver_file_entry` resource for managing and formatting a waiver file [#10098](https://github.com/chef/chef/pull/10098) ([chef-davin](https://github.com/chef-davin))
- Bump chef/chefstyle to 9e9864d3839e1a78703e6662b0dbe7a04af05fd1 [#11527](https://github.com/chef/chef/pull/11527) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- mount: Fix idempotentency for loopback mounts [#11376](https://github.com/chef/chef/pull/11376) ([msys-sgarg](https://github.com/msys-sgarg))
- Revert &quot;Kept a check in pattern matching for a mount of type loop&quot; [#11557](https://github.com/chef/chef/pull/11557) ([tas50](https://github.com/tas50))
- Strip the __env_path variable in the which helper [#11561](https://github.com/chef/chef/pull/11561) ([tas50](https://github.com/tas50))
- Revert windows hostname changes for now [#11564](https://github.com/chef/chef/pull/11564) ([tas50](https://github.com/tas50))
- Fix logrotate in tests [#11565](https://github.com/chef/chef/pull/11565) ([tas50](https://github.com/tas50))

## [v17.0.242](https://github.com/chef/chef/tree/v17.0.242) (2021-04-28)

#### Merged Pull Requests
- knife bootstrap: Windows Trusted cert path slashes fix [#10740](https://github.com/chef/chef/pull/10740) ([axelrtgs](https://github.com/axelrtgs))
- Improve our automated resource documentation generation [#10739](https://github.com/chef/chef/pull/10739) ([tas50](https://github.com/tas50))
- Add audit cookbook&#39;s chef_node_attribute_enabled to Compliance Phase. [#10735](https://github.com/chef/chef/pull/10735) ([phiggins](https://github.com/phiggins))
- locale: Update the locale-gen timeout to 1800s [#10743](https://github.com/chef/chef/pull/10743) ([tas50](https://github.com/tas50))
- Update train to 3.4.4 [#10745](https://github.com/chef/chef/pull/10745) ([tas50](https://github.com/tas50))
- Remove old test script. [#10746](https://github.com/chef/chef/pull/10746) ([phiggins](https://github.com/phiggins))
- Cleanup bootstrap&#39;s trusted_certs_dir tests. [#10754](https://github.com/chef/chef/pull/10754) ([phiggins](https://github.com/phiggins))
- Fix failures in ssl handler [#10751](https://github.com/chef/chef/pull/10751) ([phiggins](https://github.com/phiggins))
- Update links to Compliance Phase documentation in log messages. [#10755](https://github.com/chef/chef/pull/10755) ([phiggins](https://github.com/phiggins))
- Bump Chef Infra to 17 [#10760](https://github.com/chef/chef/pull/10760) ([tas50](https://github.com/tas50))
- Chef 17: Assume Rubygems 1.8 in the rubygems provider / specs [#10379](https://github.com/chef/chef/pull/10379) ([tas50](https://github.com/tas50))
- Remove EOL RHEL 6 32bit builds [#10721](https://github.com/chef/chef/pull/10721) ([tas50](https://github.com/tas50))
- Fixed cron_d resource ignoring sensitive property in Chef 17 [#10767](https://github.com/chef/chef/pull/10767) ([axl89](https://github.com/axl89))
- Pull in the new FFI we need for M1 Macs [#10772](https://github.com/chef/chef/pull/10772) ([tas50](https://github.com/tas50))
- Remove support for Ubuntu 16.04 [#10765](https://github.com/chef/chef/pull/10765) ([tas50](https://github.com/tas50))
- Misc minor perf bumps [#10773](https://github.com/chef/chef/pull/10773) ([tas50](https://github.com/tas50))
- Resolve Lint/ParenthesesAsGroupedExpression warnings [#10779](https://github.com/chef/chef/pull/10779) ([tas50](https://github.com/tas50))
- Cleanup some more disabled style cops [#10780](https://github.com/chef/chef/pull/10780) ([tas50](https://github.com/tas50))
- Refactor the code for windows_security_policy resource [#10699](https://github.com/chef/chef/pull/10699) ([chef-davin](https://github.com/chef-davin))
- Fix knife status json output for EC2 instance with no public IP. [#10781](https://github.com/chef/chef/pull/10781) ([phiggins](https://github.com/phiggins))
- Cleanup knife status [#10782](https://github.com/chef/chef/pull/10782) ([phiggins](https://github.com/phiggins))
- Stub http requests in rubygems tests. [#10761](https://github.com/chef/chef/pull/10761) ([phiggins](https://github.com/phiggins))
- Fix dnf_package version and arch property support and idempotency [#9847](https://github.com/chef/chef/pull/9847) ([lamont-granquist](https://github.com/lamont-granquist))
- Stop updating bundler in CI [#10786](https://github.com/chef/chef/pull/10786) ([tas50](https://github.com/tas50))
- Removed unused rubygems from the omnibus overrides file [#10788](https://github.com/chef/chef/pull/10788) ([tas50](https://github.com/tas50))
- Don&#39;t install util-linux into the containers in CI [#10787](https://github.com/chef/chef/pull/10787) ([tas50](https://github.com/tas50))
- Ensure we can still install RHEL 7 GCC on RHEL 6 in testing [#10723](https://github.com/chef/chef/pull/10723) ([tas50](https://github.com/tas50))
- Remove Test Kitchen tests for Amazon Linux 201X [#10789](https://github.com/chef/chef/pull/10789) ([tas50](https://github.com/tas50))
- Replace Ubuntu 20.10 testing with 21.04 [#10790](https://github.com/chef/chef/pull/10790) ([tas50](https://github.com/tas50))
- Add Test Kitchen testing for Debian 11 [#10791](https://github.com/chef/chef/pull/10791) ([tas50](https://github.com/tas50))
- Fix escaping in doc string. [#10793](https://github.com/chef/chef/pull/10793) ([phiggins](https://github.com/phiggins))
- Consolidate Windows cert tests to improve CI runtime [#10794](https://github.com/chef/chef/pull/10794) ([phiggins](https://github.com/phiggins))
- Coerce uid to integer in Windows user resource. [#10803](https://github.com/chef/chef/pull/10803) ([phiggins](https://github.com/phiggins))
- Remove the runtime dep on bundler [#10801](https://github.com/chef/chef/pull/10801) ([tas50](https://github.com/tas50))
- Update bcrypt_pbkdf to support Ruby 3 [#10804](https://github.com/chef/chef/pull/10804) ([tas50](https://github.com/tas50))
- Remove the evals in the omnibus gemfile for Dependabot [#10805](https://github.com/chef/chef/pull/10805) ([tas50](https://github.com/tas50))
- Bump test-kitchen from 2.8.0 to 2.9.0 in /omnibus [#10807](https://github.com/chef/chef/pull/10807) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Bump omnibus-software from `457df26` to `869ef4e` in /omnibus [#10808](https://github.com/chef/chef/pull/10808) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Bump omnibus from `d13ae16` to `44f1303` in /omnibus [#10806](https://github.com/chef/chef/pull/10806) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Add gemspec metadata [#10809](https://github.com/chef/chef/pull/10809) ([tas50](https://github.com/tas50))
- Pin ffi for now to prevent i386 windows failures [#10810](https://github.com/chef/chef/pull/10810) ([tas50](https://github.com/tas50))
- Fix homebrew_cask for the new syntax [#10822](https://github.com/chef/chef/pull/10822) ([tas50](https://github.com/tas50))
- Update Nokogiri to 1.11.0 [#10829](https://github.com/chef/chef/pull/10829) ([tas50](https://github.com/tas50))
- Add a new `reposdir` property in the `yum_repository` resource [#10830](https://github.com/chef/chef/pull/10830) ([tas50](https://github.com/tas50))
- Simplify the code in the hostname resource [#10832](https://github.com/chef/chef/pull/10832) ([tas50](https://github.com/tas50))
- Add 16.9 release notes [#10835](https://github.com/chef/chef/pull/10835) ([tas50](https://github.com/tas50))
- load_current_resource for systemd service more efficiently [#10776](https://github.com/chef/chef/pull/10776) ([joshuamiller01](https://github.com/joshuamiller01))
- Add Chef Infra Client 15.15 release notes [#10847](https://github.com/chef/chef/pull/10847) ([tas50](https://github.com/tas50))
- Update chef-zero to pull in webrick [#10853](https://github.com/chef/chef/pull/10853) ([tas50](https://github.com/tas50))
- adapt to FreeBSD pkgng sysexit changes [#10813](https://github.com/chef/chef/pull/10813) ([mrtazz](https://github.com/mrtazz))
- Compliance phase: change the audit cb checker to use the recipes list on the node. [#10864](https://github.com/chef/chef/pull/10864) ([lamont-granquist](https://github.com/lamont-granquist))
- Remove the kitchen-azurerm dep for kitchent tests [#10865](https://github.com/chef/chef/pull/10865) ([tas50](https://github.com/tas50))
- Fix misspelling in spec/functional/resource/aixinit_service_spec.rb. [#10868](https://github.com/chef/chef/pull/10868) ([coldiron](https://github.com/coldiron))
- Update the alternatives and chef_client_launchd descriptions [#10873](https://github.com/chef/chef/pull/10873) ([tas50](https://github.com/tas50))
- Fix yard warnings in the chef_vault dsl [#10870](https://github.com/chef/chef/pull/10870) ([tas50](https://github.com/tas50))
- Fix ohai resource spec [#10874](https://github.com/chef/chef/pull/10874) ([lamont-granquist](https://github.com/lamont-granquist))
- Pin rspec until we can resolve failures with 3.10 [#10879](https://github.com/chef/chef/pull/10879) ([tas50](https://github.com/tas50))
- Updated uuidtools version [#10881](https://github.com/chef/chef/pull/10881) ([kapilchouhan99](https://github.com/kapilchouhan99))
- Compliance Phase: even better audit cookbook detection [#10882](https://github.com/chef/chef/pull/10882) ([lamont-granquist](https://github.com/lamont-granquist))
- Add support for client.d files in chef-shell [#10880](https://github.com/chef/chef/pull/10880) ([jaymzh](https://github.com/jaymzh))
- Manually install necessary Ruby for verify pipeline [#10869](https://github.com/chef/chef/pull/10869) ([christopher-snapp](https://github.com/christopher-snapp))
- Remove Ruby 2.6 tests [#10884](https://github.com/chef/chef/pull/10884) ([tas50](https://github.com/tas50))
- Test chef-utils and chef-config on Ruby 2.6 still [#10885](https://github.com/chef/chef/pull/10885) ([tas50](https://github.com/tas50))
- Resolve chefstyle failure [#10886](https://github.com/chef/chef/pull/10886) ([tas50](https://github.com/tas50))
- Add support for lazy attributes [#10861](https://github.com/chef/chef/pull/10861) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump omnibus-software from `869ef4e` to `023e6bf` in /omnibus [#10889](https://github.com/chef/chef/pull/10889) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Bump test-kitchen from 2.9.0 to 2.10.0 in /omnibus [#10893](https://github.com/chef/chef/pull/10893) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Add backup functionality to windows_task [#10894](https://github.com/chef/chef/pull/10894) ([kimbernator](https://github.com/kimbernator))
- Bump omnibus-software from `023e6bf` to `1cff56e` in /omnibus [#10903](https://github.com/chef/chef/pull/10903) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Bump inspec-core-bin to 4.25.1 [#10907](https://github.com/chef/chef/pull/10907) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Add release notes for 16.9.29 [#10910](https://github.com/chef/chef/pull/10910) ([tas50](https://github.com/tas50))
- Don&#39;t ship dev gems in the shipping artifact [#10913](https://github.com/chef/chef/pull/10913) ([lamont-granquist](https://github.com/lamont-granquist))
- fix typo in release notes [#10924](https://github.com/chef/chef/pull/10924) ([IanMadd](https://github.com/IanMadd))
- load_current_resource for systemd_unit more efficiently [#10925](https://github.com/chef/chef/pull/10925) ([joshuamiller01](https://github.com/joshuamiller01))
- Pull in the latest Ohai [#10929](https://github.com/chef/chef/pull/10929) ([tas50](https://github.com/tas50))
- Update Ohai to 17.0.10 [#10931](https://github.com/chef/chef/pull/10931) ([tas50](https://github.com/tas50))
- Replace deprecated File.exists? with File.exist? in more places [#10934](https://github.com/chef/chef/pull/10934) ([tas50](https://github.com/tas50))
- Fix an interpolation mistake in an error message + turn on the cop [#10935](https://github.com/chef/chef/pull/10935) ([tas50](https://github.com/tas50))
- Enable Deprecated Constants Cop [#10936](https://github.com/chef/chef/pull/10936) ([tas50](https://github.com/tas50))
- Bump train-core to 3.4.8 [#10940](https://github.com/chef/chef/pull/10940) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- handles su - USER session to perform bootstrap [#10410](https://github.com/chef/chef/pull/10410) ([vsingh-msys](https://github.com/vsingh-msys))
- Bump omnibus from `44f1303` to `65c5931` in /omnibus [#10944](https://github.com/chef/chef/pull/10944) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Bump train-core to 3.4.9 [#10945](https://github.com/chef/chef/pull/10945) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Update systemd_unit.rb to make Cookstyle compliant [#10937](https://github.com/chef/chef/pull/10937) ([cpressland](https://github.com/cpressland))
- Bump inspec-core-bin to 4.26.4 [#10946](https://github.com/chef/chef/pull/10946) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Add 16.9.32 release notes [#10949](https://github.com/chef/chef/pull/10949) ([tas50](https://github.com/tas50))
- Fix DNF version comparison bug [#10951](https://github.com/chef/chef/pull/10951) ([lamont-granquist](https://github.com/lamont-granquist))
- Update Ohai to 17.0.11 and Chefstyle to 1.6.2 [#10956](https://github.com/chef/chef/pull/10956) ([tas50](https://github.com/tas50))
- Bump Ohai to 17.0.12 for Alma Linux support [#10957](https://github.com/chef/chef/pull/10957) ([tas50](https://github.com/tas50))
- fix specs for spec 3.10 [#10959](https://github.com/chef/chef/pull/10959) ([lamont-granquist](https://github.com/lamont-granquist))
- Drop some compliance log messages down to debug output [#10965](https://github.com/chef/chef/pull/10965) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump omnibus-software from `197c895` to `c523ead` in /omnibus [#10981](https://github.com/chef/chef/pull/10981) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Handle sysv compat mode when checking enabled status for systemd service [#10976](https://github.com/chef/chef/pull/10976) ([joshuamiller01](https://github.com/joshuamiller01))
- Compliance cli report [#10939](https://github.com/chef/chef/pull/10939) ([aknarts](https://github.com/aknarts))
- Chef 17: Remove windows service manager capabilities [#10928](https://github.com/chef/chef/pull/10928) ([tas50](https://github.com/tas50))
- Add support for resource action descriptions [#10952](https://github.com/chef/chef/pull/10952) ([marcparadise](https://github.com/marcparadise))
- Improve chef-utils helper descriptions [#10984](https://github.com/chef/chef/pull/10984) ([tas50](https://github.com/tas50))
- windows_certificate: Fix the `user_store` property to actually install certificates to the user store [#10977](https://github.com/chef/chef/pull/10977) ([tas50](https://github.com/tas50))
- Improve resource automation [#10988](https://github.com/chef/chef/pull/10988) ([tas50](https://github.com/tas50))
- DNF/YUM package: fix abrt errors [#10991](https://github.com/chef/chef/pull/10991) ([lamont-granquist](https://github.com/lamont-granquist))
- Improve the auto generation of documentation [#10992](https://github.com/chef/chef/pull/10992) ([tas50](https://github.com/tas50))
- Update Ohai to 17.0.17 [#10994](https://github.com/chef/chef/pull/10994) ([tas50](https://github.com/tas50))
- Update Ohai to 17.0.18 for alibabalinux support [#10995](https://github.com/chef/chef/pull/10995) ([tas50](https://github.com/tas50))
- Fix downgrades in apt_package [#10993](https://github.com/chef/chef/pull/10993) ([jaymzh](https://github.com/jaymzh))
- Extend the reboot_pending? helper to all debian-ish platforms [#10989](https://github.com/chef/chef/pull/10989) ([tas50](https://github.com/tas50))
- Bump ffi-libarchive to 1.0.17 [#11000](https://github.com/chef/chef/pull/11000) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Bump mixlib-archive to 1.1.4 [#11002](https://github.com/chef/chef/pull/11002) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Add alibaba? helper and pull in Ohai with alibaba support [#11004](https://github.com/chef/chef/pull/11004) ([tas50](https://github.com/tas50))
- Add more descriptions for docs generation [#11003](https://github.com/chef/chef/pull/11003) ([tas50](https://github.com/tas50))
- Bump omnibus-software from `1fa2052` to `a018c22` in /omnibus [#11009](https://github.com/chef/chef/pull/11009) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Use openssl 1.1.1i for OSX builds  [#11006](https://github.com/chef/chef/pull/11006) ([marcparadise](https://github.com/marcparadise))
- Bump omnibus-software from `a018c22` to `ef9714f` in /omnibus [#11023](https://github.com/chef/chef/pull/11023) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Bump berkshelf from 7.1.0 to 7.2.0 in /omnibus [#11027](https://github.com/chef/chef/pull/11027) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Fix automate compliance fetcher for profiles with at signs [#11032](https://github.com/chef/chef/pull/11032) ([lamont-granquist](https://github.com/lamont-granquist))
- mount: Fix for network mounts which use the root level as the device [#11031](https://github.com/chef/chef/pull/11031) ([ramereth](https://github.com/ramereth))
- Stop producing Habitat kernel2 packages [#11037](https://github.com/chef/chef/pull/11037) ([tas50](https://github.com/tas50))
- Fix typo in powershell_script.rb [#11040](https://github.com/chef/chef/pull/11040) ([floh96](https://github.com/floh96))
- Don&#39;t make upstart service to service on any debian platform families [#11039](https://github.com/chef/chef/pull/11039) ([tas50](https://github.com/tas50))
- Bump mixlib-shellout to 3.2.5 [#11041](https://github.com/chef/chef/pull/11041) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Remove an Upstart check for Ubuntu 8.04-9.04 [#11038](https://github.com/chef/chef/pull/11038) ([tas50](https://github.com/tas50))
- Fix hab promotes + compile with -O3 for performance [#11045](https://github.com/chef/chef/pull/11045) ([tas50](https://github.com/tas50))
- Bump omnibus-software from `ef9714f` to `dd2a33e` in /omnibus [#11050](https://github.com/chef/chef/pull/11050) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Remove macOS 10.13 from the build matrix [#10680](https://github.com/chef/chef/pull/10680) ([tas50](https://github.com/tas50))
- Fully remove user resource support for macOS &lt; 10.14 [#10688](https://github.com/chef/chef/pull/10688) ([tas50](https://github.com/tas50))
- Update to latest omnibus-software dep for openssl signing fix [#11048](https://github.com/chef/chef/pull/11048) ([marcparadise](https://github.com/marcparadise))
- Bump omnibus from `f939485` to `c882886` in /omnibus [#11057](https://github.com/chef/chef/pull/11057) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Bump mixlib-archive to 1.1.6 [#11059](https://github.com/chef/chef/pull/11059) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Bump omnibus-software from `dd2a33e` to `1dd8635` in /omnibus [#11062](https://github.com/chef/chef/pull/11062) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Bump mixlib-archive to 1.1.7 [#11066](https://github.com/chef/chef/pull/11066) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Bump omnibus to 8.1.1 for fastmsi fix [#11071](https://github.com/chef/chef/pull/11071) ([tas50](https://github.com/tas50))
- Update name of macos builder in Buildkite [#11063](https://github.com/chef/chef/pull/11063) ([tas50](https://github.com/tas50))
- bump openssl-1.0.2y [#11065](https://github.com/chef/chef/pull/11065) ([dheerajd-msys](https://github.com/dheerajd-msys))
- 16.10.17 notes [#11080](https://github.com/chef/chef/pull/11080) ([tas50](https://github.com/tas50))
- Update Ohai to 17.0.21 [#11085](https://github.com/chef/chef/pull/11085) ([tas50](https://github.com/tas50))
- Improve automatic docs generation [#11047](https://github.com/chef/chef/pull/11047) ([tas50](https://github.com/tas50))
- Integrated knife-opc into Chef [#10187](https://github.com/chef/chef/pull/10187) ([snehaldwivedi](https://github.com/snehaldwivedi))
- Re-lazy the template variable default [#11089](https://github.com/chef/chef/pull/11089) ([lamont-granquist](https://github.com/lamont-granquist))
- Further improve docs generation [#11088](https://github.com/chef/chef/pull/11088) ([tas50](https://github.com/tas50))
- Bump train-core to 3.5.2 [#11091](https://github.com/chef/chef/pull/11091) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Update Ohai to 17.0.22 [#11092](https://github.com/chef/chef/pull/11092) ([tas50](https://github.com/tas50))
- Update resolver cookbook usage in test-kitchen tests [#11086](https://github.com/chef/chef/pull/11086) ([ramereth](https://github.com/ramereth))
- Bump omnibus-software from `9390767` to `fb0fa04` in /omnibus [#11098](https://github.com/chef/chef/pull/11098) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Bump inspec-core-bin to 4.26.13 [#11099](https://github.com/chef/chef/pull/11099) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Add a compliance_mode node attribute [#11111](https://github.com/chef/chef/pull/11111) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump omnibus-software from `fb0fa04` to `a1e9c90` in /omnibus [#11116](https://github.com/chef/chef/pull/11116) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Extend node[&quot;audit&quot;][&quot;compliance_phase&quot;] to assert phase on or off [#11115](https://github.com/chef/chef/pull/11115) ([lamont-granquist](https://github.com/lamont-granquist))
- Dup default property values [#11095](https://github.com/chef/chef/pull/11095) ([lamont-granquist](https://github.com/lamont-granquist))
- Use .tr instead of .gsub where we can [#11120](https://github.com/chef/chef/pull/11120) ([tas50](https://github.com/tas50))
- Bump all deps to current and fix a spelling mistake [#11122](https://github.com/chef/chef/pull/11122) ([tas50](https://github.com/tas50))
- Use shell redirection in chef_client_cron when append_log_file is true [#11124](https://github.com/chef/chef/pull/11124) ([ramereth](https://github.com/ramereth))
- Update our bcrypt_pbkdf dep to allow the final 1.1.0 release [#11131](https://github.com/chef/chef/pull/11131) ([tas50](https://github.com/tas50))
- Removes install-as-service option which is not supported [#11137](https://github.com/chef/chef/pull/11137) ([marcparadise](https://github.com/marcparadise))
- Move idempotency logs to debug [#11149](https://github.com/chef/chef/pull/11149) ([jaymzh](https://github.com/jaymzh))
- Build place for documenting internal/dev/unsupported commands [#11148](https://github.com/chef/chef/pull/11148) ([jaymzh](https://github.com/jaymzh))
- Resolve Test Kitchen failures on Oracle 8 [#11140](https://github.com/chef/chef/pull/11140) ([tas50](https://github.com/tas50))
- Update FFI to 1.15.0 [#11151](https://github.com/chef/chef/pull/11151) ([tas50](https://github.com/tas50))
- Pin win32-certstore to 0.5.x until we resolve failures [#11153](https://github.com/chef/chef/pull/11153) ([tas50](https://github.com/tas50))
- Add effortless? helper to chef-utils [#11150](https://github.com/chef/chef/pull/11150) ([tas50](https://github.com/tas50))
- Use full path for launchctl calls [#11154](https://github.com/chef/chef/pull/11154) ([krackajak](https://github.com/krackajak))
- Bump Ohai and chefstyle tot the latest [#11156](https://github.com/chef/chef/pull/11156) ([tas50](https://github.com/tas50))
- Remove installing htop in test [#11157](https://github.com/chef/chef/pull/11157) ([tas50](https://github.com/tas50))
- Bump omnibus-software from `a7ed951` to `daeb384` in /omnibus [#11167](https://github.com/chef/chef/pull/11167) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Make the /etc/chef directory as part of the install [#11158](https://github.com/chef/chef/pull/11158) ([tas50](https://github.com/tas50))
- only run file verifiers when the contents changed [#11171](https://github.com/chef/chef/pull/11171) ([joshuamiller01](https://github.com/joshuamiller01))
- Create client.rb in postinst with 640 perms not 644 [#11168](https://github.com/chef/chef/pull/11168) ([tas50](https://github.com/tas50))
- M1 Mac arm builds [#11138](https://github.com/chef/chef/pull/11138) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump omnibus from `4a3c044` to `dd57896` in /omnibus [#11177](https://github.com/chef/chef/pull/11177) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Bump mixlib-authentication to 3.0.10 and ohai to 17.0.29 [#11183](https://github.com/chef/chef/pull/11183) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Bump chef/ohai to 771a034fdc9c9860d8c8d5d289615056ea74e8f6 [#11185](https://github.com/chef/chef/pull/11185) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Bump train-core to 3.5.4 [#11186](https://github.com/chef/chef/pull/11186) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Fix users_manage usage in kitchen-tests [#11181](https://github.com/chef/chef/pull/11181) ([ramereth](https://github.com/ramereth))
- Bump omnibus-software from `daeb384` to `f903311` in /omnibus [#11191](https://github.com/chef/chef/pull/11191) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Disable compliance phase by default [#11195](https://github.com/chef/chef/pull/11195) ([tas50](https://github.com/tas50))
- Fix compliance phase specs [#11198](https://github.com/chef/chef/pull/11198) ([tas50](https://github.com/tas50))
- Add release notes for Chef Infra Client 16.11 [#11200](https://github.com/chef/chef/pull/11200) ([tas50](https://github.com/tas50))
- Add login option to execute resource [#11201](https://github.com/chef/chef/pull/11201) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix Azure to trigger correctly on PRs [#11202](https://github.com/chef/chef/pull/11202) ([tas50](https://github.com/tas50))
- Ruby 3.0 fixes and post-bundle-install hook  [#10922](https://github.com/chef/chef/pull/10922) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump ohai from 16.10.6 to 16.10.7 in /omnibus [#11205](https://github.com/chef/chef/pull/11205) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Fix the ruby-3 omnibus builds/tests [#11209](https://github.com/chef/chef/pull/11209) ([lamont-granquist](https://github.com/lamont-granquist))
- Drop off a sample client.rb config on *nix [#11173](https://github.com/chef/chef/pull/11173) ([tas50](https://github.com/tas50))
- Fix ruby-prof loading issues [#11222](https://github.com/chef/chef/pull/11222) ([lamont-granquist](https://github.com/lamont-granquist))
- Update openssl to 1.1.1j and libarchive to 3.5.1 [#11223](https://github.com/chef/chef/pull/11223) ([tas50](https://github.com/tas50))
- Bump train-core to 3.5.5 [#11225](https://github.com/chef/chef/pull/11225) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Bump omnibus-software from `1769ef2` to `ed85910` in /omnibus [#11228](https://github.com/chef/chef/pull/11228) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Bump omnibus-software from `ed85910` to `f6aa2ed` in /omnibus [#11230](https://github.com/chef/chef/pull/11230) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Use method_missing for data bag item delegation [#11234](https://github.com/chef/chef/pull/11234) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump test-kitchen from 2.11.1 to 2.11.2 in /omnibus [#11238](https://github.com/chef/chef/pull/11238) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Bump inspec-core-bin to 4.29.3 [#11246](https://github.com/chef/chef/pull/11246) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Fix windows_user password idempotency [#11233](https://github.com/chef/chef/pull/11233) ([jaymzh](https://github.com/jaymzh))
- bump powershell shim to 0.3.2 with powershell 7.1.3 deps [#11262](https://github.com/chef/chef/pull/11262) ([mwrock](https://github.com/mwrock))
- Fix idempotency issues with network mounts [#11261](https://github.com/chef/chef/pull/11261) ([ramereth](https://github.com/ramereth))
- Bump omnibus-software from `caf6ae0` to `a0e7438` in /omnibus [#11270](https://github.com/chef/chef/pull/11270) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Convert knife to its own gem [#11180](https://github.com/chef/chef/pull/11180) ([marcparadise](https://github.com/marcparadise))
- Remove more redundant begins detected by rubocop [#11220](https://github.com/chef/chef/pull/11220) ([tas50](https://github.com/tas50))
- Bump cheffish to 16.0.26 [#11276](https://github.com/chef/chef/pull/11276) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Bump chef/ohai to 2fc35fbcbcfe7e2f3dad8f425d8307a6f216d011 [#11283](https://github.com/chef/chef/pull/11283) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Skip the cron tests on macOS 11+ [#11291](https://github.com/chef/chef/pull/11291) ([tas50](https://github.com/tas50))
- Report compliance runner not enabled if the node is not available [#11290](https://github.com/chef/chef/pull/11290) ([marcparadise](https://github.com/marcparadise))
- Update openSSL on macOS to 1.1.1k [#11295](https://github.com/chef/chef/pull/11295) ([tas50](https://github.com/tas50))
- Fix the cron skip on macOS logic [#11297](https://github.com/chef/chef/pull/11297) ([tas50](https://github.com/tas50))
- Added new property fqdn and made sure hosts entry includes the same [#11273](https://github.com/chef/chef/pull/11273) ([msys-sgarg](https://github.com/msys-sgarg))
- Bump chef/ohai to 426f5852142dd9b0fa36057c838db56bc36ed8f1 [#11304](https://github.com/chef/chef/pull/11304) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Bump omnibus-software from `76b31d1` to `f745eed` in /omnibus [#11302](https://github.com/chef/chef/pull/11302) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Bump omnibus-software from `f745eed` to `3d331d8` in /omnibus [#11310](https://github.com/chef/chef/pull/11310) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Bump chef/ohai to 4aa4f09fdddbe5ecf212ce16c06cd1d105650298 [#11312](https://github.com/chef/chef/pull/11312) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Bump omnibus-software from `3d331d8` to `ef7b496` in /omnibus [#11318](https://github.com/chef/chef/pull/11318) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Bump train-core to 3.6.0 [#11319](https://github.com/chef/chef/pull/11319) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Bump omnibus-software from `ef7b496` to `56f6321` in /omnibus [#11323](https://github.com/chef/chef/pull/11323) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Bump fauxhai-ng to 9.0.0 and InSpec to 4.31 [#11325](https://github.com/chef/chef/pull/11325) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- fix powershell exec segfaults on DSC_Resource [#11330](https://github.com/chef/chef/pull/11330) ([mwrock](https://github.com/mwrock))
- Fix failing Fauxhai related specs [#11329](https://github.com/chef/chef/pull/11329) ([tas50](https://github.com/tas50))
- Add centos_stream_platform? helper [#11296](https://github.com/chef/chef/pull/11296) ([ramereth](https://github.com/ramereth))
- Ruby-3.0 builds [#11336](https://github.com/chef/chef/pull/11336) ([lamont-granquist](https://github.com/lamont-granquist))
- Produce FIPS builds on Ubuntu as well [#11339](https://github.com/chef/chef/pull/11339) ([tas50](https://github.com/tas50))
- Knife user create to work with only username and options --email and … [#11224](https://github.com/chef/chef/pull/11224) ([msys-sgarg](https://github.com/msys-sgarg))
- Use dist constants in rubygems provider for is_omnibus? method [#11326](https://github.com/chef/chef/pull/11326) ([ramereth](https://github.com/ramereth))
- Bump inspec to 4.31.1 and ohai to 17.0.34 [#11353](https://github.com/chef/chef/pull/11353) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Allow FIPS 140-2 OpenSSL FOM to build on PPC EL platforms [#11358](https://github.com/chef/chef/pull/11358) ([btm](https://github.com/btm))
- Use new_resource for load_current_value blocks [#11368](https://github.com/chef/chef/pull/11368) ([jasonwbarnett](https://github.com/jasonwbarnett))
- Move some testing to GitHub Actions [#11364](https://github.com/chef/chef/pull/11364) ([tas50](https://github.com/tas50))
- Test running spellcheck in Github Actions [#11373](https://github.com/chef/chef/pull/11373) ([tas50](https://github.com/tas50))
- Add problem matchers for our Chefstyle run in GH [#11374](https://github.com/chef/chef/pull/11374) ([tas50](https://github.com/tas50))
- Bump chef/ohai to db08809916c84e74ec914bab3d313ec9dfc10195 [#11379](https://github.com/chef/chef/pull/11379) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Bump tty-prompt to 0.23.1 [#11389](https://github.com/chef/chef/pull/11389) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Bump chef/chefstyle to 2c32688dc259423c328ccc2cf6b9f3b1bb3cb0a5 [#11391](https://github.com/chef/chef/pull/11391) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Bump chef/ohai to 44f23f01752a95b3b93b710f9510806b781f8635 [#11392](https://github.com/chef/chef/pull/11392) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Bump omnibus-software from `0dcaeb1` to `810a6c4` in /omnibus [#11396](https://github.com/chef/chef/pull/11396) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Update tests to handle local omnibus packages from Buildkite artifacts api [#11382](https://github.com/chef/chef/pull/11382) ([nkierpiec](https://github.com/nkierpiec))
- Bump chef/ohai to 2a0da607d2d80c74adb9798c3bae1d2702ba05fd [#11399](https://github.com/chef/chef/pull/11399) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Update the download URL for windows msi [#11400](https://github.com/chef/chef/pull/11400) ([marcparadise](https://github.com/marcparadise))
- Move most compliance validation to pre-run [#11377](https://github.com/chef/chef/pull/11377) ([marcparadise](https://github.com/marcparadise))
- Revert &quot;Bump omnibus-software from `0dcaeb1` to `810a6c4` in /omnibus&quot; [#11403](https://github.com/chef/chef/pull/11403) ([nikhil2611](https://github.com/nikhil2611))
- Bump inspec-core-bin to 4.33.1 [#11413](https://github.com/chef/chef/pull/11413) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Bump omnibus from `dd57896` to `79c80e0` in /omnibus [#11410](https://github.com/chef/chef/pull/11410) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
- Bump omnibus-software from `0dcaeb1` to `3ac1dbe` in /omnibus [#11408](https://github.com/chef/chef/pull/11408) ([dependabot-preview[bot]](https://github.com/dependabot-preview[bot]))
-  Replace the ChefFS parallelizer with parallel_map helper [#11397](https://github.com/chef/chef/pull/11397) ([lamont-granquist](https://github.com/lamont-granquist))
- Lock cheffish to 17 [#11420](https://github.com/chef/chef/pull/11420) ([lamont-granquist](https://github.com/lamont-granquist))
- Produce packages for FreeBSD 13 [#11424](https://github.com/chef/chef/pull/11424) ([tas50](https://github.com/tas50))
- fix uninitialized Win32 constant [#11430](https://github.com/chef/chef/pull/11430) ([mwrock](https://github.com/mwrock))
- Compliance Phase preflight validation updates [#11404](https://github.com/chef/chef/pull/11404) ([marcparadise](https://github.com/marcparadise))
- Disable FreeBSD builds for now [#11435](https://github.com/chef/chef/pull/11435) ([tas50](https://github.com/tas50))
- Add macos unit testing with GitHub actions [#11422](https://github.com/chef/chef/pull/11422) ([tas50](https://github.com/tas50))
- Bump chef/ohai to cfeba80b1f2c8d0cb520b2c80e459325c5cf41a9 [#11436](https://github.com/chef/chef/pull/11436) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Update the habitat plan for Linux to Ruby 3 [#11437](https://github.com/chef/chef/pull/11437) ([tas50](https://github.com/tas50))
- Add Test Kitchen tests in GitHub Actions for Windows [#11438](https://github.com/chef/chef/pull/11438) ([tas50](https://github.com/tas50))
- Move macOS Test Kitchen tests to GitHub Actions [#11439](https://github.com/chef/chef/pull/11439) ([tas50](https://github.com/tas50))
- Make json-file compliance report path  visible [#11442](https://github.com/chef/chef/pull/11442) ([marcparadise](https://github.com/marcparadise))
- windows_certificate: properly add/remove pfx and private keys, change… [#11405](https://github.com/chef/chef/pull/11405) ([johnmccrae](https://github.com/johnmccrae))
- Add start/end of compliance phase logging [#11443](https://github.com/chef/chef/pull/11443) ([marcparadise](https://github.com/marcparadise))
- Disable Dnf tests for fedora [#11444](https://github.com/chef/chef/pull/11444) ([marcparadise](https://github.com/marcparadise))
- Add back the windows deps [#11449](https://github.com/chef/chef/pull/11449) ([tas50](https://github.com/tas50))
- Cache all our gems during spec runs [#11450](https://github.com/chef/chef/pull/11450) ([tas50](https://github.com/tas50))
- Improve the auto generated docs [#11448](https://github.com/chef/chef/pull/11448) ([tas50](https://github.com/tas50))
- updating Gemfile to support environment variables [#11452](https://github.com/chef/chef/pull/11452) ([jayashrig158](https://github.com/jayashrig158))
- Update omnibus gemfile.lock [#11454](https://github.com/chef/chef/pull/11454) ([tas50](https://github.com/tas50))
- Bump chef/ohai to e2dd316c2380bd2a06c8bf928357169e089a401e [#11455](https://github.com/chef/chef/pull/11455) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Add warning for resources not running in unified_mode [#11453](https://github.com/chef/chef/pull/11453) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump ohai to 17.0.42 [#11459](https://github.com/chef/chef/pull/11459) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Update the Effortless package for Windows to Ruby 3 [#11456](https://github.com/chef/chef/pull/11456) ([tas50](https://github.com/tas50))
- Disable the ohai time test so we can ship 17.0 [#11460](https://github.com/chef/chef/pull/11460) ([tas50](https://github.com/tas50))

## [v16.8.14](https://github.com/chef/chef/tree/v16.8.14) (2020-12-12)

#### Merged Pull Requests
- Bump libarchive to 3.5.0 [#10730](https://github.com/chef/chef/pull/10730) ([tas50](https://github.com/tas50))
- Update openSSL to 1.0.2x [#10732](https://github.com/chef/chef/pull/10732) ([tas50](https://github.com/tas50))
- Update libiconv to 1.16 [#10731](https://github.com/chef/chef/pull/10731) ([tas50](https://github.com/tas50))
- Raise error and retry with PTY on sudo password prompt [#10728](https://github.com/chef/chef/pull/10728) ([rveznaver](https://github.com/rveznaver))
- Fix broken code in compliance runner&#39;s send_report. [#10733](https://github.com/chef/chef/pull/10733) ([phiggins](https://github.com/phiggins))

## [v16.8.9](https://github.com/chef/chef/tree/v16.8.9) (2020-12-11)

#### Merged Pull Requests
- Resolve new spacing offenses in RuboCop 1.4 [#10691](https://github.com/chef/chef/pull/10691) ([tas50](https://github.com/tas50))
- Use URI::DEFAULT_PARSER.make_regexp instead of URI.regexp [#10674](https://github.com/chef/chef/pull/10674) ([tas50](https://github.com/tas50))
- Update the Docker file to use the RHEL 7 package [#10700](https://github.com/chef/chef/pull/10700) ([tas50](https://github.com/tas50))
- replace usages of Cmdlet class with powershell_exec [#10683](https://github.com/chef/chef/pull/10683) ([mwrock](https://github.com/mwrock))
- Enable git cache to speed up builds [#10689](https://github.com/chef/chef/pull/10689) ([tas50](https://github.com/tas50))
- Add back macOS builds to the omnibus pipeline [#10701](https://github.com/chef/chef/pull/10701) ([tas50](https://github.com/tas50))
- Update changelog with missing updates from previous prs [#10703](https://github.com/chef/chef/pull/10703) ([nkierpiec](https://github.com/nkierpiec))
- Pin our InSpec version and use Chefstyle from rubygems for now [#10702](https://github.com/chef/chef/pull/10702) ([tas50](https://github.com/tas50))
- Allow remote_file consider certificates stored under /etc/chef/trusted_certs [#10704](https://github.com/chef/chef/pull/10704) ([kapilchouhan99](https://github.com/kapilchouhan99))
- Add new Compliance Phase replicating the functionality previously in the audit cookbook [#10547](https://github.com/chef/chef/pull/10547) ([phiggins](https://github.com/phiggins))
- only test dsc_script on 64 bit and document that it will fail on 32 bit clients [#10708](https://github.com/chef/chef/pull/10708) ([mwrock](https://github.com/mwrock))
- Switch back to chefstyle from github [#10709](https://github.com/chef/chef/pull/10709) ([tas50](https://github.com/tas50))
- only run dsc_script functional tests on 64 bit ruby [#10710](https://github.com/chef/chef/pull/10710) ([mwrock](https://github.com/mwrock))
- Update license-acceptance gem to 2.1.13 [#10714](https://github.com/chef/chef/pull/10714) ([tas50](https://github.com/tas50))
- Update Train to 3.4.1 [#10716](https://github.com/chef/chef/pull/10716) ([tas50](https://github.com/tas50))
- only run systemd unit tests on linux [#10718](https://github.com/chef/chef/pull/10718) ([mwrock](https://github.com/mwrock))
- Fix for deprecation warning in knife ssh [#10717](https://github.com/chef/chef/pull/10717) ([kapilchouhan99](https://github.com/kapilchouhan99))
- windows_certificate: Add exportable option to pfx certificate [#10711](https://github.com/chef/chef/pull/10711) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Update all deps to the latest [#10720](https://github.com/chef/chef/pull/10720) ([tas50](https://github.com/tas50))
- Fix failing tests on Solaris / Enable Solaris builds again [#10719](https://github.com/chef/chef/pull/10719) ([mwrock](https://github.com/mwrock))
- hostname: Avoid erroring out when hostname is not set on mac [#10724](https://github.com/chef/chef/pull/10724) ([lamont-granquist](https://github.com/lamont-granquist))
- Update to InSpec 4.24 [#10726](https://github.com/chef/chef/pull/10726) ([tas50](https://github.com/tas50))

## [v16.7.61](https://github.com/chef/chef/tree/v16.7.61) (2020-11-26)

#### Merged Pull Requests
- Minor updates for documentation generation [#10505](https://github.com/chef/chef/pull/10505) ([tas50](https://github.com/tas50))
- Update powershell_script description to match docs site. [#10508](https://github.com/chef/chef/pull/10508) ([phiggins](https://github.com/phiggins))
- More resource documentation improvement [#10509](https://github.com/chef/chef/pull/10509) ([tas50](https://github.com/tas50))
- Resource documentation updates from review [#10510](https://github.com/chef/chef/pull/10510) ([tas50](https://github.com/tas50))
- Avoid declaring arrays in loops [#10513](https://github.com/chef/chef/pull/10513) ([tas50](https://github.com/tas50))
- Update docs generation task to handle Chef 16 required format [#10518](https://github.com/chef/chef/pull/10518) ([tas50](https://github.com/tas50))
- Avoid a slow hash merge [#10517](https://github.com/chef/chef/pull/10517) ([tas50](https://github.com/tas50))
- Avoid using complex regexes when we can use include? [#10516](https://github.com/chef/chef/pull/10516) ([tas50](https://github.com/tas50))
- Fix bad formatting in a deprecation message [#10521](https://github.com/chef/chef/pull/10521) ([tas50](https://github.com/tas50))
- Remove constantize method from Chef::Mixin::ConvertToClassName [#10522](https://github.com/chef/chef/pull/10522) ([tas50](https://github.com/tas50))
- Add required_ruby_version to chef-utils and chef-config [#10525](https://github.com/chef/chef/pull/10525) ([tas50](https://github.com/tas50))
- Added functional test for windows_package with remote_file_attributes. [#10526](https://github.com/chef/chef/pull/10526) ([antima-gupta](https://github.com/antima-gupta))
- Simplify the ifconfig provides statement on Ubuntu/Debian [#10528](https://github.com/chef/chef/pull/10528) ([tas50](https://github.com/tas50))
- Refactor ResourceGuardInterpreter [#10494](https://github.com/chef/chef/pull/10494) ([phiggins](https://github.com/phiggins))
- Move the alias for attribute to property right into the property mixin [#10520](https://github.com/chef/chef/pull/10520) ([tas50](https://github.com/tas50))
- Add bridge property to ifconfig for RHEL based systems [#10529](https://github.com/chef/chef/pull/10529) ([tas50](https://github.com/tas50))
- Test ifconfig in Test Kitchen and add examples to the resource [#10530](https://github.com/chef/chef/pull/10530) ([tas50](https://github.com/tas50))
- Use a native resource in the ifconfig debian provider [#10533](https://github.com/chef/chef/pull/10533) ([tas50](https://github.com/tas50))
- Update train-core &amp; pull in the faster MSI installs [#10534](https://github.com/chef/chef/pull/10534) ([tas50](https://github.com/tas50))
- Fix LWRP build cache [#10536](https://github.com/chef/chef/pull/10536) ([tecracer-theinen](https://github.com/tecracer-theinen))
- Minor gem cleanup for chef-bin/chef-utils/chef-config [#10539](https://github.com/chef/chef/pull/10539) ([tas50](https://github.com/tas50))
- Remove the announcement rake task + minor task updates [#10540](https://github.com/chef/chef/pull/10540) ([tas50](https://github.com/tas50))
- Remove the yard doc generation task / group [#10541](https://github.com/chef/chef/pull/10541) ([tas50](https://github.com/tas50))
- Bump Ohai to 16.7 and cacerts to the latest [#10542](https://github.com/chef/chef/pull/10542) ([tas50](https://github.com/tas50))
- ensure powershell_package commands are run with tls 1.2 [#10543](https://github.com/chef/chef/pull/10543) ([mwrock](https://github.com/mwrock))
- Remove coderay and ffi-yajl-bench binstubs [#10544](https://github.com/chef/chef/pull/10544) ([tas50](https://github.com/tas50))
- Remove unused monkeypatch on net/http. [#10548](https://github.com/chef/chef/pull/10548) ([phiggins](https://github.com/phiggins))
- Remove an empty before block in a spec [#10550](https://github.com/chef/chef/pull/10550) ([tas50](https://github.com/tas50))
- Remove references to monkeypatch method. [#10551](https://github.com/chef/chef/pull/10551) ([phiggins](https://github.com/phiggins))
- Add Test Kitchen testing on Ubuntu 20.10 [#10553](https://github.com/chef/chef/pull/10553) ([tas50](https://github.com/tas50))
- ifconfig is not compatible with Fedora 33 or later [#10555](https://github.com/chef/chef/pull/10555) ([tas50](https://github.com/tas50))
- Add back Oracle 8 Test Kitchen testing [#10554](https://github.com/chef/chef/pull/10554) ([tas50](https://github.com/tas50))
- Final batch of unified_mode providers [#10557](https://github.com/chef/chef/pull/10557) ([lamont-granquist](https://github.com/lamont-granquist))
- Update InSpec to 4.23.15 [#10559](https://github.com/chef/chef/pull/10559) ([tas50](https://github.com/tas50))
- Merge repetitive conditionals [#10558](https://github.com/chef/chef/pull/10558) ([tas50](https://github.com/tas50))
- Mount resources not idempotent with label fixes [#10566](https://github.com/chef/chef/pull/10566) ([antima-gupta](https://github.com/antima-gupta))
- Simplify a weird conditional in chef-config [#10560](https://github.com/chef/chef/pull/10560) ([tas50](https://github.com/tas50))
- Improve the package docs generation + resolve rubocop warnings [#10567](https://github.com/chef/chef/pull/10567) ([tas50](https://github.com/tas50))
- Correctly generate docs yaml files to include package warnings [#10569](https://github.com/chef/chef/pull/10569) ([tas50](https://github.com/tas50))
- Improve resource documentation [#10570](https://github.com/chef/chef/pull/10570) ([tas50](https://github.com/tas50))
- Fix some spelling / cookstyle errors in the git examples [#10575](https://github.com/chef/chef/pull/10575) ([tas50](https://github.com/tas50))
- Remove support for nexentacore and opensolaris which are both a decade EOL [#10573](https://github.com/chef/chef/pull/10573) ([tas50](https://github.com/tas50))
- Remove rspec_junit_formatter and rspec version pins [#10579](https://github.com/chef/chef/pull/10579) ([phiggins](https://github.com/phiggins))
- Don&#39;t run rspec with documentation formatter. [#10578](https://github.com/chef/chef/pull/10578) ([phiggins](https://github.com/phiggins))
- Update Ohai to 16.7.4 and win32-process to 0.9.0 [#10580](https://github.com/chef/chef/pull/10580) ([tas50](https://github.com/tas50))
- Fix secret options in windows bootstrap [#10577](https://github.com/chef/chef/pull/10577) ([mwrock](https://github.com/mwrock))
- Remove the provider_resolver specs that are not helpful [#10576](https://github.com/chef/chef/pull/10576) ([tas50](https://github.com/tas50))
- Remove a few more files from our install artifact [#10581](https://github.com/chef/chef/pull/10581) ([tas50](https://github.com/tas50))
- Remove the provides :package for solaris_package [#10572](https://github.com/chef/chef/pull/10572) ([tas50](https://github.com/tas50))
- Fix download errors during knife bootstrap on windows due to lack of TLS 1.2 support [#10574](https://github.com/chef/chef/pull/10574) ([TimothyTitan](https://github.com/TimothyTitan))
- Avoid a splat operator where we don&#39;t need one [#10583](https://github.com/chef/chef/pull/10583) ([tas50](https://github.com/tas50))
- Simplify regexes by removing extra character classes [#10584](https://github.com/chef/chef/pull/10584) ([tas50](https://github.com/tas50))
- Improve Windows resource performance by converting powershell_out usage to powershell_exec [#10545](https://github.com/chef/chef/pull/10545) ([mwrock](https://github.com/mwrock))
- Update ohai to 16.7.9 and rspec to 3.10 [#10587](https://github.com/chef/chef/pull/10587) ([tas50](https://github.com/tas50))
- Fix homebrew_update [#10586](https://github.com/chef/chef/pull/10586) ([phiggins](https://github.com/phiggins))
- Freeze strings in chef-utils [#10590](https://github.com/chef/chef/pull/10590) ([tas50](https://github.com/tas50))
- Namespace ResourceInspector to avoid conflicts with Inspec&#39;s [#10595](https://github.com/chef/chef/pull/10595) ([phiggins](https://github.com/phiggins))
- Improve auto generated resource docs [#10596](https://github.com/chef/chef/pull/10596) ([tas50](https://github.com/tas50))
- Use tr where we don&#39;t need gsub and a regex [#10597](https://github.com/chef/chef/pull/10597) ([tas50](https://github.com/tas50))
- Remove duplicate Gemfile gems + update ohai to 16.7.13 [#10602](https://github.com/chef/chef/pull/10602) ([tas50](https://github.com/tas50))
- Use .compact instead of .select/.reject to remove nils [#10601](https://github.com/chef/chef/pull/10601) ([tas50](https://github.com/tas50))
- Update to the new chefstyle [#10603](https://github.com/chef/chef/pull/10603) ([tas50](https://github.com/tas50))
- Collapse several duplicate branches down [#10604](https://github.com/chef/chef/pull/10604) ([tas50](https://github.com/tas50))
- Collapse more duplicate branches [#10605](https://github.com/chef/chef/pull/10605) ([tas50](https://github.com/tas50))
- Use ||= where we can [#10609](https://github.com/chef/chef/pull/10609) ([tas50](https://github.com/tas50))
- Don&#39;t uses regexes in splits when we don&#39;t need to [#10610](https://github.com/chef/chef/pull/10610) ([tas50](https://github.com/tas50))
- Added deprecation warning for enforce_path_sanity [#10613](https://github.com/chef/chef/pull/10613) ([kapilchouhan99](https://github.com/kapilchouhan99))
- Cleanup Chef::JSONCompat [#10612](https://github.com/chef/chef/pull/10612) ([phiggins](https://github.com/phiggins))
- chef_client_config: Resolve invalid configuration in client.rb [#10608](https://github.com/chef/chef/pull/10608) ([srb3](https://github.com/srb3))
- Update Ohai to 16.7.18 and Fauxhai to 8.4 [#10619](https://github.com/chef/chef/pull/10619) ([tas50](https://github.com/tas50))
- Update the yaml we generate for resource documentation [#10622](https://github.com/chef/chef/pull/10622) ([tas50](https://github.com/tas50))
- mount: Fixes for findmount output causing idempotency issues [#10614](https://github.com/chef/chef/pull/10614) ([antima-gupta](https://github.com/antima-gupta))
- Add additional property coerce specs to mount [#10625](https://github.com/chef/chef/pull/10625) ([tas50](https://github.com/tas50))
- provide a registry_key example that creates a multibyte binary value [#10630](https://github.com/chef/chef/pull/10630) ([mwrock](https://github.com/mwrock))
- Fix ps specs [#10633](https://github.com/chef/chef/pull/10633) ([mwrock](https://github.com/mwrock))
- Prevent failures generating docs [#10634](https://github.com/chef/chef/pull/10634) ([tas50](https://github.com/tas50))
- Change how zypper_package calculates the candidate_version [#10631](https://github.com/chef/chef/pull/10631) ([lamont-granquist](https://github.com/lamont-granquist))
- knife bootstrap deps require net/ssh [#10638](https://github.com/chef/chef/pull/10638) ([vsingh-msys](https://github.com/vsingh-msys))
- Update omnibus to remove the chef-sugar dep [#10629](https://github.com/chef/chef/pull/10629) ([tas50](https://github.com/tas50))
- mount: changes to fix solaris test failure [#10643](https://github.com/chef/chef/pull/10643) ([antima-gupta](https://github.com/antima-gupta))
- Fix group output and windows support [#10642](https://github.com/chef/chef/pull/10642) ([jaymzh](https://github.com/jaymzh))
- pull in v0.2.1 of powershell shim that fixes .net resolver [#10644](https://github.com/chef/chef/pull/10644) ([mwrock](https://github.com/mwrock))
- Fix zypper_package CI failures [#10648](https://github.com/chef/chef/pull/10648) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix idempotency issues in build_essential on the mac [#10647](https://github.com/chef/chef/pull/10647) ([tas50](https://github.com/tas50))
- mount: Changes to fix creating multiple entries in fstab [#10472](https://github.com/chef/chef/pull/10472) ([antima-gupta](https://github.com/antima-gupta))
- Remove pry-remote from the package [#10651](https://github.com/chef/chef/pull/10651) ([tas50](https://github.com/tas50))
- Update fauxhai, chef-vault, and chefstyle to the latest [#10653](https://github.com/chef/chef/pull/10653) ([tas50](https://github.com/tas50))
- Update mixlib-shellout to 3.2.2 [#10654](https://github.com/chef/chef/pull/10654) ([tas50](https://github.com/tas50))
- update pwsh in powershell_exec to 7.1.0 and add comments explaining how to pull in updates [#10652](https://github.com/chef/chef/pull/10652) ([mwrock](https://github.com/mwrock))
- user: Log what changed when updating a user [#10656](https://github.com/chef/chef/pull/10656) ([jaymzh](https://github.com/jaymzh))
- Update the docs generation for the new format [#10659](https://github.com/chef/chef/pull/10659) ([tas50](https://github.com/tas50))
- include password in guard inherited attributes [#10672](https://github.com/chef/chef/pull/10672) ([mwrock](https://github.com/mwrock))
- Update ohai and win32-service to the latest [#10673](https://github.com/chef/chef/pull/10673) ([tas50](https://github.com/tas50))
- Avoid ambiguous regexes [#10675](https://github.com/chef/chef/pull/10675) ([tas50](https://github.com/tas50))
- Mount: Fixes for Mount resource changes broke specs on AIX [#10671](https://github.com/chef/chef/pull/10671) ([antima-gupta](https://github.com/antima-gupta))
- bump ohai, win32-service, and omnibus deps [#10685](https://github.com/chef/chef/pull/10685) ([tas50](https://github.com/tas50))
- Update Ohai to 16.7.37 [#10686](https://github.com/chef/chef/pull/10686) ([tas50](https://github.com/tas50))
- Skip appx packaging on Windows [#10650](https://github.com/chef/chef/pull/10650) ([tas50](https://github.com/tas50))
- Bump omnibus / omnibus-software to the latest [#10690](https://github.com/chef/chef/pull/10690) ([tas50](https://github.com/tas50))
- Resolve NameError running mac_user resource [#10692](https://github.com/chef/chef/pull/10692) ([tas50](https://github.com/tas50))

## [v16.6.14](https://github.com/chef/chef/tree/v16.6.14) (2020-10-14)

#### Merged Pull Requests
- Pull in Ohai 16.6 and train-core/train-winrm updates [#10474](https://github.com/chef/chef/pull/10474) ([tas50](https://github.com/tas50))
- Update to the windows_audit_policy resource to fix a bug on failure-only auditing [#10473](https://github.com/chef/chef/pull/10473) ([chef-davin](https://github.com/chef-davin))
- add ruby-3.0 hash methods to immutabilize_hash [#10475](https://github.com/chef/chef/pull/10475) ([lamont-granquist](https://github.com/lamont-granquist))
- add interpreter arg to powershell_out allowing it to call pwsh.exe [#10478](https://github.com/chef/chef/pull/10478) ([mwrock](https://github.com/mwrock))
- Update to Ruby 2.7.2 / Rubygems 3.1.4 [#10480](https://github.com/chef/chef/pull/10480) ([tas50](https://github.com/tas50))
- Remove extra safe navigation [#10482](https://github.com/chef/chef/pull/10482) ([tas50](https://github.com/tas50))
- add interpreter arg to powershell_exec allowing it to run powershell core [#10476](https://github.com/chef/chef/pull/10476) ([mwrock](https://github.com/mwrock))
- fix specs on powershell v4 and below [#10484](https://github.com/chef/chef/pull/10484) ([mwrock](https://github.com/mwrock))
- Update Ohai to 16.6.1 [#10486](https://github.com/chef/chef/pull/10486) ([tas50](https://github.com/tas50))
- add interpreter to handle pwsh and powershell to powershell_script [#10488](https://github.com/chef/chef/pull/10488) ([mwrock](https://github.com/mwrock))
- Changing ifconfig provider to reduce blank lines in redhat and debian ifconfigs [#10489](https://github.com/chef/chef/pull/10489) ([jmherbst](https://github.com/jmherbst))
- Bump Chefstyle &amp; other deps [#10498](https://github.com/chef/chef/pull/10498) ([tas50](https://github.com/tas50))
- provide powershell_exec functionality on x86 [#10495](https://github.com/chef/chef/pull/10495) ([mwrock](https://github.com/mwrock))
- chef_client_config resource [#10365](https://github.com/chef/chef/pull/10365) ([tas50](https://github.com/tas50))
- Update examples and descriptions for better automated documentation [#10500](https://github.com/chef/chef/pull/10500) ([tas50](https://github.com/tas50))
- Update cacerts, ohai, and winrm to the latest [#10502](https://github.com/chef/chef/pull/10502) ([tas50](https://github.com/tas50))
- Support for ohai target mode [#10418](https://github.com/chef/chef/pull/10418) ([lamont-granquist](https://github.com/lamont-granquist))

## [v16.5.77](https://github.com/chef/chef/tree/v16.5.77) (2020-09-29)

#### Merged Pull Requests
- Add missing requires to chef/policy_builder/dynamic [#10446](https://github.com/chef/chef/pull/10446) ([tas50](https://github.com/tas50))
- Pull in the new tty-table to unlock new license-acceptance [#10450](https://github.com/chef/chef/pull/10450) ([tas50](https://github.com/tas50))
- Check for full names in Homebrew package info [#10360](https://github.com/chef/chef/pull/10360) ([ed-brex](https://github.com/ed-brex))
- Remove unused method [#10449](https://github.com/chef/chef/pull/10449) ([007lva](https://github.com/007lva))
- Fix examples markdown in chef_handler resource. [#10459](https://github.com/chef/chef/pull/10459) ([phiggins](https://github.com/phiggins))
- Simplify Hash transforms &amp; minor code refactoring [#10447](https://github.com/chef/chef/pull/10447) ([vsingh-msys](https://github.com/vsingh-msys))
- Update require gating to include chef-utils/chef-config &amp; gate more [#10451](https://github.com/chef/chef/pull/10451) ([tas50](https://github.com/tas50))
- Use ChefUtils::Dist::Infra::PRODUCT for locale warning instead of &quot;Chef&quot; [#10461](https://github.com/chef/chef/pull/10461) ([ramereth](https://github.com/ramereth))
- Preparing 16.5 hotfix patch to fix Workstation build issue [#10462](https://github.com/chef/chef/pull/10462) ([tyler-ball](https://github.com/tyler-ball))
- autoload addressable/uri on :URI inside addressable module [#10464](https://github.com/chef/chef/pull/10464) ([mwrock](https://github.com/mwrock))
- Remove unnecessary require. [#10465](https://github.com/chef/chef/pull/10465) ([phiggins](https://github.com/phiggins))
- Use Ruby 2.6 endless Range syntax [#10463](https://github.com/chef/chef/pull/10463) ([007lva](https://github.com/007lva))
- Bump dependencies to latest + resolve Chefstyle warning [#10468](https://github.com/chef/chef/pull/10468) ([tas50](https://github.com/tas50))

## [v16.5.64](https://github.com/chef/chef/tree/v16.5.64) (2020-09-17)

#### Merged Pull Requests
- Add new chef_client_trusted_certificate resource [#10331](https://github.com/chef/chef/pull/10331) ([tas50](https://github.com/tas50))
- Simplify macos detection in specs to include big sur [#10335](https://github.com/chef/chef/pull/10335) ([tas50](https://github.com/tas50))
- New exit code to signal chef-client exits due to configuration errors [#10302](https://github.com/chef/chef/pull/10302) ([NaomiReeves](https://github.com/NaomiReeves))
- Bump all deps to the latest for the require optimizations [#10337](https://github.com/chef/chef/pull/10337) ([tas50](https://github.com/tas50))
- fix chocolatey and x86 windows omnibus builds [#10339](https://github.com/chef/chef/pull/10339) ([mwrock](https://github.com/mwrock))
- Avoid knife ssh freeze on windows [#9482](https://github.com/chef/chef/pull/9482) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Start building S390x packages again [#10338](https://github.com/chef/chef/pull/10338) ([btm](https://github.com/btm))
- separate omnibus rspec path from options [#10343](https://github.com/chef/chef/pull/10343) ([mwrock](https://github.com/mwrock))
- Add macOS 11.0 (Big Sur) packages [#10332](https://github.com/chef/chef/pull/10332) ([tas50](https://github.com/tas50))
- make &#39;knife config&#39; options shorter/easier [#10346](https://github.com/chef/chef/pull/10346) ([vsingh-msys](https://github.com/vsingh-msys))
- knife config list-profiles UI with tty-table [#10341](https://github.com/chef/chef/pull/10341) ([vsingh-msys](https://github.com/vsingh-msys))
- Fix dll copying in Gemfile to remove Dir.pwd [#10325](https://github.com/chef/chef/pull/10325) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix some CI failures [#10347](https://github.com/chef/chef/pull/10347) ([phiggins](https://github.com/phiggins))
- Bump deps and resolve new Chefstyle warnings [#10349](https://github.com/chef/chef/pull/10349) ([tas50](https://github.com/tas50))
- Add initial take at chef_client_launchd [#10348](https://github.com/chef/chef/pull/10348) ([tas50](https://github.com/tas50))
- Fix habitat test script [#10350](https://github.com/chef/chef/pull/10350) ([phiggins](https://github.com/phiggins))
- Update Ohai to 16.4.13 [#10353](https://github.com/chef/chef/pull/10353) ([tas50](https://github.com/tas50))
- more config specs cleanup &amp; remove deprecated from knife config list [#10351](https://github.com/chef/chef/pull/10351) ([vsingh-msys](https://github.com/vsingh-msys))
- Validate nice values in the launchd resource [#10359](https://github.com/chef/chef/pull/10359) ([tas50](https://github.com/tas50))
- Add back nice functionality to chef_client_cron [#10358](https://github.com/chef/chef/pull/10358) ([tas50](https://github.com/tas50))
- Improve input handling and validation in chef_client_launchd [#10357](https://github.com/chef/chef/pull/10357) ([tas50](https://github.com/tas50))
- chef_client_launchd: reorder properties and fix log permissions [#10361](https://github.com/chef/chef/pull/10361) ([tas50](https://github.com/tas50))
- Update InSpec to 4.22.22 [#10363](https://github.com/chef/chef/pull/10363) ([tas50](https://github.com/tas50))
-  Fixed mount Resource for bind mounts is not idempotent. [#10171](https://github.com/chef/chef/pull/10171) ([antima-gupta](https://github.com/antima-gupta))
- More updates to the chef_client_* resources [#10362](https://github.com/chef/chef/pull/10362) ([tas50](https://github.com/tas50))
- Remove duplicate requires in the Provider class [#10369](https://github.com/chef/chef/pull/10369) ([tas50](https://github.com/tas50))
- chef_client_systemd_timer: Add the ability to set CPUQuota on the chef-client unit [#10381](https://github.com/chef/chef/pull/10381) ([tas50](https://github.com/tas50))
- Update all deps to current [#10385](https://github.com/chef/chef/pull/10385) ([tas50](https://github.com/tas50))
- Allow removing profiles in osx_profile on Big Sur [#10386](https://github.com/chef/chef/pull/10386) ([tas50](https://github.com/tas50))
- Fix nil deep_merging [#10382](https://github.com/chef/chef/pull/10382) ([lamont-granquist](https://github.com/lamont-granquist))
- Add a :reboot_delay property to the windows_ad_join resource [#10388](https://github.com/chef/chef/pull/10388) ([chef-davin](https://github.com/chef-davin))
- Add --logfile to chef-apply command [#10389](https://github.com/chef/chef/pull/10389) ([tas50](https://github.com/tas50))
- chef_client_launchd: create a launchd daemon to handle the client restart [#10390](https://github.com/chef/chef/pull/10390) ([tas50](https://github.com/tas50))
- Resolve RuboCop Style/RedundantInterpolation warnings [#10394](https://github.com/chef/chef/pull/10394) ([tas50](https://github.com/tas50))
- [data-collector] improved output_locations validation &amp; bug fixes [#10393](https://github.com/chef/chef/pull/10393) ([vsingh-msys](https://github.com/vsingh-msys))
- Improve cli boot performance by prefering autoload over requires [#10383](https://github.com/chef/chef/pull/10383) ([mwrock](https://github.com/mwrock))
- rhsm_register: Avoid potentially checking if we need to register twice [#10395](https://github.com/chef/chef/pull/10395) ([tas50](https://github.com/tas50))
- Use include? to example strings when we don&#39;t need a regex [#10396](https://github.com/chef/chef/pull/10396) ([tas50](https://github.com/tas50))
- Mock File.expand_path to fix window C:/ dir appended in absolute path [#10398](https://github.com/chef/chef/pull/10398) ([vsingh-msys](https://github.com/vsingh-msys))
- Update Ohai to 16.5 [#10399](https://github.com/chef/chef/pull/10399) ([tas50](https://github.com/tas50))
- Update openssl to 1.0.2w [#10402](https://github.com/chef/chef/pull/10402) ([tas50](https://github.com/tas50))
- Remove a redundant spec loop [#10370](https://github.com/chef/chef/pull/10370) ([tas50](https://github.com/tas50))
- Add Patents link to chef infra &amp; solo client [#10400](https://github.com/chef/chef/pull/10400) ([vsingh-msys](https://github.com/vsingh-msys))
- autoload license_acceptance/acceptor in knife loading [#10405](https://github.com/chef/chef/pull/10405) ([mwrock](https://github.com/mwrock))
- Enable s390x RHEL8 and SLES15 platforms [#10376](https://github.com/chef/chef/pull/10376) ([jaymalasinha](https://github.com/jaymalasinha))
- Allow for license-acceptance 2.0 gem [#10406](https://github.com/chef/chef/pull/10406) ([tas50](https://github.com/tas50))
- Allow cpu_quota values &gt; 100 [#10408](https://github.com/chef/chef/pull/10408) ([tas50](https://github.com/tas50))
- Use __dir__ instead of getting the dir of __FILE__ [#10401](https://github.com/chef/chef/pull/10401) ([tas50](https://github.com/tas50))
- Add an ohai timing test to find busted DNS on CI testers [#10371](https://github.com/chef/chef/pull/10371) ([lamont-granquist](https://github.com/lamont-granquist))
- Update the windows_firewall_profile resource to fix NoMethodError [#10412](https://github.com/chef/chef/pull/10412) ([chef-davin](https://github.com/chef-davin))
- Remove debug puts from snap_package [#10409](https://github.com/chef/chef/pull/10409) ([tas50](https://github.com/tas50))
- Add system_name property to rhsm_register resource [#10413](https://github.com/chef/chef/pull/10413) ([jasonwbarnett](https://github.com/jasonwbarnett))
- Update sysctl resource description to match reality [#10416](https://github.com/chef/chef/pull/10416) ([tas50](https://github.com/tas50))
- allow the use of SIDs in windows securable resources [#10423](https://github.com/chef/chef/pull/10423) ([mwrock](https://github.com/mwrock))
- Update the validation of the privilege property on the windows_user_privilege resource [#10422](https://github.com/chef/chef/pull/10422) ([tas50](https://github.com/tas50))
- Remove the Ubuntu azure pipeline test [#10434](https://github.com/chef/chef/pull/10434) ([tas50](https://github.com/tas50))
- Move dist implementation into chef-utils [#9834](https://github.com/chef/chef/pull/9834) ([bobchaos](https://github.com/bobchaos))
- Add examples to the ohai resource [#10432](https://github.com/chef/chef/pull/10432) ([tas50](https://github.com/tas50))
- Move TrainTransport to ChefConfig [#10436](https://github.com/chef/chef/pull/10436) ([lamont-granquist](https://github.com/lamont-granquist))
- More resource documentation improvements [#10435](https://github.com/chef/chef/pull/10435) ([tas50](https://github.com/tas50))
- Resolve Lint/RedundantRequireStatement &amp; Style/RedundantCondition warnings [#10437](https://github.com/chef/chef/pull/10437) ([tas50](https://github.com/tas50))
- Speed up a openssl helper specs [#10438](https://github.com/chef/chef/pull/10438) ([tas50](https://github.com/tas50))
- Resolve Style/RedundantSort warnings [#10439](https://github.com/chef/chef/pull/10439) ([tas50](https://github.com/tas50))
- Docs fixes from review [#10440](https://github.com/chef/chef/pull/10440) ([tas50](https://github.com/tas50))
- Update InSpec to the latest [#10443](https://github.com/chef/chef/pull/10443) ([tas50](https://github.com/tas50))
- Fix idempotency in the osx_profile resource and avoid writing data to disk [#10444](https://github.com/chef/chef/pull/10444) ([tas50](https://github.com/tas50))
- Update to the latest license_scout gem [#10445](https://github.com/chef/chef/pull/10445) ([tas50](https://github.com/tas50))

## [v16.4.41](https://github.com/chef/chef/tree/v16.4.41) (2020-08-19)

#### Merged Pull Requests
- Refactor the timezone resource to properly load the current timezone [#10323](https://github.com/chef/chef/pull/10323) ([tas50](https://github.com/tas50))
- Add missing requires for knife configure command [#10329](https://github.com/chef/chef/pull/10329) ([tas50](https://github.com/tas50))
- Update Ohai to 16.4.11 to resolve Windows IP detection [#10327](https://github.com/chef/chef/pull/10327) ([tas50](https://github.com/tas50))

## [v16.4.38](https://github.com/chef/chef/tree/v16.4.38) (2020-08-18)

#### Merged Pull Requests
- Fix typo and macOS version evaluation logic in `osx_profile` resource [#10319](https://github.com/chef/chef/pull/10319) ([ChefAustin](https://github.com/ChefAustin))
- Further improve osx_profile error message and add a test [#10320](https://github.com/chef/chef/pull/10320) ([tas50](https://github.com/tas50))
- Fix removing non-existent profile with osx_profile [#10324](https://github.com/chef/chef/pull/10324) ([lamont-granquist](https://github.com/lamont-granquist))

## [v16.4.35](https://github.com/chef/chef/tree/v16.4.35) (2020-08-18)

#### Merged Pull Requests
- Add dobi-powered Docker build pipelines [#10180](https://github.com/chef/chef/pull/10180) ([nkierpiec](https://github.com/nkierpiec))
- Introduce EXPEDITOR_VERSION for docker image tag [#10231](https://github.com/chef/chef/pull/10231) ([nkierpiec](https://github.com/nkierpiec))
- Fix warning in test for redefined shared example group [#10232](https://github.com/chef/chef/pull/10232) ([phiggins](https://github.com/phiggins))
- Update omnibus-software to slim our builds [#10234](https://github.com/chef/chef/pull/10234) ([tas50](https://github.com/tas50))
- Make sure darwin is always detected [#10235](https://github.com/chef/chef/pull/10235) ([tas50](https://github.com/tas50))
- Compensate for libyaml changes in yaml parsing test. [#10220](https://github.com/chef/chef/pull/10220) ([phiggins](https://github.com/phiggins))
- Bump omnibus-software to the latest [#10236](https://github.com/chef/chef/pull/10236) ([tas50](https://github.com/tas50))
- Fix install windows features when install state is removed [#9820](https://github.com/chef/chef/pull/9820) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Update libffi to 3.3 [#10238](https://github.com/chef/chef/pull/10238) ([tas50](https://github.com/tas50))
- Remove debug code from libxml2 [#10241](https://github.com/chef/chef/pull/10241) ([tas50](https://github.com/tas50))
- Cleanup more files from our package&#39;s gem installs [#10242](https://github.com/chef/chef/pull/10242) ([tas50](https://github.com/tas50))
- Further slim down libxml2 [#10244](https://github.com/chef/chef/pull/10244) ([tas50](https://github.com/tas50))
- Use .match? when we don&#39;t need data from a regex match [#10248](https://github.com/chef/chef/pull/10248) ([tas50](https://github.com/tas50))
- Convert osx_profile to custom resource [#10239](https://github.com/chef/chef/pull/10239) ([lamont-granquist](https://github.com/lamont-granquist))
- Resolve Performance/RangeInclude warnings [#10245](https://github.com/chef/chef/pull/10245) ([tas50](https://github.com/tas50))
- Use sort.reverse instead of sort { |a, b| b &lt;=&gt; a } [#10247](https://github.com/chef/chef/pull/10247) ([tas50](https://github.com/tas50))
- Use .key? instead of keys.include [#10246](https://github.com/chef/chef/pull/10246) ([tas50](https://github.com/tas50))
- Use tr not gsub for string replacement [#10251](https://github.com/chef/chef/pull/10251) ([tas50](https://github.com/tas50))
- apt_repository: Small code refactor in key_is_valid? method [#10253](https://github.com/chef/chef/pull/10253) ([phiggins](https://github.com/phiggins))
- Use .count instead of .select{}.count [#10252](https://github.com/chef/chef/pull/10252) ([tas50](https://github.com/tas50))
- Update RuboCop config to Ruby 2.6 [#10254](https://github.com/chef/chef/pull/10254) ([tas50](https://github.com/tas50))
- Convert openssl resources to unified_mode [#10249](https://github.com/chef/chef/pull/10249) ([lamont-granquist](https://github.com/lamont-granquist))
- Remove unnecessary Mixin::ShellOut in providers [#10256](https://github.com/chef/chef/pull/10256) ([tas50](https://github.com/tas50))
- Fix second chef run hang for windows_font resource [#10257](https://github.com/chef/chef/pull/10257) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Use find instead of select.first [#10255](https://github.com/chef/chef/pull/10255) ([tas50](https://github.com/tas50))
- Pull Ohai 16.4.2 into Chef Infra Client [#10259](https://github.com/chef/chef/pull/10259) ([tas50](https://github.com/tas50))
- added configuration options for chef-server [#10213](https://github.com/chef/chef/pull/10213) ([tehlers320](https://github.com/tehlers320))
- Remove more requires that come for free [#10258](https://github.com/chef/chef/pull/10258) ([tas50](https://github.com/tas50))
- Convert windows custom resources to unified_mode [#10260](https://github.com/chef/chef/pull/10260) ([lamont-granquist](https://github.com/lamont-granquist))
- Remove lzma and bzip binaries from our builds [#10263](https://github.com/chef/chef/pull/10263) ([tas50](https://github.com/tas50))
- Speed up our bundle installs by always running 3 jobs [#10264](https://github.com/chef/chef/pull/10264) ([tas50](https://github.com/tas50))
- Bump InSpec/Train/omnibus-software [#10267](https://github.com/chef/chef/pull/10267) ([tas50](https://github.com/tas50))
- Cleanup extra binaries from libxml2 and libxslt [#10265](https://github.com/chef/chef/pull/10265) ([tas50](https://github.com/tas50))
- Combine attr_reader / attr_writer into attr_accessor [#10268](https://github.com/chef/chef/pull/10268) ([tas50](https://github.com/tas50))
- Update spellcheck config with nice stuff from other repos. [#10261](https://github.com/chef/chef/pull/10261) ([phiggins](https://github.com/phiggins))
- Resolve Style/RedundantAssignment warnings [#10269](https://github.com/chef/chef/pull/10269) ([tas50](https://github.com/tas50))
- chef_client_systemd_timer: Fix failures in the :remove action [#10273](https://github.com/chef/chef/pull/10273) ([tas50](https://github.com/tas50))
- powershell_script: Use native properties and don&#39;t coerce user provided flags with powershell defaults [#10274](https://github.com/chef/chef/pull/10274) ([phiggins](https://github.com/phiggins))
- Mark deep_merge as private [#10277](https://github.com/chef/chef/pull/10277) ([lamont-granquist](https://github.com/lamont-granquist))
- Remove an unnecessary shared_context from execute resource tests [#10278](https://github.com/chef/chef/pull/10278) ([phiggins](https://github.com/phiggins))
- Clean up some interdependencies in script resource tests. [#10279](https://github.com/chef/chef/pull/10279) ([phiggins](https://github.com/phiggins))
- Fix broken powershell_script test. [#10280](https://github.com/chef/chef/pull/10280) ([phiggins](https://github.com/phiggins))
- client-run per resource error detail [#10237](https://github.com/chef/chef/pull/10237) ([vsingh-msys](https://github.com/vsingh-msys))
- Bump Ohai / Cheffish to the latest [#10281](https://github.com/chef/chef/pull/10281) ([tas50](https://github.com/tas50))
- double quotes in example for string interpolation [#10288](https://github.com/chef/chef/pull/10288) ([karlamrhein](https://github.com/karlamrhein))
- Renew an expired SSL Certificate [#10286](https://github.com/chef/chef/pull/10286) ([kapilchouhan99](https://github.com/kapilchouhan99))
- Bump Ohai to 16.4.9 [#10291](https://github.com/chef/chef/pull/10291) ([tas50](https://github.com/tas50))
- Remove a duplicate require [#10293](https://github.com/chef/chef/pull/10293) ([tas50](https://github.com/tas50))
- Use macos? helper in homebrew_update [#10290](https://github.com/chef/chef/pull/10290) ([tas50](https://github.com/tas50))
- Update chef-telemetry and ohai to the latest [#10295](https://github.com/chef/chef/pull/10295) ([tas50](https://github.com/tas50))
- Bump deps for require perf optimizations [#10296](https://github.com/chef/chef/pull/10296) ([tas50](https://github.com/tas50))
- Optimize requires for non-omnibus installs [#10294](https://github.com/chef/chef/pull/10294) ([tas50](https://github.com/tas50))
- Update Fauxhai to 8.3 [#10297](https://github.com/chef/chef/pull/10297) ([tas50](https://github.com/tas50))
- Update Omnibus kitchen config with public boxes [#10292](https://github.com/chef/chef/pull/10292) ([tas50](https://github.com/tas50))
- Minor tweaks to the platform checks in the specs [#10289](https://github.com/chef/chef/pull/10289) ([tas50](https://github.com/tas50))
- Fix File.exist throughout the codebase [#10284](https://github.com/chef/chef/pull/10284) ([tas50](https://github.com/tas50))
- Convert the functional tests over to macos? as well [#10303](https://github.com/chef/chef/pull/10303) ([tas50](https://github.com/tas50))
- do not require source when removing powershell package source [#10301](https://github.com/chef/chef/pull/10301) ([kimbernator](https://github.com/kimbernator))
- Change output to clearly show checksums are displayed incompletely [#10300](https://github.com/chef/chef/pull/10300) ([tecracer-theinen](https://github.com/tecracer-theinen))
- Delete deprecated Fauxhai definitions [#10305](https://github.com/chef/chef/pull/10305) ([tas50](https://github.com/tas50))
- Use net/http and openssl instead of net/https [#10283](https://github.com/chef/chef/pull/10283) ([tas50](https://github.com/tas50))
- Remove the unused win32-dir dependency [#10308](https://github.com/chef/chef/pull/10308) ([tas50](https://github.com/tas50))
- Fix bootstrapping windows-from-linux [#10298](https://github.com/chef/chef/pull/10298) ([lamont-granquist](https://github.com/lamont-granquist))
- Add 16.4 release notes [#10304](https://github.com/chef/chef/pull/10304) ([tas50](https://github.com/tas50))
- Update train to 3.3.16 [#10309](https://github.com/chef/chef/pull/10309) ([tas50](https://github.com/tas50))

## [v16.3.45](https://github.com/chef/chef/tree/v16.3.45) (2020-07-29)

#### Merged Pull Requests
- Bump deps to current [#10210](https://github.com/chef/chef/pull/10210) ([tas50](https://github.com/tas50))
- Mark a private method as private with yard [#10212](https://github.com/chef/chef/pull/10212) ([tas50](https://github.com/tas50))
- Use powershell_out vs. powershell_script in hostname [#10147](https://github.com/chef/chef/pull/10147) ([tas50](https://github.com/tas50))
- Define local test variables to avoid test load order bug. [#10214](https://github.com/chef/chef/pull/10214) ([phiggins](https://github.com/phiggins))
- Fix NoMethodError when server returns a 406. [#10216](https://github.com/chef/chef/pull/10216) ([phiggins](https://github.com/phiggins))
- Fix protocol negotiation for unversioned objects [#10218](https://github.com/chef/chef/pull/10218) ([lamont-granquist](https://github.com/lamont-granquist))
- Update libarchive, liblzma, and nokogiri to the latest [#10221](https://github.com/chef/chef/pull/10221) ([tas50](https://github.com/tas50))

## [v16.3.38](https://github.com/chef/chef/tree/v16.3.38) (2020-07-27)

#### Merged Pull Requests
- Reserve deprecation ID that was used in Chef-15 [#10091](https://github.com/chef/chef/pull/10091) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix syslog logging on Chef-16 [#10097](https://github.com/chef/chef/pull/10097) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump inspec-core-bin to 4.21.3 [#10101](https://github.com/chef/chef/pull/10101) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Use bash not execute in build_essential for better output [#10096](https://github.com/chef/chef/pull/10096) ([tas50](https://github.com/tas50))
- Bump train-core to 3.3.6 [#10104](https://github.com/chef/chef/pull/10104) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Update windows_security_policy for better idempotency [#10064](https://github.com/chef/chef/pull/10064) ([chef-davin](https://github.com/chef-davin))
- Update windows_security_policy to use powershell_out to be compatible with 32 bit windows [#10107](https://github.com/chef/chef/pull/10107) ([chef-davin](https://github.com/chef-davin))
- Implement ENFORCE_LICENSE dist constant for knife bootstrap [#9992](https://github.com/chef/chef/pull/9992) ([ramereth](https://github.com/ramereth))
- Switch back to a supported nokogiri release [#10114](https://github.com/chef/chef/pull/10114) ([tas50](https://github.com/tas50))
- Fix warning message for cb / core resource conflict [#10117](https://github.com/chef/chef/pull/10117) ([tas50](https://github.com/tas50))
- Add spaces after attrs [#10124](https://github.com/chef/chef/pull/10124) ([tas50](https://github.com/tas50))
- Avoid assigning variables before returning if we don&#39;t have to [#10123](https://github.com/chef/chef/pull/10123) ([tas50](https://github.com/tas50))
- Fix `powershell_exec!` test. [#10126](https://github.com/chef/chef/pull/10126) ([phiggins](https://github.com/phiggins))
- expand_path with __dir__ instead of __FILE__ [#10125](https://github.com/chef/chef/pull/10125) ([tas50](https://github.com/tas50))
- Allow iso8601 gem version 0.13 [#10128](https://github.com/chef/chef/pull/10128) ([tas50](https://github.com/tas50))
- Fix some windows package tests [#10129](https://github.com/chef/chef/pull/10129) ([phiggins](https://github.com/phiggins))
- windows_dns_record: add dns_server property with default of localhost [#10120](https://github.com/chef/chef/pull/10120) ([jeremyciak](https://github.com/jeremyciak))
- Fix systemd unit test on Windows. [#10127](https://github.com/chef/chef/pull/10127) ([phiggins](https://github.com/phiggins))
- Add introduced field to new propertyin windows_dns_record [#10132](https://github.com/chef/chef/pull/10132) ([tas50](https://github.com/tas50))
- Remove reference to deprecated option in test helper. [#10136](https://github.com/chef/chef/pull/10136) ([phiggins](https://github.com/phiggins))
- Support legacy DSS host keys with knife-ssh [#10133](https://github.com/chef/chef/pull/10133) ([tas50](https://github.com/tas50))
- Disable Naming/AsciiIdentifiers in our specs [#10139](https://github.com/chef/chef/pull/10139) ([tas50](https://github.com/tas50))
- Fix openssl config tests on Windows [#10138](https://github.com/chef/chef/pull/10138) ([phiggins](https://github.com/phiggins))
- Fix git sync if the local branch already exist [#9998](https://github.com/chef/chef/pull/9998) ([lotooo](https://github.com/lotooo))
- Fix spellcheck CI task [#10142](https://github.com/chef/chef/pull/10142) ([phiggins](https://github.com/phiggins))
- Minor chefstyle fixes in the spellcheck task [#10145](https://github.com/chef/chef/pull/10145) ([tas50](https://github.com/tas50))
- Fix some windows unit tests [#10144](https://github.com/chef/chef/pull/10144) ([phiggins](https://github.com/phiggins))
- Don&#39;t run the dnf test that Windows doesn&#39;t like on Windows. [#10149](https://github.com/chef/chef/pull/10149) ([phiggins](https://github.com/phiggins))
- Fix two warnings in tests. [#10150](https://github.com/chef/chef/pull/10150) ([phiggins](https://github.com/phiggins))
- Test and Promote Habitat builds on Linux [#10102](https://github.com/chef/chef/pull/10102) ([christopher-snapp](https://github.com/christopher-snapp))
- Fix extra quote in habitat test pipeline config [#10156](https://github.com/chef/chef/pull/10156) ([christopher-snapp](https://github.com/christopher-snapp))
- Fix execute resource with integer user parameter. [#10157](https://github.com/chef/chef/pull/10157) ([phiggins](https://github.com/phiggins))
- Fixed `knife cookbook upload -o` windows path issue [#10146](https://github.com/chef/chef/pull/10146) ([antima-gupta](https://github.com/antima-gupta))
- Bump the server api version to 2 [#10140](https://github.com/chef/chef/pull/10140) ([lamont-granquist](https://github.com/lamont-granquist))
- Use rspec constant stubbing. [#10155](https://github.com/chef/chef/pull/10155) ([phiggins](https://github.com/phiggins))
- Don&#39;t allow setting expectations on nil. [#10154](https://github.com/chef/chef/pull/10154) ([phiggins](https://github.com/phiggins))
- Update to Chefstyle 1.2 + some fixes [#10158](https://github.com/chef/chef/pull/10158) ([tas50](https://github.com/tas50))
- Remove smartos detection / support in our package scripts [#10161](https://github.com/chef/chef/pull/10161) ([tas50](https://github.com/tas50))
- Workaround rubygems ssl test failure [#10160](https://github.com/chef/chef/pull/10160) ([phiggins](https://github.com/phiggins))
- Move the rehash methods into the subcommand loader [#10159](https://github.com/chef/chef/pull/10159) ([tas50](https://github.com/tas50))
- Bump omnibus-software to pull in the new cacerts [#10163](https://github.com/chef/chef/pull/10163) ([tas50](https://github.com/tas50))
- Avoid requiring spec_helper more than once [#10148](https://github.com/chef/chef/pull/10148) ([phiggins](https://github.com/phiggins))
- Create the windows_firewall_profile resource for use with enabling/disabling and configuring the Windows firewall Domain, Private, and Public profiles [#9994](https://github.com/chef/chef/pull/9994) ([chef-davin](https://github.com/chef-davin))
- Don&#39;t allow tests to set an expectation without specific error type [#10153](https://github.com/chef/chef/pull/10153) ([phiggins](https://github.com/phiggins))
- update changelog reference to pull request for windows_security_policy 32bit windows compatibility PR [#10169](https://github.com/chef/chef/pull/10169) ([chef-davin](https://github.com/chef-davin))
- Replace single quotes with double [#10176](https://github.com/chef/chef/pull/10176) ([mattray](https://github.com/mattray))
- Reset logger in test to avoid global state persisting. [#10170](https://github.com/chef/chef/pull/10170) ([phiggins](https://github.com/phiggins))
- don&#39;t check list-profiles for already selected bad profile [#10162](https://github.com/chef/chef/pull/10162) ([dheerajd-msys](https://github.com/dheerajd-msys))
- fix windows package for Chef-16 regression [#10177](https://github.com/chef/chef/pull/10177) ([lamont-granquist](https://github.com/lamont-granquist))
- Update InSpec to 4.22 and mixlib-shellout to 3.1.1 [#10178](https://github.com/chef/chef/pull/10178) ([tas50](https://github.com/tas50))
- Replace highline ui.ask password prompt with tty-prompt gem [#10131](https://github.com/chef/chef/pull/10131) ([vsingh-msys](https://github.com/vsingh-msys))
- Update InSpec to 4.22.1 [#10183](https://github.com/chef/chef/pull/10183) ([tas50](https://github.com/tas50))
- Remove cookbook uploader global state [#10185](https://github.com/chef/chef/pull/10185) ([phiggins](https://github.com/phiggins))
- Extract shell_out helper method to chef-utils for reuse in ohai, etc [#10137](https://github.com/chef/chef/pull/10137) ([lamont-granquist](https://github.com/lamont-granquist))
- Rework macos_userdefaults resource [#10118](https://github.com/chef/chef/pull/10118) ([tas50](https://github.com/tas50))
- Move some Ruby omnibus cleanup to omnibus-software [#10189](https://github.com/chef/chef/pull/10189) ([tas50](https://github.com/tas50))
- require mixlib-shellout 3.1.1+ and pull in new ohai [#10191](https://github.com/chef/chef/pull/10191) ([tas50](https://github.com/tas50))
- Set log level to :fatal in test to prevent excess logging. [#10188](https://github.com/chef/chef/pull/10188) ([phiggins](https://github.com/phiggins))
- Update the ruby-cleanup omnibus-software configs [#10195](https://github.com/chef/chef/pull/10195) ([tas50](https://github.com/tas50))
- Update ruby cleanup omnibus software again [#10196](https://github.com/chef/chef/pull/10196) ([tas50](https://github.com/tas50))
- Fix chef-resource-inspector to handle classes in equal_to [#10197](https://github.com/chef/chef/pull/10197) ([tas50](https://github.com/tas50))
- Update the examples to match the actual usage of the windows_firewall_profile resource. [#10198](https://github.com/chef/chef/pull/10198) ([chef-davin](https://github.com/chef-davin))
- Implement default_paths API [#10193](https://github.com/chef/chef/pull/10193) ([lamont-granquist](https://github.com/lamont-granquist))
- Reduce path_helper allocations [#10200](https://github.com/chef/chef/pull/10200) ([lamont-granquist](https://github.com/lamont-granquist))
- Rename Attribute Whitelist/Blacklist to Allowed/Blocked [#10199](https://github.com/chef/chef/pull/10199) ([tas50](https://github.com/tas50))
- Fix default_paths patch [#10202](https://github.com/chef/chef/pull/10202) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump Ohai to 16.3.0 [#10203](https://github.com/chef/chef/pull/10203) ([tas50](https://github.com/tas50))
- Remove bad filter from git spec tests [#10204](https://github.com/chef/chef/pull/10204) ([lamont-granquist](https://github.com/lamont-granquist))
- fix el6 selinux [#10206](https://github.com/chef/chef/pull/10206) ([lamont-granquist](https://github.com/lamont-granquist))
- Remove some test cruft around diffing [#10205](https://github.com/chef/chef/pull/10205) ([phiggins](https://github.com/phiggins))

## [v16.2.73](https://github.com/chef/chef/tree/v16.2.73) (2020-07-01)

#### Merged Pull Requests
- More aggressively deprecate config_value [#10025](https://github.com/chef/chef/pull/10025) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix broken tests after updating diff-lcs dep [#10052](https://github.com/chef/chef/pull/10052) ([phiggins](https://github.com/phiggins))
- Setup cspell to pull from our common dictionary [#10021](https://github.com/chef/chef/pull/10021) ([tas50](https://github.com/tas50))
- Bump diff-lcs to get bugfix. [#10057](https://github.com/chef/chef/pull/10057) ([phiggins](https://github.com/phiggins))
- Inline some constants to prevent redefenition warnings in tests. [#10047](https://github.com/chef/chef/pull/10047) ([phiggins](https://github.com/phiggins))
- consume powershell shim DLLs from hab package [#10022](https://github.com/chef/chef/pull/10022) ([mwrock](https://github.com/mwrock))
- Fixed broken chef-apply with -j [#10066](https://github.com/chef/chef/pull/10066) ([komazarari](https://github.com/komazarari))
- Bump train-core to 3.3.4 [#10067](https://github.com/chef/chef/pull/10067) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Bump the external tests to 2.7 [#10062](https://github.com/chef/chef/pull/10062) ([lamont-granquist](https://github.com/lamont-granquist))
- specs: Remove more methods defined on the top-level scope [#10060](https://github.com/chef/chef/pull/10060) ([phiggins](https://github.com/phiggins))
- Update the windows_user_privilege resource to have a `:clear` action [#10063](https://github.com/chef/chef/pull/10063) ([chef-davin](https://github.com/chef-davin))
- fix habitat based windows service tests [#10070](https://github.com/chef/chef/pull/10070) ([mwrock](https://github.com/mwrock))
- Update ffi-libarchive for windows fixes / pin the dep [#10072](https://github.com/chef/chef/pull/10072) ([tas50](https://github.com/tas50))
- Remove Azure private verify pipeline [#10019](https://github.com/chef/chef/pull/10019) ([christopher-snapp](https://github.com/christopher-snapp))
- Pick some of the unit test fixes from #10068 [#10074](https://github.com/chef/chef/pull/10074) ([lamont-granquist](https://github.com/lamont-granquist))
- Revert openssl digest update that broke FIPS [#10058](https://github.com/chef/chef/pull/10058) ([tas50](https://github.com/tas50))
- Update tests and docs for umask on Windows. [#10077](https://github.com/chef/chef/pull/10077) ([phiggins](https://github.com/phiggins))
- Revert &quot;Merge pull request #10052 from chef/fix-diff-tests&quot; [#10078](https://github.com/chef/chef/pull/10078) ([phiggins](https://github.com/phiggins))
- specs: Remove test file that added a method to top-level scope. [#10027](https://github.com/chef/chef/pull/10027) ([phiggins](https://github.com/phiggins))
- Bump inspec-core-bin to 4.21.1 [#10081](https://github.com/chef/chef/pull/10081) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Pin dff-lcs, bump ohai, &amp; misc omnibus updates [#10085](https://github.com/chef/chef/pull/10085) ([tas50](https://github.com/tas50))
- Fix release build tests [#10088](https://github.com/chef/chef/pull/10088) ([phiggins](https://github.com/phiggins))
- Fix release build tests, part 2 [#10089](https://github.com/chef/chef/pull/10089) ([phiggins](https://github.com/phiggins))
- Fix release build tests, part 3 [#10093](https://github.com/chef/chef/pull/10093) ([phiggins](https://github.com/phiggins))

## [v16.2.50](https://github.com/chef/chef/tree/v16.2.50) (2020-06-23)

#### Merged Pull Requests
- Bump inspec-core-bin to 4.20.10 [#10017](https://github.com/chef/chef/pull/10017) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- windows_security_policy was using resource_name instead of provides [#10018](https://github.com/chef/chef/pull/10018) ([chef-davin](https://github.com/chef-davin))
- Fix for knife config use-profile doesn&#39;t validate that the profile exist [#10011](https://github.com/chef/chef/pull/10011) ([Vasu1105](https://github.com/Vasu1105))
- Add more examples to the resource code [#10020](https://github.com/chef/chef/pull/10020) ([tas50](https://github.com/tas50))
- Resource doc updates [#10024](https://github.com/chef/chef/pull/10024) ([phiggins](https://github.com/phiggins))
- Bump ohai to 16.2.1 [#10035](https://github.com/chef/chef/pull/10035) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))

## [v16.2.44](https://github.com/chef/chef/tree/v16.2.44) (2020-06-17)

#### Merged Pull Requests
- Chef-16.1 breaking change [#9890](https://github.com/chef/chef/pull/9890) ([lamont-granquist](https://github.com/lamont-granquist))
- Adds the homebrew_update resource [#9896](https://github.com/chef/chef/pull/9896) ([damacus](https://github.com/damacus))
- Add an input property to the execute resource for passing input on STDIN [#9910](https://github.com/chef/chef/pull/9910) ([phiggins](https://github.com/phiggins))
- Add ssl_verify option for remote_file [#9833](https://github.com/chef/chef/pull/9833) ([jaymzh](https://github.com/jaymzh))
- Update &amp; add resource descriptions for documentation generation [#9923](https://github.com/chef/chef/pull/9923) ([tas50](https://github.com/tas50))
- Update to ssl_verify_mode on remote_file [#9925](https://github.com/chef/chef/pull/9925) ([jaymzh](https://github.com/jaymzh))
- Improve auto-generated docs [#9926](https://github.com/chef/chef/pull/9926) ([tas50](https://github.com/tas50))
- Fix chefstyle violations. [#9929](https://github.com/chef/chef/pull/9929) ([phiggins](https://github.com/phiggins))
- Make sure file is properly scoped in cron_access [#9931](https://github.com/chef/chef/pull/9931) ([tas50](https://github.com/tas50))
- hostname: Remove support for Solaris 5.10 [#9928](https://github.com/chef/chef/pull/9928) ([tas50](https://github.com/tas50))
- hostname: Improve the windows reboot message [#9927](https://github.com/chef/chef/pull/9927) ([tas50](https://github.com/tas50))
- Update chef-telemetry to 1.0.8 and InSpec to 4.19 [#9934](https://github.com/chef/chef/pull/9934) ([tas50](https://github.com/tas50))
- Set up CI with Azure Pipelines [#9894](https://github.com/chef/chef/pull/9894) ([btm](https://github.com/btm))
- Add additional testing for macOS hosts [#9939](https://github.com/chef/chef/pull/9939) ([tas50](https://github.com/tas50))
- archive_file: better handle mode property and deprecate Integer values [#9950](https://github.com/chef/chef/pull/9950) ([tas50](https://github.com/tas50))
- archive_file: move ffi-libarchive into a simple helper method [#9951](https://github.com/chef/chef/pull/9951) ([tas50](https://github.com/tas50))
- Add nightly cleanup of orphaned test resources [#9943](https://github.com/chef/chef/pull/9943) ([christopher-snapp](https://github.com/christopher-snapp))
- Pin FFI &lt; 1.13 and bump inspec-core-bin to 4.19.2 [#9954](https://github.com/chef/chef/pull/9954) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Fixed Powershell_Package does not throw error when it cannot connect … [#9946](https://github.com/chef/chef/pull/9946) ([sanga1794](https://github.com/sanga1794))
- Add spellcheck to CI [#9957](https://github.com/chef/chef/pull/9957) ([phiggins](https://github.com/phiggins))
- Fix zypper_repository key handling on SLES 15+ [#9956](https://github.com/chef/chef/pull/9956) ([tas50](https://github.com/tas50))
- update learn chef name, discourse name, and copyright year [#9958](https://github.com/chef/chef/pull/9958) ([bennyvasquez](https://github.com/bennyvasquez))
- Fix rspec warning about `not_to raise_error` with a specific exception. [#9937](https://github.com/chef/chef/pull/9937) ([phiggins](https://github.com/phiggins))
- Change script resources to use pipes rather than writing to temp files [#9932](https://github.com/chef/chef/pull/9932) ([phiggins](https://github.com/phiggins))
- Update to the chef_client_scheduled_task resource frequency_modify default functionality [#9920](https://github.com/chef/chef/pull/9920) ([chef-davin](https://github.com/chef-davin))
- Update train-core to the latest [#9959](https://github.com/chef/chef/pull/9959) ([tas50](https://github.com/tas50))
- Fix wrong unit test exposed by cleaning up rspec deprecations. [#9961](https://github.com/chef/chef/pull/9961) ([phiggins](https://github.com/phiggins))
- Add more resource docs + improve yaml generation [#9960](https://github.com/chef/chef/pull/9960) ([tas50](https://github.com/tas50))
- knife vault on windows 10 fails due to ERROR: Chef::Exceptions::InvalidDataBagPath [#9952](https://github.com/chef/chef/pull/9952) ([snehaldwivedi](https://github.com/snehaldwivedi))
- Add Windows 8 Tester [#9971](https://github.com/chef/chef/pull/9971) ([christopher-snapp](https://github.com/christopher-snapp))
- Let the user know what protocol we&#39;re using in knife bootstrap [#9973](https://github.com/chef/chef/pull/9973) ([tas50](https://github.com/tas50))
- Warn during bootstrapping when using validation keys [#9974](https://github.com/chef/chef/pull/9974) ([tas50](https://github.com/tas50))
- Allow for the latest net-ssh and ffi 1.13.1  [#9978](https://github.com/chef/chef/pull/9978) ([tas50](https://github.com/tas50))
- Stop producing packages for EOL Debian 8 [#9981](https://github.com/chef/chef/pull/9981) ([tas50](https://github.com/tas50))
- Use /etc/chef for bootstrapping instead of ChefConfig [#9984](https://github.com/chef/chef/pull/9984) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Update with 2020 MVPs [#9985](https://github.com/chef/chef/pull/9985) ([Xorima](https://github.com/Xorima))
- Small code cleanups in script/windows_script [#9979](https://github.com/chef/chef/pull/9979) ([phiggins](https://github.com/phiggins))
- Fix snap_package bugs [#9944](https://github.com/chef/chef/pull/9944) ([jaymzh](https://github.com/jaymzh))
- Use .match? not =~ when match values aren&#39;t necessary [#9989](https://github.com/chef/chef/pull/9989) ([tas50](https://github.com/tas50))
- Disable snap dokken tests for now [#9993](https://github.com/chef/chef/pull/9993) ([tas50](https://github.com/tas50))
- Fix how enforce_license is set in run method for chef-apply [#9963](https://github.com/chef/chef/pull/9963) ([ramereth](https://github.com/ramereth))
- Create windows_audit_policy resource [#9980](https://github.com/chef/chef/pull/9980) ([chef-davin](https://github.com/chef-davin))
- Add &quot;most recent call first&quot; to traceback message [#9967](https://github.com/chef/chef/pull/9967) ([zfjagann](https://github.com/zfjagann))
- Improve resource documentation [#9995](https://github.com/chef/chef/pull/9995) ([tas50](https://github.com/tas50))
- Cron and Cron_d resource weekday property fixes [#10001](https://github.com/chef/chef/pull/10001) ([tas50](https://github.com/tas50))
- Cleanup more resource examples [#10002](https://github.com/chef/chef/pull/10002) ([tas50](https://github.com/tas50))
- Silence exception output in threaded test. [#10005](https://github.com/chef/chef/pull/10005) ([phiggins](https://github.com/phiggins))
- Soft fail spellchecker in ci [#10003](https://github.com/chef/chef/pull/10003) ([phiggins](https://github.com/phiggins))
- Fix for windows_audit_policy bug for when a value for the subcategory property isn&#39;t entered [#10007](https://github.com/chef/chef/pull/10007) ([chef-davin](https://github.com/chef-davin))
- Update InSpec to 4.20.6 [#10008](https://github.com/chef/chef/pull/10008) ([tas50](https://github.com/tas50))
- Bump ohai to 16.2.0 [#10009](https://github.com/chef/chef/pull/10009) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Add a umask property for resources. [#10000](https://github.com/chef/chef/pull/10000) ([phiggins](https://github.com/phiggins))
- Minor docs updates and MacOS -&gt; macOS [#10010](https://github.com/chef/chef/pull/10010) ([tas50](https://github.com/tas50))
- Update the list of allowed policies for the windows_security_policy resource [#10012](https://github.com/chef/chef/pull/10012) ([chef-davin](https://github.com/chef-davin))

## [v16.1.16](https://github.com/chef/chef/tree/v16.1.16) (2020-05-27)

#### Merged Pull Requests
- fix windows bootstrap; replicate chef/chef/pull/9839 by Chad Jessup [#9878](https://github.com/chef/chef/pull/9878) ([bobchaos](https://github.com/bobchaos))
- Fix failures inspecting a single cookbook [#9882](https://github.com/chef/chef/pull/9882) ([tas50](https://github.com/tas50))
- Fix ruby 2.7 keyword argument warning. [#9883](https://github.com/chef/chef/pull/9883) ([phiggins](https://github.com/phiggins))
- Add spellcheck config and fix a bunch of violations [#9826](https://github.com/chef/chef/pull/9826) ([phiggins](https://github.com/phiggins))
- Added armv6l and armv7l to arm? and armhf? helpers [#9887](https://github.com/chef/chef/pull/9887) ([mattray](https://github.com/mattray))
- Small cleanups to checksum logic in file/windows_package/chef::mixin::checksum [#9886](https://github.com/chef/chef/pull/9886) ([phiggins](https://github.com/phiggins))
- Fix bootstrapping windows from linux [#9889](https://github.com/chef/chef/pull/9889) ([btm](https://github.com/btm))
- Fixed armv6l and armv7l tests. [#9892](https://github.com/chef/chef/pull/9892) ([mattray](https://github.com/mattray))
- [chef-utils] fix typos [#9895](https://github.com/chef/chef/pull/9895) ([michel-slm](https://github.com/michel-slm))
- Update openssl to 1.0.2v [#9903](https://github.com/chef/chef/pull/9903) ([tas50](https://github.com/tas50))
- macos_userdefaults: Fix ruby 2.7 keyword args warning and refactor a bit [#9897](https://github.com/chef/chef/pull/9897) ([phiggins](https://github.com/phiggins))
- Refactor verify pipeline to use Ruby 2.7 on Windows docker image [#9877](https://github.com/chef/chef/pull/9877) ([christopher-snapp](https://github.com/christopher-snapp))
- Windows functional test should be single-use [#9908](https://github.com/chef/chef/pull/9908) ([christopher-snapp](https://github.com/christopher-snapp))
- Update our usage of OpenSSL::Digest to avoid Ruby 3 breaking change [#9905](https://github.com/chef/chef/pull/9905) ([tas50](https://github.com/tas50))
- Pull in updated omnibus-software for rubygems perf patch [#9916](https://github.com/chef/chef/pull/9916) ([tas50](https://github.com/tas50))

## [v16.1.0](https://github.com/chef/chef/tree/v16.1.0) (2020-05-15)

#### Merged Pull Requests
- Remove the config hash defaults [#9827](https://github.com/chef/chef/pull/9827) ([lamont-granquist](https://github.com/lamont-granquist))
- Try removing asdf entirely and just use omnibus-toolchain [#9828](https://github.com/chef/chef/pull/9828) ([tas50](https://github.com/tas50))
- Use the dist values in server error messages [#9830](https://github.com/chef/chef/pull/9830) ([tas50](https://github.com/tas50))
- Stop upgrading rubygems in tests [#9835](https://github.com/chef/chef/pull/9835) ([tas50](https://github.com/tas50))
- Update rubyinstaller-devkit-2.6.6-1-x64.exe SHA [#9845](https://github.com/chef/chef/pull/9845) ([christopher-snapp](https://github.com/christopher-snapp))
- Add examples to windows_security_policy [#9842](https://github.com/chef/chef/pull/9842) ([IanMadd](https://github.com/IanMadd))
- Avoid ruby deprecation warnings in cab_package and powershell_script [#9850](https://github.com/chef/chef/pull/9850) ([tas50](https://github.com/tas50))
- Add Debian 10 aarch64 support [#9837](https://github.com/chef/chef/pull/9837) ([christopher-snapp](https://github.com/christopher-snapp))
- Test PRs against Ruby 2.7 [#9856](https://github.com/chef/chef/pull/9856) ([tas50](https://github.com/tas50))
- Add Ubuntu 20.04 testing to our pipeline [#9859](https://github.com/chef/chef/pull/9859) ([tas50](https://github.com/tas50))
- private end to end windows 10 pipeline [#9857](https://github.com/chef/chef/pull/9857) ([btm](https://github.com/btm))
- Switch end-to-end-windows-10 back to use the Linux scripts [#9862](https://github.com/chef/chef/pull/9862) ([btm](https://github.com/btm))
- Remove most of the emojis from the buildkite tests [#9863](https://github.com/chef/chef/pull/9863) ([btm](https://github.com/btm))
- Switch Ruby functional test on Windows to Ruby 2.7 [#9864](https://github.com/chef/chef/pull/9864) ([tas50](https://github.com/tas50))
- Update Chefstyle to 1.0.5, Ohai to 16.1.1, and cheffish to 15.0.3 [#9869](https://github.com/chef/chef/pull/9869) ([tas50](https://github.com/tas50))
- Fixes and tests for Chef-16 regression in launchd [#9868](https://github.com/chef/chef/pull/9868) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump inspec-core to 4.18.114 [#9870](https://github.com/chef/chef/pull/9870) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Add 16.1 release notes [#9873](https://github.com/chef/chef/pull/9873) ([tas50](https://github.com/tas50))

## [v16.0.287](https://github.com/chef/chef/tree/v16.0.287) (2020-05-07)

#### Merged Pull Requests
- More cleanup of our installed gems [#9802](https://github.com/chef/chef/pull/9802) ([tas50](https://github.com/tas50))
- Update omnibus-software for new msys2 path [#9801](https://github.com/chef/chef/pull/9801) ([jaymalasinha](https://github.com/jaymalasinha))
- Pin chef-telementry to 1.0.3 to avoid ffi build breakage  [#9808](https://github.com/chef/chef/pull/9808) ([tas50](https://github.com/tas50))
- Bump inspec-core to 4.18.111 [#9803](https://github.com/chef/chef/pull/9803) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Fix windows_package not allowing version to be an array [#9810](https://github.com/chef/chef/pull/9810) ([tas50](https://github.com/tas50))
- Align all our comments with the code [#9811](https://github.com/chef/chef/pull/9811) ([tas50](https://github.com/tas50))
- fix launchd provider for chef-16 [#9812](https://github.com/chef/chef/pull/9812) ([lamont-granquist](https://github.com/lamont-granquist))
- Add ohai_hint and openssl_* testing in Test Kitchen [#9813](https://github.com/chef/chef/pull/9813) ([tas50](https://github.com/tas50))
- Update omnibus-software for Windows lalr1.java removal [#9815](https://github.com/chef/chef/pull/9815) ([btm](https://github.com/btm))
- Expand our sudo, sysctl, execute, apt_update and apt_preference testing [#9816](https://github.com/chef/chef/pull/9816) ([tas50](https://github.com/tas50))
- Cache the gems during the Test Kitchen tests [#9818](https://github.com/chef/chef/pull/9818) ([tas50](https://github.com/tas50))
- Don&#39;t update rubygems / bundler in the kitchen tests [#9819](https://github.com/chef/chef/pull/9819) ([tas50](https://github.com/tas50))
- Only require the driver_name property when creating printer ports [#9824](https://github.com/chef/chef/pull/9824) ([tas50](https://github.com/tas50))
- Fix a misspelling in knife subcommand. [#9825](https://github.com/chef/chef/pull/9825) ([phiggins](https://github.com/phiggins))

## [v16.0.275](https://github.com/chef/chef/tree/v16.0.275) (2020-05-05)

#### Merged Pull Requests
- Add Chef Infra Client 16 release notes [#9614](https://github.com/chef/chef/pull/9614) ([tas50](https://github.com/tas50))
- Fixes to support unbundled rake use [#9759](https://github.com/chef/chef/pull/9759) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix more ruby 2.7 warning logspam [#9762](https://github.com/chef/chef/pull/9762) ([lamont-granquist](https://github.com/lamont-granquist))
- Improve resource docs [#9764](https://github.com/chef/chef/pull/9764) ([tas50](https://github.com/tas50))
- More resource documentation improvements [#9765](https://github.com/chef/chef/pull/9765) ([tas50](https://github.com/tas50))
- More improvements to the docs generation [#9767](https://github.com/chef/chef/pull/9767) ([tas50](https://github.com/tas50))
- Improve resource self documentation [#9773](https://github.com/chef/chef/pull/9773) ([tas50](https://github.com/tas50))
- Remove an unused spec helper [#9774](https://github.com/chef/chef/pull/9774) ([tas50](https://github.com/tas50))
- Add more examples to resources [#9775](https://github.com/chef/chef/pull/9775) ([tas50](https://github.com/tas50))
- Fix symbols and arrays in yaml conversion tool [#9769](https://github.com/chef/chef/pull/9769) ([phiggins](https://github.com/phiggins))
- Modified client cron directory permission [#9782](https://github.com/chef/chef/pull/9782) ([DhaneshRaghavan](https://github.com/DhaneshRaghavan))
- chef_client_cron: cleanup the appropriate cron job [#9784](https://github.com/chef/chef/pull/9784) ([tas50](https://github.com/tas50))
- Avoid setting package to macports and then overriding to homebrew [#9783](https://github.com/chef/chef/pull/9783) ([tas50](https://github.com/tas50))
- Another round of description updates &amp;&amp; Docs generator tweaks [#9778](https://github.com/chef/chef/pull/9778) ([tas50](https://github.com/tas50))
- Fix failing RHEL 6 kitchen tests [#9740](https://github.com/chef/chef/pull/9740) ([tas50](https://github.com/tas50))
- Fix windows package super bug and cleanup [#9790](https://github.com/chef/chef/pull/9790) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix required errors in apt_preference and sysctl resources [#9791](https://github.com/chef/chef/pull/9791) ([tas50](https://github.com/tas50))
- fix Habitat Windows package build [#9739](https://github.com/chef/chef/pull/9739) ([robbkidd](https://github.com/robbkidd))
- Fix failures in the cron_d resource :remove action [#9794](https://github.com/chef/chef/pull/9794) ([tas50](https://github.com/tas50))

## [v16.0.257](https://github.com/chef/chef/tree/v16.0.257) (2020-04-28)

#### Merged Pull Requests
- Fix mac_user breakage and logging [#9158](https://github.com/chef/chef/pull/9158) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump train-core to 3.2.5 [#9159](https://github.com/chef/chef/pull/9159) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- try unit + functional tests [#9163](https://github.com/chef/chef/pull/9163) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump inspec-core to 4.18.51 [#9168](https://github.com/chef/chef/pull/9168) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- add new option bootstrap_product for install cinc via bootstrap [#9112](https://github.com/chef/chef/pull/9112) ([sawanoboly](https://github.com/sawanoboly))
- resource archive_file: apply ownership to extracted files only [#9173](https://github.com/chef/chef/pull/9173) ([bobchaos](https://github.com/bobchaos))
- Fix event log message description format [#9190](https://github.com/chef/chef/pull/9190) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Bump mixlib-cli to 2.1.5 as well as Ohai, cheffish, and telemetry [#9191](https://github.com/chef/chef/pull/9191) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Update all omnibus deps to the latest [#9192](https://github.com/chef/chef/pull/9192) ([tas50](https://github.com/tas50))
- Update libarchive to 1.0 [#9194](https://github.com/chef/chef/pull/9194) ([tas50](https://github.com/tas50))
- Bump ffi-yajl to 2.3.3 [#9195](https://github.com/chef/chef/pull/9195) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Bump mixlib-archive to 1.0.5 [#9196](https://github.com/chef/chef/pull/9196) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Bump chef-vault to 4.0.1, chef-zero to 14.0.17, mixlib-shellout to 3.0.9, and mixlib-authentication to 3.0.6 [#9198](https://github.com/chef/chef/pull/9198) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Last batch of wordmarks removal for chef-config [#9176](https://github.com/chef/chef/pull/9176) ([bobchaos](https://github.com/bobchaos))
- Remove legacy Net::HTTP not needed in Ruby 2.2+ [#9200](https://github.com/chef/chef/pull/9200) ([tas50](https://github.com/tas50))
- Expand chef-utils yard comments and make consistent [#9188](https://github.com/chef/chef/pull/9188) ([tas50](https://github.com/tas50))
- Update all deps to current [#9210](https://github.com/chef/chef/pull/9210) ([tas50](https://github.com/tas50))
- Fixes for sudo resource fails on 2nd converge when Cmnd_Alias is used [#9186](https://github.com/chef/chef/pull/9186) ([samshinde](https://github.com/samshinde))
- Clear password flags when setting the password on aix [#9209](https://github.com/chef/chef/pull/9209) ([Triodes](https://github.com/Triodes))
- Do not build Chef Infra Client on Windows 2008 R2 [#9203](https://github.com/chef/chef/pull/9203) ([tas50](https://github.com/tas50))
- Update to license_scout 1.1.2 [#9212](https://github.com/chef/chef/pull/9212) ([tas50](https://github.com/tas50))
- x509_certificate : Add the capability to automatically renew a certificate [#9187](https://github.com/chef/chef/pull/9187) ([julienhuon](https://github.com/julienhuon))
- Fix for windows task not idempotent on the windows19 and window… [#9223](https://github.com/chef/chef/pull/9223) ([Vasu1105](https://github.com/Vasu1105))
- Use the right class in knife supermarket install [#9217](https://github.com/chef/chef/pull/9217) ([tas50](https://github.com/tas50))
- Use /etc/chef for bootstrapping instead of CONF_DIR [#9226](https://github.com/chef/chef/pull/9226) ([marcparadise](https://github.com/marcparadise))
- Windows Path on Bootstrap [#8669](https://github.com/chef/chef/pull/8669) ([Xorima](https://github.com/Xorima))
- Update openssl to 1.0.2u [#9229](https://github.com/chef/chef/pull/9229) ([tas50](https://github.com/tas50))
- Generate metadata.json from metadata.rb if not exist before knife cookbook upload or knife upload or berkshelf upload [#9073](https://github.com/chef/chef/pull/9073) ([Vasu1105](https://github.com/Vasu1105))
- Add time_out property in cron resource [#9153](https://github.com/chef/chef/pull/9153) ([Nimesh-Msys](https://github.com/Nimesh-Msys))
- Remove RHEL 6 s390x (zLinux) support [#9233](https://github.com/chef/chef/pull/9233) ([jaymalasinha](https://github.com/jaymalasinha))
- Update to Ohai 16.0.2 [#9246](https://github.com/chef/chef/pull/9246) ([tas50](https://github.com/tas50))
- Require Ruby 2.6+ [#9247](https://github.com/chef/chef/pull/9247) ([tas50](https://github.com/tas50))
- WIP: Chef-16 resource cleanup + unified_mode [#9174](https://github.com/chef/chef/pull/9174) ([lamont-granquist](https://github.com/lamont-granquist))
- Add windows helpers for install type [#9235](https://github.com/chef/chef/pull/9235) ([tas50](https://github.com/tas50))
- move Chef::VersionString to Chef::Utils [#9234](https://github.com/chef/chef/pull/9234) ([lamont-granquist](https://github.com/lamont-granquist))
- Raises error if there is empty cookbook directory at the time o… [#9011](https://github.com/chef/chef/pull/9011) ([Vasu1105](https://github.com/Vasu1105))
- Fix most Ruby 2.7 test failures / systemd service provider splat args conversion [#9251](https://github.com/chef/chef/pull/9251) ([lamont-granquist](https://github.com/lamont-granquist))
- launchd: Fix capitalization of HardResourceLimits [#9239](https://github.com/chef/chef/pull/9239) ([rb2k](https://github.com/rb2k))
- fix a few more ruby 2.7 specs [#9253](https://github.com/chef/chef/pull/9253) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump train-core to 3.2.14 [#9258](https://github.com/chef/chef/pull/9258) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Fixes all notarization issues [#9219](https://github.com/chef/chef/pull/9219) ([jonsmorrow](https://github.com/jonsmorrow))
- Provider a better error message in Chef::Cookbook::CookbookVersionLoader [#9264](https://github.com/chef/chef/pull/9264) ([tas50](https://github.com/tas50))
- Use .load! in the Cookbook loader not .load_cookbooks [#9266](https://github.com/chef/chef/pull/9266) ([tas50](https://github.com/tas50))
- Ruby 2.7 IRB and remaining fixes [#9267](https://github.com/chef/chef/pull/9267) ([lamont-granquist](https://github.com/lamont-granquist))
- Cleanup the specs for the load_cookbooks warnings [#9269](https://github.com/chef/chef/pull/9269) ([tas50](https://github.com/tas50))
- switch the load method back to not raising + deprecation [#9274](https://github.com/chef/chef/pull/9274) ([lamont-granquist](https://github.com/lamont-granquist))
- berks upload skip syntax check fixes [#9281](https://github.com/chef/chef/pull/9281) ([vsingh-msys](https://github.com/vsingh-msys))
- add berkshelf as an external test [#9284](https://github.com/chef/chef/pull/9284) ([lamont-granquist](https://github.com/lamont-granquist))
- [chef-16] Remove the data bag secret short option [#9263](https://github.com/chef/chef/pull/9263) ([vsingh-msys](https://github.com/vsingh-msys))
- Remove more support for Windows 2008 R2 / RHEL 5 [#9261](https://github.com/chef/chef/pull/9261) ([tas50](https://github.com/tas50))
- Remove the deprecated knife cookbook site commands [#9288](https://github.com/chef/chef/pull/9288) ([tas50](https://github.com/tas50))
- Remove the sites-cookbooks dir from the cookbook_path default config [#9290](https://github.com/chef/chef/pull/9290) ([tas50](https://github.com/tas50))
- Merge pull request #9291 from chef/lcg/chef-utils-doc-touchup [#9291](https://github.com/chef/chef/pull/9291) ([lamont-granquist](https://github.com/lamont-granquist))
- apt_repository: add a description for components when using a PPA [#9289](https://github.com/chef/chef/pull/9289) ([tas50](https://github.com/tas50))
- Update knife status --long to use cloud attributes not ec2 specific attributes [#7882](https://github.com/chef/chef/pull/7882) ([tas50](https://github.com/tas50))
- Remove DK wording from knife warning [#9293](https://github.com/chef/chef/pull/9293) ([tas50](https://github.com/tas50))
- debian 10 ifconfig fix [#9294](https://github.com/chef/chef/pull/9294) ([lamont-granquist](https://github.com/lamont-granquist))
- Add ruby 2.7 expeditor testing [#9271](https://github.com/chef/chef/pull/9271) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix fuzzy node search to work when the search type is a string rather than a symbol [#9287](https://github.com/chef/chef/pull/9287) ([mimato](https://github.com/mimato))
- add bk testing against merge commit [#9296](https://github.com/chef/chef/pull/9296) ([lamont-granquist](https://github.com/lamont-granquist))
- Add windows_nt_version and powershell_version helpers to chef-utils [#9297](https://github.com/chef/chef/pull/9297) ([tas50](https://github.com/tas50))
- declare_resource.rb: consistently use `/x/y.txt` [#9273](https://github.com/chef/chef/pull/9273) ([michel-slm](https://github.com/michel-slm))
- revert to &quot;chef&quot; [#9300](https://github.com/chef/chef/pull/9300) ([bobchaos](https://github.com/bobchaos))
- Move knife-acl gem commands into chef in their own namespaces [#9292](https://github.com/chef/chef/pull/9292) ([tas50](https://github.com/tas50))
- Add cloud helpers from chef-sugar [#9302](https://github.com/chef/chef/pull/9302) ([lamont-granquist](https://github.com/lamont-granquist))
- chef-utils: add which/train_helpers/path_sanity to the DSL [#9303](https://github.com/chef/chef/pull/9303) ([lamont-granquist](https://github.com/lamont-granquist))
- Add chef-sugar include_recipe? helper [#9304](https://github.com/chef/chef/pull/9304) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump win32-service to 2.1.5 [#9301](https://github.com/chef/chef/pull/9301) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Fix wrong windows_firewall_rule specs which is passing :enable action which does not existurce does not have enable action so passing… [#9298](https://github.com/chef/chef/pull/9298) ([Vasu1105](https://github.com/Vasu1105))
- Adding entitlement for unsigned memory execution [#9317](https://github.com/chef/chef/pull/9317) ([jonsmorrow](https://github.com/jonsmorrow))
- mac_user: fixing gid and system properties, and adding hidden property [#9275](https://github.com/chef/chef/pull/9275) ([chilcote](https://github.com/chilcote))
- Add comment block to sysctl resource [#8409](https://github.com/chef/chef/pull/8409) ([lanky](https://github.com/lanky))
- Add an introduced field to sysctl and expand testing [#9321](https://github.com/chef/chef/pull/9321) ([tas50](https://github.com/tas50))
- Document the new hidden field in mac_user ships in 15.8 [#9322](https://github.com/chef/chef/pull/9322) ([tas50](https://github.com/tas50))
- Expand the chef-utils yard for better vscode plugin generation [#9326](https://github.com/chef/chef/pull/9326) ([tas50](https://github.com/tas50))
- Add chef-sugar virtualization helpers [#9315](https://github.com/chef/chef/pull/9315) ([lamont-granquist](https://github.com/lamont-granquist))
- Add some version string backcompat APIs [#9330](https://github.com/chef/chef/pull/9330) ([lamont-granquist](https://github.com/lamont-granquist))
- Add a default_description in windows_task [#9329](https://github.com/chef/chef/pull/9329) ([tas50](https://github.com/tas50))
- Swap the methods and the aliases in the chef-utils platforms [#9327](https://github.com/chef/chef/pull/9327) ([tas50](https://github.com/tas50))
- Pull the windows Ruby installer from S3 for tests [#9332](https://github.com/chef/chef/pull/9332) ([tas50](https://github.com/tas50))
- Update FFI and pin win32-service to 2.1.5+ [#9337](https://github.com/chef/chef/pull/9337) ([tas50](https://github.com/tas50))
- Add Debian 10 (Buster) Tester [#9341](https://github.com/chef/chef/pull/9341) ([christopher-snapp](https://github.com/christopher-snapp))
- Improve welcome text in chef-shell [#9342](https://github.com/chef/chef/pull/9342) ([tas50](https://github.com/tas50))
- Lazy load as many knife deps as possible [#9343](https://github.com/chef/chef/pull/9343) ([tas50](https://github.com/tas50))
- Expand the path in knife cookbook upload errors [#9344](https://github.com/chef/chef/pull/9344) ([tas50](https://github.com/tas50))
- Bump inspec-core to 4.18.85 [#9346](https://github.com/chef/chef/pull/9346) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Update docker? help comment to show it&#39;s since 12.11 [#9348](https://github.com/chef/chef/pull/9348) ([tas50](https://github.com/tas50))
- Add notify_group resource [#9349](https://github.com/chef/chef/pull/9349) ([lamont-granquist](https://github.com/lamont-granquist))
- update syntax of `update-rc.d` commands in enable &amp; disable actions [#8884](https://github.com/chef/chef/pull/8884) ([robuye](https://github.com/robuye))
- Add compile_time property to all resources [#9360](https://github.com/chef/chef/pull/9360) ([lamont-granquist](https://github.com/lamont-granquist))
- Allow setting file_cache_path and file_backup_path value in client.rb during bootstrap [#9361](https://github.com/chef/chef/pull/9361) ([kapilchouhan99](https://github.com/kapilchouhan99))
- Add missing require_relative in chef-utils [#9363](https://github.com/chef/chef/pull/9363) ([tas50](https://github.com/tas50))
- Bump all deps to the latest [#9365](https://github.com/chef/chef/pull/9365) ([tas50](https://github.com/tas50))
- Add chef_vault_secret resource from chef-vault cookbook [#9364](https://github.com/chef/chef/pull/9364) ([tas50](https://github.com/tas50))
- Add examples to various resources [#9366](https://github.com/chef/chef/pull/9366) ([tas50](https://github.com/tas50))
- windows_ad_join: Fix joining specific domains when domain trusts are involved [#9370](https://github.com/chef/chef/pull/9370) ([srb3](https://github.com/srb3))
- Use require_relative within the specs [#9375](https://github.com/chef/chef/pull/9375) ([tas50](https://github.com/tas50))
- Update libarchive to 3.4.2 and nokogiri to 1.10.8 [#9377](https://github.com/chef/chef/pull/9377) ([tas50](https://github.com/tas50))
- Relax the cheffish constraint [#9379](https://github.com/chef/chef/pull/9379) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix our verbosity help [#9385](https://github.com/chef/chef/pull/9385) ([tas50](https://github.com/tas50))
- Chefstyle fixes identified with Rubocop 0.80 [#9374](https://github.com/chef/chef/pull/9374) ([tas50](https://github.com/tas50))
- fix ruby 2.7 URI.unescape deprecation [#9387](https://github.com/chef/chef/pull/9387) ([lamont-granquist](https://github.com/lamont-granquist))
- Convert more resources to unified_mode [#9386](https://github.com/chef/chef/pull/9386) ([lamont-granquist](https://github.com/lamont-granquist))
- Update HTTPServerException to be HTTPClientException [#9381](https://github.com/chef/chef/pull/9381) ([tas50](https://github.com/tas50))
- Parse YAML recipes [#8653](https://github.com/chef/chef/pull/8653) ([lamont-granquist](https://github.com/lamont-granquist))
- Add distro constants to the bootstrap templates to support non-Chef distros [#9371](https://github.com/chef/chef/pull/9371) ([bobchaos](https://github.com/bobchaos))
- When bootstrapping don&#39;t send an empty run_list if we are using policyfiles instead [#9156](https://github.com/chef/chef/pull/9156) ([NAshwini](https://github.com/NAshwini))
- ChefFS &amp; knife environment matching the output [#8986](https://github.com/chef/chef/pull/8986) ([vsingh-msys](https://github.com/vsingh-msys))
- Bump inspec-core to 4.18.97 [#9388](https://github.com/chef/chef/pull/9388) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Dist windows powershell wrapper [#9065](https://github.com/chef/chef/pull/9065) ([bobchaos](https://github.com/bobchaos))
- More unified mode conversion and resource cleanup [#9393](https://github.com/chef/chef/pull/9393) ([lamont-granquist](https://github.com/lamont-granquist))
- Use the chef-utils helpers in our resources  [#9397](https://github.com/chef/chef/pull/9397) ([tas50](https://github.com/tas50))
- Convert the node[:platform_version] to a Chef::VersionString [#9400](https://github.com/chef/chef/pull/9400) ([lamont-granquist](https://github.com/lamont-granquist))
- Migrating windows_user_privilege resource from windows cookbook [#9279](https://github.com/chef/chef/pull/9279) ([Vasu1105](https://github.com/Vasu1105))
- Bump all deps to current [#9401](https://github.com/chef/chef/pull/9401) ([tas50](https://github.com/tas50))
- Update license_scout to 1.1.7 to resolve build failures [#9402](https://github.com/chef/chef/pull/9402) ([tas50](https://github.com/tas50))
- Cookstyle fixes for our resources [#9395](https://github.com/chef/chef/pull/9395) ([tas50](https://github.com/tas50))
- Accept exit code 3010 as valid in windows_package [#9396](https://github.com/chef/chef/pull/9396) ([tas50](https://github.com/tas50))
- Remove the &quot;Core&quot; DSL for Chef-16 [#9411](https://github.com/chef/chef/pull/9411) ([lamont-granquist](https://github.com/lamont-granquist))
- Update the rhsm_erata* and rhsm_register resources for RHEL 8 [#9409](https://github.com/chef/chef/pull/9409) ([tas50](https://github.com/tas50))
- Update Ohai to 16.0.7 [#9415](https://github.com/chef/chef/pull/9415) ([tas50](https://github.com/tas50))
- Remove all the code that checks for Windows Nano [#9417](https://github.com/chef/chef/pull/9417) ([tas50](https://github.com/tas50))
- Remove support for macOS &lt; 10.12 in the service resource [#9420](https://github.com/chef/chef/pull/9420) ([tas50](https://github.com/tas50))
- Deprecate supports_powershell_execution_bypass? check [#9418](https://github.com/chef/chef/pull/9418) ([tas50](https://github.com/tas50))
- directory resource: Remove support for macOS &lt; 10.11 [#9421](https://github.com/chef/chef/pull/9421) ([tas50](https://github.com/tas50))
- Don&#39;t require/include Mixin Shellout in freebsd_package and openbsd_package [#9423](https://github.com/chef/chef/pull/9423) ([tas50](https://github.com/tas50))
- Deprecate the older_than_win_2012_or_8? helper [#9424](https://github.com/chef/chef/pull/9424) ([tas50](https://github.com/tas50))
- Update gcc pinning for solaris to 5.4.0 [#9430](https://github.com/chef/chef/pull/9430) ([jaymalasinha](https://github.com/jaymalasinha))
- Fix gsub so only file endings of .rb and .json are removed. [#9429](https://github.com/chef/chef/pull/9429) ([joerg](https://github.com/joerg))
- Remove constraints on specs [#9428](https://github.com/chef/chef/pull/9428) ([tas50](https://github.com/tas50))
- Remove the last bits of Appveyor from the specs [#9427](https://github.com/chef/chef/pull/9427) ([tas50](https://github.com/tas50))
- More removal of Windows 2008 R2 support from windows_feature_powershell [#9426](https://github.com/chef/chef/pull/9426) ([tas50](https://github.com/tas50))
- Remove the mixin powershell includes from resources [#9425](https://github.com/chef/chef/pull/9425) ([tas50](https://github.com/tas50))
- Deprecate Chef::Platform.supports_msi? [#9422](https://github.com/chef/chef/pull/9422) ([tas50](https://github.com/tas50))
- Bump train-core to 3.2.23 [#9432](https://github.com/chef/chef/pull/9432) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Replace highline.color with pastel.decorate [#9434](https://github.com/chef/chef/pull/9434) ([btm](https://github.com/btm))
- Use the action DSL consistently [#9433](https://github.com/chef/chef/pull/9433) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix file descriptor leak in our tests [#9449](https://github.com/chef/chef/pull/9449) ([lamont-granquist](https://github.com/lamont-granquist))
- Ruby 2.7 omnibus builds [#9454](https://github.com/chef/chef/pull/9454) ([lamont-granquist](https://github.com/lamont-granquist))
- Add windows_security_policy resource [#9280](https://github.com/chef/chef/pull/9280) ([NAshwini](https://github.com/NAshwini))
- Update all our links to use the new docs site format / cleanup descriptions [#9445](https://github.com/chef/chef/pull/9445) ([tas50](https://github.com/tas50))
- timezone: Remove support for ubuntu &lt; 16.04 / Debian &lt; 8 [#9452](https://github.com/chef/chef/pull/9452) ([tas50](https://github.com/tas50))
- Remove the canonical DSL [#9441](https://github.com/chef/chef/pull/9441) ([lamont-granquist](https://github.com/lamont-granquist))
- link resource: Remove checks for symoblic link support on Windows [#9455](https://github.com/chef/chef/pull/9455) ([tas50](https://github.com/tas50))
- Test on Ubuntu 20.04 in Buildkite [#9458](https://github.com/chef/chef/pull/9458) ([tas50](https://github.com/tas50))
- Disable failing windows tests while we troubleshoot [#9459](https://github.com/chef/chef/pull/9459) ([tas50](https://github.com/tas50))
- Update Ohai to 16.0.9 [#9461](https://github.com/chef/chef/pull/9461) ([tas50](https://github.com/tas50))
- Use Ohai&#39;s cloud attributes in knife node / status presenters [#9460](https://github.com/chef/chef/pull/9460) ([tas50](https://github.com/tas50))
- Stop installing packages on our constainers that are already there [#9465](https://github.com/chef/chef/pull/9465) ([tas50](https://github.com/tas50))
- Fix windows_certificate functional tests under buildkite [#9467](https://github.com/chef/chef/pull/9467) ([kapilchouhan99](https://github.com/kapilchouhan99))
- Pin to Rake 13.0.1 to prevent double rake [#9464](https://github.com/chef/chef/pull/9464) ([tas50](https://github.com/tas50))
- Use the aws cli to download ruby in the windows tests [#9468](https://github.com/chef/chef/pull/9468) ([tas50](https://github.com/tas50))
- Remove support in debian service init for old update-rc [#9453](https://github.com/chef/chef/pull/9453) ([tas50](https://github.com/tas50))
- Update Fauxhai to 8.0 [#9471](https://github.com/chef/chef/pull/9471) ([tas50](https://github.com/tas50))
- Fix require breaking windows functional tests in BK [#9472](https://github.com/chef/chef/pull/9472) ([phiggins](https://github.com/phiggins))
- Expose equal_to values in property / chef-resource-inspector [#9444](https://github.com/chef/chef/pull/9444) ([tas50](https://github.com/tas50))
- Add the chef-vault helpers from the chef-vault cookbook [#9477](https://github.com/chef/chef/pull/9477) ([tas50](https://github.com/tas50))
- Bring in the extended Ruby cleanup used in chef-workstation [#9478](https://github.com/chef/chef/pull/9478) ([tas50](https://github.com/tas50))
- Fix load path in test runs. [#9479](https://github.com/chef/chef/pull/9479) ([phiggins](https://github.com/phiggins))
- Add always_dump_stacktrace config option &amp; workaround to fix the encoding bugs [#9474](https://github.com/chef/chef/pull/9474) ([lamont-granquist](https://github.com/lamont-granquist))
- Update all deps to current [#9483](https://github.com/chef/chef/pull/9483) ([tas50](https://github.com/tas50))
- Add alternatives resource for Linux [#9481](https://github.com/chef/chef/pull/9481) ([tas50](https://github.com/tas50))
- Remove some of the ruby cleanup to fix builds [#9486](https://github.com/chef/chef/pull/9486) ([tas50](https://github.com/tas50))
- Fix typo in the cron_access docs [#9485](https://github.com/chef/chef/pull/9485) ([tas50](https://github.com/tas50))
- Update Ohai to 16.0.12 [#9488](https://github.com/chef/chef/pull/9488) ([tas50](https://github.com/tas50))
- Remove additional files from the gems in our builds [#9489](https://github.com/chef/chef/pull/9489) ([tas50](https://github.com/tas50))
- Use Dist constants in resource erb templates [#9491](https://github.com/chef/chef/pull/9491) ([bobchaos](https://github.com/bobchaos))
- Cleanup a bunch more files and pull in the smaller license-acceptance [#9490](https://github.com/chef/chef/pull/9490) ([tas50](https://github.com/tas50))
- Add user_ulimit resource from the ulimit cookbook [#9487](https://github.com/chef/chef/pull/9487) ([tas50](https://github.com/tas50))
- Turn off notifications from log resource by default [#9484](https://github.com/chef/chef/pull/9484) ([lamont-granquist](https://github.com/lamont-granquist))
- Pull in many of Zenspider&#39;s rspec improvements [#9493](https://github.com/chef/chef/pull/9493) ([tas50](https://github.com/tas50))
- Use the correct constant in the resource support files [#9506](https://github.com/chef/chef/pull/9506) ([tas50](https://github.com/tas50))
- add group to windows_firewall_rule resource [#8729](https://github.com/chef/chef/pull/8729) ([pschaumburg](https://github.com/pschaumburg))
- powershell_package: Use ohai data to get the powershell release instead of shelling out [#9492](https://github.com/chef/chef/pull/9492) ([sanga1794](https://github.com/sanga1794))
- Refresh DNF package provider and add aarch el8 testing support [#9500](https://github.com/chef/chef/pull/9500) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix windows_firewall_rule resource for rules with multiple profiles [#9511](https://github.com/chef/chef/pull/9511) ([tecracer-theinen](https://github.com/tecracer-theinen))
- extend windows_firewall_rule abilities with displayname and description [#9514](https://github.com/chef/chef/pull/9514) ([pschaumburg](https://github.com/pschaumburg))
- Bump train-core to 3.2.26 [#9515](https://github.com/chef/chef/pull/9515) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Fix loading the template file in the user_ulimit resource [#9516](https://github.com/chef/chef/pull/9516) ([tas50](https://github.com/tas50))
- Add support for parsing YAML recipes with chef-apply [#9507](https://github.com/chef/chef/pull/9507) ([btm](https://github.com/btm))
- Move cron_d validation methods to a helper and use that in the cron resource [#9522](https://github.com/chef/chef/pull/9522) ([tas50](https://github.com/tas50))
- Add chef_client_cron resource from chef-client cookbook [#9518](https://github.com/chef/chef/pull/9518) ([tas50](https://github.com/tas50))
- clean up chef_client_cron [#9527](https://github.com/chef/chef/pull/9527) ([lamont-granquist](https://github.com/lamont-granquist))
- Add : https_for_ca_consumer property to rhsm_register resource [#9525](https://github.com/chef/chef/pull/9525) ([jasonwbarnett](https://github.com/jasonwbarnett))
- Add chef_client_windows_task resource from chef-client cookbook [#9528](https://github.com/chef/chef/pull/9528) ([tas50](https://github.com/tas50))
- Switch to RUBY_PLATFORM for the windows check [#9531](https://github.com/chef/chef/pull/9531) ([tas50](https://github.com/tas50))
- Add missing introduced value to the new property in rhsm_register [#9534](https://github.com/chef/chef/pull/9534) ([tas50](https://github.com/tas50))
- Add a `knife yaml convert` tool [#9508](https://github.com/chef/chef/pull/9508) ([btm](https://github.com/btm))
- Improve chef_client_* resources [#9540](https://github.com/chef/chef/pull/9540) ([tas50](https://github.com/tas50))
- Fixed windows share cannot modify frozen string bug [#9524](https://github.com/chef/chef/pull/9524) ([sanga1794](https://github.com/sanga1794))
- Fix unintuitive behavior of sources on gem resources [#9480](https://github.com/chef/chef/pull/9480) ([phiggins](https://github.com/phiggins))
- Skip the ifconfig functional tests if we don&#39;t have ifconfig [#9549](https://github.com/chef/chef/pull/9549) ([tas50](https://github.com/tas50))
- Add Ubuntu 20.04 (x86_64) Tester [#9523](https://github.com/chef/chef/pull/9523) ([christopher-snapp](https://github.com/christopher-snapp))
- Remove SLES 11 support from build_essential [#9551](https://github.com/chef/chef/pull/9551) ([tas50](https://github.com/tas50))
- build_essential resource: fix macOS 10.15 and improve installation support with a new :upgrade action for macOS [#9550](https://github.com/chef/chef/pull/9550) ([tas50](https://github.com/tas50))
- Simplify the matching code per code review [#9552](https://github.com/chef/chef/pull/9552) ([tas50](https://github.com/tas50))
- Fix cloud? helper to only report true on cloud instances [#9553](https://github.com/chef/chef/pull/9553) ([tas50](https://github.com/tas50))
- Fix functional tests on Windows 10 by matching less [#9563](https://github.com/chef/chef/pull/9563) ([btm](https://github.com/btm))
- Add Windows 10 Tester [#9564](https://github.com/chef/chef/pull/9564) ([tas50](https://github.com/tas50))
- Make the hab version check a full version check not just minor release [#9565](https://github.com/chef/chef/pull/9565) ([TheLunaticScripter](https://github.com/TheLunaticScripter))
- Stop building S390x packages [#9568](https://github.com/chef/chef/pull/9568) ([tas50](https://github.com/tas50))
- Update Ruby to 2.7.1 / bundler to 2.1.4 [#9569](https://github.com/chef/chef/pull/9569) ([tas50](https://github.com/tas50))
- Update Nokogiri to 1.11.0.rc2 [#9572](https://github.com/chef/chef/pull/9572) ([tas50](https://github.com/tas50))
- Convert more resources to unified_mode [#9570](https://github.com/chef/chef/pull/9570) ([lamont-granquist](https://github.com/lamont-granquist))
- Add after_resource to pair with current_resource [#9562](https://github.com/chef/chef/pull/9562) ([lamont-granquist](https://github.com/lamont-granquist))
- fix chef_vault_secret after_resource breakage [#9574](https://github.com/chef/chef/pull/9574) ([lamont-granquist](https://github.com/lamont-granquist))
- Add Ubuntu 20.04 x86_64 and Ubuntu 18.04 aarch64 testers [#9584](https://github.com/chef/chef/pull/9584) ([tas50](https://github.com/tas50))
- Change the name_property to be the identity property by default, and to have desired_state: false by default [#9581](https://github.com/chef/chef/pull/9581) ([lamont-granquist](https://github.com/lamont-granquist))
- Dist windows bootstrap template - fix msi_url [#9596](https://github.com/chef/chef/pull/9596) ([bobchaos](https://github.com/bobchaos))
- Implement eager_load_libraries metadata option [#9593](https://github.com/chef/chef/pull/9593) ([lamont-granquist](https://github.com/lamont-granquist))
- Use $env:temp instead of c:/ for functional tests [#9591](https://github.com/chef/chef/pull/9591) ([btm](https://github.com/btm))
- windows_firewall_rule: Fix idempotency and add icmp_type property [#9544](https://github.com/chef/chef/pull/9544) ([pschaumburg](https://github.com/pschaumburg))
- Updated introduced version for start_when_available option [#9602](https://github.com/chef/chef/pull/9602) ([Vasu1105](https://github.com/Vasu1105))
-  Improved Ruby download/install for functional tests [#9603](https://github.com/chef/chef/pull/9603) ([btm](https://github.com/btm))
- Really skip the reboot pending func test if a reboot is pending [#9611](https://github.com/chef/chef/pull/9611) ([btm](https://github.com/btm))
- Bump mixlib-cli to 2.1.6 [#9615](https://github.com/chef/chef/pull/9615) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Spell checking in comments and log messages [#9609](https://github.com/chef/chef/pull/9609) ([vsingh-msys](https://github.com/vsingh-msys))
- Cache gems in the verify pipeline to speed up tests [#9607](https://github.com/chef/chef/pull/9607) ([tas50](https://github.com/tas50))
- Bump inspec-core to 4.18.104 [#9625](https://github.com/chef/chef/pull/9625) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Fixed systemd_unit not respecting sensitive property [#9623](https://github.com/chef/chef/pull/9623) ([sanga1794](https://github.com/sanga1794))
- Bump train-core to 3.2.27 [#9628](https://github.com/chef/chef/pull/9628) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Add arm? helper to chef-utils [#9622](https://github.com/chef/chef/pull/9622) ([tas50](https://github.com/tas50))
- Bump highline to 2.x [#9633](https://github.com/chef/chef/pull/9633) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix knife bootstrap_version CLI option overriding config option [#9634](https://github.com/chef/chef/pull/9634) ([lamont-granquist](https://github.com/lamont-granquist))
- Add chef_client_systemd_timer resource [#9624](https://github.com/chef/chef/pull/9624) ([tas50](https://github.com/tas50))
- Add Amazon Linux 2 Testers [#9641](https://github.com/chef/chef/pull/9641) ([christopher-snapp](https://github.com/christopher-snapp))
- Add resource partials [#9632](https://github.com/chef/chef/pull/9632) ([lamont-granquist](https://github.com/lamont-granquist))
- Support non-Linux hosts in chef_client_cron [#9647](https://github.com/chef/chef/pull/9647) ([tas50](https://github.com/tas50))
- Add the plist resource from the macos cookbook [#9642](https://github.com/chef/chef/pull/9642) ([tas50](https://github.com/tas50))
- Remove support for SLES11 and update tests to just on openSUSE [#9299](https://github.com/chef/chef/pull/9299) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Fixes for sudo password prompt [#9635](https://github.com/chef/chef/pull/9635) ([vsingh-msys](https://github.com/vsingh-msys))
- Require at least trainc-core 3.2.28 to resolve our sudo bootstrap issues [#9654](https://github.com/chef/chef/pull/9654) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Use the correct plist class in the mac user provider [#9655](https://github.com/chef/chef/pull/9655) ([tas50](https://github.com/tas50))
- Remove copyright dates [#9656](https://github.com/chef/chef/pull/9656) ([lamont-granquist](https://github.com/lamont-granquist))
- Update license scout to fix broken windows builds [#9657](https://github.com/chef/chef/pull/9657) ([tas50](https://github.com/tas50))
- Updates to timeout properties in various resources [#9659](https://github.com/chef/chef/pull/9659) ([tas50](https://github.com/tas50))
- Replace a few uses of attributes / parameters in messaging with properties [#9664](https://github.com/chef/chef/pull/9664) ([tas50](https://github.com/tas50))
- Fix to use correct Amazon Linux 2 queues [#9662](https://github.com/chef/chef/pull/9662) ([christopher-snapp](https://github.com/christopher-snapp))
- msu_package: Fix cumulative updates installation and provide a 3600s default timeout [#9649](https://github.com/chef/chef/pull/9649) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Add a warning to the end of the chef run for EOL releses [#9666](https://github.com/chef/chef/pull/9666) ([tas50](https://github.com/tas50))
- msu_package: Removal also requires passing timeout property [#9676](https://github.com/chef/chef/pull/9676) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Ruby 2.7 fix for powershell_out [#9679](https://github.com/chef/chef/pull/9679) ([lamont-granquist](https://github.com/lamont-granquist))
- Merge ohai resource / provider into a single resource [#9681](https://github.com/chef/chef/pull/9681) ([tas50](https://github.com/tas50))
- Fix platform_version Chef::VersionString API [#9682](https://github.com/chef/chef/pull/9682) ([lamont-granquist](https://github.com/lamont-granquist))
- Knife bootstrap options cleanup [#9646](https://github.com/chef/chef/pull/9646) ([lamont-granquist](https://github.com/lamont-granquist))
- Update Ohai to 16.0.18 for Windows DMI plugin [#9687](https://github.com/chef/chef/pull/9687) ([tas50](https://github.com/tas50))
- Force requiring properties [#9688](https://github.com/chef/chef/pull/9688) ([lamont-granquist](https://github.com/lamont-granquist))
- Add multipackage support to homebrew [#7982](https://github.com/chef/chef/pull/7982) ([tas50](https://github.com/tas50))
- Remove &quot;Code Can&quot; from dmg background [#9690](https://github.com/chef/chef/pull/9690) ([tas50](https://github.com/tas50))
- [CHORE] with_clean_env is deprecated [#9692](https://github.com/chef/chef/pull/9692) ([damacus](https://github.com/damacus))
- Bump ruby for windows to 2.7 [#9693](https://github.com/chef/chef/pull/9693) ([TheLunaticScripter](https://github.com/TheLunaticScripter))
- Remove a few additional files from our builds [#9689](https://github.com/chef/chef/pull/9689) ([tas50](https://github.com/tas50))
- git resource: Fix for exceptions raised in why-run mode [#9627](https://github.com/chef/chef/pull/9627) ([kapilchouhan99](https://github.com/kapilchouhan99))
- Add multipackage support to pacman package resource [#9694](https://github.com/chef/chef/pull/9694) ([tas50](https://github.com/tas50))
- Remove deprecated Chef-10 constraint handling [#9663](https://github.com/chef/chef/pull/9663) ([damacus](https://github.com/damacus))
- Move some of the ruby-cleanup logic into omnibus-software [#9696](https://github.com/chef/chef/pull/9696) ([tas50](https://github.com/tas50))
- Bump Chefstyle to 1.0.3 and Ohai to 16.0.19 [#9697](https://github.com/chef/chef/pull/9697) ([tas50](https://github.com/tas50))
- Bump omnibus-software to avoid double pry [#9700](https://github.com/chef/chef/pull/9700) ([tas50](https://github.com/tas50))
- Remove the unused simplecov depedency [#9699](https://github.com/chef/chef/pull/9699) ([tas50](https://github.com/tas50))
- Update omnibus-software again to bring in double pry fixes [#9704](https://github.com/chef/chef/pull/9704) ([tas50](https://github.com/tas50))
- Add Ubuntu 20.04 + SLES 15 aarch64 Testers [#9712](https://github.com/chef/chef/pull/9712) ([christopher-snapp](https://github.com/christopher-snapp))
- Use the new Chef definition w/o appbundler [#9710](https://github.com/chef/chef/pull/9710) ([tas50](https://github.com/tas50))
- Fix for Chocolate_resource options causing extra quotes [#9509](https://github.com/chef/chef/pull/9509) ([kapilchouhan99](https://github.com/kapilchouhan99))
- Make sure all the non-multipackage packge resources can&#39;t take arrays [#9721](https://github.com/chef/chef/pull/9721) ([tas50](https://github.com/tas50))
- Enable caching of all our buildkite jobs again [#9672](https://github.com/chef/chef/pull/9672) ([tas50](https://github.com/tas50))
- Minor improvements to the resource descriptions [#9725](https://github.com/chef/chef/pull/9725) ([tas50](https://github.com/tas50))
- Refactor scm, git and subversion resources &amp; fix longstanding git issues [#9726](https://github.com/chef/chef/pull/9726) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix linux plan to use ruby 2.7 [#9728](https://github.com/chef/chef/pull/9728) ([TheLunaticScripter](https://github.com/TheLunaticScripter))
- Set timeouts in service and windows_service correctly [#9729](https://github.com/chef/chef/pull/9729) ([tas50](https://github.com/tas50))
- Allow Arrays in msu_package version again [#9730](https://github.com/chef/chef/pull/9730) ([tas50](https://github.com/tas50))
- Resolve deprecations in chef-utils specs [#9731](https://github.com/chef/chef/pull/9731) ([tas50](https://github.com/tas50))
- locale: Support setting locale on Windows [#9648](https://github.com/chef/chef/pull/9648) ([kapilchouhan99](https://github.com/kapilchouhan99))
- Use our fork of docker-api in the kitchen tests [#9733](https://github.com/chef/chef/pull/9733) ([tas50](https://github.com/tas50))
- Update Ohai to 16.0.20 [#9734](https://github.com/chef/chef/pull/9734) ([tas50](https://github.com/tas50))
- Run Test Kitchen tests on Ruby 2.7 [#9737](https://github.com/chef/chef/pull/9737) ([tas50](https://github.com/tas50))
- Test and better document the locale resource [#9736](https://github.com/chef/chef/pull/9736) ([tas50](https://github.com/tas50))
- Remove the Windows version check in windows_share [#9741](https://github.com/chef/chef/pull/9741) ([tas50](https://github.com/tas50))
- Bump inspec-core-bin to 4.18.108 [#9743](https://github.com/chef/chef/pull/9743) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Add powershell_exec! helper to make conversion from powershell_out! easier [#9742](https://github.com/chef/chef/pull/9742) ([tas50](https://github.com/tas50))
- Update bcrypt_pbkdf to 1.1.0.rc1 [#9749](https://github.com/chef/chef/pull/9749) ([marcparadise](https://github.com/marcparadise))
- Disable the windows_exec test for now [#9753](https://github.com/chef/chef/pull/9753) ([tas50](https://github.com/tas50))
- Updates for auto generated docs [#9750](https://github.com/chef/chef/pull/9750) ([phiggins](https://github.com/phiggins))
- Remove git func test for upstream [#9757](https://github.com/chef/chef/pull/9757) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix the powershell spec to use the right method [#9756](https://github.com/chef/chef/pull/9756) ([tas50](https://github.com/tas50))
- Rework logging to resolve STDOUT / log_location issues [#9751](https://github.com/chef/chef/pull/9751) ([lamont-granquist](https://github.com/lamont-granquist))
- Stop pinning rake [#9744](https://github.com/chef/chef/pull/9744) ([tas50](https://github.com/tas50))

## [v15.6.10](https://github.com/chef/chef/tree/v15.6.10) (2019-12-12)

#### Merged Pull Requests
- Spelling, punctuation, grammar [#9122](https://github.com/chef/chef/pull/9122) ([ehershey](https://github.com/ehershey))
- restoring correct value to windows event source [#9117](https://github.com/chef/chef/pull/9117) ([bobchaos](https://github.com/bobchaos))
- [yum_repository] Add indentation for multiple baseurls [#9134](https://github.com/chef/chef/pull/9134) ([bugok](https://github.com/bugok))
- Tiny spelling typo and grammar [#9135](https://github.com/chef/chef/pull/9135) ([ehershey](https://github.com/ehershey))
- Resolve non-zero &quot;success&quot; error code issues with linux_user re… [#9105](https://github.com/chef/chef/pull/9105) ([skippyj](https://github.com/skippyj))
- Bump omnibus-software to remove libtool+pkg-config [#9136](https://github.com/chef/chef/pull/9136) ([lamont-granquist](https://github.com/lamont-granquist))
- Update Ohai and pull in Ruby perf improvements [#9137](https://github.com/chef/chef/pull/9137) ([tas50](https://github.com/tas50))
- Bump Omnibus to the latest [#9138](https://github.com/chef/chef/pull/9138) ([tas50](https://github.com/tas50))
- Update omnnibus-software to add further ruby cleanup [#9141](https://github.com/chef/chef/pull/9141) ([tas50](https://github.com/tas50))
- Update ruby_prof to 1.0 [#9130](https://github.com/chef/chef/pull/9130) ([tas50](https://github.com/tas50))
- bump omnibus-software + rhel6 fix [#9145](https://github.com/chef/chef/pull/9145) ([lamont-granquist](https://github.com/lamont-granquist))
- Specify item path in Node.read! error message [#9147](https://github.com/chef/chef/pull/9147) ([zeusttu](https://github.com/zeusttu))
- Symbolize config for ssl_verify_mode in credentials [#9064](https://github.com/chef/chef/pull/9064) ([teknofire](https://github.com/teknofire))
- Replace hardcoded /etc/chef with Chef::Dist::CONF_DIR [#9060](https://github.com/chef/chef/pull/9060) ([bobchaos](https://github.com/bobchaos))
- Fix for ChefConfig should expand relative paths [#9042](https://github.com/chef/chef/pull/9042) ([kapilchouhan99](https://github.com/kapilchouhan99))
- Fix apt_repository uri single/double quotes and spaces [#9036](https://github.com/chef/chef/pull/9036) ([vsingh-msys](https://github.com/vsingh-msys))
- Add output for the file provider verification [#9039](https://github.com/chef/chef/pull/9039) ([lamont-granquist](https://github.com/lamont-granquist))
- Add a new distro constant for chef-apply [#9149](https://github.com/chef/chef/pull/9149) ([bobchaos](https://github.com/bobchaos))
- Remove duplicate constant for Chef::Dist::SHORT [#9150](https://github.com/chef/chef/pull/9150) ([bobchaos](https://github.com/bobchaos))
- Bump ohai to 15.6.3 [#9152](https://github.com/chef/chef/pull/9152) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))

## [v15.5.17](https://github.com/chef/chef/tree/v15.5.17) (2019-11-21)

## [v15.5.16](https://github.com/chef/chef/tree/v15.5.16) (2019-11-21)

#### Merged Pull Requests
- Require relative in the win32-eventlog rakefile [#9116](https://github.com/chef/chef/pull/9116) ([tas50](https://github.com/tas50))

## [v15.5.15](https://github.com/chef/chef/tree/v15.5.15) (2019-11-19)

#### Merged Pull Requests
- Improve input validation on windows_package [#9102](https://github.com/chef/chef/pull/9102) ([tas50](https://github.com/tas50))
- Don&#39;t ship the extra rake tasks in the gem [#9104](https://github.com/chef/chef/pull/9104) ([tas50](https://github.com/tas50))
- Convert reboot resource to a custom resource with descriptions [#7239](https://github.com/chef/chef/pull/7239) ([tas50](https://github.com/tas50))
- Remove bonus `.md` to fix link [#9110](https://github.com/chef/chef/pull/9110) ([btm](https://github.com/btm))
- Fix failures in build_essential on rhel platforms [#9111](https://github.com/chef/chef/pull/9111) ([lamont-granquist](https://github.com/lamont-granquist))
- fix enforce_path_sanity being set to true [#9114](https://github.com/chef/chef/pull/9114) ([lamont-granquist](https://github.com/lamont-granquist))

## [v15.5.9](https://github.com/chef/chef/tree/v15.5.9) (2019-11-15)

#### Merged Pull Requests
- Sync over resource documentation from the docs site [#8999](https://github.com/chef/chef/pull/8999) ([tas50](https://github.com/tas50))
- Update maintainers link in CONTRIBUTING.md [#9012](https://github.com/chef/chef/pull/9012) ([vsingh-msys](https://github.com/vsingh-msys))
- correct typos in license headers [#9016](https://github.com/chef/chef/pull/9016) ([pombredanne](https://github.com/pombredanne))
- Fix knife node show non-existent attributes [#9025](https://github.com/chef/chef/pull/9025) ([vsingh-msys](https://github.com/vsingh-msys))
- Validate format option values using `in` attribute [#9026](https://github.com/chef/chef/pull/9026) ([vsingh-msys](https://github.com/vsingh-msys))
- knife ssh: Fix Exception: NoMethodError: undefined method join for nil:NilClass [#9028](https://github.com/chef/chef/pull/9028) ([vsingh-msys](https://github.com/vsingh-msys))
- [Data-collector] Add cookbooks attribute to run_end_message [#8893](https://github.com/chef/chef/pull/8893) ([vsingh-msys](https://github.com/vsingh-msys))
- Fix license acceptance in `omnibus/kitchen.yml` [#9030](https://github.com/chef/chef/pull/9030) ([christopher-snapp](https://github.com/christopher-snapp))
- Fix knife cookbook metadata from file name args [#9032](https://github.com/chef/chef/pull/9032) ([vsingh-msys](https://github.com/vsingh-msys))
- Turn on unified_mode for 35 core resources [#9034](https://github.com/chef/chef/pull/9034) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump all deps to the latest versions [#9037](https://github.com/chef/chef/pull/9037) ([tas50](https://github.com/tas50))
- Allow for the mixlib-authentication 3.x gem [#9040](https://github.com/chef/chef/pull/9040) ([tas50](https://github.com/tas50))
- Fix multiple chefignore file issues [#8925](https://github.com/chef/chef/pull/8925) ([vsingh-msys](https://github.com/vsingh-msys))
- a Windows Habitat plan [#8900](https://github.com/chef/chef/pull/8900) ([robbkidd](https://github.com/robbkidd))
- Bump omnibus to 6.1.10 [#9048](https://github.com/chef/chef/pull/9048) ([btm](https://github.com/btm))
- [knife config get] Fix TypeError: no implicit conversion of nil into String [#9049](https://github.com/chef/chef/pull/9049) ([vsingh-msys](https://github.com/vsingh-msys))
- Update omnibus [#9050](https://github.com/chef/chef/pull/9050) ([jaymalasinha](https://github.com/jaymalasinha))
- systemd_unit needs to log [#9046](https://github.com/chef/chef/pull/9046) ([jaymzh](https://github.com/jaymzh))
- Update lixml2, libxslt, and nokogiri to the latest [#9054](https://github.com/chef/chef/pull/9054) ([tas50](https://github.com/tas50))
- Updates for Chefstyle with Rubocop 0.75.1 [#9055](https://github.com/chef/chef/pull/9055) ([tas50](https://github.com/tas50))
- service/systemd_unit: Don&#39;t try to reenable services in an indirect status [#9047](https://github.com/chef/chef/pull/9047) ([jaymzh](https://github.com/jaymzh))
- dist constants in win logs [#9058](https://github.com/chef/chef/pull/9058) ([bobchaos](https://github.com/bobchaos))
- Remove useless search arg mangling [#9070](https://github.com/chef/chef/pull/9070) ([lamont-granquist](https://github.com/lamont-granquist))
- fix the habitat package promotion tests [#9061](https://github.com/chef/chef/pull/9061) ([robbkidd](https://github.com/robbkidd))
- Add chef-utils gem with various recipe DSL helpers [#8922](https://github.com/chef/chef/pull/8922) ([lamont-granquist](https://github.com/lamont-granquist))
- 🚧 WIP: remove Oracle 8 from TK tests run in CI [#9074](https://github.com/chef/chef/pull/9074) ([robbkidd](https://github.com/robbkidd))
- Add new chef_sleep resource [#9081](https://github.com/chef/chef/pull/9081) ([tas50](https://github.com/tas50))
- rename windows_ruby_platform? to windows_ruby? [#9085](https://github.com/chef/chef/pull/9085) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix action collection nilclass error early in runs [#9083](https://github.com/chef/chef/pull/9083) ([lamont-granquist](https://github.com/lamont-granquist))
- reserve a number for chef-sugar deprecation warnings [#9086](https://github.com/chef/chef/pull/9086) ([lamont-granquist](https://github.com/lamont-granquist))
- Switch our tests back to chef-sugar [#9084](https://github.com/chef/chef/pull/9084) ([tas50](https://github.com/tas50))
- Bump all deps to current [#9087](https://github.com/chef/chef/pull/9087) ([tas50](https://github.com/tas50))
- [knife list] Validate name argument &amp; raise error if no args provided [#9059](https://github.com/chef/chef/pull/9059) ([vsingh-msys](https://github.com/vsingh-msys))
- Remove the use of Chef Sugar from the Kitchen tests [#9088](https://github.com/chef/chef/pull/9088) ([tas50](https://github.com/tas50))
- Revert &quot;Validate name argument for knife list&quot; [#9090](https://github.com/chef/chef/pull/9090) ([tas50](https://github.com/tas50))
- Update all deps to the latest including omnibus-software with faster Ruby [#9091](https://github.com/chef/chef/pull/9091) ([tas50](https://github.com/tas50))
- Support multiple profiles in windows_firewall_rule [#8916](https://github.com/chef/chef/pull/8916) ([Happycoil](https://github.com/Happycoil))
- Additional chef-utils helpers for rhel6/7/8 [#9095](https://github.com/chef/chef/pull/9095) ([lamont-granquist](https://github.com/lamont-granquist))
- Update InSpec to 4.18 [#9096](https://github.com/chef/chef/pull/9096) ([tas50](https://github.com/tas50))
- Reorder the helper docs and expand platforms and descriptions [#9092](https://github.com/chef/chef/pull/9092) ([tas50](https://github.com/tas50))
- Bump inspec-core-bin to 4.18.39 [#9098](https://github.com/chef/chef/pull/9098) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Improve resource descriptions and the rake task for docs generation [#9097](https://github.com/chef/chef/pull/9097) ([tas50](https://github.com/tas50))
- Add Chef Infra Client 15.5. release notes [#9089](https://github.com/chef/chef/pull/9089) ([tas50](https://github.com/tas50))

## [v15.4.45](https://github.com/chef/chef/tree/v15.4.45) (2019-10-15)

#### Merged Pull Requests
- Revert &quot;Drop privileges before creating files in solo mode&quot; [#8880](https://github.com/chef/chef/pull/8880) ([lamont-granquist](https://github.com/lamont-granquist))
- Add more resource examples to the codebase [#8868](https://github.com/chef/chef/pull/8868) ([tas50](https://github.com/tas50))
- Fix for chocolatey_package fails using extra options [#8765](https://github.com/chef/chef/pull/8765) ([kapilchouhan99](https://github.com/kapilchouhan99))
- bump gems [#8907](https://github.com/chef/chef/pull/8907) ([lamont-granquist](https://github.com/lamont-granquist))
- Add empty chefcli config_context to fix commands with chefcli in knife.rb [#8911](https://github.com/chef/chef/pull/8911) ([coding-blip](https://github.com/coding-blip))
- fix converge_if_changed to compare default values [#8912](https://github.com/chef/chef/pull/8912) ([lamont-granquist](https://github.com/lamont-granquist))
- Require train-winrm &gt;= 0.2.5 [#8914](https://github.com/chef/chef/pull/8914) ([tas50](https://github.com/tas50))
- [Resource::remote_file] Fix show_progress in remote_file is cau… [#8904](https://github.com/chef/chef/pull/8904) ([vsingh-msys](https://github.com/vsingh-msys))
- [knife ssh] Fix interactive mode exit error [#8917](https://github.com/chef/chef/pull/8917) ([vsingh-msys](https://github.com/vsingh-msys))
- Updated package license for macos and windows. [#8910](https://github.com/chef/chef/pull/8910) ([samshinde](https://github.com/samshinde))
- Fix some places where constants from dist.rb were not used. [#8921](https://github.com/chef/chef/pull/8921) ([Tensibai](https://github.com/Tensibai))
- Enable Windows Buildkite verification on default image Windows… [#8882](https://github.com/chef/chef/pull/8882) ([jaymalasinha](https://github.com/jaymalasinha))
- Bump inspec-core to 4.17.7 [#8923](https://github.com/chef/chef/pull/8923) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Add #to_yaml method for ImmutableMash &amp; ImmutableArray [#8927](https://github.com/chef/chef/pull/8927) ([vsingh-msys](https://github.com/vsingh-msys))
- Update inspec to 4.17.11 and cleanup buildkite testing a bit [#8930](https://github.com/chef/chef/pull/8930) ([tas50](https://github.com/tas50))
- Bump inspec-core to 4.17.14 [#8932](https://github.com/chef/chef/pull/8932) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Swap test gem install of fpm for chef-ruby-lvm [#8934](https://github.com/chef/chef/pull/8934) ([tas50](https://github.com/tas50))
- Bump inspec-core-bin to 4.17.15 [#8936](https://github.com/chef/chef/pull/8936) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Bump inspec-core to 4.17.15 [#8935](https://github.com/chef/chef/pull/8935) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Add testing in Buildkite for Oracle Linux 6/7/8 [#8937](https://github.com/chef/chef/pull/8937) ([tas50](https://github.com/tas50))
- bump omnibus gems [#8938](https://github.com/chef/chef/pull/8938) ([lamont-granquist](https://github.com/lamont-granquist))
- Update openSUSE testing in Buildkite [#8931](https://github.com/chef/chef/pull/8931) ([tas50](https://github.com/tas50))
- Removing sh -c wrapper around the bootstrapper command string [#8885](https://github.com/chef/chef/pull/8885) ([Nimesh-Msys](https://github.com/Nimesh-Msys))
- Bump Ruby to 2.6.5 to address CVEs #8951 [#8952](https://github.com/chef/chef/pull/8952) ([christopher-snapp](https://github.com/christopher-snapp))
- Bump inspec-core-bin to 4.17.17 [#8953](https://github.com/chef/chef/pull/8953) ([chef-expeditor[bot]](https://github.com/chef-expeditor[bot]))
- Revert Gemfile.lock to Bundler 1.17.3 [#8956](https://github.com/chef/chef/pull/8956) ([tas50](https://github.com/tas50))
- Remove EOL openSUSE Leap 42 testing [#8955](https://github.com/chef/chef/pull/8955) ([tas50](https://github.com/tas50))
- Add CentOS 8 kitchen testing to buildkite [#8954](https://github.com/chef/chef/pull/8954) ([tas50](https://github.com/tas50))
- windows_share: make path idempotent by coercing to backwhacks [#8967](https://github.com/chef/chef/pull/8967) ([Happycoil](https://github.com/Happycoil))
- sudo: perform config validation on the overall sudoers state [#8928](https://github.com/chef/chef/pull/8928) ([samshinde](https://github.com/samshinde))
- Fix for knife subcommand --help don&#39;t work as intended.  [#8915](https://github.com/chef/chef/pull/8915) ([Vasu1105](https://github.com/Vasu1105))
- Fix Bootstrap password prompt [#8856](https://github.com/chef/chef/pull/8856) ([samshinde](https://github.com/samshinde))
- Require train ~3.1 for bootstrapping and openssl 1.0.2t [#8968](https://github.com/chef/chef/pull/8968) ([tas50](https://github.com/tas50))
- windows_ad_join: Add :leave action to for leaving an AD domain [#8379](https://github.com/chef/chef/pull/8379) ([jasonwbarnett](https://github.com/jasonwbarnett))
- windows_service: don&#39;t update the service if the run_as_user ca… [#8981](https://github.com/chef/chef/pull/8981) ([jasonwbarnett](https://github.com/jasonwbarnett))
- Fix yum &amp; dnf shellout if exit with nonzero status [#8972](https://github.com/chef/chef/pull/8972) ([vsingh-msys](https://github.com/vsingh-msys))
- Event dispatcher thread local storage [#8950](https://github.com/chef/chef/pull/8950) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix undefined method `each&#39; for String [#8987](https://github.com/chef/chef/pull/8987) ([vsingh-msys](https://github.com/vsingh-msys))
- Avoid a PATH environment variable update before a windows package install [#8961](https://github.com/chef/chef/pull/8961) ([jeremyhage](https://github.com/jeremyhage))
- Using umask to avoid race conditions in bootstrap [#8895](https://github.com/chef/chef/pull/8895) ([Nimesh-Msys](https://github.com/Nimesh-Msys))
- Enhance knife supermarket list &amp; search [#8971](https://github.com/chef/chef/pull/8971) ([vsingh-msys](https://github.com/vsingh-msys))
- Fix typo for knife download --[no]diff and --[-no]force options. [#8995](https://github.com/chef/chef/pull/8995) ([Vasu1105](https://github.com/Vasu1105))
- [knife] Deprecate data bag secret (-s) short option due to conflict with --server-url option [#8909](https://github.com/chef/chef/pull/8909) ([vsingh-msys](https://github.com/vsingh-msys))
- knife: Improve messaging for installing official plugins into DK / Workstationn [#8899](https://github.com/chef/chef/pull/8899) ([vsingh-msys](https://github.com/vsingh-msys))
- Update train to 3.1.4 and update omnibus-software to fix AIX ruby [#8997](https://github.com/chef/chef/pull/8997) ([tas50](https://github.com/tas50))

## [v15.3.14](https://github.com/chef/chef/tree/v15.3.14) (2019-09-12)

#### Merged Pull Requests
- Improve the auto-generated docs [#8806](https://github.com/chef/chef/pull/8806) ([tas50](https://github.com/tas50))
- Update the link to our release cadence information [#8807](https://github.com/chef/chef/pull/8807) ([tas50](https://github.com/tas50))
- Updated knife cookbook metadata from file command banner [#8812](https://github.com/chef/chef/pull/8812) ([samshinde](https://github.com/samshinde))
- Begin signing MSI&#39;s with renewed Windows Signing Cert [#8813](https://github.com/chef/chef/pull/8813) ([schisamo](https://github.com/schisamo))
- Update omnibus build deps to the latest [#8823](https://github.com/chef/chef/pull/8823) ([tas50](https://github.com/tas50))
- Add unified_mode for resources [#8668](https://github.com/chef/chef/pull/8668) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix crash when showing error about missing profile [#8828](https://github.com/chef/chef/pull/8828) ([andrewdotn](https://github.com/andrewdotn))
- Add AIX 7.2 platform [#8832](https://github.com/chef/chef/pull/8832) ([jaymalasinha](https://github.com/jaymalasinha))
- ifconfig: fix regex matching interface name with hyphen [#8756](https://github.com/chef/chef/pull/8756) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Fail on interval runs on windows as interval runs on Windows don&#39;t entirely work [#6777](https://github.com/chef/chef/pull/6777) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix node[:cookbooks] attribute [#8846](https://github.com/chef/chef/pull/8846) ([lamont-granquist](https://github.com/lamont-granquist))
- remove app_server_support spec file [#8852](https://github.com/chef/chef/pull/8852) ([lamont-granquist](https://github.com/lamont-granquist))
- Update InSpec to 4.12 and Train to 3.0 [#8854](https://github.com/chef/chef/pull/8854) ([tas50](https://github.com/tas50))
- Bootstrap: Only use sudo when changing ownership if --sudo is passed [#8815](https://github.com/chef/chef/pull/8815) ([vsingh-msys](https://github.com/vsingh-msys))
- Deprecate macOS 10.12 and add macOS 10.15 support [#8850](https://github.com/chef/chef/pull/8850) ([jaymalasinha](https://github.com/jaymalasinha))
- Update InSpec to 4.16 and addressable to 2.7.0 [#8857](https://github.com/chef/chef/pull/8857) ([tas50](https://github.com/tas50))
- Update libarchive to 3.4.0 and pin in omnibus_overrides.rb [#8862](https://github.com/chef/chef/pull/8862) ([tas50](https://github.com/tas50))
- Bump ohai to 15.3.1 [#8863](https://github.com/chef/chef/pull/8863) ([chef-ci](https://github.com/chef-ci))
- Migrate Appveyor windows testing to Buildkite [#8867](https://github.com/chef/chef/pull/8867) ([jaymalasinha](https://github.com/jaymalasinha))
- convert chocolatey resource to use shell_out splat args [#8861](https://github.com/chef/chef/pull/8861) ([lamont-granquist](https://github.com/lamont-granquist))
- Remove duplicate policy_path config [#8864](https://github.com/chef/chef/pull/8864) ([tas50](https://github.com/tas50))
- Add Chef 15.3 release notes [#8860](https://github.com/chef/chef/pull/8860) ([tas50](https://github.com/tas50))
- Bootstrap: Set pty true only if required [#8816](https://github.com/chef/chef/pull/8816) ([vsingh-msys](https://github.com/vsingh-msys))
- Support to provide --local flag to gem installer. [#8847](https://github.com/chef/chef/pull/8847) ([samshinde](https://github.com/samshinde))
- Add mac_user resource that is compatible with macOS &gt;= 10.14 [#8775](https://github.com/chef/chef/pull/8775) ([ryancragun](https://github.com/ryancragun))
- Fix for user resource does not handle a gid specified as a string [#8869](https://github.com/chef/chef/pull/8869) ([kapilchouhan99](https://github.com/kapilchouhan99))
- [macos] fix mac_user platform constraints [#8874](https://github.com/chef/chef/pull/8874) ([ryancragun](https://github.com/ryancragun))
- Bootstrap: Fix typo when checking for existing chef-client [#8876](https://github.com/chef/chef/pull/8876) ([teknofire](https://github.com/teknofire))
- Update openssl to 1.0.2t [#8878](https://github.com/chef/chef/pull/8878) ([tas50](https://github.com/tas50))

## [v15.2.20](https://github.com/chef/chef/tree/v15.2.20) (2019-08-08)

#### Merged Pull Requests
- Bump inspec-core to 4.6.9 [#8701](https://github.com/chef/chef/pull/8701) ([chef-ci](https://github.com/chef-ci))
- windows_task: Fix for :day option is not accepting integer value [#8705](https://github.com/chef/chef/pull/8705) ([vsingh-msys](https://github.com/vsingh-msys))
- update bldr config with new hab package name [#8706](https://github.com/chef/chef/pull/8706) ([robbkidd](https://github.com/robbkidd))
- fixes for chefstyle bump [#8707](https://github.com/chef/chef/pull/8707) ([lamont-granquist](https://github.com/lamont-granquist))
- Deprecate Ubuntu-14 [#8712](https://github.com/chef/chef/pull/8712) ([jaymalasinha](https://github.com/jaymalasinha))
- Improve generation of docs site resource pages [#8718](https://github.com/chef/chef/pull/8718) ([tas50](https://github.com/tas50))
- fix Layout/AlignArguments [#8708](https://github.com/chef/chef/pull/8708) ([lamont-granquist](https://github.com/lamont-granquist))
- More Chefstyle updates [#8711](https://github.com/chef/chef/pull/8711) ([lamont-granquist](https://github.com/lamont-granquist))
- Add examples to the apt_repository resource [#8719](https://github.com/chef/chef/pull/8719) ([tas50](https://github.com/tas50))
- Bump inspec-core to 4.7.3 [#8726](https://github.com/chef/chef/pull/8726) ([chef-ci](https://github.com/chef-ci))
- Remove rspec config for Travis [#8728](https://github.com/chef/chef/pull/8728) ([tas50](https://github.com/tas50))
- Roll back Rubygems to 3.0.3 to prevent double bundler install [#8736](https://github.com/chef/chef/pull/8736) ([tas50](https://github.com/tas50))
- Bump openSSL to 1.0.2s [#8735](https://github.com/chef/chef/pull/8735) ([tas50](https://github.com/tas50))
- Pull in latest omnibus-software to fix Windows builds [#8739](https://github.com/chef/chef/pull/8739) ([btm](https://github.com/btm))
- Fix RDoc copy-pasta in Chef::Mixin::ParamsValidate#validate [#8740](https://github.com/chef/chef/pull/8740) ([RubyTuesdayDONO](https://github.com/RubyTuesdayDONO))
- Remove the unused rspec kitchen tests [#8741](https://github.com/chef/chef/pull/8741) ([tas50](https://github.com/tas50))
- test that inspec binstub is in the omnibus artifact [#8750](https://github.com/chef/chef/pull/8750) ([lamont-granquist](https://github.com/lamont-granquist))
- dnf_package fixes for RHEL8 [#8754](https://github.com/chef/chef/pull/8754) ([lamont-granquist](https://github.com/lamont-granquist))
- Add rspec testing on Fedora in Buildkite [#8759](https://github.com/chef/chef/pull/8759) ([tas50](https://github.com/tas50))
- Implement disable for disabling kernel_modules [#8747](https://github.com/chef/chef/pull/8747) ([tomdoherty](https://github.com/tomdoherty))
- Bump InSpec, Ohai, and appbundler to the latest [#8761](https://github.com/chef/chef/pull/8761) ([tas50](https://github.com/tas50))
- Move chef-client and chef-solo shared code into a base class and remove duplication and skew [#8744](https://github.com/chef/chef/pull/8744) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump train-core to 2.1.19 [#8766](https://github.com/chef/chef/pull/8766) ([chef-ci](https://github.com/chef-ci))
- Update bzip2 from 1.0.6 -&gt; 1.0.8 to resolve CVEs [#8768](https://github.com/chef/chef/pull/8768) ([tas50](https://github.com/tas50))
- Duration field in resource report needs to be String [#8767](https://github.com/chef/chef/pull/8767) ([lamont-granquist](https://github.com/lamont-granquist))
- Tweak data collector exception handling [#8776](https://github.com/chef/chef/pull/8776) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix zypper test failures [#8774](https://github.com/chef/chef/pull/8774) ([jaymalasinha](https://github.com/jaymalasinha))
- Jsinha/add rhel8 [#8742](https://github.com/chef/chef/pull/8742) ([jaymalasinha](https://github.com/jaymalasinha))
- Enable Kitchen dockken tests with BK linux executor [#8783](https://github.com/chef/chef/pull/8783) ([jaymalasinha](https://github.com/jaymalasinha))
- Bump mixlib-shellout to 3.0.7 [#8784](https://github.com/chef/chef/pull/8784) ([chef-ci](https://github.com/chef-ci))
- Remove Travis / Jenkins config / docs [#8786](https://github.com/chef/chef/pull/8786) ([tas50](https://github.com/tas50))
- Bump inspec-core-bin to 4.10.4 and Ohai to 15.2.4 [#8788](https://github.com/chef/chef/pull/8788) ([chef-ci](https://github.com/chef-ci))
- Cleanup of habitat/plan.sh for chef-infra-client [#8789](https://github.com/chef/chef/pull/8789) ([afiune](https://github.com/afiune))
- Stop building Chef Infra Client on SLES 11 [#8796](https://github.com/chef/chef/pull/8796) ([tas50](https://github.com/tas50))
- zypper_package upgrade action not working [#8462](https://github.com/chef/chef/pull/8462) ([foobarbam](https://github.com/foobarbam))
- Fix for rhsm_repo disable does not support wildcard [#8794](https://github.com/chef/chef/pull/8794) ([kapilchouhan99](https://github.com/kapilchouhan99))
- fix knife node environment set output [#8772](https://github.com/chef/chef/pull/8772) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Chef-15: Make temp dir using mkdir instead of mktemp [#8795](https://github.com/chef/chef/pull/8795) ([vsingh-msys](https://github.com/vsingh-msys))
- Property: Reorder comparison with NOT_PASSED. [#8781](https://github.com/chef/chef/pull/8781) ([ab](https://github.com/ab))
- Consistently use NOT_PASSED over alternatives [#8800](https://github.com/chef/chef/pull/8800) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump ohai to 15.2.5 [#8803](https://github.com/chef/chef/pull/8803) ([chef-ci](https://github.com/chef-ci))

## [v15.1.36](https://github.com/chef/chef/tree/v15.1.36) (2019-07-01)

#### Merged Pull Requests
- Chef Infra Client 15 Release Notes Additional edits [#8543](https://github.com/chef/chef/pull/8543) ([mjingle](https://github.com/mjingle))
- Only set client_pem in bootstrap_context when validatorless [#8567](https://github.com/chef/chef/pull/8567) ([btm](https://github.com/btm))
- Fix chef-config requires lines [#8545](https://github.com/chef/chef/pull/8545) ([lamont-granquist](https://github.com/lamont-granquist))
- Better target mode no-creds errors [#8571](https://github.com/chef/chef/pull/8571) ([lamont-granquist](https://github.com/lamont-granquist))
- Gate requires with idempotency check [#8544](https://github.com/chef/chef/pull/8544) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix delete_resource for resources [#8570](https://github.com/chef/chef/pull/8570) ([artem-sidorenko](https://github.com/artem-sidorenko))
- Fix service enable idempotency in sles11 [#8256](https://github.com/chef/chef/pull/8256) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Better target mode shell_out [#8584](https://github.com/chef/chef/pull/8584) ([lamont-granquist](https://github.com/lamont-granquist))
- Preserve train connection in target mode to prevent running duplicate OS detection commands [#8590](https://github.com/chef/chef/pull/8590) ([btm](https://github.com/btm))
- Fix for knife bootstrap inheritance issue with knife plugins [#8585](https://github.com/chef/chef/pull/8585) ([Vasu1105](https://github.com/Vasu1105))
- make which/where be target-mode aware [#8588](https://github.com/chef/chef/pull/8588) ([lamont-granquist](https://github.com/lamont-granquist))
- launchd: add launch_events property [#8582](https://github.com/chef/chef/pull/8582) ([chilcote](https://github.com/chilcote))
- Chef 15: Fix order of connection before registering node [#8574](https://github.com/chef/chef/pull/8574) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Add introduced field to launch_events in launchd [#8592](https://github.com/chef/chef/pull/8592) ([tas50](https://github.com/tas50))
- Chef-15: Add missing deprecated options [#8573](https://github.com/chef/chef/pull/8573) ([vsingh-msys](https://github.com/vsingh-msys))
- Use Shellwords.join in target-mode shell_out [#8594](https://github.com/chef/chef/pull/8594) ([lamont-granquist](https://github.com/lamont-granquist))
- fix shellout require idempotency and bump gems [#8595](https://github.com/chef/chef/pull/8595) ([lamont-granquist](https://github.com/lamont-granquist))
- Fixed issue for chef-client run was throwing error when provided empty string with it [#8200](https://github.com/chef/chef/pull/8200) ([vinay033](https://github.com/vinay033))
- Enable target mode on ruby_block, log and breakpoint [#8593](https://github.com/chef/chef/pull/8593) ([lamont-granquist](https://github.com/lamont-granquist))
- Add distro constants for solo, zero and automate [#8460](https://github.com/chef/chef/pull/8460) ([bobchaos](https://github.com/bobchaos))
- Chef 15: Fix ssh user set from cli [#8558](https://github.com/chef/chef/pull/8558) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Improving error handling for template render [#8562](https://github.com/chef/chef/pull/8562) ([brodock](https://github.com/brodock))
- Add new chocolatey_feature resource for managing features in Chocolatey [#8581](https://github.com/chef/chef/pull/8581) ([gep13](https://github.com/gep13))
- Trace output the actual bootstrap template filename [#8619](https://github.com/chef/chef/pull/8619) ([btm](https://github.com/btm))
- Raise knife exceptions when verbosity is 3 (-VVV) [#8618](https://github.com/chef/chef/pull/8618) ([btm](https://github.com/btm))
- Add hooks for plugins in knife bootstrap [#8628](https://github.com/chef/chef/pull/8628) ([btm](https://github.com/btm))
- Create bootstrap template in binmode to fix line endings [#8631](https://github.com/chef/chef/pull/8631) ([btm](https://github.com/btm))
- more distro constants [#8630](https://github.com/chef/chef/pull/8630) ([bobchaos](https://github.com/bobchaos))
- Chef-15: Added deprecation check for short arguments [#8626](https://github.com/chef/chef/pull/8626) ([Nimesh-Msys](https://github.com/Nimesh-Msys))
- Avoid constant warnings [#8633](https://github.com/chef/chef/pull/8633) ([tas50](https://github.com/tas50))
- Speed up buildkite tests [#8636](https://github.com/chef/chef/pull/8636) ([tas50](https://github.com/tas50))
- More speedups to the Buildkite PR verification tests [#8639](https://github.com/chef/chef/pull/8639) ([tas50](https://github.com/tas50))
- Update Buildkite config with Ubuntu/CentOS/openSUSE containers [#8641](https://github.com/chef/chef/pull/8641) ([tas50](https://github.com/tas50))
- use mixlib-cli&#39;s deprecation mechanism [#8637](https://github.com/chef/chef/pull/8637) ([marcparadise](https://github.com/marcparadise))
- Make sure to ship the inspec binary [#8660](https://github.com/chef/chef/pull/8660) ([tas50](https://github.com/tas50))
- Update Habitat Build [#8598](https://github.com/chef/chef/pull/8598) ([ncerny](https://github.com/ncerny))
- Update Ohai to 15.1.3 and license-acceptance to 1.0.13 [#8661](https://github.com/chef/chef/pull/8661) ([tas50](https://github.com/tas50))
- Target mode for systemd service helper [#8614](https://github.com/chef/chef/pull/8614) ([lamont-granquist](https://github.com/lamont-granquist))
- Update omnibus-software to unbreak chef builds [#8665](https://github.com/chef/chef/pull/8665) ([tas50](https://github.com/tas50))
- Add Chef 12 updating docs [#8664](https://github.com/chef/chef/pull/8664) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump inspec to 4.6.3 [#8666](https://github.com/chef/chef/pull/8666) ([chef-ci](https://github.com/chef-ci))
- Move the data collector should_be_enabled? check [#8670](https://github.com/chef/chef/pull/8670) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump inspec-core-bin to 4.6.4 [#8672](https://github.com/chef/chef/pull/8672) ([chef-ci](https://github.com/chef-ci))
- added scaffolding-chef plan [#8659](https://github.com/chef/chef/pull/8659) ([echohack](https://github.com/echohack))
- [chef-client] [scaffolding-chef] add new build configuration for scaffolding-chef [#8677](https://github.com/chef/chef/pull/8677) ([echohack](https://github.com/echohack))
- [chef-client] [scaffolding-chef] add new build configuration for scaffolding-chef [#8678](https://github.com/chef/chef/pull/8678) ([echohack](https://github.com/echohack))
- Bump ohai to 15.1.5 [#8681](https://github.com/chef/chef/pull/8681) ([chef-ci](https://github.com/chef-ci))
- Update ffi-libarchive to 0.4.10 [#8688](https://github.com/chef/chef/pull/8688) ([tas50](https://github.com/tas50))
- [scaffolding-chef] Rolling out the scaffolding-chef package [#8679](https://github.com/chef/chef/pull/8679) ([echohack](https://github.com/echohack))
- Update Rubygems to 3.0.4 [#8689](https://github.com/chef/chef/pull/8689) ([tas50](https://github.com/tas50))
- Pin to ruby-prof 0.17 [#8690](https://github.com/chef/chef/pull/8690) ([tas50](https://github.com/tas50))
- Improve how we bundler install in appveyor [#8663](https://github.com/chef/chef/pull/8663) ([tas50](https://github.com/tas50))
- Ignore noisy outputs at create temp_dir during bootstrap [#8682](https://github.com/chef/chef/pull/8682) ([sawanoboly](https://github.com/sawanoboly))
- chocolatey_source: Add additional actions and propereties for configuring sources [#8635](https://github.com/chef/chef/pull/8635) ([gep13](https://github.com/gep13))
- yum_package: Better handle yum exceptions in our helper so we always close the rpmdb [#8692](https://github.com/chef/chef/pull/8692) ([lamont-granquist](https://github.com/lamont-granquist))
- Add introduced fields for chocolatey_source [#8691](https://github.com/chef/chef/pull/8691) ([tas50](https://github.com/tas50))
- Enable Habitat build promotion in Expeditor again [#8693](https://github.com/chef/chef/pull/8693) ([tas50](https://github.com/tas50))
- Fix a typo in the hostname resource property descriptions [#8695](https://github.com/chef/chef/pull/8695) ([tas50](https://github.com/tas50))
- Add rake task for generating the docs site content [#8694](https://github.com/chef/chef/pull/8694) ([tas50](https://github.com/tas50))
- Rename the habitat package to chef-infra-client [#8698](https://github.com/chef/chef/pull/8698) ([tas50](https://github.com/tas50))
- Bump train-core to 2.1.13 [#8699](https://github.com/chef/chef/pull/8699) ([chef-ci](https://github.com/chef-ci))
- Pass yum_package options to underlying python helper [#8687](https://github.com/chef/chef/pull/8687) ([Annih](https://github.com/Annih))

## [v15.0.300](https://github.com/chef/chef/tree/v15.0.300) (2019-05-16)

#### Merged Pull Requests
- Add license CLI options to chef-apply command [#8554](https://github.com/chef/chef/pull/8554) ([tas50](https://github.com/tas50))
- Enable pty for bootstrap ssh [#8560](https://github.com/chef/chef/pull/8560) ([marcparadise](https://github.com/marcparadise))

## [v15.0.298](https://github.com/chef/chef/tree/v15.0.298) (2019-05-15)

#### Merged Pull Requests
- Bump license-acceptance to 1.0.8 to resolve failures on Windows 2012R2 [#8538](https://github.com/chef/chef/pull/8538) ([chef-ci](https://github.com/chef-ci))
- Update habitat/plan.sh to allow building of Chef Infra Client 15 [#8552](https://github.com/chef/chef/pull/8552) ([smacfarlane](https://github.com/smacfarlane))
- Bump license-acceptance to 1.0.11 to resolve failures on Windows 2016 [#8551](https://github.com/chef/chef/pull/8551) ([aaronwalker](https://github.com/aaronwalker))
- Multiple Bootstrap bug fixes [#8539](https://github.com/chef/chef/pull/8539) ([marcparadise](https://github.com/marcparadise))
- Bump train-core to 2.1.2 [#8553](https://github.com/chef/chef/pull/8553) ([chef-ci](https://github.com/chef-ci))

## [v15.0.293](https://github.com/chef/chef/tree/v15.0.293) (2019-05-14)

#### Merged Pull Requests
- Start Chef 15 development [#7785](https://github.com/chef/chef/pull/7785) ([tas50](https://github.com/tas50))
- Remove the deprecated knife bootstrap --identity-file flag [#7489](https://github.com/chef/chef/pull/7489) ([tas50](https://github.com/tas50))
- Make all Chef 14 preview resources into full resources [#7786](https://github.com/chef/chef/pull/7786) ([tas50](https://github.com/tas50))
- Update description fields from the docs site [#7784](https://github.com/chef/chef/pull/7784) ([tas50](https://github.com/tas50))
- Do the shell_out deprecations for Chef-15. [#7788](https://github.com/chef/chef/pull/7788) ([lamont-granquist](https://github.com/lamont-granquist))
- Remove legacy require_recipe DSL method [#7790](https://github.com/chef/chef/pull/7790) ([tas50](https://github.com/tas50))
- Remove cookbook merging/shadowing from the cookbooker loader [#7792](https://github.com/chef/chef/pull/7792) ([lamont-granquist](https://github.com/lamont-granquist))
- shell_out auto-timeout still needs to be restricted to only providers [#7793](https://github.com/chef/chef/pull/7793) ([lamont-granquist](https://github.com/lamont-granquist))
- add GEMFILE_MOD to pin ohai to github master [#7796](https://github.com/chef/chef/pull/7796) ([lamont-granquist](https://github.com/lamont-granquist))
- Require mixin::shellout where we use it [#7798](https://github.com/chef/chef/pull/7798) ([tas50](https://github.com/tas50))
- Allow passing array to supports in mount again [#7803](https://github.com/chef/chef/pull/7803) ([tas50](https://github.com/tas50))
- Multiple fixes to dmg_package [#7802](https://github.com/chef/chef/pull/7802) ([tas50](https://github.com/tas50))
- Remove deprecated support for FreeBSD pkg provider [#7789](https://github.com/chef/chef/pull/7789) ([tas50](https://github.com/tas50))
- Refactor Cookbook loader logic now that we don&#39;t support merging [#7794](https://github.com/chef/chef/pull/7794) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix inspector to properly handle defaults that are symbols [#7813](https://github.com/chef/chef/pull/7813) ([tas50](https://github.com/tas50))
- Remove unused route resource properties [#7240](https://github.com/chef/chef/pull/7240) ([tas50](https://github.com/tas50))
- Add windows_certificate and windows_share resources [#7731](https://github.com/chef/chef/pull/7731) ([tas50](https://github.com/tas50))
- Update win32-certstore to include a license [#7822](https://github.com/chef/chef/pull/7822) ([tas50](https://github.com/tas50))
- Fix testing / installing on SLES 15 [#7819](https://github.com/chef/chef/pull/7819) ([tas50](https://github.com/tas50))
- More cookbook loader cleanup and documentation [#7820](https://github.com/chef/chef/pull/7820) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump win32-certstore to 0.1.11 [#7823](https://github.com/chef/chef/pull/7823) ([tas50](https://github.com/tas50))
- Remove preview resource from windows_certificate &amp; windows_share [#7818](https://github.com/chef/chef/pull/7818) ([tas50](https://github.com/tas50))
- Fix chef-apply crash for reboot [#7720](https://github.com/chef/chef/pull/7720) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Handle `interactive_enabled` property in windows_task resource [#7814](https://github.com/chef/chef/pull/7814) ([Nimesh-Msys](https://github.com/Nimesh-Msys))
- Update win32-taskscheduler to 2.0.1 [#7843](https://github.com/chef/chef/pull/7843) ([tas50](https://github.com/tas50))
- Remove deprecated knife status --hide-healthy flag [#7791](https://github.com/chef/chef/pull/7791) ([tas50](https://github.com/tas50))
- Remove the deprecated ohai_name property from the ohai resource [#7787](https://github.com/chef/chef/pull/7787) ([tas50](https://github.com/tas50))
- Added property `description` on windows_task resource [#7777](https://github.com/chef/chef/pull/7777) ([kapilchouhan99](https://github.com/kapilchouhan99))
- Remove knife cookbook test feature [#7323](https://github.com/chef/chef/pull/7323) ([tas50](https://github.com/tas50))
- Bump inspec-core to 3.0.25 [#7853](https://github.com/chef/chef/pull/7853) ([chef-ci](https://github.com/chef-ci))
- Set http_disable_auth_on_redirect to true [#7856](https://github.com/chef/chef/pull/7856) ([tas50](https://github.com/tas50))
- powershell_package doc update [#7857](https://github.com/chef/chef/pull/7857) ([Happycoil](https://github.com/Happycoil))
- Remove the check for nil code property in the script provider [#7855](https://github.com/chef/chef/pull/7855) ([tas50](https://github.com/tas50))
- Chef 15 node attribute array fixes [#7840](https://github.com/chef/chef/pull/7840) ([lamont-granquist](https://github.com/lamont-granquist))
- Add additional github issue templates [#7859](https://github.com/chef/chef/pull/7859) ([tas50](https://github.com/tas50))
- Remove knife user support for open source Chef Server &lt; 12 [#7841](https://github.com/chef/chef/pull/7841) ([tas50](https://github.com/tas50))
- Remove the remaining OSC 11 knife user commands [#7868](https://github.com/chef/chef/pull/7868) ([tas50](https://github.com/tas50))
- Improve resource descriptions for resource documentation automation [#7808](https://github.com/chef/chef/pull/7808) ([tas50](https://github.com/tas50))
- Add windows_firewall_rule [#7842](https://github.com/chef/chef/pull/7842) ([Happycoil](https://github.com/Happycoil))
- Make knife command banners consistent [#7869](https://github.com/chef/chef/pull/7869) ([tas50](https://github.com/tas50))
- Add more validation_messages to properties [#7867](https://github.com/chef/chef/pull/7867) ([tas50](https://github.com/tas50))
- Fully remove knife cookbook create command [#7852](https://github.com/chef/chef/pull/7852) ([tas50](https://github.com/tas50))
- Defer running initramfs_command until end of run [#7871](https://github.com/chef/chef/pull/7871) ([tomdoherty](https://github.com/tomdoherty))
- resource inspector: don&#39;t convert nil to &quot;nil&quot; in default values [#7880](https://github.com/chef/chef/pull/7880) ([tas50](https://github.com/tas50))
- Add additional descriptions to resource and update others [#7881](https://github.com/chef/chef/pull/7881) ([tas50](https://github.com/tas50))
- Allow passing multiple ports in windows_firewall [#7879](https://github.com/chef/chef/pull/7879) ([tas50](https://github.com/tas50))
- Update more descriptions and tweak default handling in chef-resource-inspector [#7884](https://github.com/chef/chef/pull/7884) ([tas50](https://github.com/tas50))
- Remove Chef provisioning lazy loading [#7866](https://github.com/chef/chef/pull/7866) ([tas50](https://github.com/tas50))
- add tests for yum version with package_source bug [#7886](https://github.com/chef/chef/pull/7886) ([lamont-granquist](https://github.com/lamont-granquist))
- fix whitespace in node attributes [ci skip] [#7890](https://github.com/chef/chef/pull/7890) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix the knife integration spec timeouts [#7896](https://github.com/chef/chef/pull/7896) ([lamont-granquist](https://github.com/lamont-granquist))
- windows_ad_join: Switch to UPN format usernames for use with AD cmdlets [#7895](https://github.com/chef/chef/pull/7895) ([stuartpreston](https://github.com/stuartpreston))
- Make sure we define windows_task resource on *nix systems [#7903](https://github.com/chef/chef/pull/7903) ([tas50](https://github.com/tas50))
- Add nillability to attribute deep merging [#7892](https://github.com/chef/chef/pull/7892) ([lamont-granquist](https://github.com/lamont-granquist))
- Update deps to bring in the new ca-certs [#7897](https://github.com/chef/chef/pull/7897) ([tas50](https://github.com/tas50))
- Always run policy_file if a policy_file or policy_group exists [#7910](https://github.com/chef/chef/pull/7910) ([tas50](https://github.com/tas50))
- windows_feature: Move provider logic into the default of the install_method property [#7912](https://github.com/chef/chef/pull/7912) ([tas50](https://github.com/tas50))
- Update inspec-core to 3.0.46 [#7924](https://github.com/chef/chef/pull/7924) ([tas50](https://github.com/tas50))
- Replace usage of win_friendly_path helper in windows_certificate [#7927](https://github.com/chef/chef/pull/7927) ([tas50](https://github.com/tas50))
- Update Cheffish to 14.0.4 [#7936](https://github.com/chef/chef/pull/7936) ([tas50](https://github.com/tas50))
- use --no-tty during apt-keys fro gpg - fixes #7913 [#7914](https://github.com/chef/chef/pull/7914) ([EugenMayer](https://github.com/EugenMayer))
- windows_feature_dism: support installed deleted features [#7905](https://github.com/chef/chef/pull/7905) ([kapilchouhan99](https://github.com/kapilchouhan99))
- Improve resource descriptions for documentation [#7929](https://github.com/chef/chef/pull/7929) ([tas50](https://github.com/tas50))
- Add additional resource description fields [#7938](https://github.com/chef/chef/pull/7938) ([tas50](https://github.com/tas50))
- Require chef-zero 14.0.11 or later to resolve Rack gem CVEs [#7940](https://github.com/chef/chef/pull/7940) ([tas50](https://github.com/tas50))
- windows_certificate: Add testing of the defaults and allowed properties [#7917](https://github.com/chef/chef/pull/7917) ([tas50](https://github.com/tas50))
- Fully convert remote_directory to use properties [#7947](https://github.com/chef/chef/pull/7947) ([tas50](https://github.com/tas50))
- Replace several uses of attribute with property in resources [#7943](https://github.com/chef/chef/pull/7943) ([tas50](https://github.com/tas50))
- Convert service resource to use properties [#7946](https://github.com/chef/chef/pull/7946) ([tas50](https://github.com/tas50))
- windows_workgroup: Coerce the provided reboot property and add more tests [#7916](https://github.com/chef/chef/pull/7916) ([tas50](https://github.com/tas50))
- Remove unused yum_timeout and yum_lock_timeout configs [#7909](https://github.com/chef/chef/pull/7909) ([tas50](https://github.com/tas50))
- Allow Integers for all group / owner properties [#7948](https://github.com/chef/chef/pull/7948) ([tas50](https://github.com/tas50))
- Chef-15:  require instead of load libraries [#7954](https://github.com/chef/chef/pull/7954) ([lamont-granquist](https://github.com/lamont-granquist))
- Chef-15: switch default of allow_downgrade to true [#7953](https://github.com/chef/chef/pull/7953) ([lamont-granquist](https://github.com/lamont-granquist))
- windows_share: Fix idempotency by removing the &quot;everyone&quot; access [#7956](https://github.com/chef/chef/pull/7956) ([tas50](https://github.com/tas50))
- windows_share: Accounts to be revoked should be provided as an individually quoted string array [#7959](https://github.com/chef/chef/pull/7959) ([stuartpreston](https://github.com/stuartpreston))
- wipe the installer direction before installation [#7964](https://github.com/chef/chef/pull/7964) ([lamont-granquist](https://github.com/lamont-granquist))
- need -rf to remove dirs [#7966](https://github.com/chef/chef/pull/7966) ([lamont-granquist](https://github.com/lamont-granquist))
- windows_share: Avoid ConvertTo-Json errors on Windows 2012r2 with powershell 4  [#7961](https://github.com/chef/chef/pull/7961) ([derekgroh](https://github.com/derekgroh))
- Update inspec to 3.0.52 [#7978](https://github.com/chef/chef/pull/7978) ([tas50](https://github.com/tas50))
- Update openssl to 1.0.2q [#7979](https://github.com/chef/chef/pull/7979) ([tas50](https://github.com/tas50))
- Support apt-get --allow-downgrades [#7963](https://github.com/chef/chef/pull/7963) ([lamont-granquist](https://github.com/lamont-granquist))
- cab_package: Chef should fail when specified package is not applicable to the image [#7951](https://github.com/chef/chef/pull/7951) ([kapilchouhan99](https://github.com/kapilchouhan99))
- Added windows support for the timezone resource [#7806](https://github.com/chef/chef/pull/7806) ([username-is-already-taken2](https://github.com/username-is-already-taken2))
- gem_package provider supports --no-document and rubygems 3.x [#7986](https://github.com/chef/chef/pull/7986) ([lamont-granquist](https://github.com/lamont-granquist))
- pull the ohai version from the bundle not from master [#7987](https://github.com/chef/chef/pull/7987) ([lamont-granquist](https://github.com/lamont-granquist))
- Make sure which mixin requires chef_class [#7989](https://github.com/chef/chef/pull/7989) ([tas50](https://github.com/tas50))
- better kithen ohai pinning [#7998](https://github.com/chef/chef/pull/7998) ([lamont-granquist](https://github.com/lamont-granquist))
- Initial suppport for snap packages [#7999](https://github.com/chef/chef/pull/7999) ([lamont-granquist](https://github.com/lamont-granquist))
- package resource: Add RHEL 8 support to DNF package installer [#8003](https://github.com/chef/chef/pull/8003) ([pixdrift](https://github.com/pixdrift))
- RHEL8 yum_package fix. [#8005](https://github.com/chef/chef/pull/8005) ([lamont-granquist](https://github.com/lamont-granquist))
- Pin the ohai definition to use the ohai version from Gemfile.lock [#8012](https://github.com/chef/chef/pull/8012) ([tas50](https://github.com/tas50))
- Fix locking ohai to to the value in the Gemfile.lock [#8014](https://github.com/chef/chef/pull/8014) ([tas50](https://github.com/tas50))
- Update InSpec to 3.0.61 and Ohai to 15.0.20 [#8010](https://github.com/chef/chef/pull/8010) ([tas50](https://github.com/tas50))
- timezone: updated description to include windows [#8018](https://github.com/chef/chef/pull/8018) ([Stromweld](https://github.com/Stromweld))
- Require Ruby 2.5 or later [#8023](https://github.com/chef/chef/pull/8023) ([tas50](https://github.com/tas50))
- Bugfixes to powershell_package_source [#8025](https://github.com/chef/chef/pull/8025) ([Happycoil](https://github.com/Happycoil))
- Allow the use of tagged?(tags) method in both only_if and not_if blocks [#7977](https://github.com/chef/chef/pull/7977) ([kapilchouhan99](https://github.com/kapilchouhan99))
- Chef 15: Windows Server 2019 version detection [#8031](https://github.com/chef/chef/pull/8031) ([stuartpreston](https://github.com/stuartpreston))
- Remove travis apt proxy before running functional tests [#8040](https://github.com/chef/chef/pull/8040) ([lamont-granquist](https://github.com/lamont-granquist))
- minimal_ohai: Add init_package plugin as a required plugin [#7980](https://github.com/chef/chef/pull/7980) ([tas50](https://github.com/tas50))
- fix EBUSY errors in preinst script [#8046](https://github.com/chef/chef/pull/8046) ([lamont-granquist](https://github.com/lamont-granquist))
- Added property `comment` on Windows group. [#8038](https://github.com/chef/chef/pull/8038) ([kapilchouhan99](https://github.com/kapilchouhan99))
- windows_ad_join: suppress sensitive stderr [#8054](https://github.com/chef/chef/pull/8054) ([Happycoil](https://github.com/Happycoil))
- Adding VC Redistributable files required for powershell_exec on Windows [#8059](https://github.com/chef/chef/pull/8059) ([stuartpreston](https://github.com/stuartpreston))
- windows_certificate: Fix invalid byte sequence errors with pfx certicates [#8008](https://github.com/chef/chef/pull/8008) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Update inspec to 3.1 and bump all the mixlibs [#8062](https://github.com/chef/chef/pull/8062) ([tas50](https://github.com/tas50))
- Bump license_scout to 1.0.20 for licensing tests [#8065](https://github.com/chef/chef/pull/8065) ([tas50](https://github.com/tas50))
- windows_certificate: Fix failures in delete action fails if certificate doesn&#39;t exist [#8000](https://github.com/chef/chef/pull/8000) ([Vasu1105](https://github.com/Vasu1105))
- Disable s3 omnibus cache [#8068](https://github.com/chef/chef/pull/8068) ([tas50](https://github.com/tas50))
- Update train-core to 1.6.3 for smaller size and new winrm options [#8074](https://github.com/chef/chef/pull/8074) ([tas50](https://github.com/tas50))
- Bump inspec-core to 3.2.6 [#8076](https://github.com/chef/chef/pull/8076) ([tas50](https://github.com/tas50))
- Bump multiple deps to the latest [#8085](https://github.com/chef/chef/pull/8085) ([tas50](https://github.com/tas50))
- Update rubygems to 2.7.7 and bundler to 1.17.3 [#8091](https://github.com/chef/chef/pull/8091) ([tas50](https://github.com/tas50))
- Support Ruby 2.6 and add Ruby 2.6 testing [#7922](https://github.com/chef/chef/pull/7922) ([tas50](https://github.com/tas50))
- windows_task resource: Allow non-system users without password [#7918](https://github.com/chef/chef/pull/7918) ([Nimesh-Msys](https://github.com/Nimesh-Msys))
- Don&#39;t system exit on ohai CriticalPluginFailure [#8098](https://github.com/chef/chef/pull/8098) ([joshuamiller01](https://github.com/joshuamiller01))
- user resource: Remove support for macOS 10.7 and 10.7 upgraded to 10.8+ [#8110](https://github.com/chef/chef/pull/8110) ([tas50](https://github.com/tas50))
- Add a bit more yard to chef-config/config [#8119](https://github.com/chef/chef/pull/8119) ([tas50](https://github.com/tas50))
- Update license scout 1.0.21 [#8130](https://github.com/chef/chef/pull/8130) ([tas50](https://github.com/tas50))
- Update license_scout to 1.0.22 [#8133](https://github.com/chef/chef/pull/8133) ([tas50](https://github.com/tas50))
- ssh_known_host_entry: Use the host name_property in debug logging [#8124](https://github.com/chef/chef/pull/8124) ([tas50](https://github.com/tas50))
- openssl_ec_private_key / openssl_x509_request.rb: properly use the path properties when specified [#8122](https://github.com/chef/chef/pull/8122) ([tas50](https://github.com/tas50))
- homebrew_cask / homebrew_tap:  Properly use the cask_name and tap_name properties [#8123](https://github.com/chef/chef/pull/8123) ([tas50](https://github.com/tas50))
- windows_printer: prevent failures when deleting printers and using device_id property [#8125](https://github.com/chef/chef/pull/8125) ([tas50](https://github.com/tas50))
- Updates homebrew_cask tap name [#8139](https://github.com/chef/chef/pull/8139) ([jeroenj](https://github.com/jeroenj))
- Fix cask resource running each chef-client run [#8140](https://github.com/chef/chef/pull/8140) ([jeroenj](https://github.com/jeroenj))
- Allow for mixlib-archive 1.x [#8137](https://github.com/chef/chef/pull/8137) ([tas50](https://github.com/tas50))
- Sysctl: Allow slashes in key or block name [#8136](https://github.com/chef/chef/pull/8136) ([kapilchouhan99](https://github.com/kapilchouhan99))
- Hide knife cookbook site &amp; null by setting them to deprecated category [#8148](https://github.com/chef/chef/pull/8148) ([tas50](https://github.com/tas50))
- Add a deprecation warning to knife cookbook site [#8149](https://github.com/chef/chef/pull/8149) ([tas50](https://github.com/tas50))
- Remove &#39;attributes&#39;  attribute from cookbook metadata [#8151](https://github.com/chef/chef/pull/8151) ([tas50](https://github.com/tas50))
- Bump misc deps the latest [#8153](https://github.com/chef/chef/pull/8153) ([tas50](https://github.com/tas50))
- Remove bogus &quot;solaris&quot; platform from specs [#8159](https://github.com/chef/chef/pull/8159) ([tas50](https://github.com/tas50))
- Remove hpux support from group&#39;s usermod provider [#8160](https://github.com/chef/chef/pull/8160) ([tas50](https://github.com/tas50))
- Use the latest omnibus-software and nokogiri [#8162](https://github.com/chef/chef/pull/8162) ([tas50](https://github.com/tas50))
- windows_certificate: Ensure all actions are fully idempotent [#8118](https://github.com/chef/chef/pull/8118) ([Nimesh-Msys](https://github.com/Nimesh-Msys))
- apt_repository: Don&#39;t create gpg temporary files owned by root in the running user&#39;s home directory [#8104](https://github.com/chef/chef/pull/8104) ([vijaymmali1990](https://github.com/vijaymmali1990))
- Remove support for unsupported opensuse &lt; 42 from group provider [#8158](https://github.com/chef/chef/pull/8158) ([tas50](https://github.com/tas50))
- Misc YARD updates for knife [#8169](https://github.com/chef/chef/pull/8169) ([tas50](https://github.com/tas50))
- Cleanup requires / includes in knife supermarket [#8166](https://github.com/chef/chef/pull/8166) ([tas50](https://github.com/tas50))
- [knife] Remove duplicate code blocks in the knife cookbook upload command [#8135](https://github.com/chef/chef/pull/8135) ([f9n](https://github.com/f9n))
- Update Rubygems to 3.0.2 [#8174](https://github.com/chef/chef/pull/8174) ([tas50](https://github.com/tas50))
- git: Don&#39;t display the repo URL when sensitive property is set [#8179](https://github.com/chef/chef/pull/8179) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Update knife bootstrap template to use up to date omnitruck URL [#8190](https://github.com/chef/chef/pull/8190) ([mivok](https://github.com/mivok))
- Convert execute_resource remaining properties to use properties  [#8178](https://github.com/chef/chef/pull/8178) ([Vasu1105](https://github.com/Vasu1105))
- windows_certificate: Import PFX certificates with their private keys [#8193](https://github.com/chef/chef/pull/8193) ([Nimesh-Msys](https://github.com/Nimesh-Msys))
- windows_task: Properly set command / argumentts so resource updates behave as expected [#8201](https://github.com/chef/chef/pull/8201) ([Nimesh-Msys](https://github.com/Nimesh-Msys))
- chef-solo: Fixes for extra cookbook_path with parent dir that doesn&#39;t exist causes crash [#8202](https://github.com/chef/chef/pull/8202) ([vsingh-msys](https://github.com/vsingh-msys))
- powershell_script: Prefer user provided flags over the defaults [#8167](https://github.com/chef/chef/pull/8167) ([Nimesh-Msys](https://github.com/Nimesh-Msys))
- Bump InSpec to 3.5.0 [#8211](https://github.com/chef/chef/pull/8211) ([tas50](https://github.com/tas50))
- Add windows_dfs and windows_dns resources [#8198](https://github.com/chef/chef/pull/8198) ([tas50](https://github.com/tas50))
- Add windows_uac resource [#8212](https://github.com/chef/chef/pull/8212) ([tas50](https://github.com/tas50))
- More consist descriptions for resource name properties [#8216](https://github.com/chef/chef/pull/8216) ([tas50](https://github.com/tas50))
- add ed25519 gemset and update omnibus-software [#8221](https://github.com/chef/chef/pull/8221) ([lamont-granquist](https://github.com/lamont-granquist))
- Alter how we set set group members in solaris / unify group testing [#8226](https://github.com/chef/chef/pull/8226) ([tas50](https://github.com/tas50))
- Chef::Config: Uniform config dir path separator [#8219](https://github.com/chef/chef/pull/8219) ([vsingh-msys](https://github.com/vsingh-msys))
- windows_certificate: Add support to import Base 64 encoded CER certificates [#8229](https://github.com/chef/chef/pull/8229) ([Nimesh-Msys](https://github.com/Nimesh-Msys))
- Update scripts to use new EXPEDITOR_ environment variables [#8232](https://github.com/chef/chef/pull/8232) ([tduffield](https://github.com/tduffield))
- chocolatey_package: use provided options when determing available options to allow using private sources [#8230](https://github.com/chef/chef/pull/8230) ([vsingh-msys](https://github.com/vsingh-msys))
- Cleanup the user resource and convert it to the resource DSL + delete user_add provider [#8228](https://github.com/chef/chef/pull/8228) ([tas50](https://github.com/tas50))
- Update InSpec to 3.6.6 [#8235](https://github.com/chef/chef/pull/8235) ([tas50](https://github.com/tas50))
- add LazyModuleInclude to Universal DSL [#8243](https://github.com/chef/chef/pull/8243) ([lamont-granquist](https://github.com/lamont-granquist))
- pin rbnacl to 5.x [#8244](https://github.com/chef/chef/pull/8244) ([lamont-granquist](https://github.com/lamont-granquist))
- allow setting mode for openssl_dhparam after creation [#8245](https://github.com/chef/chef/pull/8245) ([btm](https://github.com/btm))
- Update libxml2 to 2.9.9 [#8240](https://github.com/chef/chef/pull/8240) ([tas50](https://github.com/tas50))
- windows_share: Improve path comparison to prevent convering on each run [#8248](https://github.com/chef/chef/pull/8248) ([Xorima](https://github.com/Xorima))
- rollback rbnacl [#8255](https://github.com/chef/chef/pull/8255) ([lamont-granquist](https://github.com/lamont-granquist))
- Update omnibus gemfile deps to remove pry [#8257](https://github.com/chef/chef/pull/8257) ([tas50](https://github.com/tas50))
- Remove checks / patches for old versions of Ruby [#8259](https://github.com/chef/chef/pull/8259) ([tas50](https://github.com/tas50))
- Update openssl to 1.0.2r [#8258](https://github.com/chef/chef/pull/8258) ([tas50](https://github.com/tas50))
- windows_certificate: Import nested certificates while importing P7B certs. [#8242](https://github.com/chef/chef/pull/8242) ([Nimesh-Msys](https://github.com/Nimesh-Msys))
- mount: Add proper new lines when on AIX to prevent failures [#8271](https://github.com/chef/chef/pull/8271) ([gsreynolds](https://github.com/gsreynolds))
- Update rubygems to 3.0.3 [#8276](https://github.com/chef/chef/pull/8276) ([tas50](https://github.com/tas50))
- Refactor windows_service unit tests [#8279](https://github.com/chef/chef/pull/8279) ([jasonwbarnett](https://github.com/jasonwbarnett))
- Extract ActionCollection out of ResourceReporter, overhaul DataCollector [#8063](https://github.com/chef/chef/pull/8063) ([lamont-granquist](https://github.com/lamont-granquist))
- Allow win32-service 2.x and bump InSpec to 3.7.1 [#8285](https://github.com/chef/chef/pull/8285) ([tas50](https://github.com/tas50))
- Remove the rake task to generate a pre-announcement [#8288](https://github.com/chef/chef/pull/8288) ([tas50](https://github.com/tas50))
- Remove audit mode from chef-client [#7728](https://github.com/chef/chef/pull/7728) ([tas50](https://github.com/tas50))
- Loosen win32-certstore pin and bump to 0.3.0 [#8286](https://github.com/chef/chef/pull/8286) ([tas50](https://github.com/tas50))
- Add misc YARD comments [#8287](https://github.com/chef/chef/pull/8287) ([tas50](https://github.com/tas50))
- windows_service: Fix action :start to not resets credentials on service [#8278](https://github.com/chef/chef/pull/8278) ([jasonwbarnett](https://github.com/jasonwbarnett))
- fix unsolvable Gemfile.lock [#8300](https://github.com/chef/chef/pull/8300) ([lamont-granquist](https://github.com/lamont-granquist))
- Allow the use of `--delete-entire-chef-repo` [#8298](https://github.com/chef/chef/pull/8298) ([ABewsher](https://github.com/ABewsher))
- Early allocation of the Chef::RunContext [#8301](https://github.com/chef/chef/pull/8301) ([lamont-granquist](https://github.com/lamont-granquist))
- Loosen mixlib deps to allow for the latest versions [#8304](https://github.com/chef/chef/pull/8304) ([tas50](https://github.com/tas50))
- Update Ruby to 2.5.5 [#8296](https://github.com/chef/chef/pull/8296) ([tas50](https://github.com/tas50))
- Pin expeditor to ruby 2.5.3 and bump train to 1.7.6 [#8308](https://github.com/chef/chef/pull/8308) ([tas50](https://github.com/tas50))
- Remove the travis gem from our gemfile [#8310](https://github.com/chef/chef/pull/8310) ([tas50](https://github.com/tas50))
- Update chef-zero to 14.0.12 [#8312](https://github.com/chef/chef/pull/8312) ([tas50](https://github.com/tas50))
- Update win32-service gem and fix #8195 [#8322](https://github.com/chef/chef/pull/8322) ([jasonwbarnett](https://github.com/jasonwbarnett))
- Update InSpec to 3.7.11 and mixlib-cli to 2.0.3 [#8329](https://github.com/chef/chef/pull/8329) ([tas50](https://github.com/tas50))
- Remove Ubuntu 14.04 testing [#8330](https://github.com/chef/chef/pull/8330) ([tas50](https://github.com/tas50))
- Update Ruby to 2.6.2 [#8333](https://github.com/chef/chef/pull/8333) ([tas50](https://github.com/tas50))
- Update inspec to 3.9.0 [#8336](https://github.com/chef/chef/pull/8336) ([tas50](https://github.com/tas50))
- fix data collector non-utf8 file output [#8337](https://github.com/chef/chef/pull/8337) ([lamont-granquist](https://github.com/lamont-granquist))
- Remove windows-api pin and update Gemfile.lock [#8328](https://github.com/chef/chef/pull/8328) ([jaymalasinha](https://github.com/jaymalasinha))
- Update nokogiri to 1.10.2 [#8338](https://github.com/chef/chef/pull/8338) ([tas50](https://github.com/tas50))
- locale: Add support to set all LC ENV variables and deprecate LC_ALL [#8324](https://github.com/chef/chef/pull/8324) ([Nimesh-Msys](https://github.com/Nimesh-Msys))
- Add PROJECT_NAME to omnibus-test scripts [#8346](https://github.com/chef/chef/pull/8346) ([tas50](https://github.com/tas50))
- Add Ruby 2.6 testing Appveyor [#8349](https://github.com/chef/chef/pull/8349) ([tas50](https://github.com/tas50))
- Implement Chef::Resource#copy_properties_from [#8344](https://github.com/chef/chef/pull/8344) ([lamont-granquist](https://github.com/lamont-granquist))
- Add Debian 10 testing to Travis [#8348](https://github.com/chef/chef/pull/8348) ([tas50](https://github.com/tas50))
- Avoid occasionally randomly reusing a gid in tests [#8352](https://github.com/chef/chef/pull/8352) ([btm](https://github.com/btm))
- Don&#39;t force DSC functional tests to PS4 [#8359](https://github.com/chef/chef/pull/8359) ([btm](https://github.com/btm))
- Add Verification tests in Buildkite [#8357](https://github.com/chef/chef/pull/8357) ([jaymalasinha](https://github.com/jaymalasinha))
- Drop privileges before creating files in solo mode [#8361](https://github.com/chef/chef/pull/8361) ([btm](https://github.com/btm))
- Add a new archive_file resource from the libarchive cookbook [#8028](https://github.com/chef/chef/pull/8028) ([tas50](https://github.com/tas50))
- Allow empty strings in -o to result in empty override run list [#8370](https://github.com/chef/chef/pull/8370) ([lamont-granquist](https://github.com/lamont-granquist))
- Limit locale resource to Linux [#8375](https://github.com/chef/chef/pull/8375) ([btm](https://github.com/btm))
- Prevent accidentally configuring windows_service properties [#8351](https://github.com/chef/chef/pull/8351) ([jasonwbarnett](https://github.com/jasonwbarnett))
- Allow encrypting a previously unencrypted data bag [#8077](https://github.com/chef/chef/pull/8077) ([vijaymmali1990](https://github.com/vijaymmali1990))
- Remove a functional test for the reboot_pending DSL [#8383](https://github.com/chef/chef/pull/8383) ([btm](https://github.com/btm))
- Improve the error message when no config can be loaded [#8389](https://github.com/chef/chef/pull/8389) ([tas50](https://github.com/tas50))
- Use color in chef-solo by default on Windows [#8390](https://github.com/chef/chef/pull/8390) ([tas50](https://github.com/tas50))
- Sync the CLI option descriptions between chef-client and chef-solo [#8391](https://github.com/chef/chef/pull/8391) ([tas50](https://github.com/tas50))
- Replace highline with tty-screen in knife list [#8381](https://github.com/chef/chef/pull/8381) ([tas50](https://github.com/tas50))
- fix default/override attribute blacklists and whitelists [#8396](https://github.com/chef/chef/pull/8396) ([lamont-granquist](https://github.com/lamont-granquist))
- Add ed25519 deps, bump highline and net-ssh pins and pull inspec from git [#8380](https://github.com/chef/chef/pull/8380) ([tas50](https://github.com/tas50))
- Triggering expeditor version bump [#8405](https://github.com/chef/chef/pull/8405) ([marcparadise](https://github.com/marcparadise))
- Replace kitchen-appbundle-updater in Travis tests with Test Kitchen lifecycle hooks [#8403](https://github.com/chef/chef/pull/8403) ([lamont-granquist](https://github.com/lamont-granquist))
- Merge the local and travis kitchen tests into a single config [#8406](https://github.com/chef/chef/pull/8406) ([tas50](https://github.com/tas50))
- Switch to inspec/train from gems [#8407](https://github.com/chef/chef/pull/8407) ([tas50](https://github.com/tas50))
- Add Chef::Dist to abstract branding details to a single location [#8368](https://github.com/chef/chef/pull/8368) ([bobchaos](https://github.com/bobchaos))
- Implement new owner/review structure + expand dev docs [#8350](https://github.com/chef/chef/pull/8350) ([tas50](https://github.com/tas50))
-  Move ed25519 gems into omnibus [#8410](https://github.com/chef/chef/pull/8410) ([tas50](https://github.com/tas50))
- Refactor bootstrapping to use train as the transport with full Windows bootstrap support [#8253](https://github.com/chef/chef/pull/8253) ([marcparadise](https://github.com/marcparadise))
- Fix for write permissions were not working properly on windows [#8168](https://github.com/chef/chef/pull/8168) ([vijaymmali1990](https://github.com/vijaymmali1990))
- windows_task: Add start_when_available support [#8420](https://github.com/chef/chef/pull/8420) ([vsingh-msys](https://github.com/vsingh-msys))
- Add the introduced field to snap_package [#8412](https://github.com/chef/chef/pull/8412) ([tas50](https://github.com/tas50))
- &quot;chef-client&quot; =&gt; #{Chef::Dist::CLIENT} [#8418](https://github.com/chef/chef/pull/8418) ([bobchaos](https://github.com/bobchaos))
- Implement bootstrap directly with train [#8419](https://github.com/chef/chef/pull/8419) ([marcparadise](https://github.com/marcparadise))
- Enable license acceptance during bootstrap  [#8411](https://github.com/chef/chef/pull/8411) ([marcparadise](https://github.com/marcparadise))
- Remove chef-* bin files from chef gem [#8413](https://github.com/chef/chef/pull/8413) ([lamont-granquist](https://github.com/lamont-granquist))
- Update InSpec preview to 4.2.0 [#8426](https://github.com/chef/chef/pull/8426) ([tas50](https://github.com/tas50))
- Update property descriptions for new resources [#8424](https://github.com/chef/chef/pull/8424) ([tas50](https://github.com/tas50))
- remove windows executables from windows gemspec [#8430](https://github.com/chef/chef/pull/8430) ([lamont-granquist](https://github.com/lamont-granquist))
- Fixed bootstrap error while using --msi-url option with knife bootstrap winrm [#8435](https://github.com/chef/chef/pull/8435) ([Vasu1105](https://github.com/Vasu1105))
- fix chef-bin bundling in omnibus [#8439](https://github.com/chef/chef/pull/8439) ([lamont-granquist](https://github.com/lamont-granquist))
- file: Tell people what file a link is pointing at in warning messages [#8417](https://github.com/chef/chef/pull/8417) ([jaymzh](https://github.com/jaymzh))
- Update InSpec to 4.3.2 [#8444](https://github.com/chef/chef/pull/8444) ([jaymalasinha](https://github.com/jaymalasinha))
- [CHEF-8422] Fix incorrect deprecation warnings [#8429](https://github.com/chef/chef/pull/8429) ([marcparadise](https://github.com/marcparadise))
- Remove old maintainer gems from the Gemfile [#8445](https://github.com/chef/chef/pull/8445) ([tas50](https://github.com/tas50))
- Update to Ruby 2.6.3 [#8446](https://github.com/chef/chef/pull/8446) ([tas50](https://github.com/tas50))
- Replace Chef Client by its constant in Chef::Dist [#8448](https://github.com/chef/chef/pull/8448) ([Tensibai](https://github.com/Tensibai))
- [CHEF-8432] Ensure default protocol is used properly. Use correct &#39;require&#39; before accessing Net::SSH constants. [#8440](https://github.com/chef/chef/pull/8440) ([marcparadise](https://github.com/marcparadise))
- Fixed empty value for knife status long output [#8415](https://github.com/chef/chef/pull/8415) ([vijaymmali1990](https://github.com/vijaymmali1990))
- Add connstant for Chef Server and improve help messaging [#8452](https://github.com/chef/chef/pull/8452) ([tas50](https://github.com/tas50))
- Update more brand names to current [#8454](https://github.com/chef/chef/pull/8454) ([tas50](https://github.com/tas50))
- Chef-15: cookbook compiler should parse only .rb files [#8456](https://github.com/chef/chef/pull/8456) ([lamont-granquist](https://github.com/lamont-granquist))
- Resolve exceptions when running knife diff [#8459](https://github.com/chef/chef/pull/8459) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix for cron resource get confused by environment/property mismatch [#8455](https://github.com/chef/chef/pull/8455) ([btm](https://github.com/btm))
- Restore bootstrap pre-release support [#8442](https://github.com/chef/chef/pull/8442) ([marcparadise](https://github.com/marcparadise))
- Move more DSL helpers into universal so they&#39;re available everywhere [#8457](https://github.com/chef/chef/pull/8457) ([lamont-granquist](https://github.com/lamont-granquist))
- [CHEF-8423] Upgrade train-core to 2.1.0 for windows detection over ssh [#8465](https://github.com/chef/chef/pull/8465) ([marcparadise](https://github.com/marcparadise))
- Add logic to require acceptance of the Chef license to run the client [#8354](https://github.com/chef/chef/pull/8354) ([tyler-ball](https://github.com/tyler-ball))
- Initial target_mode implementation [#7758](https://github.com/chef/chef/pull/7758) ([btm](https://github.com/btm))
- Chef 15: Unable to create temp dir on windows system [#8476](https://github.com/chef/chef/pull/8476) ([vsingh-msys](https://github.com/vsingh-msys))
- Remove the Chef 11 admin flag from knife client create [#8473](https://github.com/chef/chef/pull/8473) ([tas50](https://github.com/tas50))
- package: move response_file and response_file_variables out of base package resource [#8307](https://github.com/chef/chef/pull/8307) ([kapilchouhan99](https://github.com/kapilchouhan99))
- Update a few more knife.rb references to include config.rb [#8474](https://github.com/chef/chef/pull/8474) ([tas50](https://github.com/tas50))
- Point people to Learn Chef in the post install message [#8483](https://github.com/chef/chef/pull/8483) ([tas50](https://github.com/tas50))
- Remove resource collision deprecations [#8470](https://github.com/chef/chef/pull/8470) ([lamont-granquist](https://github.com/lamont-granquist))
- Check for directories on Windows before creating [#8487](https://github.com/chef/chef/pull/8487) ([marcparadise](https://github.com/marcparadise))
- Target mode code tweaks [#8480](https://github.com/chef/chef/pull/8480) ([lamont-granquist](https://github.com/lamont-granquist))
- knife bootstrap should only request license when installing Chef 15 [#8471](https://github.com/chef/chef/pull/8471) ([tyler-ball](https://github.com/tyler-ball))
- Chef 15: FATAL: Configuration error SyntaxError in client.rb during bootstrap [#8496](https://github.com/chef/chef/pull/8496) ([vsingh-msys](https://github.com/vsingh-msys))
- Update the omnibus build license to the Chef EULA [#8498](https://github.com/chef/chef/pull/8498) ([btm](https://github.com/btm))
- Clean up omnibus installer error and remove chef-fips [#8499](https://github.com/chef/chef/pull/8499) ([lamont-granquist](https://github.com/lamont-granquist))
- Convert EULA to a local file [#8505](https://github.com/chef/chef/pull/8505) ([btm](https://github.com/btm))
- Convert require to require_relative [#8508](https://github.com/chef/chef/pull/8508) ([lamont-granquist](https://github.com/lamont-granquist))
- windows_feature: Fix failures on windows 2008r2 [#8492](https://github.com/chef/chef/pull/8492) ([kapilchouhan99](https://github.com/kapilchouhan99))
- CHEF_LICENSE environment variables should be quoted [#8513](https://github.com/chef/chef/pull/8513) ([tyler-ball](https://github.com/tyler-ball))
- Fix for Chef::Exceptions::Win32APIError: The operation completed successfully. [#8451](https://github.com/chef/chef/pull/8451) ([kapilchouhan99](https://github.com/kapilchouhan99))
- Chef 15: bootstrap options --max-wait raises NoMethodError: undefined method / [#8489](https://github.com/chef/chef/pull/8489) ([vsingh-msys](https://github.com/vsingh-msys))
- Add comments to the Dockerfile explaining how it all works [#8509](https://github.com/chef/chef/pull/8509) ([tas50](https://github.com/tas50))
- Use exports compatibile with /bin/sh in the bootstrap script [#8507](https://github.com/chef/chef/pull/8507) ([MarkGibbons](https://github.com/MarkGibbons))
- Change some more require to require_relative [#8519](https://github.com/chef/chef/pull/8519) ([lamont-granquist](https://github.com/lamont-granquist))
- [knife-ec2-547] Update config_source to support using knife classes without requiring merge_config [#8506](https://github.com/chef/chef/pull/8506) ([marcparadise](https://github.com/marcparadise))
- Pin bundler to 1.17.2 which is included in Ruby 2.6 [#8518](https://github.com/chef/chef/pull/8518) ([tas50](https://github.com/tas50))
- Chef 15: Minor winrm check code refactor [#8522](https://github.com/chef/chef/pull/8522) ([vsingh-msys](https://github.com/vsingh-msys))
- Update to Chef Infra Client in Add/Remove Programs &amp; Event Log [#8520](https://github.com/chef/chef/pull/8520) ([tas50](https://github.com/tas50))
- Use new Net:SSH host key verify values [#8524](https://github.com/chef/chef/pull/8524) ([btm](https://github.com/btm))
- Chef 15: Add --session-timeout bootstrap option for both ssh &amp; winrm [#8521](https://github.com/chef/chef/pull/8521) ([vsingh-msys](https://github.com/vsingh-msys))
- Rename the windows_dfs :install actions to :create [#8527](https://github.com/chef/chef/pull/8527) ([tas50](https://github.com/tas50))

## [v14.12.9](https://github.com/chef/chef/tree/v14.12.9) (2019-04-20)

#### Merged Pull Requests
- Backport #8077 to Chef 14 [#8384](https://github.com/chef/chef/pull/8384) ([btm](https://github.com/btm))
- Update win32-service + bump inspec to 3.9.3 [#8387](https://github.com/chef/chef/pull/8387) ([tas50](https://github.com/tas50))
- Add placeholder license acceptance flags [#8398](https://github.com/chef/chef/pull/8398) ([tas50](https://github.com/tas50))
- Fix default/override attribute blacklists and whitelists [#8400](https://github.com/chef/chef/pull/8400) ([tas50](https://github.com/tas50))
- Improve the error message when no config can be loaded  [#8401](https://github.com/chef/chef/pull/8401) ([tas50](https://github.com/tas50))
- Sync the CLI option descriptions between chef-client and chef-solo [#8402](https://github.com/chef/chef/pull/8402) ([tas50](https://github.com/tas50))

## [v14.12.3](https://github.com/chef/chef/tree/v14.12.3) (2019-04-16)

#### Merged Pull Requests
- windows_certificate: Import nested certificates while importing P7B certs [#8274](https://github.com/chef/chef/pull/8274) ([tas50](https://github.com/tas50))
- Backport fix for #8080 [#8303](https://github.com/chef/chef/pull/8303) ([jasonwbarnett](https://github.com/jasonwbarnett))
- Loosen the win32-cerstore and win32-service dependencies [#8295](https://github.com/chef/chef/pull/8295) ([tas50](https://github.com/tas50))
- Remove travis gem dep and bump versions of multiple components  [#8315](https://github.com/chef/chef/pull/8315) ([tas50](https://github.com/tas50))
- Remove windows-api pin and update InSpec to 3.9.0 [#8327](https://github.com/chef/chef/pull/8327) ([jaymalasinha](https://github.com/jaymalasinha))
- Update Ruby to 2.5.5 and nokogiri to 1.10.2 [#8339](https://github.com/chef/chef/pull/8339) ([tas50](https://github.com/tas50))
- Backport two test fixes/changes to chef-14 [#8364](https://github.com/chef/chef/pull/8364) ([btm](https://github.com/btm))
- Drop privileges before creating files in solo mode [#8372](https://github.com/chef/chef/pull/8372) ([btm](https://github.com/btm))

## [v14.11.21](https://github.com/chef/chef/tree/v14.11.21) (2019-03-07)

#### Merged Pull Requests
- Update rubygems to 2.7.8 and bundler to 1.17.3 [#8194](https://github.com/chef/chef/pull/8194) ([tas50](https://github.com/tas50))
- windows_certificate: Import PFX certificates with their private keys [#8206](https://github.com/chef/chef/pull/8206) ([tas50](https://github.com/tas50))
- windows_task: Properly set command / arguments so resource updates behave as expected [#8205](https://github.com/chef/chef/pull/8205) ([tas50](https://github.com/tas50))
- Update knife bootstrap template to use up to date omnitruck URL [#8207](https://github.com/chef/chef/pull/8207) ([tas50](https://github.com/tas50))
- chef-solo: Fixes for extra cookbook_path with parent dir that doesn&#39;t exist causes crash [#8209](https://github.com/chef/chef/pull/8209) ([tas50](https://github.com/tas50))
- Update InSpec to 3.5.0 [#8214](https://github.com/chef/chef/pull/8214) ([tas50](https://github.com/tas50))
- Chef-14: add ed25519 gemset and update omnibus-software [#8222](https://github.com/chef/chef/pull/8222) ([lamont-granquist](https://github.com/lamont-granquist))
- Update InSpec to 3.6.6 [#8237](https://github.com/chef/chef/pull/8237) ([tas50](https://github.com/tas50))
- Chef-14: add lazy module include to universal DSL [#8246](https://github.com/chef/chef/pull/8246) ([lamont-granquist](https://github.com/lamont-granquist))
- Chef-14: rollback rbnacl [#8254](https://github.com/chef/chef/pull/8254) ([lamont-granquist](https://github.com/lamont-granquist))
- Update libxml2 to 2.9.9 [#8238](https://github.com/chef/chef/pull/8238) ([tas50](https://github.com/tas50))
- Use proper paths on Windows in chef-config [#8261](https://github.com/chef/chef/pull/8261) ([tas50](https://github.com/tas50))
- windows_share: Improve path comparison to prevent convering on each run [#8262](https://github.com/chef/chef/pull/8262) ([tas50](https://github.com/tas50))
- ﻿﻿chocolatey_package: use provided options when determing available options to allow using private sources [#8263](https://github.com/chef/chef/pull/8263) ([tas50](https://github.com/tas50))
- openssl_dhparam: allow changing file mode on subsequent runs [#8264](https://github.com/chef/chef/pull/8264) ([tas50](https://github.com/tas50))
- More consist descriptions for resource name properties [#8265](https://github.com/chef/chef/pull/8265) ([tas50](https://github.com/tas50))
- Update openssl to 1.0.2r [#8266](https://github.com/chef/chef/pull/8266) ([tas50](https://github.com/tas50))
- windows_certificate: Add support to import Base 64 encoded CER certificates [#8267](https://github.com/chef/chef/pull/8267) ([tas50](https://github.com/tas50))
- Update InSpec to 3.7.1 [#8268](https://github.com/chef/chef/pull/8268) ([tas50](https://github.com/tas50))
- Update cacerts to 2019-01-22 file [#8270](https://github.com/chef/chef/pull/8270) ([tas50](https://github.com/tas50))
- mount: Add proper new lines when on AIX to prevent failures [#8273](https://github.com/chef/chef/pull/8273) ([tas50](https://github.com/tas50))
- Update Rubygems to 2.7.9 + Add release notes for Chef 14.11 [#8272](https://github.com/chef/chef/pull/8272) ([tas50](https://github.com/tas50))

## [v14.10.9](https://github.com/chef/chef/tree/v14.10.9) (2019-01-30)

#### Merged Pull Requests
- Bump all deps to the latest versions [#8154](https://github.com/chef/chef/pull/8154) ([tas50](https://github.com/tas50))
- windows_certificate: Ensure all actions are fully idempotent [#8163](https://github.com/chef/chef/pull/8163) ([tas50](https://github.com/tas50))
- Add a deprecation warning to knife cookbook site [#8164](https://github.com/chef/chef/pull/8164) ([tas50](https://github.com/tas50))
- Update nokogiri to 1.10.1 [#8172](https://github.com/chef/chef/pull/8172) ([tas50](https://github.com/tas50))
- Bump all deps to current [#8173](https://github.com/chef/chef/pull/8173) ([tas50](https://github.com/tas50))
- Cleanup dependencies and comments in knife plugins [#8183](https://github.com/chef/chef/pull/8183) ([tas50](https://github.com/tas50))
- apt_repository: Don&#39;t create gpg temporary files owned by root in the running user&#39;s home directory [#8184](https://github.com/chef/chef/pull/8184) ([tas50](https://github.com/tas50))
- Update inspec to 3.3.14 [#8185](https://github.com/chef/chef/pull/8185) ([tas50](https://github.com/tas50))
- Officially deprecate cookbook shadowing and audit mode [#8187](https://github.com/chef/chef/pull/8187) ([tas50](https://github.com/tas50))
- Backport git resource fix in #8179 and update win32-certstore [#8189](https://github.com/chef/chef/pull/8189) ([tas50](https://github.com/tas50))
- Bump InSpec to 3.4.1 [#8192](https://github.com/chef/chef/pull/8192) ([tas50](https://github.com/tas50))

## [v14.9.13](https://github.com/chef/chef/tree/v14.9.13) (2019-01-22)

#### Merged Pull Requests
-  Bump mixlib-archive, mixlib-shellout, semverse, and train-core to the latest [#8041](https://github.com/chef/chef/pull/8041) ([tas50](https://github.com/tas50))
- Chef 14: Windows Server 2019 version detection [#8033](https://github.com/chef/chef/pull/8033) ([stuartpreston](https://github.com/stuartpreston))
- Bump mixlib-shellout to 2.4.2 and inspec to 3.0.64 [#8027](https://github.com/chef/chef/pull/8027) ([chef-ci](https://github.com/chef-ci))
- Bump mixlib-archive to 0.4.19 and mixlib-shellout to 2.4.4 [#8037](https://github.com/chef/chef/pull/8037) ([chef-ci](https://github.com/chef-ci))
- Backport: Bugfixes to powershell_package_source [#8050](https://github.com/chef/chef/pull/8050) ([stuartpreston](https://github.com/stuartpreston))
- Backport: Allow setting the comment on a Windows group [#8052](https://github.com/chef/chef/pull/8052) ([stuartpreston](https://github.com/stuartpreston))
- Backport: windows_ad_join: suppress sensitive stderr [#8061](https://github.com/chef/chef/pull/8061) ([stuartpreston](https://github.com/stuartpreston))
- Bump inspec-core to 3.1.3 [#8048](https://github.com/chef/chef/pull/8048) ([chef-ci](https://github.com/chef-ci))
- Backport: Adding VC Redistributable files required for powershell_exec on Windows [#8060](https://github.com/chef/chef/pull/8060) ([stuartpreston](https://github.com/stuartpreston))
- Bump license_scout to 1.0.20 for licensing tests [#8064](https://github.com/chef/chef/pull/8064) ([tas50](https://github.com/tas50))
- Bump train-core to 1.6.3 [#8067](https://github.com/chef/chef/pull/8067) ([chef-ci](https://github.com/chef-ci))
- windows_certificate: Fix failures in delete action fails if certificate doesn&#39;t exist [#8073](https://github.com/chef/chef/pull/8073) ([tas50](https://github.com/tas50))
- chef 14: windows_certificate: Fix invalid byte sequence errors with pfx certicates [#8071](https://github.com/chef/chef/pull/8071) ([tas50](https://github.com/tas50))
- chef 14: minimal_ohai: Add init_package plugin as a required plugin [#8072](https://github.com/chef/chef/pull/8072) ([tas50](https://github.com/tas50))
- Disable s3 omnibus cache [#8069](https://github.com/chef/chef/pull/8069) ([tas50](https://github.com/tas50))
- Bump inspec-core to 3.2.6 [#8075](https://github.com/chef/chef/pull/8075) ([chef-ci](https://github.com/chef-ci))
- Bump mixlib-cli to 2.0.0 and win32-certstore to 0.2.1 [#8092](https://github.com/chef/chef/pull/8092) ([chef-ci](https://github.com/chef-ci))
- Support and test on Ruby 2.6 [#8121](https://github.com/chef/chef/pull/8121) ([tas50](https://github.com/tas50))
- windows_task resource: allow non-system users without password for interactive tasks [#8120](https://github.com/chef/chef/pull/8120) ([tas50](https://github.com/tas50))
- Chef 14: A windows support to the timezone resource [#8129](https://github.com/chef/chef/pull/8129) ([tas50](https://github.com/tas50))
- Update license scout to 1.0.22 [#8131](https://github.com/chef/chef/pull/8131) ([tas50](https://github.com/tas50))
- Backport various name_property fixes in resources from Chef 15 [#8134](https://github.com/chef/chef/pull/8134) ([tas50](https://github.com/tas50))
- Allow for mixlib-archive 1.x [#8141](https://github.com/chef/chef/pull/8141) ([tas50](https://github.com/tas50))
- sysctl: Allow slashes in key or block name [#8142](https://github.com/chef/chef/pull/8142) ([tas50](https://github.com/tas50))
- homebrew_cask: Ensure the resource is fully idempotent [#8143](https://github.com/chef/chef/pull/8143) ([tas50](https://github.com/tas50))

## [v14.8.12](https://github.com/chef/chef/tree/v14.8.12) (2018-12-13)

#### Merged Pull Requests
- Chef 14 Backport: fix the knife integration spec timeouts [#7899](https://github.com/chef/chef/pull/7899) ([lamont-granquist](https://github.com/lamont-granquist))
- Chef 14 Backport: windows_ad_join: Switch to UPN format usernames for use with AD cmdlets [#7906](https://github.com/chef/chef/pull/7906) ([stuartpreston](https://github.com/stuartpreston))
- Chef 14 Backport: Make sure we define windows_task resource on *nix systems [#7907](https://github.com/chef/chef/pull/7907) ([stuartpreston](https://github.com/stuartpreston))
- Update inspec and ca-certs to the latest [#7898](https://github.com/chef/chef/pull/7898) ([tas50](https://github.com/tas50))
- Backport: windows_feature: Move provider logic into the default of the install_method property [#7920](https://github.com/chef/chef/pull/7920) ([tas50](https://github.com/tas50))
- Bump InSpec to 3.0.46 [#7931](https://github.com/chef/chef/pull/7931) ([tas50](https://github.com/tas50))
- Replace usage of win_friendly_path helper in windows_certificate [#7932](https://github.com/chef/chef/pull/7932) ([tas50](https://github.com/tas50))
- Update cheffish to 14.0.4 [#7937](https://github.com/chef/chef/pull/7937) ([tas50](https://github.com/tas50))
- Bump inspec-core to 3.0.52 [#7945](https://github.com/chef/chef/pull/7945) ([chef-ci](https://github.com/chef-ci))
- Chef 14: Replace several uses of attribute with property in resources [#7967](https://github.com/chef/chef/pull/7967) ([tas50](https://github.com/tas50))
- Chef 14: windows_certificate: Add testing of the defaults and allowed properties [#7968](https://github.com/chef/chef/pull/7968) ([tas50](https://github.com/tas50))
- Chef 14: Improve resource descriptions [#7969](https://github.com/chef/chef/pull/7969) ([tas50](https://github.com/tas50))
- Chef 14: windows_workgroup: Coerce the provided reboot property and add more t ests [#7972](https://github.com/chef/chef/pull/7972) ([tas50](https://github.com/tas50))
- Chef 14: windows_share: Properly split the users to be revoked using quotes [#7974](https://github.com/chef/chef/pull/7974) ([tas50](https://github.com/tas50))
- Chef 14: apt_repository: prevent gpg key import on newer Debian releases [#7971](https://github.com/chef/chef/pull/7971) ([tas50](https://github.com/tas50))
- Chef 14: windows_share: Fix idempotency by removing the &quot;everyone&quot; access [#7973](https://github.com/chef/chef/pull/7973) ([tas50](https://github.com/tas50))
- Chef 14: removed features are also available for installation in windows_feature_dism [#7970](https://github.com/chef/chef/pull/7970) ([tas50](https://github.com/tas50))
- Update to openssl 1.0.2q [#7976](https://github.com/chef/chef/pull/7976) ([tas50](https://github.com/tas50))
- cab_package: Fail if the cab does not apply to the current windows image [#7992](https://github.com/chef/chef/pull/7992) ([tas50](https://github.com/tas50))
- gem_package: support the --no-document flag needed for Ruby 2.6 / rubygems 3 [#7994](https://github.com/chef/chef/pull/7994) ([tas50](https://github.com/tas50))
- windows_share: Avoid ConvertTo-Json errors on Windows 2012r2 with powershell 4 [#7991](https://github.com/chef/chef/pull/7991) ([tas50](https://github.com/tas50))
- apt_package: Support downgrades for apt packages [#7993](https://github.com/chef/chef/pull/7993) ([tas50](https://github.com/tas50))
- Make sure which mixin requires chef_class [#7995](https://github.com/chef/chef/pull/7995) ([tas50](https://github.com/tas50))
- Bump inspec-core to 3.0.61 [#8002](https://github.com/chef/chef/pull/8002) ([chef-ci](https://github.com/chef-ci))
- dnf_package: Add RHEL 8 support [#8006](https://github.com/chef/chef/pull/8006) ([tas50](https://github.com/tas50))
- Bump ohai to 14.8.10 for improved virtualization and platform detection [#8019](https://github.com/chef/chef/pull/8019) ([chef-ci](https://github.com/chef-ci))
- Make sure the ohai CLI uses the same version of ohai as chef-client [#8020](https://github.com/chef/chef/pull/8020) ([tas50](https://github.com/tas50))

## [v14.7.17](https://github.com/chef/chef/tree/v14.7.17) (2018-11-08)

#### Merged Pull Requests
- Allow passing array to supports in mount resource again [#7809](https://github.com/chef/chef/pull/7809) ([tas50](https://github.com/tas50))
- Automated resource documentation improvements [#7811](https://github.com/chef/chef/pull/7811) ([tas50](https://github.com/tas50))
- Backport: Add macOS support to the timezone resource [#7830](https://github.com/chef/chef/pull/7830) ([tas50](https://github.com/tas50))
- Backport: Fix inspector to properly handle defaults that are symbols [#7826](https://github.com/chef/chef/pull/7826) ([tas50](https://github.com/tas50))
- Backport: Fix SLES 15 upgrades removing the symlinks [#7827](https://github.com/chef/chef/pull/7827) ([tas50](https://github.com/tas50))
- Backport: Add windows_share and windows_certificate resources [#7833](https://github.com/chef/chef/pull/7833) ([tas50](https://github.com/tas50))
- Backport: Handle `interactive_enabled` property in windows_task resource [#7832](https://github.com/chef/chef/pull/7832) ([tas50](https://github.com/tas50))
- Backport: Multiple fixes to dmg_package including functional EULA acceptance [#7831](https://github.com/chef/chef/pull/7831) ([tas50](https://github.com/tas50))
- Backport: Fix chef-apply crash for reboot [#7828](https://github.com/chef/chef/pull/7828) ([tas50](https://github.com/tas50))
- Update win32-taskscheduler to 2.0.1 [#7844](https://github.com/chef/chef/pull/7844) ([tas50](https://github.com/tas50))
- Backport: Added `description` property on windows_task resource [#7848](https://github.com/chef/chef/pull/7848) ([btm](https://github.com/btm))
- Backport: Add default_descriptions to properties [#7873](https://github.com/chef/chef/pull/7873) ([tas50](https://github.com/tas50))
- Backport: Make knife command banners consistent [#7874](https://github.com/chef/chef/pull/7874) ([tas50](https://github.com/tas50))
- Add more validation_messages to properties [#7875](https://github.com/chef/chef/pull/7875) ([tas50](https://github.com/tas50))
- Backport: Add windows_firewall_rule resource [#7876](https://github.com/chef/chef/pull/7876) ([tas50](https://github.com/tas50))
- Backport: Resource property description updates [#7887](https://github.com/chef/chef/pull/7887) ([tas50](https://github.com/tas50))
- Backport: Allow multiple local and remote ports in the windows_firewall_rule resource [#7888](https://github.com/chef/chef/pull/7888) ([tas50](https://github.com/tas50))
- Backport: Defer running initramfs_command until end of run [#7889](https://github.com/chef/chef/pull/7889) ([tas50](https://github.com/tas50))
- fix whitespace in node attributes [ci skip] [#7891](https://github.com/chef/chef/pull/7891) ([lamont-granquist](https://github.com/lamont-granquist))

## [v14.6.47](https://github.com/chef/chef/tree/v14.6.47) (2018-10-26)

#### Merged Pull Requests
- zypper_package: Add new global_options property [#7518](https://github.com/chef/chef/pull/7518) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Bump chef-vault to 3.4.2 [#7675](https://github.com/chef/chef/pull/7675) ([chef-ci](https://github.com/chef-ci))
- Adds full_name property to user resource for Windows. [#7677](https://github.com/chef/chef/pull/7677) ([Vasu1105](https://github.com/Vasu1105))
- Upgrade to rspec 3.8.x [#7691](https://github.com/chef/chef/pull/7691) ([lamont-granquist](https://github.com/lamont-granquist))
- Fixed introduced version to 14.6 for newly added properties in zypper_package and windows_user resource as it got released in 14.6. [#7692](https://github.com/chef/chef/pull/7692) ([Vasu1105](https://github.com/Vasu1105))
- Minor optimization in yum_helper.py to avoid RPM DB corruption under certain scenarios [#7696](https://github.com/chef/chef/pull/7696) ([Nimesh-Msys](https://github.com/Nimesh-Msys))
- replace some instances of to_hash with to_h [#7697](https://github.com/chef/chef/pull/7697) ([lamont-granquist](https://github.com/lamont-granquist))
- Sanitize inputs to Gem::Version in comparison operation of Package provider superclass [#7703](https://github.com/chef/chef/pull/7703) ([lamont-granquist](https://github.com/lamont-granquist))
- Change the allow_downgrade pseudo-default in the package provider superclass to true [#7701](https://github.com/chef/chef/pull/7701) ([lamont-granquist](https://github.com/lamont-granquist))
- short circuit before the version_compare call [#7705](https://github.com/chef/chef/pull/7705) ([lamont-granquist](https://github.com/lamont-granquist))
- add some big FIXMEs [#7706](https://github.com/chef/chef/pull/7706) ([lamont-granquist](https://github.com/lamont-granquist))
- fixed typo in description property of rhsm_errata_level resource [#7710](https://github.com/chef/chef/pull/7710) ([freakinhippie](https://github.com/freakinhippie))
- Bump inspec-core to 2.3.5 [#7709](https://github.com/chef/chef/pull/7709) ([chef-ci](https://github.com/chef-ci))
- Bump inspec-core to 2.3.10 [#7723](https://github.com/chef/chef/pull/7723) ([chef-ci](https://github.com/chef-ci))
- Add chef-cleanup omnibus-software defn [#7725](https://github.com/chef/chef/pull/7725) ([lamont-granquist](https://github.com/lamont-granquist))
- better docs for Chef::Knife::Bootstrap#validate_options! [#7719](https://github.com/chef/chef/pull/7719) ([bankair](https://github.com/bankair))
- Cleanup the Test Kitchen setup in omnibus [#7726](https://github.com/chef/chef/pull/7726) ([tas50](https://github.com/tas50))
- Only include the Windows distro files on Windows [#7727](https://github.com/chef/chef/pull/7727) ([tas50](https://github.com/tas50))
- Add the timezone resource from the timezone_lwrp cookbook [#7736](https://github.com/chef/chef/pull/7736) ([tas50](https://github.com/tas50))
- Enable x86_64-linux-kernel2 habitat builds for chef-client [#7722](https://github.com/chef/chef/pull/7722) ([smacfarlane](https://github.com/smacfarlane))
- Bump win32-taskscheduler to 1.0.12 [#7740](https://github.com/chef/chef/pull/7740) ([chef-ci](https://github.com/chef-ci))
- Bump ohai to 14.6.2 [#7742](https://github.com/chef/chef/pull/7742) ([chef-ci](https://github.com/chef-ci))
- Bump win32-taskscheduler to 2.0 [#7743](https://github.com/chef/chef/pull/7743) ([btm](https://github.com/btm))
- When a property regex fails don&#39;t call it an option [#7745](https://github.com/chef/chef/pull/7745) ([tas50](https://github.com/tas50))
- Bump inspec-core to 2.3.23 [#7747](https://github.com/chef/chef/pull/7747) ([chef-ci](https://github.com/chef-ci))
- Bump inspec-core to 2.3.24 [#7748](https://github.com/chef/chef/pull/7748) ([chef-ci](https://github.com/chef-ci))
- Update omnibus deps [#7749](https://github.com/chef/chef/pull/7749) ([tas50](https://github.com/tas50))
- Update Nokogiri to 1.8.5 [#7750](https://github.com/chef/chef/pull/7750) ([tas50](https://github.com/tas50))
- Node Attributes: Build ImmutableMash properly in deep_merge! [#7752](https://github.com/chef/chef/pull/7752) ([lamont-granquist](https://github.com/lamont-granquist))
- File provider:  fix sticky bits management / preservation [#7753](https://github.com/chef/chef/pull/7753) ([lamont-granquist](https://github.com/lamont-granquist))
- Run more Travis tests on Ruby 2.5.1 [#7755](https://github.com/chef/chef/pull/7755) ([tas50](https://github.com/tas50))
- Add support for localized system account to windows_task resource [#7679](https://github.com/chef/chef/pull/7679) ([jugatsu](https://github.com/jugatsu))
- Update omnibus to use ruby-cleanup definition [#7757](https://github.com/chef/chef/pull/7757) ([tas50](https://github.com/tas50))
- Bump mixlib-archive to 0.4.18 [#7759](https://github.com/chef/chef/pull/7759) ([chef-ci](https://github.com/chef-ci))
- Bump train-core to 1.5.4 [#7760](https://github.com/chef/chef/pull/7760) ([chef-ci](https://github.com/chef-ci))
- Update Ruby to 2.5.3 [#7766](https://github.com/chef/chef/pull/7766) ([tas50](https://github.com/tas50))
- [chef/chef]Fix duplicate logs [#7698](https://github.com/chef/chef/pull/7698) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Throw better error on invalid resources actions [#7729](https://github.com/chef/chef/pull/7729) ([tas50](https://github.com/tas50))
- Don&#39;t ship contributing.md and VERSION file in the gem [#7769](https://github.com/chef/chef/pull/7769) ([tas50](https://github.com/tas50))
- Fix registry key bug when sensitive is true [#7767](https://github.com/chef/chef/pull/7767) ([josh-barker](https://github.com/josh-barker))
- Use the Chefstyle gem instead of a git checkout [#7770](https://github.com/chef/chef/pull/7770) ([tas50](https://github.com/tas50))
- Switch back to chefstyle from git and use the updated chef omnibus def [#7772](https://github.com/chef/chef/pull/7772) ([tas50](https://github.com/tas50))
- Update InSpec to 3.0 [#7773](https://github.com/chef/chef/pull/7773) ([tas50](https://github.com/tas50))
- Update chef-vault and serverspec to the latest [#7774](https://github.com/chef/chef/pull/7774) ([tas50](https://github.com/tas50))
- Move iso8601 gem to windows only gemspec [#7778](https://github.com/chef/chef/pull/7778) ([tas50](https://github.com/tas50))
- Add some retry/delay in HTTP functional tests [#7780](https://github.com/chef/chef/pull/7780) ([schisamo](https://github.com/schisamo))
- Pin rake to 12.3.0 to prevent installing 2 copies in our install [#7779](https://github.com/chef/chef/pull/7779) ([tas50](https://github.com/tas50))
- Fix locale on RHEL 6 / Amazon Linux [#7782](https://github.com/chef/chef/pull/7782) ([tas50](https://github.com/tas50))

## [v14.5.33](https://github.com/chef/chef/tree/v14.5.33) (2018-09-25)

#### Merged Pull Requests
- windows_service: Remove potentially sensitive info from the log [#7659](https://github.com/chef/chef/pull/7659) ([stuartpreston](https://github.com/stuartpreston))
- windows_feature: Fix exception message grammar [#7669](https://github.com/chef/chef/pull/7669) ([dgreeninger](https://github.com/dgreeninger))
- Add @jjlimepoint as a maintainer for chef-provisioning [#7649](https://github.com/chef/chef/pull/7649) ([jjlimepoint](https://github.com/jjlimepoint))
- Deprecate ohai resource&#39;s ohai_name property [#7667](https://github.com/chef/chef/pull/7667) ([tas50](https://github.com/tas50))
- Fix failures in windows_ad_join in 14.5.27 [#7673](https://github.com/chef/chef/pull/7673) ([tas50](https://github.com/tas50))
- Update to the latest omnibus-software for builds [#7676](https://github.com/chef/chef/pull/7676) ([tas50](https://github.com/tas50))

## [v14.5.27](https://github.com/chef/chef/tree/v14.5.27) (2018-09-20)

#### Merged Pull Requests
- Bump mixlib-archive to 0.4.16 [#7595](https://github.com/chef/chef/pull/7595) ([chef-ci](https://github.com/chef-ci))
- Add additional property docs + update existing docs [#7600](https://github.com/chef/chef/pull/7600) ([tas50](https://github.com/tas50))
- Simplify the rake task to updating gem dependencies [#7602](https://github.com/chef/chef/pull/7602) ([lamont-granquist](https://github.com/lamont-granquist))
- Build chef omnibus package with Chef 14 / Berkshelf 7 [#7603](https://github.com/chef/chef/pull/7603) ([tas50](https://github.com/tas50))
- windows_auto_run: Avoid declare_resource where it&#39;s not needed [#7608](https://github.com/chef/chef/pull/7608) ([tas50](https://github.com/tas50))
- Allow resource_inspector be used outside the binary [#7609](https://github.com/chef/chef/pull/7609) ([tas50](https://github.com/tas50))
- Update property descriptions and remove extra nil types [#7604](https://github.com/chef/chef/pull/7604) ([tas50](https://github.com/tas50))
- Update inspec-core to 2.2.78 [#7606](https://github.com/chef/chef/pull/7606) ([tas50](https://github.com/tas50))
- Shorten the resource collision deprecation message [#7601](https://github.com/chef/chef/pull/7601) ([lamont-granquist](https://github.com/lamont-granquist))
- Update rubyzip to 1.2.2 [#7618](https://github.com/chef/chef/pull/7618) ([tas50](https://github.com/tas50))
- Remove the CBGB [#7619](https://github.com/chef/chef/pull/7619) ([nathenharvey](https://github.com/nathenharvey))
- Add additional resource descriptions [#7623](https://github.com/chef/chef/pull/7623) ([tas50](https://github.com/tas50))
- Remove unnecessary declare_resource usage in build_essential [#7624](https://github.com/chef/chef/pull/7624) ([tas50](https://github.com/tas50))
- Add introduced versions for properties and more descriptions [#7627](https://github.com/chef/chef/pull/7627) ([tas50](https://github.com/tas50))
- Properly capitalize PowerShell in descriptions and errors [#7630](https://github.com/chef/chef/pull/7630) ([tas50](https://github.com/tas50))
- Add required properties to the resource inspector output [#7631](https://github.com/chef/chef/pull/7631) ([tas50](https://github.com/tas50))
- Fix remote_directory does not obey removal of file specificity [#7551](https://github.com/chef/chef/pull/7551) ([thechile](https://github.com/thechile))
- Update expeditor config to use subscriptions [#7632](https://github.com/chef/chef/pull/7632) ([tas50](https://github.com/tas50))
- paludis_package: Make sure timeout property is an Integer [#7625](https://github.com/chef/chef/pull/7625) ([tas50](https://github.com/tas50))
- Add locale resource more managing the system&#39;s locale [#7633](https://github.com/chef/chef/pull/7633) ([vincentaubert](https://github.com/vincentaubert))
- windows_ad_join resource - add newname property [#7637](https://github.com/chef/chef/pull/7637) ([derekgroh](https://github.com/derekgroh))
- Bump inspec-core to 2.2.101 [#7640](https://github.com/chef/chef/pull/7640) ([chef-ci](https://github.com/chef-ci))
- windows_workgroup Resource for joining Windows Workgroups [#7564](https://github.com/chef/chef/pull/7564) ([derekgroh](https://github.com/derekgroh))
- Update libarchive to 3.3.3 [#7641](https://github.com/chef/chef/pull/7641) ([tas50](https://github.com/tas50))
- Rename windows_ad_join&#39;s newname to be new_hostname [#7643](https://github.com/chef/chef/pull/7643) ([tas50](https://github.com/tas50))
- Bump ohai to 14.5.0 [#7644](https://github.com/chef/chef/pull/7644) ([chef-ci](https://github.com/chef-ci))
- Fix resource descriptions for ohai_hint and rhsm_errata_level [#7645](https://github.com/chef/chef/pull/7645) ([tas50](https://github.com/tas50))
- More Resource doc fixes [#7646](https://github.com/chef/chef/pull/7646) ([tas50](https://github.com/tas50))
- Move subversion properties out of scm and into subversion [#7648](https://github.com/chef/chef/pull/7648) ([tas50](https://github.com/tas50))
- Bump InSpec and Ohai to the latest [#7657](https://github.com/chef/chef/pull/7657) ([tas50](https://github.com/tas50))
- Add Chef 14.5 release notes [#7652](https://github.com/chef/chef/pull/7652) ([tas50](https://github.com/tas50))
- Pull in updated omnibus-software [#7658](https://github.com/chef/chef/pull/7658) ([tas50](https://github.com/tas50))
- Update script resource deprecation waring [#7651](https://github.com/chef/chef/pull/7651) ([tas50](https://github.com/tas50))
- Remove Bryant Lippert as a FreeBSD maintainer [#7654](https://github.com/chef/chef/pull/7654) ([tas50](https://github.com/tas50))
- Wire up openssl_x509 [#7660](https://github.com/chef/chef/pull/7660) ([tas50](https://github.com/tas50))

## [v14.4.56](https://github.com/chef/chef/tree/v14.4.56) (2018-08-29)

#### Merged Pull Requests
- [MSYS-843] - Add remove_account_right function to win32/security [#7445](https://github.com/chef/chef/pull/7445) ([Nimesh-Msys](https://github.com/Nimesh-Msys))
- Add proper yard deprecated tags on methods [#7452](https://github.com/chef/chef/pull/7452) ([tas50](https://github.com/tas50))
- Remove require mixlib/shellouts where not necessary [#7457](https://github.com/chef/chef/pull/7457) ([tas50](https://github.com/tas50))
- Add knife config get/use-profile commands [#7455](https://github.com/chef/chef/pull/7455) ([coderanger](https://github.com/coderanger))
- Fixing array args in some unix providers [#7379](https://github.com/chef/chef/pull/7379) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix duplicated query parameters to resolve Chef::HTTP::Simple regression [#7465](https://github.com/chef/chef/pull/7465) ([lamont-granquist](https://github.com/lamont-granquist))
- Move all knife cookbook site plugin logic into knife supermarket [#7466](https://github.com/chef/chef/pull/7466) ([tas50](https://github.com/tas50))
- Improve the error message when knife bootstrap windows isn&#39;t installed  [#7470](https://github.com/chef/chef/pull/7470) ([tas50](https://github.com/tas50))
- Remove require json_compat where not used [#7472](https://github.com/chef/chef/pull/7472) ([tas50](https://github.com/tas50))
- Make gem_installer generate a valid Gemfile [#6168](https://github.com/chef/chef/pull/6168) ([oclaussen](https://github.com/oclaussen))
- Bump version to 14.4.0 [#7476](https://github.com/chef/chef/pull/7476) ([tas50](https://github.com/tas50))
- add back clean_array API [#7477](https://github.com/chef/chef/pull/7477) ([lamont-granquist](https://github.com/lamont-granquist))
- ifconfig: Allow specifying VLAN on RHEL/Centos [#7478](https://github.com/chef/chef/pull/7478) ([tas50](https://github.com/tas50))
- Allow specifying VLAN &amp; Gateway on RHEL/Centos [#6400](https://github.com/chef/chef/pull/6400) ([tomdoherty](https://github.com/tomdoherty))
- group: convert to properties with descriptions and improve comma separated parsing [#7474](https://github.com/chef/chef/pull/7474) ([tas50](https://github.com/tas50))
- Pull in the latest inspec-core and train-core [#7487](https://github.com/chef/chef/pull/7487) ([tas50](https://github.com/tas50))
- ifconfig: Add gateway property on RHEL/Debian based systems [#7475](https://github.com/chef/chef/pull/7475) ([tas50](https://github.com/tas50))
- Expand platform support for the route resource [#7480](https://github.com/chef/chef/pull/7480) ([tas50](https://github.com/tas50))
- Handling Quotes in Windows Task Commands and Arguments [#7497](https://github.com/chef/chef/pull/7497) ([Nimesh-Msys](https://github.com/Nimesh-Msys))
- Functional tests: Ensure we logon with the local security_user account [#7498](https://github.com/chef/chef/pull/7498) ([stuartpreston](https://github.com/stuartpreston))
- Make sure knife descriptions all have periods [#7473](https://github.com/chef/chef/pull/7473) ([tas50](https://github.com/tas50))
- Add minor version bumping to Expeditor config [#7501](https://github.com/chef/chef/pull/7501) ([tas50](https://github.com/tas50))
- Bump version of ISO8601 to latest (0.11.0) [#7505](https://github.com/chef/chef/pull/7505) ([Nimesh-Msys](https://github.com/Nimesh-Msys))
- Assume credentials supplied are still valid if they cannot be validated due to a Windows account restriction [#7416](https://github.com/chef/chef/pull/7416) ([stuartpreston](https://github.com/stuartpreston))
- Add support for setting task priority [#7464](https://github.com/chef/chef/pull/7464) ([Vasu1105](https://github.com/Vasu1105))
- Add additional resource descriptions [#7506](https://github.com/chef/chef/pull/7506) ([tas50](https://github.com/tas50))
- [SHACK-304] Deprecation checking turns up false positive [#7515](https://github.com/chef/chef/pull/7515) ([tyler-ball](https://github.com/tyler-ball))
- MSYS-858 : added warning if allow_downgrade set to be false and tried to install older version [#7495](https://github.com/chef/chef/pull/7495) ([piyushawasthi](https://github.com/piyushawasthi))
- Always update both the loaded sysctl value and the sysctl.d value on disk [#7519](https://github.com/chef/chef/pull/7519) ([Nimesh-Msys](https://github.com/Nimesh-Msys))
- [SHACK-290] Unpacking tarball paths suffer from URI error [#7523](https://github.com/chef/chef/pull/7523) ([tyler-ball](https://github.com/tyler-ball))
- Prevent failures RHSM resources by using default_env in execute resources [#7520](https://github.com/chef/chef/pull/7520) ([tas50](https://github.com/tas50))
- add chef_version API to provides lines [#7524](https://github.com/chef/chef/pull/7524) ([lamont-granquist](https://github.com/lamont-granquist))
- Maybe hold off on rspec 3.8 [#7527](https://github.com/chef/chef/pull/7527) ([cheeseplus](https://github.com/cheeseplus))
- stop parsing init script at the &quot;### END INIT INFO&quot; marker. [#7525](https://github.com/chef/chef/pull/7525) ([goblin23](https://github.com/goblin23))
- Bump Ohai to 14.4 [#7532](https://github.com/chef/chef/pull/7532) ([tas50](https://github.com/tas50))
- Update omnibus to 5.6.15 [#7536](https://github.com/chef/chef/pull/7536) ([tas50](https://github.com/tas50))
- Update inspec to 2.2.61 [#7534](https://github.com/chef/chef/pull/7534) ([tas50](https://github.com/tas50))
- osx_profile: Use the full path to /usr/bin/profiles [#7539](https://github.com/chef/chef/pull/7539) ([tas50](https://github.com/tas50))
- Run rspec tests within a kitchen container on CentOS 7 [#7529](https://github.com/chef/chef/pull/7529) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix issue of setting comment for windows user [#7537](https://github.com/chef/chef/pull/7537) ([NAshwini](https://github.com/NAshwini))
- Require mixlib-shellout 2.4 or later [#7543](https://github.com/chef/chef/pull/7543) ([tas50](https://github.com/tas50))
- windows_package: Fix package sensitive error [#7353](https://github.com/chef/chef/pull/7353) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Add cron_d and cron_access resources [#7253](https://github.com/chef/chef/pull/7253) ([tas50](https://github.com/tas50))
- Update to openssl 1.0.2p [#7546](https://github.com/chef/chef/pull/7546) ([tas50](https://github.com/tas50))
- Add new openssl resources: ec_private_key, ec_public_key, certificate, and x509_request [#7513](https://github.com/chef/chef/pull/7513) ([tas50](https://github.com/tas50))
- Fix failed RHEL6 32-bit functional tests [#7555](https://github.com/chef/chef/pull/7555) ([lamont-granquist](https://github.com/lamont-granquist))
- Restart Python yum helper before each repo enable/disable [#7558](https://github.com/chef/chef/pull/7558) ([cosinusoidally](https://github.com/cosinusoidally))
- Support for battery power options in windows_task resource [#7483](https://github.com/chef/chef/pull/7483) ([dheerajd-msys](https://github.com/dheerajd-msys))
- support repeated options in systemd_unit [#7560](https://github.com/chef/chef/pull/7560) ([dbresson](https://github.com/dbresson))
- Validatorless bootstrap fix [#7562](https://github.com/chef/chef/pull/7562) ([coderanger](https://github.com/coderanger))
- Pull in the latest InSpec and Ohai [#7563](https://github.com/chef/chef/pull/7563) ([tas50](https://github.com/tas50))
- switch shell_out to shell_out! in func tests [#7565](https://github.com/chef/chef/pull/7565) ([lamont-granquist](https://github.com/lamont-granquist))
- Update to Ohai 14.4.2 [#7570](https://github.com/chef/chef/pull/7570) ([tas50](https://github.com/tas50))
- lazy the default resource_name until after parsing [#7566](https://github.com/chef/chef/pull/7566) ([lamont-granquist](https://github.com/lamont-granquist))
- Modernize our Rakefile / Version bumping system [#7574](https://github.com/chef/chef/pull/7574) ([tas50](https://github.com/tas50))
- Fix rake task to build the correct gemspec on Chef [#7579](https://github.com/chef/chef/pull/7579) ([tas50](https://github.com/tas50))
- Pull in latest omnibus definitions + new inspec/train [#7581](https://github.com/chef/chef/pull/7581) ([tas50](https://github.com/tas50))
- Simplify / fix our yard doc Rake task [#7580](https://github.com/chef/chef/pull/7580) ([tas50](https://github.com/tas50))
- Update the announcement rake task with kitchen examples [#7583](https://github.com/chef/chef/pull/7583) ([tas50](https://github.com/tas50))
-  Add openssl_x509_crl resource and fix default modes in x509_certificate / x509_request  [#7586](https://github.com/chef/chef/pull/7586) ([tas50](https://github.com/tas50))
- Add missing description to windows_feature_powershell [#7587](https://github.com/chef/chef/pull/7587) ([tas50](https://github.com/tas50))
- Resolve new_resource error with cron_d resource [#7588](https://github.com/chef/chef/pull/7588) ([tas50](https://github.com/tas50))
- openssl resources: Improve descriptions and fix provides for Chef 14.X [#7590](https://github.com/chef/chef/pull/7590) ([tas50](https://github.com/tas50))
- Be more explicit in disabling provides for openssl_x509 [#7591](https://github.com/chef/chef/pull/7591) ([tas50](https://github.com/tas50))

## [v14.3.37](https://github.com/chef/chef/tree/v14.3.37) (2018-07-11)

#### Merged Pull Requests
- Expand development docs with branch/backport + more [#7343](https://github.com/chef/chef/pull/7343) ([tas50](https://github.com/tas50))
- Add skip_publisher_check property to powershell_package [#7259](https://github.com/chef/chef/pull/7259) ([Happycoil](https://github.com/Happycoil))
- Support windows_feature_powershell on Windows 2008 R2 [#7349](https://github.com/chef/chef/pull/7349) ([tas50](https://github.com/tas50))
- Bump the version to 14.3.0 [#7346](https://github.com/chef/chef/pull/7346) ([tas50](https://github.com/tas50))
- Deprecated the Chef::Provider::Package::Freebsd::Pkg provider [#7350](https://github.com/chef/chef/pull/7350) ([tas50](https://github.com/tas50))
- Make shell_out_compact automatically pull timeouts off the resource + remove uses of shell_out_compact_timeout [#7330](https://github.com/chef/chef/pull/7330) ([lamont-granquist](https://github.com/lamont-granquist))
- Add whyrun message when installing a local file on Windows [#7351](https://github.com/chef/chef/pull/7351) ([josh-barker](https://github.com/josh-barker))
- Implement rfc107: NodeMap locking for resource and provider handlers [#7224](https://github.com/chef/chef/pull/7224) ([coderanger](https://github.com/coderanger))
- Update help link in Add/Remove Programs on Windows [#7345](https://github.com/chef/chef/pull/7345) ([stuartpreston](https://github.com/stuartpreston))
- Add ssh_known_hosts_entry resource from ssh_known_hosts cookbook [#7161](https://github.com/chef/chef/pull/7161) ([tas50](https://github.com/tas50))
- Add kernel_module resource from the kernel_module cookbook [#7165](https://github.com/chef/chef/pull/7165) ([tas50](https://github.com/tas50))
- Mount: Fix errors on Windows when using the mount_point property [#7284](https://github.com/chef/chef/pull/7284) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Update to the latest inspec and liblzma [#7355](https://github.com/chef/chef/pull/7355) ([tas50](https://github.com/tas50))
- Add missing chef/resource requires in resource [#7364](https://github.com/chef/chef/pull/7364) ([tas50](https://github.com/tas50))
- package: Make sure to use the package_name name properties [#7365](https://github.com/chef/chef/pull/7365) ([tas50](https://github.com/tas50))
- windows_feature_dism: Fix errors when specifying the source [#7370](https://github.com/chef/chef/pull/7370) ([tas50](https://github.com/tas50))
- Add more property descriptions to resources [#7358](https://github.com/chef/chef/pull/7358) ([tas50](https://github.com/tas50))
- removing mwrock from client maintainers [#7369](https://github.com/chef/chef/pull/7369) ([mwrock](https://github.com/mwrock))
- Pull in win32-taskscheduler 1.0.2 [#7371](https://github.com/chef/chef/pull/7371) ([tas50](https://github.com/tas50))
- windows_task: Don&#39;t allow bad username/password to be provided to a task which will fail later [#7288](https://github.com/chef/chef/pull/7288) ([Vasu1105](https://github.com/Vasu1105))
- windows_task: Fix for task is not idempotent when task name includes parent folder [#7293](https://github.com/chef/chef/pull/7293) ([Vasu1105](https://github.com/Vasu1105))
- Remove awesome customers testing and update kitchen configs [#7377](https://github.com/chef/chef/pull/7377) ([tas50](https://github.com/tas50))
- Silence deprecation warnings [#7375](https://github.com/chef/chef/pull/7375) ([coderanger](https://github.com/coderanger))
- Remove the unused audit test cookbook [#7378](https://github.com/chef/chef/pull/7378) ([tas50](https://github.com/tas50))
- Unification of shell_out APIs [#7372](https://github.com/chef/chef/pull/7372) ([lamont-granquist](https://github.com/lamont-granquist))
- Rework the credentials file system to support any config keys. [#7387](https://github.com/chef/chef/pull/7387) ([coderanger](https://github.com/coderanger))
- deprecate old shell_out APIs [#7382](https://github.com/chef/chef/pull/7382) ([lamont-granquist](https://github.com/lamont-granquist))
- Add missing knife license headers [#7397](https://github.com/chef/chef/pull/7397) ([tas50](https://github.com/tas50))
- Add chocolatey_config and chocolatey_source resources [#7388](https://github.com/chef/chef/pull/7388) ([tas50](https://github.com/tas50))
- Remove the existing acceptance testing framework [#7399](https://github.com/chef/chef/pull/7399) ([tas50](https://github.com/tas50))
- Remove sudo/gcc-c++ package installs from kitchen tests [#7398](https://github.com/chef/chef/pull/7398) ([tas50](https://github.com/tas50))
- Add missing require knife [#7400](https://github.com/chef/chef/pull/7400) ([tas50](https://github.com/tas50))
- Switch powershell_exec mixin to use FFI instead of COM [#7380](https://github.com/chef/chef/pull/7380) ([stuartpreston](https://github.com/stuartpreston))
- Rename the kitchen base test suite to end-to-end [#7385](https://github.com/chef/chef/pull/7385) ([tas50](https://github.com/tas50))
- Pull in new InSpec and win32-service [#7405](https://github.com/chef/chef/pull/7405) ([tas50](https://github.com/tas50))
- Chefstyle fixes [#7414](https://github.com/chef/chef/pull/7414) ([lamont-granquist](https://github.com/lamont-granquist))
- More chefstyle updates [#7415](https://github.com/chef/chef/pull/7415) ([lamont-granquist](https://github.com/lamont-granquist))
- chefstyle: fix Style/MutableConstant [#7417](https://github.com/chef/chef/pull/7417) ([lamont-granquist](https://github.com/lamont-granquist))
- knife config and a bunch of UX improvements [#7390](https://github.com/chef/chef/pull/7390) ([coderanger](https://github.com/coderanger))
- fix some chefstyle offenses [#7427](https://github.com/chef/chef/pull/7427) ([lamont-granquist](https://github.com/lamont-granquist))
- Don&#39;t require rubygems in our binaries [#7428](https://github.com/chef/chef/pull/7428) ([tas50](https://github.com/tas50))
- bump chefstyle + inspec-core [#7431](https://github.com/chef/chef/pull/7431) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix dupe stdout_logger [#7401](https://github.com/chef/chef/pull/7401) ([nsdavidson](https://github.com/nsdavidson))
- Prevent failures using windows_feature due to the platform helper [#7433](https://github.com/chef/chef/pull/7433) ([tas50](https://github.com/tas50))
- Bump Ohai to 14.3.0 [#7437](https://github.com/chef/chef/pull/7437) ([tas50](https://github.com/tas50))
- Enable Amazon Linux 2.0 tests again [#7442](https://github.com/chef/chef/pull/7442) ([tas50](https://github.com/tas50))
- Add missing descriptions and add periods after resource the descriptions [#7444](https://github.com/chef/chef/pull/7444) ([tas50](https://github.com/tas50))
- Attributes -&gt; Properties in a few more resources [#7448](https://github.com/chef/chef/pull/7448) ([tas50](https://github.com/tas50))

## [v14.2.0](https://github.com/chef/chef/tree/v14.2.0) (2018-06-07)

#### Merged Pull Requests
- publish habitat packages [#7272](https://github.com/chef/chef/pull/7272) ([thommay](https://github.com/thommay))
- improved regex accuracy lib/chef/resource/hostname.rb [#7262](https://github.com/chef/chef/pull/7262) ([bottkv488](https://github.com/bottkv488))
- Add additional unit tests for resource actions/properties [#7266](https://github.com/chef/chef/pull/7266) ([tas50](https://github.com/tas50))
- Add additional resource unit tests [#7275](https://github.com/chef/chef/pull/7275) ([tas50](https://github.com/tas50))
- Add default_action to the resource inspector [#7276](https://github.com/chef/chef/pull/7276) ([tas50](https://github.com/tas50))
- UID now starts at 501, uses createhomedir instead [#4903](https://github.com/chef/chef/pull/4903) ([nmcspadden](https://github.com/nmcspadden))
- [MSYS-817] fix for windows_task does not parse backslashes in the commad property [#7281](https://github.com/chef/chef/pull/7281) ([Vasu1105](https://github.com/Vasu1105))
- object validation for DataHandlerBase#normalize_hash [#7264](https://github.com/chef/chef/pull/7264) ([jeremymv2](https://github.com/jeremymv2))
- Fix manifest entries for root files [#7270](https://github.com/chef/chef/pull/7270) ([thommay](https://github.com/thommay))
- Fix systemd_unit user context [#7274](https://github.com/chef/chef/pull/7274) ([mal](https://github.com/mal))
- Cleanup AIX and Solaris user resources. [#7249](https://github.com/chef/chef/pull/7249) ([lamont-granquist](https://github.com/lamont-granquist))
- Cookbook Version:  add host-&lt;fqdn&gt; to the error message for templates and files specificity [#7295](https://github.com/chef/chef/pull/7295) ([lamont-granquist](https://github.com/lamont-granquist))
- add default_env flag to shell_out and execute resource [#7298](https://github.com/chef/chef/pull/7298) ([lamont-granquist](https://github.com/lamont-granquist))
- Properly print path to config file to the screen in knife configure [#7325](https://github.com/chef/chef/pull/7325) ([tas50](https://github.com/tas50))
- windows_ad_join: Ensure that reboot requests work [#7328](https://github.com/chef/chef/pull/7328) ([thommay](https://github.com/thommay))
- Better errors with uninstalled official knife plugins [#7326](https://github.com/chef/chef/pull/7326) ([tas50](https://github.com/tas50))
- convert a_to_s to shell_out_compact in DNF/yum [#7313](https://github.com/chef/chef/pull/7313) ([lamont-granquist](https://github.com/lamont-granquist))
- Support signing with ssh-agent [#7324](https://github.com/chef/chef/pull/7324) ([coderanger](https://github.com/coderanger))
- fix yum versionlock quoting [#7329](https://github.com/chef/chef/pull/7329) ([lamont-granquist](https://github.com/lamont-granquist))
- resource_inspector: Add default values for properties [#7300](https://github.com/chef/chef/pull/7300) ([thommay](https://github.com/thommay))
- Check local file exists before installing a windows package [#7299](https://github.com/chef/chef/pull/7299) ([josh-barker](https://github.com/josh-barker))
- Fix :configure_startup action to configure delayed start [#7297](https://github.com/chef/chef/pull/7297) ([jasonwbarnett](https://github.com/jasonwbarnett))
- Allow securable resource tests to work on Windows 10 machines connected to an Azure Active Directory [#7301](https://github.com/chef/chef/pull/7301) ([stuartpreston](https://github.com/stuartpreston))
- Quote git remote_url property (PR 6249 + chefstyle fix) [#7014](https://github.com/chef/chef/pull/7014) ([tas50](https://github.com/tas50))
- Use inspec-core, new ffi gem, and bump deps [#7332](https://github.com/chef/chef/pull/7332) ([lamont-granquist](https://github.com/lamont-granquist))
- bump ohai to 14.2.0 [#7333](https://github.com/chef/chef/pull/7333) ([lamont-granquist](https://github.com/lamont-granquist))

## [v14.1.12](https://github.com/chef/chef/tree/v14.1.12) (2018-05-16)

#### Merged Pull Requests
- Remove redundant &quot;?&quot; in knife configure [#7235](https://github.com/chef/chef/pull/7235) ([alexymik](https://github.com/alexymik))
- Switch Node#role? to use the attributes expansion instead of the run list [#7234](https://github.com/chef/chef/pull/7234) ([coderanger](https://github.com/coderanger))
- fix git provider: -prune-tags is not available with old git versions, fixes #7233 [#7247](https://github.com/chef/chef/pull/7247) ([rmoriz](https://github.com/rmoriz))
- repo_name property should be part of new_resource object [#7252](https://github.com/chef/chef/pull/7252) ([tj-anderson](https://github.com/tj-anderson))
- remote_directory: restore overwrite default [#7254](https://github.com/chef/chef/pull/7254) ([rmoriz](https://github.com/rmoriz))
- apt_repository: Use the repo_name name property [#7244](https://github.com/chef/chef/pull/7244) ([tas50](https://github.com/tas50))
- Update Habitat plan to correctly build [#6111](https://github.com/chef/chef/pull/6111) ([elliott-davis](https://github.com/elliott-davis))
- Update Ohai to 14.1.3 [#7258](https://github.com/chef/chef/pull/7258) ([tas50](https://github.com/tas50))
- Fix windows_task resource not handling commands with arguments [#7250](https://github.com/chef/chef/pull/7250) ([Vasu1105](https://github.com/Vasu1105))
- Update win32-taskscheduler gem to fix creating tasks as the SYSTEM user [#7265](https://github.com/chef/chef/pull/7265) ([tas50](https://github.com/tas50))
- Use some unique task names for windows_task functional tests [#7267](https://github.com/chef/chef/pull/7267) ([btm](https://github.com/btm))

## [v14.1.1](https://github.com/chef/chef/tree/v14.1.1) (2018-05-08)

#### Merged Pull Requests
- fix for Red Hat Satellite yum_package bug [#7147](https://github.com/chef/chef/pull/7147) ([lamont-granquist](https://github.com/lamont-granquist))
- add name_property to resource inspector [#7164](https://github.com/chef/chef/pull/7164) ([thommay](https://github.com/thommay))
- Windows MSI: files are now re-unzipped during repair mode [#7111](https://github.com/chef/chef/pull/7111) ([stuartpreston](https://github.com/stuartpreston))
- Some options, i.e. metric, require specifying dev [#7162](https://github.com/chef/chef/pull/7162) ([tomdoherty](https://github.com/tomdoherty))
- Avoid conflict with build_powershell_command from powershell_out mixin [#7173](https://github.com/chef/chef/pull/7173) ([stuartpreston](https://github.com/stuartpreston))
- Ubuntu 1804 - passing tests and fixed ifconfig provider [#7174](https://github.com/chef/chef/pull/7174) ([thommay](https://github.com/thommay))
- CLI help text now includes :trace log level [#7186](https://github.com/chef/chef/pull/7186) ([stuartpreston](https://github.com/stuartpreston))
- Fix NoMethodError when (un)locking single packages in apt and zypper [#7138](https://github.com/chef/chef/pull/7138) ([RoboticCheese](https://github.com/RoboticCheese))
- Whitelist some additional Hash/Array methods [#7198](https://github.com/chef/chef/pull/7198) ([lamont-granquist](https://github.com/lamont-granquist))
- Convert some of remote_directory to use properties [#7204](https://github.com/chef/chef/pull/7204) ([tas50](https://github.com/tas50))
- Don&#39;t always request lazy files [#7208](https://github.com/chef/chef/pull/7208) ([thommay](https://github.com/thommay))
- Allow specifying `ignore_failure :quiet` to disable the error spew [#7194](https://github.com/chef/chef/pull/7194) ([coderanger](https://github.com/coderanger))
- [MSYS-752] windows task rewrite using win32-taskscheduler [#6815](https://github.com/chef/chef/pull/6815) ([Vasu1105](https://github.com/Vasu1105))
- Trying to use --recipe-url on Windows with local file fails [#7223](https://github.com/chef/chef/pull/7223) ([tyler-ball](https://github.com/tyler-ball))

## [v14.0.202](https://github.com/chef/chef/tree/v14.0.202) (2018-04-16)

#### Merged Pull Requests
- Update InSpec to 2.1.21 [#7109](https://github.com/chef/chef/pull/7109) ([tas50](https://github.com/tas50))
- add delegator for property_is_set? to providers [#7122](https://github.com/chef/chef/pull/7122) ([lamont-granquist](https://github.com/lamont-granquist))
- Modify the provides for all resources from cookbooks so chef wins [#7134](https://github.com/chef/chef/pull/7134) ([tas50](https://github.com/tas50))
- Fix RHSM registration using passwords [#7133](https://github.com/chef/chef/pull/7133) ([tas50](https://github.com/tas50))
- fix Chef-14 chef_fs/chef-zero perf regression [#7143](https://github.com/chef/chef/pull/7143) ([lamont-granquist](https://github.com/lamont-granquist))
- fix for enable/disable repo ordering [#7148](https://github.com/chef/chef/pull/7148) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix up knife logging [#7144](https://github.com/chef/chef/pull/7144) ([thommay](https://github.com/thommay))
- Add support for route metric [#7140](https://github.com/chef/chef/pull/7140) ([tomdoherty](https://github.com/tomdoherty))
- add the resources() dsl method back to providers [#7152](https://github.com/chef/chef/pull/7152) ([lamont-granquist](https://github.com/lamont-granquist))
- bump omnibus [#7157](https://github.com/chef/chef/pull/7157) ([lamont-granquist](https://github.com/lamont-granquist))
- add support for lock bot [#7136](https://github.com/chef/chef/pull/7136) ([lamont-granquist](https://github.com/lamont-granquist))
-  Catch json.load exceptions causing syslog errors  [#7155](https://github.com/chef/chef/pull/7155) ([tomdoherty](https://github.com/tomdoherty))

## [v14.0.190](https://github.com/chef/chef/tree/v14.0.190) (2018-04-03)

#### Merged Pull Requests
- Remove erl_call and deploy resources [#6753](https://github.com/chef/chef/pull/6753) ([tas50](https://github.com/tas50))
- Remove knife index rebuild command that requires Chef &lt; 11 [#6728](https://github.com/chef/chef/pull/6728) ([tas50](https://github.com/tas50))
- Remove deprecated -r option for Solo mode [#6719](https://github.com/chef/chef/pull/6719) ([tas50](https://github.com/tas50))
- Chef 14: Remove deprecated knife ssh csshx command [#6444](https://github.com/chef/chef/pull/6444) ([tas50](https://github.com/tas50))
- Add dhparam, rsa_private_key and rsa_public_key resources [#6736](https://github.com/chef/chef/pull/6736) ([tas50](https://github.com/tas50))
- Remove deprecated knife ssh --identity-file option [#6445](https://github.com/chef/chef/pull/6445) ([tas50](https://github.com/tas50))
- Prevent knife search --id-only from outputting IDs in the same format… [#6742](https://github.com/chef/chef/pull/6742) ([zanecodes](https://github.com/zanecodes))
- Remove update-rc.d -n (dryrun) option. [#6723](https://github.com/chef/chef/pull/6723) ([vinsonlee](https://github.com/vinsonlee))
- Remove unused chef_server_fqdn argument: run_status [#6670](https://github.com/chef/chef/pull/6670) ([jasonwbarnett](https://github.com/jasonwbarnett))
- Fixing missing and/or inconsistent quoting in knife search documentation [#6607](https://github.com/chef/chef/pull/6607) ([andyfeller](https://github.com/andyfeller))
- add create and delete actions for windows_service [#6595](https://github.com/chef/chef/pull/6595) ([jasonwbarnett](https://github.com/jasonwbarnett))
- Convert actions in Chef::Resource::Notification to symbols to prevent double notification [#6515](https://github.com/chef/chef/pull/6515) ([dimsh99](https://github.com/dimsh99))
- Revert &quot;add create and delete actions for windows_service&quot; [#6763](https://github.com/chef/chef/pull/6763) ([lamont-granquist](https://github.com/lamont-granquist))
- Rename the OpenSSL mixin to avoid name conflicts [#6764](https://github.com/chef/chef/pull/6764) ([tas50](https://github.com/tas50))
- Remove node.set and node.set_unless attribute levels [#6762](https://github.com/chef/chef/pull/6762) ([lamont-granquist](https://github.com/lamont-granquist))
- Convert node map to last-writer-wins for ties [#6765](https://github.com/chef/chef/pull/6765) ([lamont-granquist](https://github.com/lamont-granquist))
- [MSYS-727] Added support for setting node policy name and group from knife [#6656](https://github.com/chef/chef/pull/6656) ([piyushawasthi](https://github.com/piyushawasthi))
- Fail on interval runs on windows [#6766](https://github.com/chef/chef/pull/6766) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump to ruby 2.5.0 [#6770](https://github.com/chef/chef/pull/6770) ([thommay](https://github.com/thommay))
- Fix the changelog for the 13.7 release [#6772](https://github.com/chef/chef/pull/6772) ([tas50](https://github.com/tas50))
- Revert &quot;Fail on interval runs on windows&quot; [#6776](https://github.com/chef/chef/pull/6776) ([lamont-granquist](https://github.com/lamont-granquist))
- speed up http func tests [#6775](https://github.com/chef/chef/pull/6775) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix regression where message isn&#39;t an identity property in log resource [#6779](https://github.com/chef/chef/pull/6779) ([tas50](https://github.com/tas50))
- update immutable API blacklist and whitelist [#6778](https://github.com/chef/chef/pull/6778) ([lamont-granquist](https://github.com/lamont-granquist))
- Added idempotent checks to windows_task_spec [#6761](https://github.com/chef/chef/pull/6761) ([NAshwini](https://github.com/NAshwini))
- [MSYS-724] Chef::Util::Windows::LogonSession should allow having only the prescribed users permissions [#6687](https://github.com/chef/chef/pull/6687) ([NimishaS](https://github.com/NimishaS))
- allow uninstall of bundler to fail [#6789](https://github.com/chef/chef/pull/6789) ([lamont-granquist](https://github.com/lamont-granquist))
- fix node assignment of ImmutableArrays to VividMashes/AttrArrays [#6790](https://github.com/chef/chef/pull/6790) ([lamont-granquist](https://github.com/lamont-granquist))
- use a relative link so that docker does not drop our ca bundle link [#6796](https://github.com/chef/chef/pull/6796) ([thommay](https://github.com/thommay))
- Force the creation of a relative link for cacerts [#6798](https://github.com/chef/chef/pull/6798) ([thommay](https://github.com/thommay))
- Nillable properties are the default now [#6800](https://github.com/chef/chef/pull/6800) ([thommay](https://github.com/thommay))
- Remove epic_fail alias to ignore_failure [#6801](https://github.com/chef/chef/pull/6801) ([tas50](https://github.com/tas50))
- Use attempt or attempts in the retries logging [#6802](https://github.com/chef/chef/pull/6802) ([tas50](https://github.com/tas50))
- Add MSIFASTINSTALL property, supported by Windows Installer 5.0 [#6806](https://github.com/chef/chef/pull/6806) ([stuartpreston](https://github.com/stuartpreston))
- Add create, delete and configure actions to windows_service [#6804](https://github.com/chef/chef/pull/6804) ([jasonwbarnett](https://github.com/jasonwbarnett))
- Update error handling for &quot;knife status&quot; #3287 [#6756](https://github.com/chef/chef/pull/6756) ([cramaechi](https://github.com/cramaechi))
- use a stricter comparison so knife ssh only fails if --exit-on-error [#6582](https://github.com/chef/chef/pull/6582) ([sarkis](https://github.com/sarkis))
- Ensure package (un)locking is idempotent [#6494](https://github.com/chef/chef/pull/6494) ([Rarian](https://github.com/Rarian))
- Fix Appveyor testing:  the format of this flametest doesn&#39;t matter [#6808](https://github.com/chef/chef/pull/6808) ([lamont-granquist](https://github.com/lamont-granquist))
- Remove the spec for epic_fail [#6809](https://github.com/chef/chef/pull/6809) ([tas50](https://github.com/tas50))
- Update /etc/fstab on FreeBSD #4959 [#6782](https://github.com/chef/chef/pull/6782) ([cramaechi](https://github.com/cramaechi))
- Avoid dpkg prompts for modified config files [#6810](https://github.com/chef/chef/pull/6810) ([thommay](https://github.com/thommay))
- guard against somehow being called by the package resource [#6820](https://github.com/chef/chef/pull/6820) ([thommay](https://github.com/thommay))
- Remove testing of Debian 7 as it&#39;s going EOL [#6826](https://github.com/chef/chef/pull/6826) ([tas50](https://github.com/tas50))
- Fix windows_task idle_time validation [#6807](https://github.com/chef/chef/pull/6807) ([algaut](https://github.com/algaut))
- Grammar fixes in windows_task [#6828](https://github.com/chef/chef/pull/6828) ([Happycoil](https://github.com/Happycoil))
- Link to the knife docs when the knife config file is missing [#6364](https://github.com/chef/chef/pull/6364) ([tas50](https://github.com/tas50))
- Don&#39;t rely on the Passwd Ohai plugin in resources [#6833](https://github.com/chef/chef/pull/6833) ([thommay](https://github.com/thommay))
- Simplify powershell_out calls in powershell_package [#6837](https://github.com/chef/chef/pull/6837) ([Happycoil](https://github.com/Happycoil))
- Use the license_scout that comes with Omnibus gem [#6839](https://github.com/chef/chef/pull/6839) ([tduffield](https://github.com/tduffield))
- add additional systemd_unit actions [#6835](https://github.com/chef/chef/pull/6835) ([nathwill](https://github.com/nathwill))
- Implement resource enhancement RFCs [#6818](https://github.com/chef/chef/pull/6818) ([thommay](https://github.com/thommay))
- invites_sort_fail: Clean the invites array before sorting it [#6463](https://github.com/chef/chef/pull/6463) ([MarkGibbons](https://github.com/MarkGibbons))
- Fix issue #2351, chef-client doesn&#39;t make /etc/chef if the directory … [#6429](https://github.com/chef/chef/pull/6429) ([jseely](https://github.com/jseely))
- [MSYS-726] Allow setting environment variables at the user level [#6612](https://github.com/chef/chef/pull/6612) ([harikesh-kolekar](https://github.com/harikesh-kolekar))
- RemoteFile: unlink tempfile when using cache control shows unchanged [#6822](https://github.com/chef/chef/pull/6822) ([lamont-granquist](https://github.com/lamont-granquist))
- only run windows env specs on windows [#6850](https://github.com/chef/chef/pull/6850) ([thommay](https://github.com/thommay))
- add Chef::NodeMap#delete_class API [#6846](https://github.com/chef/chef/pull/6846) ([lamont-granquist](https://github.com/lamont-granquist))
- Use the updated inspec gem - 1.51.18 [#6845](https://github.com/chef/chef/pull/6845) ([tas50](https://github.com/tas50))
- registry_key: Add sensitive property support for suppressing output (fixes #5695) [#6496](https://github.com/chef/chef/pull/6496) ([shoekstra](https://github.com/shoekstra))
- Add hostname resource from chef_hostname cookbook [#6795](https://github.com/chef/chef/pull/6795) ([tas50](https://github.com/tas50))
- fix ohai tests after require_plugin removal [#6867](https://github.com/chef/chef/pull/6867) ([thommay](https://github.com/thommay))
- Add new Redhat Subscription Manager resources [#6827](https://github.com/chef/chef/pull/6827) ([tas50](https://github.com/tas50))
- Add powershell_package source param [#6843](https://github.com/chef/chef/pull/6843) ([Happycoil](https://github.com/Happycoil))
- Add ohai_hint resource from ohai cookbook [#6793](https://github.com/chef/chef/pull/6793) ([tas50](https://github.com/tas50))
- check identifier to resolve exported cookbooks by chef export [#6859](https://github.com/chef/chef/pull/6859) ([sawanoboly](https://github.com/sawanoboly))
- fix chefstyle [#6874](https://github.com/chef/chef/pull/6874) ([thommay](https://github.com/thommay))
- make sure all proxy settings are dealt with [#6875](https://github.com/chef/chef/pull/6875) ([thommay](https://github.com/thommay))
- updating paranoid to verify_host_key [#6869](https://github.com/chef/chef/pull/6869) ([tarcinil](https://github.com/tarcinil))
- Add macos_user_defaults resource from mac_os_x cookbook [#6878](https://github.com/chef/chef/pull/6878) ([tas50](https://github.com/tas50))
- Disable sudo on unit tests [#6879](https://github.com/chef/chef/pull/6879) ([lamont-granquist](https://github.com/lamont-granquist))
- Update libxml2 to 2.9.7 [#6885](https://github.com/chef/chef/pull/6885) ([tas50](https://github.com/tas50))
- Allow tarballs generated by chef export to be used [#6871](https://github.com/chef/chef/pull/6871) ([thommay](https://github.com/thommay))
- Add new introduced and description resource properties to many resources [#6854](https://github.com/chef/chef/pull/6854) ([tas50](https://github.com/tas50))
- The end of our long travis unit testing nightmare [#6888](https://github.com/chef/chef/pull/6888) ([lamont-granquist](https://github.com/lamont-granquist))
- Add chef_handler resource from chef_handler cookbook [#6895](https://github.com/chef/chef/pull/6895) ([tas50](https://github.com/tas50))
- Modernize macosx_service [#6908](https://github.com/chef/chef/pull/6908) ([tas50](https://github.com/tas50))
- Modernize mdadm [#6905](https://github.com/chef/chef/pull/6905) ([tas50](https://github.com/tas50))
- Simplify how we define the powershell_package resource_name [#6901](https://github.com/chef/chef/pull/6901) ([tas50](https://github.com/tas50))
- revert lazy attributes [#6911](https://github.com/chef/chef/pull/6911) ([lamont-granquist](https://github.com/lamont-granquist))
- Convert parts of cron resource to use properties [#6904](https://github.com/chef/chef/pull/6904) ([tas50](https://github.com/tas50))
- Add more introduced and description fields to resources [#6899](https://github.com/chef/chef/pull/6899) ([tas50](https://github.com/tas50))
- surface default guard interpreter errors [#5972](https://github.com/chef/chef/pull/5972) ([nathwill](https://github.com/nathwill))
- Add windows auto_run, font, pagefile, printer, printer_port, and shortcut resources [#6767](https://github.com/chef/chef/pull/6767) ([tas50](https://github.com/tas50))
- Add description, validation_message, and introduced fields into openssl resources [#6855](https://github.com/chef/chef/pull/6855) ([tas50](https://github.com/tas50))
- Added Flag to distinguish between gateway and host key to fix issue #6210 [#6514](https://github.com/chef/chef/pull/6514) ([erikparra](https://github.com/erikparra))
- Don&#39;t use .eql? in the aix mount provider [#6915](https://github.com/chef/chef/pull/6915) ([tas50](https://github.com/tas50))
- [knife] Don&#39;t crash when a deprecated cookbook has no replacement [#6853](https://github.com/chef/chef/pull/6853) ([rlyders](https://github.com/rlyders))
- Add support for knife bootstrap-preinstall-command [#6861](https://github.com/chef/chef/pull/6861) ([smcavallo](https://github.com/smcavallo))
- Raise fatal error If FQDN duplicated [#6781](https://github.com/chef/chef/pull/6781) ([linyows](https://github.com/linyows))
- Stop mixlib-cli default clobbering mixlib-config settings [#6916](https://github.com/chef/chef/pull/6916) ([lamont-granquist](https://github.com/lamont-granquist))
- fix for master of chefstyle [#6919](https://github.com/chef/chef/pull/6919) ([lamont-granquist](https://github.com/lamont-granquist))
- fixing red omnibus builds [#6921](https://github.com/chef/chef/pull/6921) ([lamont-granquist](https://github.com/lamont-granquist))
- Revert appbundler to 0.10.0 [#6922](https://github.com/chef/chef/pull/6922) ([lamont-granquist](https://github.com/lamont-granquist))
- need to pin appbundler in omnibus [#6924](https://github.com/chef/chef/pull/6924) ([lamont-granquist](https://github.com/lamont-granquist))
- Remove git ref on bundler-audit [#6925](https://github.com/chef/chef/pull/6925) ([lamont-granquist](https://github.com/lamont-granquist))
- this really needs to be turned into a yml file... [#6926](https://github.com/chef/chef/pull/6926) ([lamont-granquist](https://github.com/lamont-granquist))
- Remove the :uninstall action from chocolatey_package - CHEF-21 [#6920](https://github.com/chef/chef/pull/6920) ([tas50](https://github.com/tas50))
- use appbundler 0.11.1 for omnibus builds [#6930](https://github.com/chef/chef/pull/6930) ([lamont-granquist](https://github.com/lamont-granquist))
- bump appbundler again, again [#6931](https://github.com/chef/chef/pull/6931) ([lamont-granquist](https://github.com/lamont-granquist))
- Allow specifying a comment for routes [#6929](https://github.com/chef/chef/pull/6929) ([tomdoherty](https://github.com/tomdoherty))
- Update our tests based on new resources we ship [#6939](https://github.com/chef/chef/pull/6939) ([tas50](https://github.com/tas50))
- Add Ubuntu 18.04 Testing in Travis [#6937](https://github.com/chef/chef/pull/6937) ([tas50](https://github.com/tas50))
- Apt repo cleanup and testing expansion [#6498](https://github.com/chef/chef/pull/6498) ([tas50](https://github.com/tas50))
- Use the existing helper method for package resource classes that don&#39;t support allow_downgrade [#6942](https://github.com/chef/chef/pull/6942) ([coderanger](https://github.com/coderanger))
- Set properties in git resource using our resource DSL [#6902](https://github.com/chef/chef/pull/6902) ([tas50](https://github.com/tas50))
- Modernize provides in the portage_package resource [#6903](https://github.com/chef/chef/pull/6903) ([tas50](https://github.com/tas50))
- registry_key: Properly limit allowed values for architecture [#6947](https://github.com/chef/chef/pull/6947) ([tas50](https://github.com/tas50))
- Add more description fields, style fixes, add missing requires [#6943](https://github.com/chef/chef/pull/6943) ([tas50](https://github.com/tas50))
- Add attribute hoisting into core [#6927](https://github.com/chef/chef/pull/6927) ([jonlives](https://github.com/jonlives))
-  Don&#39;t use supervisor process for one-shot / command-line runs [#6914](https://github.com/chef/chef/pull/6914) ([lamont-granquist](https://github.com/lamont-granquist))
- add a utility to dump info about resources [#6896](https://github.com/chef/chef/pull/6896) ([thommay](https://github.com/thommay))
- Remove support for Windows 2003 [#6923](https://github.com/chef/chef/pull/6923) ([tas50](https://github.com/tas50))
- Avoid compile time error in apt_repository [#6953](https://github.com/chef/chef/pull/6953) ([tas50](https://github.com/tas50))
- Added source_file to FromFile [#6938](https://github.com/chef/chef/pull/6938) ([zfjagann](https://github.com/zfjagann))
- remove deprecated property namespace collisions [#6952](https://github.com/chef/chef/pull/6952) ([lamont-granquist](https://github.com/lamont-granquist))
- Remove explicit setting of @provider and depend on ProviderResolver [#6958](https://github.com/chef/chef/pull/6958) ([jasonwbarnett](https://github.com/jasonwbarnett))
- Convert more set_or_returns to proper properties [#6950](https://github.com/chef/chef/pull/6950) ([tas50](https://github.com/tas50))
- Rename bff provider to match its resource [#6956](https://github.com/chef/chef/pull/6956) ([tas50](https://github.com/tas50))
- New interop between Chef and PowerShell 4.0 (or higher) [#6941](https://github.com/chef/chef/pull/6941) ([stuartpreston](https://github.com/stuartpreston))
- Remove the manpages [#6974](https://github.com/chef/chef/pull/6974) ([tas50](https://github.com/tas50))
- RFC 106: expose name and chef_environment as attrs [#6967](https://github.com/chef/chef/pull/6967) ([thommay](https://github.com/thommay))
- Use node.override not node.normal in the windows_feature_dism resource [#6962](https://github.com/chef/chef/pull/6962) ([tas50](https://github.com/tas50))
- Remove platfom restrictions in provides and don&#39;t require providers [#6957](https://github.com/chef/chef/pull/6957) ([tas50](https://github.com/tas50))
- Properly validate reboot_action in dsc_resource [#6951](https://github.com/chef/chef/pull/6951) ([tas50](https://github.com/tas50))
- Don&#39;t use String.new in the cron provider [#6976](https://github.com/chef/chef/pull/6976) ([tas50](https://github.com/tas50))
- Knife should give a useful error when the chef_server_url isn&#39;t a chef server API [#6253](https://github.com/chef/chef/pull/6253) ([jeunito](https://github.com/jeunito))
- Bump to ruby 2.5.0 [#6838](https://github.com/chef/chef/pull/6838) ([thommay](https://github.com/thommay))
- Add output_locations functionality to data collector [#6873](https://github.com/chef/chef/pull/6873) ([jonlives](https://github.com/jonlives))
- Require Ruby 2.4+ [#6983](https://github.com/chef/chef/pull/6983) ([tas50](https://github.com/tas50))
- Pass pointer to LsaFreeMemory, not FFI::MemoryPointer [#6980](https://github.com/chef/chef/pull/6980) ([btm](https://github.com/btm))
- Stripping out Authorization header on redirect to a different host [#6985](https://github.com/chef/chef/pull/6985) ([bugok](https://github.com/bugok))
- Remove knife help which used the manpages [#6982](https://github.com/chef/chef/pull/6982) ([tas50](https://github.com/tas50))
- update mount to use properties and fix 6851 [#6969](https://github.com/chef/chef/pull/6969) ([thommay](https://github.com/thommay))
- Yum refactor [#6540](https://github.com/chef/chef/pull/6540) ([lamont-granquist](https://github.com/lamont-granquist))
- Use Chef omnibus def that includes libarchive [#6993](https://github.com/chef/chef/pull/6993) ([tas50](https://github.com/tas50))
- Revert &quot;Stripping out Authorization header on redirect to a different host [#6996](https://github.com/chef/chef/pull/6996) ([tas50](https://github.com/tas50))
- Add the sudo resource from the sudo resource [#6979](https://github.com/chef/chef/pull/6979) ([tas50](https://github.com/tas50))
- Add more resource descriptions and convert resources to use properties [#6994](https://github.com/chef/chef/pull/6994) ([tas50](https://github.com/tas50))
- Lazy eval empty Hash/Array resource properties. [#6997](https://github.com/chef/chef/pull/6997) ([tas50](https://github.com/tas50))
- Detect new &quot;automatically&quot; installed string in Zypper [#7009](https://github.com/chef/chef/pull/7009) ([tas50](https://github.com/tas50))
- Fail with a warning if users specify apt/yum/zypper repos with slashes [#7000](https://github.com/chef/chef/pull/7000) ([tas50](https://github.com/tas50))
- Remove Chef 12-isms from the apt_repository resource [#6998](https://github.com/chef/chef/pull/6998) ([tas50](https://github.com/tas50))
- Add dmg_package, homebrew_cask, and homebrew_tap resources [#6963](https://github.com/chef/chef/pull/6963) ([tas50](https://github.com/tas50))
- Add missing installed logic for macos in build_essential [#7005](https://github.com/chef/chef/pull/7005) ([tas50](https://github.com/tas50))
- memoize some work in the package class [#6661](https://github.com/chef/chef/pull/6661) ([lamont-granquist](https://github.com/lamont-granquist))
- Pagefile sizes are in megabytes not bytes [#7019](https://github.com/chef/chef/pull/7019) ([tas50](https://github.com/tas50))
- Support installing removed windows features from source [#7015](https://github.com/chef/chef/pull/7015) ([tas50](https://github.com/tas50))
- Save the node&#39;s UUID as an attribute [#7016](https://github.com/chef/chef/pull/7016) ([thommay](https://github.com/thommay))
- rubocop fixes from engine bump to 0.54.0 [#7023](https://github.com/chef/chef/pull/7023) ([lamont-granquist](https://github.com/lamont-granquist))
- remove dead code from property declaration [#7025](https://github.com/chef/chef/pull/7025) ([lamont-granquist](https://github.com/lamont-granquist))
- sudo: Don&#39;t fail on FreeBSD. Turns out there&#39;s a .d directory [#7033](https://github.com/chef/chef/pull/7033) ([tas50](https://github.com/tas50))
- Add sysctl_param resource from the sysctl cookbook [#7022](https://github.com/chef/chef/pull/7022) ([tas50](https://github.com/tas50))
- Suppress nested causes for sensitive exceptions [#7032](https://github.com/chef/chef/pull/7032) ([thommay](https://github.com/thommay))
- Use the latest libarchive/bzip2 defs in omnibus [#7035](https://github.com/chef/chef/pull/7035) ([tas50](https://github.com/tas50))
- Add windows_adjoin resource [#6981](https://github.com/chef/chef/pull/6981) ([tas50](https://github.com/tas50))
- Fix a few bugs in the sudo resource [#7038](https://github.com/chef/chef/pull/7038) ([tas50](https://github.com/tas50))
- Upgrade to openssl 1.1 [#7044](https://github.com/chef/chef/pull/7044) ([tas50](https://github.com/tas50))
- Revert &quot;Upgrade to openssl 1.1&quot; [#7045](https://github.com/chef/chef/pull/7045) ([tas50](https://github.com/tas50))
- Add swap_file resource from the swap cookbook [#6990](https://github.com/chef/chef/pull/6990) ([tas50](https://github.com/tas50))
- Parser 2.5.0.4 was yanked [#7055](https://github.com/chef/chef/pull/7055) ([tas50](https://github.com/tas50))
- Ensure that we pass the correct options to mount [#7030](https://github.com/chef/chef/pull/7030) ([thommay](https://github.com/thommay))
- RFC-102: Deprecation warning in resources [#7050](https://github.com/chef/chef/pull/7050) ([thommay](https://github.com/thommay))
- Ship InSpec 2 [#7051](https://github.com/chef/chef/pull/7051) ([thommay](https://github.com/thommay))
- Update information on updating gems / Expeditor [#7057](https://github.com/chef/chef/pull/7057) ([tas50](https://github.com/tas50))
- Update openssl to 1.0.2o [#7075](https://github.com/chef/chef/pull/7075) ([tas50](https://github.com/tas50))
- Add / update resource descriptions [#7073](https://github.com/chef/chef/pull/7073) ([tas50](https://github.com/tas50))
- Sudo resource: specify ruby type for visudo_binary [#7076](https://github.com/chef/chef/pull/7076) ([brewn](https://github.com/brewn))
- Add Chef 13.8 and 14.0 release notes [#7074](https://github.com/chef/chef/pull/7074) ([tas50](https://github.com/tas50))
- Fix array parsing in windows_feature_dism / windows_feature_powershell [#7078](https://github.com/chef/chef/pull/7078) ([tas50](https://github.com/tas50))
- Setting nil to properties with implicit nil sets default value [#7037](https://github.com/chef/chef/pull/7037) ([lamont-granquist](https://github.com/lamont-granquist))
- windows_feature_dism: Be case insensitive with feature names [#7079](https://github.com/chef/chef/pull/7079) ([tas50](https://github.com/tas50))
- Add basic hostname validation on Windows [#7087](https://github.com/chef/chef/pull/7087) ([tas50](https://github.com/tas50))
- [windows_ad_join] add description for :join action [#7082](https://github.com/chef/chef/pull/7082) ([brewn](https://github.com/brewn))
- [windows_font] get rid of &quot;remove&quot; in description [#7089](https://github.com/chef/chef/pull/7089) ([brewn](https://github.com/brewn))
- Fix method missing error in dmg_package [#7091](https://github.com/chef/chef/pull/7091) ([tas50](https://github.com/tas50))
- Avoid lookups for rights of &#39;LocalSystem&#39; in windows service [#7083](https://github.com/chef/chef/pull/7083) ([btm](https://github.com/btm))
- macos_userdefaults: Fix 2 failures [#7095](https://github.com/chef/chef/pull/7095) ([tas50](https://github.com/tas50))
-  Bump Ruby to 2.5.1 [#7090](https://github.com/chef/chef/pull/7090) ([tas50](https://github.com/tas50))
- homebrew_tap / homebrew_cask: Fix compile time errors with the user mixin [#7097](https://github.com/chef/chef/pull/7097) ([tas50](https://github.com/tas50))
- scrub tempfile names [#7104](https://github.com/chef/chef/pull/7104) ([lamont-granquist](https://github.com/lamont-granquist))
- Address possible gem installs between interval runs that are then used in the config [#7106](https://github.com/chef/chef/pull/7106) ([coderanger](https://github.com/coderanger))
- Bring in the windows_feature_powershell improvements from the cookbook [#7098](https://github.com/chef/chef/pull/7098) ([tas50](https://github.com/tas50))
- Stripping Authorization header upon redirects (second try) [#7006](https://github.com/chef/chef/pull/7006) ([bugok](https://github.com/bugok))
- [CHEF-7026] Rewrite portage package provider candidate_version determination and fix tests [#7027](https://github.com/chef/chef/pull/7027) ([gengor](https://github.com/gengor))
- Don&#39;t fail on every hostname with windows [#7107](https://github.com/chef/chef/pull/7107) ([tas50](https://github.com/tas50))
- [windows_printer_port] fix typo + add action descriptions [#7093](https://github.com/chef/chef/pull/7093) ([brewn](https://github.com/brewn))

## [v13.12.14](https://github.com/chef/chef/tree/v13.12.14) (2019-03-07)

#### Merged Pull Requests
- Update openssl to 1.0.2q and bring in latest omnibus-software [#8088](https://github.com/chef/chef/pull/8088) ([tas50](https://github.com/tas50))
- Update Chef 13 to the latest gem deps [#8145](https://github.com/chef/chef/pull/8145) ([tas50](https://github.com/tas50))
- Update omnibus Chef dep to 14.8 [#8146](https://github.com/chef/chef/pull/8146) ([tas50](https://github.com/tas50))
- Fix for Property deprecations are broken in Chef 13 [#8132](https://github.com/chef/chef/pull/8132) ([kapilchouhan99](https://github.com/kapilchouhan99))
- Update knife bootstrap template to use up to date omnitruck URL [#8208](https://github.com/chef/chef/pull/8208) ([tas50](https://github.com/tas50))
- Update nokogiri to 1.10.1 [#8218](https://github.com/chef/chef/pull/8218) ([tas50](https://github.com/tas50))
- Update Ohai to 13.12.6 [#8223](https://github.com/chef/chef/pull/8223) ([tas50](https://github.com/tas50))
- Chef-13: add lazy module include to universal DSL [#8247](https://github.com/chef/chef/pull/8247) ([lamont-granquist](https://github.com/lamont-granquist))
- Update libxml2 to 2.9.9 [#8239](https://github.com/chef/chef/pull/8239) ([tas50](https://github.com/tas50))
-  Update openssl to 1.0.2r and rubygems to 2.7.9  [#8280](https://github.com/chef/chef/pull/8280) ([tas50](https://github.com/tas50))
- mount: Add proper new lines when on AIX to prevent failures  [#8281](https://github.com/chef/chef/pull/8281) ([tas50](https://github.com/tas50))

## [v13.12.3](https://github.com/chef/chef/tree/v13.12.3) (2018-11-01)

#### Merged Pull Requests
- Backport omnibus cleanup + MSI speedup logic from Chef 14 [#7739](https://github.com/chef/chef/pull/7739) ([tas50](https://github.com/tas50))
- Bump dependencies / slim the package size [#7805](https://github.com/chef/chef/pull/7805) ([tas50](https://github.com/tas50))
- Pin rake to 12.0 to prevent shipping 2 copies [#7812](https://github.com/chef/chef/pull/7812) ([tas50](https://github.com/tas50))
- Update Ohai to 13.12.4 [#7817](https://github.com/chef/chef/pull/7817) ([tas50](https://github.com/tas50))
- Backport:  Throw better error on invalid resources actions [#7836](https://github.com/chef/chef/pull/7836) ([tas50](https://github.com/tas50))

## [v13.11.3](https://github.com/chef/chef/tree/v13.11.3) (2018-09-26)

#### Merged Pull Requests
- Update to openssl 1.0.2p [#7547](https://github.com/chef/chef/pull/7547) ([tas50](https://github.com/tas50))
- Use the existing helper method for package resource classes that don&#39;t support allow_downgrade [#7548](https://github.com/chef/chef/pull/7548) ([tas50](https://github.com/tas50))
- windows_service: Remove potentially sensitive info from the log [#7688](https://github.com/chef/chef/pull/7688) ([tas50](https://github.com/tas50))
- Improve the error message when knife bootstrap windows isn&#39;t installed  [#7686](https://github.com/chef/chef/pull/7686) ([tas50](https://github.com/tas50))
- Fix remote_directory does not obey removal of file specificity [#7687](https://github.com/chef/chef/pull/7687) ([tas50](https://github.com/tas50))
- windows_package: Avoid exposing sensitive data during package install failures if sensitive property set [#7684](https://github.com/chef/chef/pull/7684) ([tas50](https://github.com/tas50))
- osx_profile: Use the full path to /usr/bin/profiles [#7683](https://github.com/chef/chef/pull/7683) ([tas50](https://github.com/tas50))

## [v13.10.4](https://github.com/chef/chef/tree/v13.10.4) (2018-08-08)

#### Merged Pull Requests
- Check local file exists before installing a windows package [#7341](https://github.com/chef/chef/pull/7341) ([josh-barker](https://github.com/josh-barker))
- Backport for 13: scrub tempfile names [#7526](https://github.com/chef/chef/pull/7526) ([tyler-ball](https://github.com/tyler-ball))
- Pin to rspec to &lt; 3.8 [#7528](https://github.com/chef/chef/pull/7528) ([cheeseplus](https://github.com/cheeseplus))
- [SHACK-290] Unpacking tarball paths suffer from URI error [#7522](https://github.com/chef/chef/pull/7522) ([tyler-ball](https://github.com/tyler-ball))

## [v13.10.0](https://github.com/chef/chef/tree/v13.10.0) (2018-07-11)

#### Merged Pull Requests
- Trying to use --recipe-url on Windows with local file fails [#7426](https://github.com/chef/chef/pull/7426) ([tyler-ball](https://github.com/tyler-ball))
- Pull in latest win32-service gem [#7432](https://github.com/chef/chef/pull/7432) ([tas50](https://github.com/tas50))
- Bump Ohai to 13.10.0 [#7438](https://github.com/chef/chef/pull/7438) ([tas50](https://github.com/tas50))
- Backport duplicate logger fix [#7447](https://github.com/chef/chef/pull/7447) ([btm](https://github.com/btm))
- Bump to 13.10 and add release notes [#7454](https://github.com/chef/chef/pull/7454) ([tas50](https://github.com/tas50))

## [v13.9.4](https://github.com/chef/chef/tree/v13.9.4) (2018-06-07)

#### Merged Pull Requests
- Update nokogiri, ruby, and openssl for CVEs [#7232](https://github.com/chef/chef/pull/7232) ([tas50](https://github.com/tas50))
- Backport Ubuntu 18.04 fixes [#7280](https://github.com/chef/chef/pull/7280) ([thommay](https://github.com/thommay))
- Chef-13: Bump ffi to 1.9.25 along with the rest of things [#7337](https://github.com/chef/chef/pull/7337) ([lamont-granquist](https://github.com/lamont-granquist))

## [v13.9.1](https://github.com/chef/chef/tree/v13.9.1) (2018-05-08)

#### Merged Pull Requests
- Backport RFC-101/RFC-104 resource enhancements [#6964](https://github.com/chef/chef/pull/6964) ([thommay](https://github.com/thommay))
- Pass pointer to LsaFreeMemory, not FFI::MemoryPointer [#6991](https://github.com/chef/chef/pull/6991) ([btm](https://github.com/btm))
- Backport mount provider fixes to 13 [#7007](https://github.com/chef/chef/pull/7007) ([thommay](https://github.com/thommay))
- [chef-13] support nils because of course [#7017](https://github.com/chef/chef/pull/7017) ([thommay](https://github.com/thommay))
- Empty commit to trigger a release build [#7040](https://github.com/chef/chef/pull/7040) ([btm](https://github.com/btm))
- partially revert 61e3d4bb: do not use properties for mount [#7031](https://github.com/chef/chef/pull/7031) ([thommay](https://github.com/thommay))
- Bump dependencies to bring in Ohai 13.9 [#7135](https://github.com/chef/chef/pull/7135) ([tas50](https://github.com/tas50))
- Windows MSI: files are now re-unzipped during repair mode (Backport to Chef 13) [#7112](https://github.com/chef/chef/pull/7112) ([stuartpreston](https://github.com/stuartpreston))
- Don&#39;t always request lazy files [#7216](https://github.com/chef/chef/pull/7216) ([thommay](https://github.com/thommay))
- 13.9 Release notes [#7218](https://github.com/chef/chef/pull/7218) ([thommay](https://github.com/thommay))
- RFC-102: Deprecation warning in resources [#7219](https://github.com/chef/chef/pull/7219) ([thommay](https://github.com/thommay))

## [v13.8.5](https://github.com/chef/chef/tree/v13.8.5) (2018-03-07)

#### Merged Pull Requests
- [knife] Don&#39;t crash when a deprecated cookbook has no replacement (#6853) [#6936](https://github.com/chef/chef/pull/6936) ([tas50](https://github.com/tas50))
- lock ffi at 1.9.21 [#6960](https://github.com/chef/chef/pull/6960) ([thommay](https://github.com/thommay))

## [v13.8.3](https://github.com/chef/chef/tree/v13.8.3) (2018-03-05)

#### Merged Pull Requests
- Link to the knife.rb docs when the knife.rb file is missing [#6892](https://github.com/chef/chef/pull/6892) ([tas50](https://github.com/tas50))
- Revert &quot;Revert &quot;fixup some unit tests&quot;&quot; [#6912](https://github.com/chef/chef/pull/6912) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump depenencies to pull in Ohai 13.8 / InSpec 1.51.21 [#6934](https://github.com/chef/chef/pull/6934) ([tas50](https://github.com/tas50))

## [v13.8.0](https://github.com/chef/chef/tree/v13.8.0) (2018-02-27)

#### Merged Pull Requests
- Fix regression where message isn&#39;t an identity property in log resource [#6780](https://github.com/chef/chef/pull/6780) ([tas50](https://github.com/tas50))
- fix node assignment of ImmutableArrays to VividMashes/AttrArrays (Chef-13 backport) [#6791](https://github.com/chef/chef/pull/6791) ([lamont-granquist](https://github.com/lamont-granquist))
- Ensure that we create a docker compatible ca-certs symlink [#6799](https://github.com/chef/chef/pull/6799) ([thommay](https://github.com/thommay))
- Backport the powershell spec fix to get Appveyor green again [#6813](https://github.com/chef/chef/pull/6813) ([tas50](https://github.com/tas50))
- Use the version of LicenseScout that comes with the Omnibus gem. [#6841](https://github.com/chef/chef/pull/6841) ([tduffield](https://github.com/tduffield))
- RemoteFile: unlink tempfile when using cache control shows unchanged (Chef-13 backport) [#6849](https://github.com/chef/chef/pull/6849) ([lamont-granquist](https://github.com/lamont-granquist))
- add Chef::NodeMap#delete_class API (Chef 13 backport) [#6848](https://github.com/chef/chef/pull/6848) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix windows_task idle_time validation [#6856](https://github.com/chef/chef/pull/6856) ([tas50](https://github.com/tas50))
- Update libxml2 to 2.9.7 [#6886](https://github.com/chef/chef/pull/6886) ([tas50](https://github.com/tas50))
- use a stricter comparison so knife ssh only fails if --exit-on-error [#6894](https://github.com/chef/chef/pull/6894) ([tas50](https://github.com/tas50))
-  Prevent knife search --id-only from outputting IDs in the same format as an empty hash [#6893](https://github.com/chef/chef/pull/6893) ([tas50](https://github.com/tas50))
- Chef-13 revert lazy attributes [#6898](https://github.com/chef/chef/pull/6898) ([lamont-granquist](https://github.com/lamont-granquist))

## [v13.7.16](https://github.com/chef/chef/tree/v13.7.16) (2018-01-23)

#### Merged Pull Requests
- Update release notes for 13.7 [#6751](https://github.com/chef/chef/pull/6751) ([thommay](https://github.com/thommay))
- Revert deprecation of use_inline_resources [#6754](https://github.com/chef/chef/pull/6754) ([tas50](https://github.com/tas50))
- fix double-logging bug [#6752](https://github.com/chef/chef/pull/6752) ([lamont-granquist](https://github.com/lamont-granquist))
- Add a warning that Chef 11 server support in knife user is deprecated [#6725](https://github.com/chef/chef/pull/6725) ([tas50](https://github.com/tas50))
- fix non-daemonized umask [#6745](https://github.com/chef/chef/pull/6745) ([lamont-granquist](https://github.com/lamont-granquist))
- simplify node_map logic [#6637](https://github.com/chef/chef/pull/6637) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix knife status to show seconds when needed #5055 [#6738](https://github.com/chef/chef/pull/6738) ([cramaechi](https://github.com/cramaechi))
- Enable the deprecation for use_inline_resource [#6732](https://github.com/chef/chef/pull/6732) ([tas50](https://github.com/tas50))
- Fix dscl group provider gid_used? [#6703](https://github.com/chef/chef/pull/6703) ([get9](https://github.com/get9))
- Fix windows_task resource not being idempotent for random_delay and execution_time_limit [#6688](https://github.com/chef/chef/pull/6688) ([Vasu1105](https://github.com/Vasu1105))
- Update to Ruby 2.4.3 [#6737](https://github.com/chef/chef/pull/6737) ([tas50](https://github.com/tas50))
- DSCL: Check for set home property before file existence (fixes #5777) [#6735](https://github.com/chef/chef/pull/6735) ([get9](https://github.com/get9))
- Modernize windows_path resource [#6699](https://github.com/chef/chef/pull/6699) ([tas50](https://github.com/tas50))
- Don&#39;t check both platform_family / os in provides when platform_family will do [#6711](https://github.com/chef/chef/pull/6711) ([tas50](https://github.com/tas50))
- Update the knife editor error message to point to the correct document [#6726](https://github.com/chef/chef/pull/6726) ([tas50](https://github.com/tas50))
- Remove a useless regex in zypper_repository resource [#6710](https://github.com/chef/chef/pull/6710) ([tas50](https://github.com/tas50))
- Deprecate erl_call resource [#6720](https://github.com/chef/chef/pull/6720) ([tas50](https://github.com/tas50))
- Improve property warnings in resources [#6717](https://github.com/chef/chef/pull/6717) ([tas50](https://github.com/tas50))
- Remove lock files and test github masters in Kitchen Tests [#6709](https://github.com/chef/chef/pull/6709) ([tas50](https://github.com/tas50))
- [MSYS-692] Fix issue with PowerShell function buffer [#6664](https://github.com/chef/chef/pull/6664) ([TheLunaticScripter](https://github.com/TheLunaticScripter))
- Escape single-quoted strings from the context in knife bootstrap [#6695](https://github.com/chef/chef/pull/6695) ([aespinosa](https://github.com/aespinosa))
- Allow injecting tempfiles into Chef::HTTP [#6701](https://github.com/chef/chef/pull/6701) ([lamont-granquist](https://github.com/lamont-granquist))
- Modernize launchd resource [#6698](https://github.com/chef/chef/pull/6698) ([tas50](https://github.com/tas50))
- Add an &#39;s&#39; for quantity of 0 cookbooks. [#6552](https://github.com/chef/chef/pull/6552) ([anoadragon453](https://github.com/anoadragon453))
- Fix yum_repository allowing priority of 0 and remove string regexes [#6697](https://github.com/chef/chef/pull/6697) ([tas50](https://github.com/tas50))
- Add descriptions and yard @since comments to all resources [#6696](https://github.com/chef/chef/pull/6696) ([tas50](https://github.com/tas50))
- Cleanup to some of the resource specs [#6692](https://github.com/chef/chef/pull/6692) ([tas50](https://github.com/tas50))
- fix for data bag names partially matching search reserved words [#6652](https://github.com/chef/chef/pull/6652) ([sandratiffin](https://github.com/sandratiffin))
- Modernize directory resource [#6693](https://github.com/chef/chef/pull/6693) ([tas50](https://github.com/tas50))
- Modernize the ifconfig resource [#6684](https://github.com/chef/chef/pull/6684) ([tas50](https://github.com/tas50))
- Slight improvements to validation failures [#6690](https://github.com/chef/chef/pull/6690) ([thommay](https://github.com/thommay))
- Modernize osx_profile resource [#6685](https://github.com/chef/chef/pull/6685) ([tas50](https://github.com/tas50))
- Modernize cookbook_file resource and expand specs [#6689](https://github.com/chef/chef/pull/6689) ([tas50](https://github.com/tas50))
- implement credential management [#6660](https://github.com/chef/chef/pull/6660) ([thommay](https://github.com/thommay))
- Modernize reboot resource and add spec [#6683](https://github.com/chef/chef/pull/6683) ([tas50](https://github.com/tas50))
- Fix bugs in handling &#39;source&#39;  in msu_package and cab_package [#6686](https://github.com/chef/chef/pull/6686) ([tas50](https://github.com/tas50))
- Move docker and git top cookbook tests to travis [#6673](https://github.com/chef/chef/pull/6673) ([scotthain](https://github.com/scotthain))
- Modernize the log resource [#6676](https://github.com/chef/chef/pull/6676) ([tas50](https://github.com/tas50))
- Avoid a few initializers in resources by using the DSL we have [#6671](https://github.com/chef/chef/pull/6671) ([tas50](https://github.com/tas50))
- Don&#39;t use .match? which is Ruby 2.4+ only in windows_task [#6675](https://github.com/chef/chef/pull/6675) ([tas50](https://github.com/tas50))
- windows_task: Fix resource isn&#39;t fully idempotent due to command property [#6654](https://github.com/chef/chef/pull/6654) ([Vasu1105](https://github.com/Vasu1105))
- Invalid date error on windows_task with frequency :on_logon [#6618](https://github.com/chef/chef/pull/6618) ([NimishaS](https://github.com/NimishaS))
- Fix sneaky chefstyle violations [#6655](https://github.com/chef/chef/pull/6655) ([thommay](https://github.com/thommay))
- Ensure data bags names can contain reserved words [#6636](https://github.com/chef/chef/pull/6636) ([EmFl](https://github.com/EmFl))
- windows_task: Add additional input validation to properties [#6628](https://github.com/chef/chef/pull/6628) ([tas50](https://github.com/tas50))
- Solaris: Fix svcadm clear to only run in maintenance state [#6631](https://github.com/chef/chef/pull/6631) ([jaymalasinha](https://github.com/jaymalasinha))
- speedup node_map get and set operations [#6632](https://github.com/chef/chef/pull/6632) ([lamont-granquist](https://github.com/lamont-granquist))
- Update for openssl 1.0.2n and inspec 1.48 [#6630](https://github.com/chef/chef/pull/6630) ([tas50](https://github.com/tas50))
- Improved windows_task logging [#6617](https://github.com/chef/chef/pull/6617) ([tas50](https://github.com/tas50))
- Update InSpec to 1.47 and Ohai to 13.7 [#6616](https://github.com/chef/chef/pull/6616) ([tas50](https://github.com/tas50))
- Add openSUSE testing in Travis &amp; expand cookbooks we test [#6614](https://github.com/chef/chef/pull/6614) ([tas50](https://github.com/tas50))
- Knife SSH prefix option [#6590](https://github.com/chef/chef/pull/6590) ([mal](https://github.com/mal))
- Add Amazon Linux testing to PRs in Travis [#6611](https://github.com/chef/chef/pull/6611) ([tas50](https://github.com/tas50))
- Hide sensitive properties in converge_if_changed. [#6576](https://github.com/chef/chef/pull/6576) ([cma-arnold](https://github.com/cma-arnold))
- Bump dependencies to pick up InSpec v1.46.2 [#6609](https://github.com/chef/chef/pull/6609) ([adamleff](https://github.com/adamleff))
- Fix windows_path converging on every run [#6541](https://github.com/chef/chef/pull/6541) ([tas50](https://github.com/tas50))
- add unit_name name_property to systemd_unit (fixes #6542) [#6546](https://github.com/chef/chef/pull/6546) ([nathwill](https://github.com/nathwill))
- fix NodeMap to not throw exceptions on platform_versions [#6608](https://github.com/chef/chef/pull/6608) ([lamont-granquist](https://github.com/lamont-granquist))
- Enable Fedora integration testing in Travis [#6523](https://github.com/chef/chef/pull/6523) ([tas50](https://github.com/tas50))
- Only warn if a secret was actually given [#6605](https://github.com/chef/chef/pull/6605) ([coderanger](https://github.com/coderanger))
- Makes life easier for hook authors switching from the older report handler syntax [#6574](https://github.com/chef/chef/pull/6574) ([coderanger](https://github.com/coderanger))
- [MSYS-688] Fixed invalid date and Invalid starttime error [#6544](https://github.com/chef/chef/pull/6544) ([NimishaS](https://github.com/NimishaS))
- Selinux shellout fix (#6346) [#6567](https://github.com/chef/chef/pull/6567) ([deltamualpha](https://github.com/deltamualpha))
- Switch from the Travis container to the VM [#6600](https://github.com/chef/chef/pull/6600) ([btm](https://github.com/btm))
- Don&#39;t try to uninstall bundler on appveyor [#6597](https://github.com/chef/chef/pull/6597) ([btm](https://github.com/btm))
- Fix variable name in solaris service provider [#6596](https://github.com/chef/chef/pull/6596) ([jaymalasinha](https://github.com/jaymalasinha))
- Revert &quot;add missing functional tests for users&quot; [#6588](https://github.com/chef/chef/pull/6588) ([lamont-granquist](https://github.com/lamont-granquist))
- Filter out periods from tmux session name [#6593](https://github.com/chef/chef/pull/6593) ([afn](https://github.com/afn))
- Fix mount test, also update ifconfig to work with both common versions. [#6587](https://github.com/chef/chef/pull/6587) ([scotthain](https://github.com/scotthain))
- Change a useradd_spec test for RHEL &gt;= 6.8 and &gt;= 7.3 [#6555](https://github.com/chef/chef/pull/6555) ([jeremiahsnapp](https://github.com/jeremiahsnapp))
- replace deprecated Dir.exists? with Dir.exist? [#6583](https://github.com/chef/chef/pull/6583) ([thomasdziedzic](https://github.com/thomasdziedzic))
- Add ohai_time to minimal_ohai filter [#6584](https://github.com/chef/chef/pull/6584) ([btm](https://github.com/btm))

## [v13.6.4](https://github.com/chef/chef/tree/v13.6.4) (2017-11-06)

#### Merged Pull Requests
- [MSYS-492]Add missing functional tests for users [#6425](https://github.com/chef/chef/pull/6425) ([harikesh-kolekar](https://github.com/harikesh-kolekar))
- Fix the invalid version comparison in apt/dpkg providers [#6558](https://github.com/chef/chef/pull/6558) ([tas50](https://github.com/tas50))
- Fix the invalid version comparison of apt packages. [#6554](https://github.com/chef/chef/pull/6554) ([komazarari](https://github.com/komazarari))
- Bump openssl and rubygems to latest [#6568](https://github.com/chef/chef/pull/6568) ([tas50](https://github.com/tas50))

## [v13.6.0](https://github.com/chef/chef/tree/v13.6.0) (2017-10-30)

#### Merged Pull Requests
- Bump InSpec to v1.40.0 [#6460](https://github.com/chef/chef/pull/6460) ([adamleff](https://github.com/adamleff))
- Force encoding to UTF_8 in chef-shell to prevent failures [#6447](https://github.com/chef/chef/pull/6447) ([tas50](https://github.com/tas50))
- Only warn about skipping sync once [#6454](https://github.com/chef/chef/pull/6454) ([Happycoil](https://github.com/Happycoil))
- Import the zypper GPG key before templating the repo [#6410](https://github.com/chef/chef/pull/6410) ([tas50](https://github.com/tas50))
- Fixes to package upgrade behaviour [#6428](https://github.com/chef/chef/pull/6428) ([jonlives](https://github.com/jonlives))
- Tweak the knife banners for multi-arg commands. [#6466](https://github.com/chef/chef/pull/6466) ([coderanger](https://github.com/coderanger))
- dnf_resource: be more specific for rhel packages [#6435](https://github.com/chef/chef/pull/6435) ([NaomiReeves](https://github.com/NaomiReeves))
- Prevent creation of data bags named node, role, client or environment [#6469](https://github.com/chef/chef/pull/6469) ([sanditiffin](https://github.com/sanditiffin))
- Remove cookbook_artifacts from CHEF_11_OSS_STATIC_OBJECTS [#6478](https://github.com/chef/chef/pull/6478) ([itmustbejj](https://github.com/itmustbejj))
- Add allow_downgrade to zypper_package resource  [#6476](https://github.com/chef/chef/pull/6476) ([yeoldegrove](https://github.com/yeoldegrove))
- Don&#39;t spin in powershell module that launches chef processes [#6481](https://github.com/chef/chef/pull/6481) ([ksubrama](https://github.com/ksubrama))
- Sleep for another interval after handling SIGHUP [#6461](https://github.com/chef/chef/pull/6461) ([grekasius](https://github.com/grekasius))
- Support new CriticalOhaiPlugins [#6486](https://github.com/chef/chef/pull/6486) ([jaymzh](https://github.com/jaymzh))
- Package: only RHEL &gt;= 8 and Fedora &gt;= 22 get dnf [#6490](https://github.com/chef/chef/pull/6490) ([lamont-granquist](https://github.com/lamont-granquist))
- Windows: Added :none frequency to windows_task resource [#6394](https://github.com/chef/chef/pull/6394) ([NAshwini](https://github.com/NAshwini))
- Fix rebooter for solaris and background reboots [#6497](https://github.com/chef/chef/pull/6497) ([lamont-granquist](https://github.com/lamont-granquist))
- Added parser for DSC configuration [#6473](https://github.com/chef/chef/pull/6473) ([piyushawasthi](https://github.com/piyushawasthi))
- Add array support for choco pkg from artifactory [#6437](https://github.com/chef/chef/pull/6437) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Bump dependencies to pull in new InSpec [#6511](https://github.com/chef/chef/pull/6511) ([adamleff](https://github.com/adamleff))
- Fix remote_file with UNC paths failing [#6510](https://github.com/chef/chef/pull/6510) ([tas50](https://github.com/tas50))
- Deprecate the deploy resource and family [#6468](https://github.com/chef/chef/pull/6468) ([coderanger](https://github.com/coderanger))
- Include Ohai 13.6 [#6521](https://github.com/chef/chef/pull/6521) ([btm](https://github.com/btm))
- Use the latest libxml2, libxslt, libyaml, and openssl [#6520](https://github.com/chef/chef/pull/6520) ([tas50](https://github.com/tas50))
- Pull in the latest libiconv and nokogiri [#6532](https://github.com/chef/chef/pull/6532) ([tas50](https://github.com/tas50))

## [v13.5.3](https://github.com/chef/chef/tree/v13.5.3) (2017-10-03)

#### Merged Pull Requests
- Fix password property is sensitive for mount resource  [#6442](https://github.com/chef/chef/pull/6442) ([dimsh99](https://github.com/dimsh99))
- Only accept MM/DD/YYYY for windows_task start_day [#6434](https://github.com/chef/chef/pull/6434) ([jaym](https://github.com/jaym))
- Update dependencies to pull in InSpec v1.39.1 [#6440](https://github.com/chef/chef/pull/6440) ([adamleff](https://github.com/adamleff))
- Fix Knife search ID only option to actually filter result set [#6438](https://github.com/chef/chef/pull/6438) ([dimsh99](https://github.com/dimsh99))
- Add throttle and metalink options to yum_repository [#6431](https://github.com/chef/chef/pull/6431) ([tas50](https://github.com/tas50))
- Don&#39;t catch SIGCHLD from dnf_helper.py [#6416](https://github.com/chef/chef/pull/6416) ([nemith](https://github.com/nemith))
- Open apt resources up to prevent breaking change [#6417](https://github.com/chef/chef/pull/6417) ([tas50](https://github.com/tas50))
- Remove unused requires in yum_repository [#6413](https://github.com/chef/chef/pull/6413) ([tas50](https://github.com/tas50))
- Quiet the output of the zypper refresh and add force [#6408](https://github.com/chef/chef/pull/6408) ([tas50](https://github.com/tas50))
- Replace which apt-get check with simple debian check in apt resources [#6409](https://github.com/chef/chef/pull/6409) ([tas50](https://github.com/tas50))

## [v12.21.14](https://github.com/chef/chef/tree/v12.21.14) (2017-09-27)

## [v13.4.24](https://github.com/chef/chef/tree/v13.4.24) (2017-09-14)

#### Merged Pull Requests
- Fixed dsc_script for WMF5 [#6383](https://github.com/chef/chef/pull/6383) ([piyushawasthi](https://github.com/piyushawasthi))
- windows_task resource is not idempotent when specifying start_time and start_day [#6312](https://github.com/chef/chef/pull/6312) ([harikesh-kolekar](https://github.com/harikesh-kolekar))
- Allow specifying default gateway on RHEL/Centos [#6386](https://github.com/chef/chef/pull/6386) ([tomdoherty](https://github.com/tomdoherty))
- Use ruby 2.4.2 to addess multiple security vulnerabilities [#6404](https://github.com/chef/chef/pull/6404) ([thommay](https://github.com/thommay))

## [v13.4.19](https://github.com/chef/chef/tree/v13.4.19) (2017-09-13)

#### Bug Fixes
- Ignore validation errors in Resource#to_text [#6331](https://github.com/chef/chef/pull/6331) ([coderanger](https://github.com/coderanger))
- Auto import gpg keys in zypper_repository [#6348](https://github.com/chef/chef/pull/6348) ([tas50](https://github.com/tas50))
- Handle apple's git in the git resource [#6359](https://github.com/chef/chef/pull/6359) ([kzw](https://github.com/kzw))
- Launchd should not load launchagents as root. [#6353](https://github.com/chef/chef/pull/6353) ([mikedodge04](https://github.com/mikedodge04))
- Pass json configuration to ShellSession class [#6314](https://github.com/chef/chef/pull/6314) ([btm](https://github.com/btm))

#### Merged Pull Requests
- Add windows_path resource from the Windows cookbook [#6295](https://github.com/chef/chef/pull/6295) ([NimishaS](https://github.com/NimishaS))
- Bump Bundler version to 1.15.4 [#6349](https://github.com/chef/chef/pull/6349) ([jakauppila](https://github.com/jakauppila))
- dnf_provider: be more specific when we provide `package` [#6351](https://github.com/chef/chef/pull/6351) ([jaymzh](https://github.com/jaymzh))
- Speed up immutabilization [#6355](https://github.com/chef/chef/pull/6355) ([lamont-granquist](https://github.com/lamont-granquist))
- Node attributes: remove useless dup in merge_all [#6356](https://github.com/chef/chef/pull/6356) ([lamont-granquist](https://github.com/lamont-granquist))
- Link to the knife docs in both places where we error on editor [#6363](https://github.com/chef/chef/pull/6363) ([tas50](https://github.com/tas50))
- Bump rubygems to 2.6.13 [#6365](https://github.com/chef/chef/pull/6365) ([lamont-granquist](https://github.com/lamont-granquist))
- Ship chef-vault in the omnibus package [#6370](https://github.com/chef/chef/pull/6370) ([thommay](https://github.com/thommay))
- Support an array of keys for apt_repository [#6372](https://github.com/chef/chef/pull/6372) ([gsreynolds](https://github.com/gsreynolds))
- Immutablize properly as we deep merge [#6362](https://github.com/chef/chef/pull/6362) ([lamont-granquist](https://github.com/lamont-granquist))
- Alternate user local logon authentication for remote_file resource [#5832](https://github.com/chef/chef/pull/5832) ([NimishaS](https://github.com/NimishaS))
- Add support for specifying ETHTOOL_OPTS in the ifconfig resource [#6384](https://github.com/chef/chef/pull/6384) ([tomdoherty](https://github.com/tomdoherty))

## [v13.3.42](https://github.com/chef/chef/tree/v13.3.42) (2017-08-16)

#### Merged Pull Requests
- Apt: Add apt_preference resource from apt cookbooks [#5529](https://github.com/chef/chef/pull/5529) ([tas50](https://github.com/tas50))
- Fix typos [#6298](https://github.com/chef/chef/pull/6298) ([akitada](https://github.com/akitada))
- Set explicit page size for every search request [#6299](https://github.com/chef/chef/pull/6299) ([stevendanna](https://github.com/stevendanna))
- Add .dockerignore to reduce size of resulting images [#6296](https://github.com/chef/chef/pull/6296) ([tduffield](https://github.com/tduffield))
- Fix git command in DCO sign-off example [#6306](https://github.com/chef/chef/pull/6306) ([edmorley](https://github.com/edmorley))
- Add option to enable unprivileged symlink creation on windows [#6236](https://github.com/chef/chef/pull/6236) ([svmastersamurai](https://github.com/svmastersamurai))
- Bump omnibus-software version [#6310](https://github.com/chef/chef/pull/6310) ([thommay](https://github.com/thommay))
- Throw readable errors if multiple dsc resources are found [#6307](https://github.com/chef/chef/pull/6307) ([Happycoil](https://github.com/Happycoil))
- Add zypper_repository resource [#5948](https://github.com/chef/chef/pull/5948) ([tas50](https://github.com/tas50))
- Pull in Ohai 13.3 [#6319](https://github.com/chef/chef/pull/6319) ([tas50](https://github.com/tas50))
- Maintain compat with old zypper_repo resource used in cookbooks [#6318](https://github.com/chef/chef/pull/6318) ([tas50](https://github.com/tas50))
- README improvement for Chef beginner. [#6297](https://github.com/chef/chef/pull/6297) ([takaya-fuj19](https://github.com/takaya-fuj19))
- Bump InSpec to v1.33.1 [#6324](https://github.com/chef/chef/pull/6324) ([adamleff](https://github.com/adamleff))


## [v13.3.27](https://github.com/chef/chef/tree/v13.3.27) (2017-07-26)
[Full Changelog](https://github.com/chef/chef/compare/v13.0.118...v13.3.27)

- Added username/password validation for elevated option [\#6293](https://github.com/chef/chef/pull/6293) ([NimishaS](https://github.com/NimishaS))
- Bump mixlib-shellout for \#6271 [\#6285](https://github.com/chef/chef/pull/6285) ([btm](https://github.com/btm))
- Added :elevated option for powershell\_script resource [\#6271](https://github.com/chef/chef/pull/6271) ([NimishaS](https://github.com/NimishaS))
- Make mount idempotent on Aix [\#6213](https://github.com/chef/chef/pull/6213) ([NAshwini](https://github.com/NAshwini))
- Allow windows\_task create action to update tasks. [\#6193](https://github.com/chef/chef/pull/6193) ([harikesh-kolekar](https://github.com/harikesh-kolekar))
- Use socketless local mode by default [\#6177](https://github.com/chef/chef/pull/6177) ([coderanger](https://github.com/coderanger))
- Convert breakpoint resource to a custom resource [\#6176](https://github.com/chef/chef/pull/6176) ([lamont-granquist](https://github.com/lamont-granquist))
- Make non-legacy solo use socketless mode [\#6174](https://github.com/chef/chef/pull/6174) ([coderanger](https://github.com/coderanger))
- Prefer Systemd with sysvinit script over Upstart for service provider [\#6157](https://github.com/chef/chef/pull/6157) ([shortdudey123](https://github.com/shortdudey123))

## v13.0.118 (2017-04-12)

- Fix Gems won't install on Windows with Chef 13
- Fix yum_package options option broken in Chef 13
- Fix cookbooks uploaded by Chef 13 can't be used by Chef 12
- Update Ohai to 13.0.1 to fix the OpenStack and Eucalyptus plugins

## v13.0.113 (2017-04-06)

- Use Ohai 13.0
- Add new server enforced required recipe feature
- shell_out PATH fixes and path_sanity changes
- Remove magic from the logger/formatter settings
- Add new windows_task resource
- Better solution to gem_package source issues
- Remove the knife cookbook create command in favor of Chef-DK
- Remove need to define use_inline_resources and always enable inline resources
- RFC 59 - Load ohai plugins
- Use new lzma lib
- Have knife cookbook generate use SPDX standard license strings
- Implement RFC033: Root aliases
- Ensure DataBagItems are a Mash
- Add InSpec to chef omnibus builds
- Remove knife cookbook site vendor
- Make Standardized Exit Codes The Default Behavior
- Tweaks to rubygems source option for urls
- Allow lazy{} to be used in template resource variables.
- Freeze property defaults
- fix knife ssh --exit-on-error
- Add -u param to usermod in linux_user resource when using non_unique
- Launchd limit_load_to_session_type accepts Array or String
- Remove the consts for DSL-based resources/providers
- Add real support for rb files (at least roles) in knife-serve
- Adding restart action to launchd resource
- systemd_unit verifier escape hatch
- Ensure we check all required fields
- V2 Cookbook Manifests
- Fix and simplify rake bundle:* commands
- Expand the system info displayed on error to give us some more data to work with when helping users
- Add policy_name and policy_group indexes to converge message sent to ...
- Turn on zypper gpg checks by default
- Knife search exit 1 when no results
- Remove deprecated knife subcommand APIs
- Coerce package options property to an Array
- Fix cookbook gem installer
- Remove iconv from the chef build
- Remove deprecated Chef::ResourceResolver.resource API
- Fix notifying array resources
- Remove deprecated run_command API entirely
- Apply knife search node fuzzifier to knife ssh
- Remove Chef::Resource.updated=
- Remove deprecated launchd resource hash property
- Remove more deprecated method_missing access
- Support nameless resources and remove deprecated multi-arg resources
- bumping acceptance gems
- Set default guard_interpreter to powershell_script on Windows
- Remove more deprecated provider_resolver code
- Make ActionClass a class
- Don't include nokogiri gem as it doesn't compile on Windows right now
- Retry API requests if using an unsupported version
- Bump _XOPEN_SOURCE to 600 for ruby 2.4 on Solaris
- Upgrade Ruby to the 2.4.1 release
- Fix action class weirdness in Chef-13
- Make ResourceReporter smarter to get resource identity and state
- Don't `rescue Exception` in retryable resources
- Simplify DSL creation
- Remove deprecated Chef::Client attrs
- Remove method_missing from the DSL
- Remove support for the sort option to searches.
- smf_recursive_dependencies: Allow solaris services to start recursively.
- Fix for creating users in non english windows machines
- Remove node_map back-compat
- Fix chef-shell option name and help message
- Remove Chef::ShellOut
- Remove deprecated run_context methods
- Remove old platform mapping code
- Remove the old rake tasks
- Properly use chef-shell in SoloSession by deprecating old behavior into SoloLegacySession
- Raise on properties redefining inherited methods
- Optimize cheffs
- Remove Chef::REST
- Fix node#debug_value access through arrays
- Nillable properties
- Freeze merged node attribute
- Properly deep dup Node#to_hash
- Add release policy badge to README
- Remove the deprecated easy_install resource
- Remove declare_resource create_if_missing API
- Kill JSON auto inflate with fire
- Remove method_missing access to node object.
- Cleanup of Chef::Resource
- Add attribute blacklist
- Enable why-run by default in resources
- Ensure that there are no pesky // in our paths
- Compress debs and rpms with xz
- Fix apt_repository for Ubuntu 16.10+
- Remove all Chef 11 era deprecations
- Remove partial_search methods
- Use v3 data bag encryption
- Remove %{file} from verify interpolation
- Revert "Remove all 11 era deprecations"
- Convert additional resource methods to properties
- Remove backcompat classes
- Remove provisioning from the downstream tests
- Remove supports API from Chef::Resource
- Be a bit less keen to help properties
- Add an option for gateway_identity_file that will allow key-based authentication on the gateway.
- Mac: Validate that a machine has a computer level profile
- Verify data bag exists before trying to create it in knife
- Remove resource cloning and 3694 warnings
- HTTP: add debug long for non-JSON response


## [v12.21.4](https://github.com/chef/chef/tree/v12.21.4) (2017-08-14)
[Full Changelog](https://github.com/chef/chef/compare/v12.21.3...v12.21.4)

**Fixed bugs:**
- Backport #5941 (Make ResourceReporter smarter to get resource identity and state) [\#6308](https://github.com/chef/chef/pull/6308)

**Tech cleanup:**
- Bump omnibus-software to fix early Rubygems segfaults on Windows [\#6329](https://github.com/chef/chef/pull/6329)
- Upgrade Ruby from 2.3.1 to 2.3.4
- Upgrade libiconv from 1.14 to 1.15
- Upgrade Rubygems from 2.6.10 to 2.6.12

## [v12.21.3](https://github.com/chef/chef/tree/v12.21.3) (2017-06-23)
[Full Changelog](https://github.com/chef/chef/compare/v12.21.1...v12.21.3)

**Fixed bugs:**
- Properly send expanded run list event for policy file nodes [\#6229](https://github.com/chef/chef/pull/6229) / [\#6233](https://github.com/chef/chef/pull/6233)

## [v12.21.1](https://github.com/chef/chef/tree/v12.21.1) (2017-06-20)
[Full Changelog](https://github.com/chef/chef/compare/v12.21.0...v12.21.1)

- Handle the supports pseudo-property more gracefully [\#6222](https://github.com/chef/chef/pull/6222) ([coderanger](https://github.com/coderanger))
- Provide better system information when Chef crashes [\#6173](https://github.com/chef/chef/pull/6173) ([coderanger](https://github.com/coderanger))
- On Debian based systems, correctly prefer Systemd to Upstart [\#6157](https://github.com/chef/chef/pull/6157) ([shortdudey123](https://github.com/shortdudey123))
- Don't crash if we downgrade from Chef 13 to Chef 12 [\#6129](https://github.com/chef/chef/pull/6129) ([akitada](https://github.com/akitada))
- Update zlib to 1.2.11 to resolve CVEs [#6219](https://github.com/chef/chef/pull/6219) ([thommay](https://github.com/thommay))
- Update Ohai to 8.24 with improved EC2 metadata handling, dmi code fixes, and scala/lua detection fixes

## v12.20.3 (2017-04-30)

- Add the ability to define a server enforced required recipe[#6032](https://github.com/chef/chef/pull/6032)([sdelano](https://github.com/sdelano))
- Fix apt_repository key fingerprint for Ubuntu 16.10+
- Verify if a databag exists before we try to create it with knife
- Bump json, winrm, plist, and net-ssh gems to the latest [#6106](https://github.com/chef/chef/pull/6106) ([rhass](https://github.com/rhass))

## v12.19.36 (2017-02-23)

- Use shellsplit for apt_package options [#5838](https://github.com/chef/chef/pull/5838) ([mivok](https://github.com/mivok))

## [v12.19.33](https://github.com/chef/chef/tree/v12.19.33) (2017-02-16)
[Full Changelog](https://github.com/chef/chef/compare/v12.18.31...v12.19.33)

- coerce immutable arrays to normal arrays in the yum\_package resource [\#5816](https://github.com/chef/chef/pull/5816) ([lamont-granquist](https://github.com/lamont-granquist))
- Suppress sensitive properties from resource log and reporting output [\#5803](https://github.com/chef/chef/pull/5803) ([tduffield](https://github.com/tduffield))
- Sanitize UTF-8 data sent to Data Collector [\#5793](https://github.com/chef/chef/pull/5793) ([lamont-granquist](https://github.com/lamont-granquist))
- Add multipackage\_api support to yum\_package provider [\#5791](https://github.com/chef/chef/pull/5791) ([tduffield](https://github.com/tduffield))
- rhel7 / dnf 2.0 fixes / improved errors [\#5782](https://github.com/chef/chef/pull/5782) ([lamont-granquist](https://github.com/lamont-granquist))
- Grant Administrators group permissions to nodes directory under chef-solo [\#5781](https://github.com/chef/chef/pull/5781) ([tduffield](https://github.com/tduffield))
- Fix --no-fips on chef-client [\#5778](https://github.com/chef/chef/pull/5778) ([btm](https://github.com/btm))
- Raise error if ips\_package install returns non-zero [\#5773](https://github.com/chef/chef/pull/5773) ([tduffield](https://github.com/tduffield))
- Use CIDR notation rather than netmask in route-eth0 file [\#5772](https://github.com/chef/chef/pull/5772) ([tduffield](https://github.com/tduffield))
- Verify systemd\_unit file with custom verifier [\#5765](https://github.com/chef/chef/pull/5765) ([mal](https://github.com/mal))
- Windows alternate user support for execute resources [\#5764](https://github.com/chef/chef/pull/5764) ([NimishaS](https://github.com/NimishaS))
- favor metadata.json over metadata.rb [\#5750](https://github.com/chef/chef/pull/5750) ([lamont-granquist](https://github.com/lamont-granquist))
- Ensure ssh search paginates correctly [\#5744](https://github.com/chef/chef/pull/5744) ([thommay](https://github.com/thommay))
- Do not modify File's new\_resource during why-run [\#5742](https://github.com/chef/chef/pull/5742) ([scottopherson](https://github.com/scottopherson))
- Add gems for ECC algorithm support to omnibus. [\#5736](https://github.com/chef/chef/pull/5736) ([rhass](https://github.com/rhass))
- dh/url support cab [\#5732](https://github.com/chef/chef/pull/5732) ([dheerajd-msys](https://github.com/dheerajd-msys))
- use git archive to speed up putting source in place [\#5730](https://github.com/chef/chef/pull/5730) ([robbkidd](https://github.com/robbkidd))
- use pkg.path variable to reference path to self [\#5729](https://github.com/chef/chef/pull/5729) ([robbkidd](https://github.com/robbkidd))
- Raise NamedSecurityInfo related exception using HR result. [\#5727](https://github.com/chef/chef/pull/5727) ([Aliasgar16](https://github.com/Aliasgar16))
- Core: Ensure paths are correctly escaped when syntax checking [\#5704](https://github.com/chef/chef/pull/5704) ([ceneo](https://github.com/ceneo))
- Added module\_version attribute for dsc\_resource for SxS support [\#5701](https://github.com/chef/chef/pull/5701) ([Aliasgar16](https://github.com/Aliasgar16))
- Bump net-ssh to v4, add dependencies for ed25519 support [\#5687](https://github.com/chef/chef/pull/5687) ([onlyhavecans](https://github.com/onlyhavecans))

## [v12.18.31](https://github.com/chef/chef/tree/v12.18.31) (2017-01-11)
[Full Changelog](https://github.com/chef/chef/compare/v12.17.44...v12.18.31)

**Implemented enhancements:**

- yum\_repository: Allow baseurl to be an array & allow fastestmirror\_enabled false [\#5708](https://github.com/chef/chef/pull/5708) ([tas50](https://github.com/tas50))
- Adding returns property to chocolatey\_package resource [\#5688](https://github.com/chef/chef/pull/5688) ([Vasu1105](https://github.com/Vasu1105))
- Code cleanup in the user provider [\#5674](https://github.com/chef/chef/pull/5674) ([lamont-granquist](https://github.com/lamont-granquist))
- Code cleanup in the group provider [\#5673](https://github.com/chef/chef/pull/5673) ([lamont-granquist](https://github.com/lamont-granquist))
- Core: Formally deprecate run\_command [\#5666](https://github.com/chef/chef/pull/5666) ([lamont-granquist](https://github.com/lamont-granquist))
- Set MSI Scheduled Task name to match chef-client cookbook managed name [\#5657](https://github.com/chef/chef/pull/5657) ([mwrock](https://github.com/mwrock))
- remove Chef::Platform::HandlerMap [\#5636](https://github.com/chef/chef/pull/5636) ([lamont-granquist](https://github.com/lamont-granquist))
- Core: Properly deprecate old Chef::Platform methods [\#5631](https://github.com/chef/chef/pull/5631) ([lamont-granquist](https://github.com/lamont-granquist))

**Fixed bugs:**

- Fix error thrown by solo when run on Windows as SYSTEM [\#5693](https://github.com/chef/chef/pull/5693) ([scottopherson](https://github.com/scottopherson))
- Report a blank resource if sensitive is enabled [\#5668](https://github.com/chef/chef/pull/5668) ([afiune](https://github.com/afiune))
- Ensure node.docker? returns boolean [\#5645](https://github.com/chef/chef/pull/5645) ([andrewjamesbrown](https://github.com/andrewjamesbrown))
- Fix Data Collector organization parsing regex [\#5630](https://github.com/chef/chef/pull/5630) ([adamleff](https://github.com/adamleff))
- Core: Use object ID when detected unprocessed Resources [\#5604](https://github.com/chef/chef/pull/5604) ([adamleff](https://github.com/adamleff))

**Merged pull requests:**

- Core: fix node attribute "unless" API methods [\#5717](https://github.com/chef/chef/pull/5717) ([lamont-granquist](https://github.com/lamont-granquist))

## [v12.17.44](https://github.com/chef/chef/tree/v12.17.44) (2016-12-07)
[Full Changelog](https://github.com/chef/chef/compare/v12.16.42...v12.17.44)

**Implemented enhancements:**

- Action :umount for mount resource is an obtuse anachronism [\#5595](https://github.com/chef/chef/issues/5595)
- Core: Update ohai resource to new style, stop overwriting name property [\#5607](https://github.com/chef/chef/pull/5607) ([adamleff](https://github.com/adamleff))
- Linux: mount provider - skip device detection for zfs [\#5603](https://github.com/chef/chef/pull/5603) ([ttr](https://github.com/ttr))
- Core: Ensure chef-solo creates node files w/ correct permissions [\#5601](https://github.com/chef/chef/pull/5601) ([scottopherson](https://github.com/scottopherson))
- Resources: Add unmount as an alias to umount in the mount resource [\#5599](https://github.com/chef/chef/pull/5599) ([shortdudey123](https://github.com/shortdudey123))
- Core: Update Data Collector to use Chef::JSONCompat [\#5590](https://github.com/chef/chef/pull/5590) ([adamleff](https://github.com/adamleff))
- Knife: Add ability to pass multiple nodes to knife node/client delete [\#5572](https://github.com/chef/chef/pull/5572) ([jeunito](https://github.com/jeunito))
- Core: Data Collector debug log should output JSON [\#5570](https://github.com/chef/chef/pull/5570) ([adamleff](https://github.com/adamleff))
- Yum: Purge yum cache before deleting repo config [\#5509](https://github.com/chef/chef/pull/5509) ([iancward](https://github.com/iancward))
- Knife Bootstrap: Passing config\_log\_level and config\_log\_location from config.rb [\#5502](https://github.com/chef/chef/pull/5502) ([dheerajd-msys](https://github.com/dheerajd-msys))

**Fixed bugs:**

- Custom Resources: Undefined method up\_to\_date thrown by Chef 12.16.42 [\#5593](https://github.com/chef/chef/issues/5593)
- Core: Ensure deprecation messages are always included [\#5618](https://github.com/chef/chef/pull/5618) ([thommay](https://github.com/thommay))
- Core: Fix bug where Access Controls on existing symlink resources would be ignored on first chef-client run [\#5616](https://github.com/chef/chef/pull/5616) ([tduffield](https://github.com/tduffield))
- The suggested fix for the manage\_home deprecation is incorrect [\#5615](https://github.com/chef/chef/pull/5615) ([tas50](https://github.com/tas50))
- change choco -version to choco --version [\#5613](https://github.com/chef/chef/pull/5613) ([spuder](https://github.com/spuder))
- Knife: Correct example `chef\_server\_url` in `knife configure` [\#5602](https://github.com/chef/chef/pull/5602) ([jerryaldrichiii](https://github.com/jerryaldrichiii))
- Windows: Ensure correct version of shutdown is called when using the reboot resource [\#5596](https://github.com/chef/chef/pull/5596) ([Xoph](https://github.com/Xoph))
- Windows: Support for running cab\_package on non-English system locales [\#5591](https://github.com/chef/chef/pull/5591) ([jugatsu](https://github.com/jugatsu))
- Core: Ensure Data Collector resource report exists before updating [\#5571](https://github.com/chef/chef/pull/5571) ([adamleff](https://github.com/adamleff))
- Windows: Use the full path to expand.exe for msu\_package [\#5564](https://github.com/chef/chef/pull/5564) ([NimishaS](https://github.com/NimishaS))
- Unset http\[s\]\_proxy in the subversion spec [\#5562](https://github.com/chef/chef/pull/5562) ([stefanor](https://github.com/stefanor))
- Core: fix Lint/UnifiedInteger cop [\#5547](https://github.com/chef/chef/pull/5547) ([lamont-granquist](https://github.com/lamont-granquist))
- Core: fix ImmutableArray slices [\#5541](https://github.com/chef/chef/pull/5541) ([lamont-granquist](https://github.com/lamont-granquist))
- Prevent apt\_update failures on non-Linux platforms [\#5524](https://github.com/chef/chef/pull/5524) ([tas50](https://github.com/tas50))
- Core: Ensure that the sensitive property is correctly accessed [\#5508](https://github.com/chef/chef/pull/5508) ([axos88](https://github.com/axos88))

**Closed issues:**

- cab\_package doesn't support running on non-English system locales [\#5592](https://github.com/chef/chef/issues/5592)
- Support restarting/stopping/ the service from state paused on windows [\#5586](https://github.com/chef/chef/issues/5586)

## [v12.16.42](https://github.com/chef/chef/tree/v12.16.42) (2016-11-04)
[Full Changelog](https://github.com/chef/chef/compare/v12.15.19...v12.16.42)

**Implemented enhancements:**

- Core: improve readability of property-resource namespace collision exception message [\#5500](https://github.com/chef/chef/pull/5500) ([lamont-granquist](https://github.com/lamont-granquist))
- Omnibus: Pull in Ohai 8.21.0 and other new deps [\#5499](https://github.com/chef/chef/pull/5499) ([tas50](https://github.com/tas50))
- Core: Add deprecations to Data Collector run completion messages [\#5496](https://github.com/chef/chef/pull/5496) ([adamleff](https://github.com/adamleff))
- Core: add attribute\_changed hook to event handlers [\#5495](https://github.com/chef/chef/pull/5495) ([lamont-granquist](https://github.com/lamont-granquist))
- Knife: Add the `--field-separator` flag to knife show commands [\#5489](https://github.com/chef/chef/pull/5489) ([tduffield](https://github.com/tduffield))
- Core: Enable Signed Header Auth for Data Collector, and Configure the Data Collector Automatically [\#5487](https://github.com/chef/chef/pull/5487) ([danielsdeleo](https://github.com/danielsdeleo))
- Core: set use\_inline\_resources in package superclass [\#5483](https://github.com/chef/chef/pull/5483) ([lamont-granquist](https://github.com/lamont-granquist))
- Package: Add new "lock" action for apt, yum and zypper packages [\#5395](https://github.com/chef/chef/pull/5395) ([yeoldegrove](https://github.com/yeoldegrove))

**Fixed bugs:**

- Enable data collector w/o token for solo, but require explicit URL [\#5511](https://github.com/chef/chef/pull/5511) ([danielsdeleo](https://github.com/danielsdeleo))
- Core: Include chef/chef\_class in Chef::REST for method log\_deprecation [\#5504](https://github.com/chef/chef/pull/5504) ([smalltown](https://github.com/smalltown))
- Knife: Updating knife ssl fetch to correctly store certificate when it does not have a CN [\#5498](https://github.com/chef/chef/pull/5498) ([tyler-ball](https://github.com/tyler-ball))
- Knife: Fixed knife download cookbooks issue which used to corrupt the certificate files each time the command was fired. [\#5494](https://github.com/chef/chef/pull/5494) ([Aliasgar16](https://github.com/Aliasgar16))
- Solaris: Properly check lock status of users on solaris2 [\#5486](https://github.com/chef/chef/pull/5486) ([tduffield](https://github.com/tduffield))
- Solaris: Fix IPS package must create symlinks to package commands [\#5485](https://github.com/chef/chef/pull/5485) ([jaymalasinha](https://github.com/jaymalasinha))

## [v12.15.19](https://github.com/chef/chef/tree/v12.15.19) (2016-10-07)
[Full Changelog](https://github.com/chef/chef/compare/v12.14.89...v12.15.19)

**Enhancements:**

- Adding support for rfc 62 exit code 213 (Chef upgrades) [\#5428](https://github.com/chef/chef/pull/5428) ([jeremymv2](https://github.com/jeremymv2))
- Allow raw_key to override the configured signing\_key [\#5314](https://github.com/chef/chef/pull/5314) ([thommay](https://github.com/thommay))
- Set yum\_repository gpgcheck default to true [\#5398](https://github.com/chef/chef/pull/5398) ([shortdudey123](https://github.com/shortdudey123))
- Allow deletion of registry\_key without the need for users to pass data key in values hash. [\#5359](https://github.com/chef/chef/pull/5359) ([Aliasgar16](https://github.com/Aliasgar16))
- Adding support for cab files to Chef package provider on windows [\#5285](https://github.com/chef/chef/pull/5285) ([Vasu1105](https://github.com/Vasu1105))
- Ignore unknown metadata fields in metadata.rb [\#5299](https://github.com/chef/chef/pull/5299) ([lamont-granquist](https://github.com/lamont-granquist))

**Fixed Bugs:**

- knife ssh: use the command line prompt for sudo if set [\#5427](https://github.com/chef/chef/pull/5427) ([lamont-granquist](https://github.com/lamont-granquist))
- User provider: Fix manage\_home provider inconsistency for Mac and FreeBSD providers [\#5423](https://github.com/chef/chef/pull/5423) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix for "Chefspec template rendering fails when cookbook\_name != directory name" [\#5417](https://github.com/chef/chef/pull/5417) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix solaris handling for useradd -m/-M behavior [\#5408](https://github.com/chef/chef/pull/5408) ([coderanger](https://github.com/coderanger))
- Normalize full key name to avoid resource update on identical key names [\#5290](https://github.com/chef/chef/pull/5290) ([bai](https://github.com/bai))
- Add trailing newline to generated 15update-stamp [\#5382](https://github.com/chef/chef/pull/5382) ([pwalz](https://github.com/pwalz))
- Invalid `dsc_scripts` should fail the run [\#5377](https://github.com/chef/chef/pull/5377) ([NimishaS](https://github.com/NimishaS))
- Revert --local filter for gems installed from  paths [\#5379](https://github.com/chef/chef/pull/5379) ([mwrock](https://github.com/mwrock))
- Fix knife list\_commands\(\) [\#5386](https://github.com/chef/chef/pull/5386) ([lamont-granquist](https://github.com/lamont-granquist))
- Don't use -r for users or groups on Solaris. [\#5355](https://github.com/chef/chef/pull/5355) ([coderanger](https://github.com/coderanger))
- Chef 12 Attribute Regression [\#5360](https://github.com/chef/chef/pull/5360) ([gbagnoli](https://github.com/gbagnoli))
- Handling Errno::ETIMEDOUT [\#5358](https://github.com/chef/chef/pull/5358) ([NimishaS](https://github.com/NimishaS))

## [v12.14.89](https://github.com/chef/chef/tree/v12.14.89) (2016-09-22)
[Full Changelog](https://github.com/chef/chef/compare/v12.14.77...v12.14.89)

**Fixed Bugs:**

- Revert "Verify systemd\_unit file during create" [\#5326](https://github.com/chef/chef/pull/5326) ([mwrock](https://github.com/mwrock))
- Fix method\_access and array handling in node presenter [\#5351](https://github.com/chef/chef/pull/5351) ([lamont-granquist](https://github.com/lamont-granquist))
- Fixed undefined short\_cksum method issue and checksum in uppercase issue for windows\_package resource. [\#5332](https://github.com/chef/chef/pull/5332) ([Aliasgar16](https://github.com/Aliasgar16))
- Fix makecache action name in yum\_repository [\#5348](https://github.com/chef/chef/pull/5348) ([tas50](https://github.com/tas50))

## [v12.14.77](https://github.com/chef/chef/tree/v12.14.77) (2016-09-19)
[Full Changelog](https://github.com/chef/chef/compare/v12.14.60...v12.14.77)

**Fixed Bugs:**

- Revert supports\[:manage\_home\] behavior [\#5322](https://github.com/chef/chef/pull/5322) ([lamont-granquist](https://github.com/lamont-granquist))
- Preserve the extension of the file in the rendered tempfile in File providers [\#5327](https://github.com/chef/chef/pull/5327) ([lamont-granquist](https://github.com/lamont-granquist))
- Allow the :delete action for yum\_repository + fix old property support [\#5320](https://github.com/chef/chef/pull/5320) ([tas50](https://github.com/tas50))

## [v12.14.60](https://github.com/chef/chef/tree/v12.14.60) (2016-09-09)
[Full Changelog](https://github.com/chef/chef/compare/v12.13.37...v12.14.60)

**Enhancements:**

- Only support Solaris 10u11 and newer [\#5264](https://github.com/chef/chef/pull/5264) ([rhass](https://github.com/rhass))
- Added code to handle deletion of directories on Windows that are symlinks. [\#5234](https://github.com/chef/chef/pull/5234) ([Aliasgar16](https://github.com/Aliasgar16))
- Readability improvements to options parsing code [\#5289](https://github.com/chef/chef/pull/5289) ([lamont-granquist](https://github.com/lamont-granquist))
- Add Hash type to launchd:keep\_alive [\#5182](https://github.com/chef/chef/pull/5182) ([erikng](https://github.com/erikng))
- Added timeout during removing of windows package [\#5250](https://github.com/chef/chef/pull/5250) ([dheerajd-msys](https://github.com/dheerajd-msys))
- Bump openssl to 1.0.2h [\#5260](https://github.com/chef/chef/pull/5260) ([lamont-granquist](https://github.com/lamont-granquist))
- Rewrite linux\_user provider check\_lock [\#5248](https://github.com/chef/chef/pull/5248) ([lamont-granquist](https://github.com/lamont-granquist))
- Allow flagging a resource property as sensitive [\#5185](https://github.com/chef/chef/pull/5185) ([adamleff](https://github.com/adamleff))
- Rewrite linux useradd provider [\#5243](https://github.com/chef/chef/pull/5243) ([lamont-granquist](https://github.com/lamont-granquist))
- Add yum_repository resource from the yum cookbook [\#5187](https://github.com/chef/chef/pull/5187) ([thommay](https://github.com/thommay))
- Verify systemd\_unit file during create [\#5210](https://github.com/chef/chef/pull/5210) ([mal](https://github.com/mal))
- Add a warning for guard blocks that return a non-empty string [\#5233](https://github.com/chef/chef/pull/5233) ([coderanger](https://github.com/coderanger))
- Forward package cookbook\_name to underlying remote\_file [\#5128](https://github.com/chef/chef/pull/5128) ([Annih](https://github.com/Annih))
- Fix "URI.escape is obsolete" warnings [\#5230](https://github.com/chef/chef/pull/5230) ([jkeiser](https://github.com/jkeiser))
- Remove ruby 2.1 support [\#5220](https://github.com/chef/chef/pull/5220) ([lamont-granquist](https://github.com/lamont-granquist))
- User provider manage\_home behavior and refactor [\#5122](https://github.com/chef/chef/pull/5122) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix Style/BlockDelimiters, Style/MultilineBlockLayout and 0.42.0 engine upgrade [\#5218](https://github.com/chef/chef/pull/5218) ([lamont-granquist](https://github.com/lamont-granquist))
- Switch from Ruby 2.1.9 to Ruby 2.3.1 [\#5190](https://github.com/chef/chef/pull/5190) ([jkeiser](https://github.com/jkeiser))
- Update to latest chefstyle [\#5217](https://github.com/chef/chef/pull/5217) ([jkeiser](https://github.com/jkeiser))
- Rubygems memory performance improvement [\#5203](https://github.com/chef/chef/pull/5203) ([lamont-granquist](https://github.com/lamont-granquist))
- HTTP 1.1 keepalives for cookbook synchronization [\#5151](https://github.com/chef/chef/pull/5151) ([lamont-granquist](https://github.com/lamont-granquist))

**Fixed Bugs:**

- Fixes GH-4955, allowing local gems with remote dependencies [\#5098](https://github.com/chef/chef/pull/5098) ([jyaworski](https://github.com/jyaworski))
- Hook up the recipe\_file\_loaded event which was defined but not actually called [\#5281](https://github.com/chef/chef/pull/5281) ([coderanger](https://github.com/coderanger))
- fix gem\_package regression in master [\#5262](https://github.com/chef/chef/pull/5262) ([lamont-granquist](https://github.com/lamont-granquist))
- Added fix for spaces in profile identifiers [\#5159](https://github.com/chef/chef/pull/5159) ([natewalck](https://github.com/natewalck))
- Add a hook for compat\_resource [\#5259](https://github.com/chef/chef/pull/5259) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix flush\_cache issues in yum\_package [\#5258](https://github.com/chef/chef/pull/5258) ([jaymzh](https://github.com/jaymzh))
- Use symbols instead of strings as keys for systemd user property [\#5241](https://github.com/chef/chef/pull/5241) ([joshuamiller01](https://github.com/joshuamiller01))
- Use upstart goal state as service status [\#5249](https://github.com/chef/chef/pull/5249) ([evan2645](https://github.com/evan2645))
- Fix the useradd test filters [\#5236](https://github.com/chef/chef/pull/5236) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix specify members of group on suse/openbsd/solaris2/hpux [\#5152](https://github.com/chef/chef/pull/5152) ([tas50](https://github.com/tas50))
- Fix cookbook upload of symlinked cookbooks in Ruby 2.3 on Windows [\#5216](https://github.com/chef/chef/pull/5216) ([jkeiser](https://github.com/jkeiser))
- Don't use relative\_path\_from on glob results [\#5215](https://github.com/chef/chef/pull/5215) ([jkeiser](https://github.com/jkeiser))

## [v12.13.37](https://github.com/chef/chef/tree/v12.13.37) (2016-08-12)
[Full Changelog](https://github.com/chef/chef/compare/v12.13.30...v12.13.37)

**Enhancements:**

- Bumping ohai and mixlib-log to fix regression [\#5197](https://github.com/chef/chef/pull/5197) ([mwrock](https://github.com/mwrock))
- Remove requires in Chef::Recipe that are no longer necessary [\#5189](https://github.com/chef/chef/pull/5189) ([lamont-granquist](https://github.com/lamont-granquist))

## [v12.13.30](https://github.com/chef/chef/tree/v12.13.30) (2016-08-05)
[Full Changelog](https://github.com/chef/chef/compare/v12.12.15...v12.13.30)

**Enhancements:**

- noop apt_update similar to apt_repository [\#5173](https://github.com/chef/chef/pull/5173) ([lamont-granquist](https://github.com/lamont-granquist))
- Bump dependencies to bring in Ohai 8.18 [\#5168](https://github.com/chef/chef/pull/5168) ([tas50](https://github.com/tas50))
- Make Chef work with Ruby 2.3, update Ruby to 2.1.9 [\#5165](https://github.com/chef/chef/pull/5165) ([jkeiser](https://github.com/jkeiser))
- Log cause chain for exceptions [\#3354](https://github.com/chef/chef/pull/3354) ([jaym](https://github.com/jaym))
- First pass on --config-option handling. [\#5045](https://github.com/chef/chef/pull/5045) ([coderanger](https://github.com/coderanger))
- Add bootstrap proxy authentication support. [\#4059](https://github.com/chef/chef/pull/4059) ([yossigo](https://github.com/yossigo))
- Support setting an empty string for cron attrs [\#5127](https://github.com/chef/chef/pull/5127) ([thommay](https://github.com/thommay))
- Also clear notifications when deleting a resource. [\#5146](https://github.com/chef/chef/pull/5146) ([coderanger](https://github.com/coderanger))
- Clean up subscribes internals and notification storage. [\#5145](https://github.com/chef/chef/pull/5145) ([coderanger](https://github.com/coderanger))
- Cache ChefFS children [\#5131](https://github.com/chef/chef/pull/5131) ([thommay](https://github.com/thommay))
- Update to rspec 3.5 [\#5126](https://github.com/chef/chef/pull/5126) ([thommay](https://github.com/thommay))
- Add `chef\_data\_bag\_item` to Cheffish DSL methods [\#5125](https://github.com/chef/chef/pull/5125) ([danielsdeleo](https://github.com/danielsdeleo))
- replace glibc resolver with ruby resolver [\#5123](https://github.com/chef/chef/pull/5123) ([lamont-granquist](https://github.com/lamont-granquist))
- The user must specify a category for a new cookbook [\#5091](https://github.com/chef/chef/pull/5091) ([thommay](https://github.com/thommay))
- Warn if not installing an individual bff fileset [\#5093](https://github.com/chef/chef/pull/5093) ([mwrock](https://github.com/mwrock))
- Use Mixlib::Archive to extract tarballs [\#5080](https://github.com/chef/chef/pull/5080) ([thommay](https://github.com/thommay))
- Data Collector server URL validation, and disable on host down [\#5076](https://github.com/chef/chef/pull/5076) ([adamleff](https://github.com/adamleff))

**Fixed Bugs:**

- Don't log error for reporting audit data in when in chef-zero [\#5016](https://github.com/chef/chef/pull/5016) ([erichelgeson](https://github.com/erichelgeson))
- Invalidate the file system cache on deletion [\#5154](https://github.com/chef/chef/pull/5154) ([thommay](https://github.com/thommay))
- Root ACLs are a top level json file not a sub-directory [\#5155](https://github.com/chef/chef/pull/5155) ([thommay](https://github.com/thommay))
- Install nokogiri and pin mixlib-cli [\#5118](https://github.com/chef/chef/pull/5118) ([ksubrama](https://github.com/ksubrama))
- Ensure that the valid option is given back to the option parser [\#5114](https://github.com/chef/chef/pull/5114) ([dldinternet](https://github.com/dldinternet))
- Fixed regex for zypper version 1.13.\*.  [\#5109](https://github.com/chef/chef/pull/5109) ([yeoldegrove](https://github.com/yeoldegrove))
- add back method\_missing support to set\_unless [\#5103](https://github.com/chef/chef/pull/5103) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix \#5094 node.default\_unless issue in 12.12.13 [\#5097](https://github.com/chef/chef/pull/5097) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix \#5078 using cwd parameter instead of Dir.pwd [\#5079](https://github.com/chef/chef/pull/5079) ([Tensibai](https://github.com/Tensibai))

## [v12.12.15](https://github.com/chef/chef/tree/v12.12.15) (2016-07-08)
[Full Changelog](https://github.com/chef/chef/compare/v12.12.13...v12.12.15)

**Fixed Bugs:**

- Fix for #5094 12.12.13 node.default_unless issue [\#5097](https://github.com/chef/chef/pull/5097) ([lamont-granquist](https://github.com/lamont-granquist))

## [v12.12.13](https://github.com/chef/chef/tree/v12.12.13) (2016-07-01)
[Full Changelog](https://github.com/chef/chef/compare/v12.11.18...v12.12.13)

**Implemented Enhancements:**

- Tweak 3694 warnings [\#5075](https://github.com/chef/chef/pull/5075) ([lamont-granquist](https://github.com/lamont-granquist))
- Adding node object to Data collector run\_converge message [\#5065](https://github.com/chef/chef/pull/5065) ([adamleff](https://github.com/adamleff))
- Attribute API improvements [\#5029](https://github.com/chef/chef/pull/5029) ([lamont-granquist](https://github.com/lamont-granquist))
- Remove deprecated Thread.exclusive around require call. [\#5068](https://github.com/chef/chef/pull/5068) ([maxlazio](https://github.com/maxlazio))
- Ensure that chef-solo uses the expected repo dir [\#5059](https://github.com/chef/chef/pull/5059) ([thommay](https://github.com/thommay))
- Expand data\_collector resource list to include all resources [\#5058](https://github.com/chef/chef/pull/5058) ([adamleff](https://github.com/adamleff))
- Turn off fips with an empty environment var [\#5048](https://github.com/chef/chef/pull/5048) ([mwrock](https://github.com/mwrock))
- Deprecate knife-supermarket gem [\#4896](https://github.com/chef/chef/pull/4896) ([thommay](https://github.com/thommay))
- Update Nokogiri [\#5042](https://github.com/chef/chef/pull/5042) ([mwrock](https://github.com/mwrock))
- Remote resource should respect sensitive flag [\#5025](https://github.com/chef/chef/pull/5025) ([PrajaktaPurohit](https://github.com/PrajaktaPurohit))
- Convert the 3694 warning to a deprecation so it will be subject to the usual deprecation formatting \(collected at the bottom, can be made an error, etc\). [\#5022](https://github.com/chef/chef/pull/5022) ([coderanger](https://github.com/coderanger))
- Deprecate `knife cookbook create` in favor of `chef generate cookbook`. [\#5021](https://github.com/chef/chef/pull/5021) ([tylercloke](https://github.com/tylercloke))

**Fixed Bugs:**

- Fixes windows_package uninstall scenarios by calling uninstall string directly [\#5050](https://github.com/chef/chef/pull/5050) ([mwrock](https://github.com/mwrock))
- Fix gem_package idempotency [\#5046](https://github.com/chef/chef/pull/5046) ([thommay](https://github.com/thommay))
- Undefined local variable lookup in multiplexed_dir.rb [\#5027](https://github.com/chef/chef/issues/5027) ([robdimarco](https://github.com/robdimarco))
- Correctly write out data collector metadata file [\#5019](https://github.com/chef/chef/pull/5019) ([adamleff](https://github.com/adamleff))
- Eliminate missing constant errors for LWRP class [\#5000](https://github.com/chef/chef/pull/5000) ([PrajaktaPurohit](https://github.com/PrajaktaPurohit))
- Updated_resource_count to data collector should only include updated resources [\#5006](https://github.com/chef/chef/pull/5006) ([adamleff](https://github.com/adamleff))
- Don't mask directory deletion errors [\#4991](https://github.com/chef/chef/pull/4991) ([jaymzh](https://github.com/jaymzh))

## [v12.11.18](https://github.com/chef/chef/tree/v12.11.18) (2016-06-02)
[Full Changelog](https://github.com/chef/chef/compare/v12.11.17...v12.11.18)

**Implemented Enhancements:**

- Creation of the new DataCollector reporter [\#4973](https://github.com/chef/chef/pull/4973) ([adamleff](https://github.com/adamleff))
- Add systemd\_unit try-restart, reload-or-restart, reload-or-try-restart actions [\#4908](https://github.com/chef/chef/pull/4908) ([nathwill](https://github.com/nathwill))
- RFC062 exit status chef client [\#4611](https://github.com/chef/chef/pull/4611) ([smurawski](https://github.com/smurawski))
- Create 'universal' DSL [\#4942](https://github.com/chef/chef/pull/4942) ([lamont-granquist](https://github.com/lamont-granquist))
- Handle numeric id for the user value in the git resource [\#4902](https://github.com/chef/chef/pull/4902) ([MichaelPereira](https://github.com/MichaelPereira))
- RFC 31 - Default solo to local mode [\#4919](https://github.com/chef/chef/pull/4919) ([thommay](https://github.com/thommay))
- Wire up chef handlers directly from libraries [\#4933](https://github.com/chef/chef/pull/4933) ([lamont-granquist](https://github.com/lamont-granquist))
- Reject malformed ini content in systemd\_unit resource [\#4907](https://github.com/chef/chef/pull/4907) ([nathwill](https://github.com/nathwill))
- Update usage of @new\_resource.destination to `cwd` within the git hwrp [\#4898](https://github.com/chef/chef/pull/4898) ([joshburt](https://github.com/joshburt))
- Support Ruby Files in ChefFS [\#4887](https://github.com/chef/chef/pull/4887) ([thommay](https://github.com/thommay))
- Adds a system check for fips enablement and runs in fips mode if enabled [\#4880](https://github.com/chef/chef/pull/4880) ([mwrock](https://github.com/mwrock))
- Lazy'ing candidate\_version in package provider [\#4869](https://github.com/chef/chef/pull/4869) ([lamont-granquist](https://github.com/lamont-granquist))
- Add systemd\_unit resource [\#4700](https://github.com/chef/chef/pull/4700) ([nathwill](https://github.com/nathwill))
- Bump chef-zero to avoid aggressive logging [\#4878](https://github.com/chef/chef/pull/4878) ([stevendanna](https://github.com/stevendanna))

**Fixed Bugs:**

- Fix \#4949 and Avoid Errno::EBUSY on docker containers [\#4979](https://github.com/chef/chef/pull/4979) ([andrewjamesbrown](https://github.com/andrewjamesbrown))
- Ensure recipe-url works right in solo [\#4957](https://github.com/chef/chef/pull/4957) ([thommay](https://github.com/thommay))
- Fix portage provider to support version with character [\#4966](https://github.com/chef/chef/pull/4966) ([crigor](https://github.com/crigor))
- Fixes \#4968 and only retrieves the latest version of packages from chocolatey [\#4977](https://github.com/chef/chef/pull/4977) ([mwrock](https://github.com/mwrock))
- Update contributing doc to better reflect reality [\#4962](https://github.com/chef/chef/pull/4962) ([tas50](https://github.com/tas50))
- Load cookbook versions correctly for knife [\#4936](https://github.com/chef/chef/pull/4936) ([thommay](https://github.com/thommay))
- Gem metadata command needs Gem.clear\_paths [\#4929](https://github.com/chef/chef/pull/4929) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix os x profile provider for nil [\#4921](https://github.com/chef/chef/pull/4921) ([achand](https://github.com/achand))
- Cookbook site install : tar error on windows [\#4867](https://github.com/chef/chef/pull/4867) ([willoucom](https://github.com/willoucom))
- Fix yum\_package breakage \(the =~ operator in ruby is awful\) [\#4912](https://github.com/chef/chef/pull/4912) ([lamont-granquist](https://github.com/lamont-granquist))
- Encode registry enumerated values and keys to utf8 instead of the local codepage [\#4906](https://github.com/chef/chef/pull/4906) ([mwrock](https://github.com/mwrock))
- Chocolatey Package Provider chomps nil object [\#4760](https://github.com/chef/chef/pull/4760) ([svmastersamurai](https://github.com/svmastersamurai))
- Fixes knife ssl check on windows [\#4886](https://github.com/chef/chef/pull/4886) ([mwrock](https://github.com/mwrock))

## [v12.10.24](https://github.com/chef/chef/tree/v12.10.24) (2016-04-27)
[Full Changelog](https://github.com/chef/chef/compare/v12.10.23...v12.10.24)

**Fixed Bugs:**

- Removing non-existent members from group should not fail [\#4812](https://github.com/chef/chef/pull/4812) ([chefsalim](https://github.com/chefsalim))
- The easy\_install provider and resource are deprecated and will be removed in Chef 13 [\#4860](https://github.com/chef/chef/pull/4860) ([coderanger](https://github.com/coderanger))

**Tech cleanup:**

- Refactor ChefFS files to be files [\#4837](https://github.com/chef/chef/pull/4837) ([thommay](https://github.com/thommay))
- Rename and add backcompat requires for ChefFS dirs [\#4830](https://github.com/chef/chef/pull/4830) ([thommay](https://github.com/thommay))
- Refactor ChefFS directories to be directories [\#4826](https://github.com/chef/chef/pull/4826) ([thommay](https://github.com/thommay))
- Move all ChefFS exceptions into a single file [\#4822](https://github.com/chef/chef/pull/4822) ([thommay](https://github.com/thommay))

**Enhancements:**

- Add layout option support for device creation to mdadm resource provider [\#4855](https://github.com/chef/chef/pull/4855) ([kbruner](https://github.com/kbruner))
- add notifying\_block and subcontext\_block to chef [\#4818](https://github.com/chef/chef/pull/4818) ([lamont-granquist](https://github.com/lamont-granquist))
- modernize shell\_out method syntax [\#4865](https://github.com/chef/chef/pull/4865) ([lamont-granquist](https://github.com/lamont-granquist))
- Update rubygems provider to support local install of gems if so specified [\#4847](https://github.com/chef/chef/pull/4847) ([PrajaktaPurohit](https://github.com/PrajaktaPurohit))
- fix details in with\_run\_context [\#4839](https://github.com/chef/chef/pull/4839) ([lamont-granquist](https://github.com/lamont-granquist))
- Lock dependencies of chef through a `Gemfile.lock` [\#4820](https://github.com/chef/chef/pull/4820) ([jkeiser](https://github.com/jkeiser))
- add better resource manipulation API [\#4834](https://github.com/chef/chef/pull/4834) ([lamont-granquist](https://github.com/lamont-granquist))
- add nillable apt\_repository and nillable properties [\#4832](https://github.com/chef/chef/pull/4832) ([lamont-granquist](https://github.com/lamont-granquist))

## [v12.9](https://github.com/chef/chef/tree/v12.9.38) (2016-04-09)
[Full Changelog](https://github.com/chef/chef/compare/v12.8.2...v12.9.38)

**Implemented enhancements:**

- Sftp remote file support [\#4750](https://github.com/chef/chef/pull/4750) ([jkerry](https://github.com/jkerry))
- Setting init\_command should be accepted instead of specific command overrides [\#4709](https://github.com/chef/chef/pull/4709) ([coderanger](https://github.com/coderanger))
- Add a NoOp provider [\#4798](https://github.com/chef/chef/pull/4798) ([thommay](https://github.com/thommay))
- Add ability to notify from inside LWRP to wrapping resource\_collections [\#4017](https://github.com/chef/chef/issues/4017)
- Notifications from LWRPS/sub-resources can trigger resources in outer run\_context scopes [\#4741](https://github.com/chef/chef/pull/4741) ([lamont-granquist](https://github.com/lamont-granquist))
- Improve the docs generated by knife cookbook create [\#4757](https://github.com/chef/chef/pull/4757) ([tas50](https://github.com/tas50))
- Need Config/CLI options to move interval+splay sleep to end of client loop [\#3305](https://github.com/chef/chef/issues/3305)
- Add optional integer argument for --daemonize option [\#4759](https://github.com/chef/chef/pull/4759) ([jrunning](https://github.com/jrunning))
- Add shorthand :syslog and :win\_evt for log\_location config [\#4751](https://github.com/chef/chef/pull/4751) ([jrunning](https://github.com/jrunning))

**Fixed bugs:**

- chef\_gem and gem metadata don't play well [\#4710](https://github.com/chef/chef/issues/4710)
- Fix cookbook metadata 'gem' command to make it useful [\#4809](https://github.com/chef/chef/pull/4809) ([lamont-granquist](https://github.com/lamont-granquist))
- Convert timeout config to integer [\#4787](https://github.com/chef/chef/pull/4787) ([chefsalim](https://github.com/chefsalim))
- The mount resource is not idempotent on windows [\#3861](https://github.com/chef/chef/issues/3861)
- fix for \#4715 - unset TMPDIR in homebrew package provider [\#4716](https://github.com/chef/chef/pull/4716) ([gips0n](https://github.com/gips0n))
- tons of "Deprecation class overwrites LWRP resource" WARNING SPAM with chefspec [\#4668](https://github.com/chef/chef/issues/4668)

**Merged pull requests:**

- Add apt\_repository resource [\#4782](https://github.com/chef/chef/pull/4782) ([thommay](https://github.com/thommay))
- Point to the right license file for chef. [\#4811](https://github.com/chef/chef/pull/4811) ([sersut](https://github.com/sersut))
- add omnibus license metadata [\#4805](https://github.com/chef/chef/pull/4805) ([patrick-wright](https://github.com/patrick-wright))
- Add default timeout [\#4804](https://github.com/chef/chef/pull/4804) ([chefsalim](https://github.com/chefsalim))
- Spec break on Windows due to temp dir and short path names [\#4776](https://github.com/chef/chef/pull/4776) ([adamedx](https://github.com/adamedx))
- Require chef/version since it's used here [\#4762](https://github.com/chef/chef/pull/4762) ([jkeiser](https://github.com/jkeiser))
- remove pry from rbx build [\#4761](https://github.com/chef/chef/pull/4761) ([lamont-granquist](https://github.com/lamont-granquist))
- ruby 2.0.0 is EOL [\#4752](https://github.com/chef/chef/pull/4752) ([lamont-granquist](https://github.com/lamont-granquist))
- supresses parser gem errors [\#4755](https://github.com/chef/chef/pull/4755) ([lamont-granquist](https://github.com/lamont-granquist))
- Set inherit=false on the fallback provider constant lookup. [\#4753](https://github.com/chef/chef/pull/4753) ([coderanger](https://github.com/coderanger))

**Closed issues:**

- Uploading an encrypted data bag to Chef server fails [\#4815](https://github.com/chef/chef/issues/4815)
- powershell\_script does not have PSCredential capability [\#4589](https://github.com/chef/chef/issues/4589)
- Documentation don't include how to setup mail server during deployment of Chef server [\#4807](https://github.com/chef/chef/issues/4807)
- Resource 'mount' and chef 12.5.1 [\#4056](https://github.com/chef/chef/issues/4056)
- Incorrect $TMPDIR environment variable on OS X [\#4715](https://github.com/chef/chef/issues/4715)
- group provider on suse Linux adds user multiple times [\#4689](https://github.com/chef/chef/issues/4689)
- Unexpected error when using "knife cookbook show ...." [\#4659](https://github.com/chef/chef/issues/4659)

## [12.8.1](https://github.com/chef/chef/tree/12.8.1) (2016-03-07)
[Full Changelog](https://github.com/chef/chef/compare/12.7.2...12.8.1)

**Implemented enhancements:**

- Clarify the probable cause of tempfile creation failure during cookbook sync [\#2171](https://github.com/chef/chef/issues/2171)
- Remove static libraries from Chef package [\#4654](https://github.com/chef/chef/pull/4654) ([chefsalim](https://github.com/chefsalim))
- Have client.rb verify that FIPS mode can be enforced [\#4630](https://github.com/chef/chef/pull/4630) ([ksubrama](https://github.com/ksubrama))
- List all of the unignored files when loading a cookbook [\#4629](https://github.com/chef/chef/pull/4629) ([danielsdeleo](https://github.com/danielsdeleo))
- adding pry and pry-byebug to dev dependencies [\#4601](https://github.com/chef/chef/pull/4601) ([mwrock](https://github.com/mwrock))
- Split group members on commas [\#4583](https://github.com/chef/chef/pull/4583) ([thommay](https://github.com/thommay))
- Make tempfiles easier to read \(prepend chef to the name\) [\#4582](https://github.com/chef/chef/pull/4582) ([thommay](https://github.com/thommay))
- Extend cookbook shadowing deprecation warnings more broadly [\#4574](https://github.com/chef/chef/pull/4574) ([lamont-granquist](https://github.com/lamont-granquist))
- tell knife's edit\_data what the object is [\#4548](https://github.com/chef/chef/pull/4548) ([thommay](https://github.com/thommay))
- Implement knife bootstrap client.d RFC [\#4529](https://github.com/chef/chef/pull/4529) ([jaym](https://github.com/jaym))
- Update to Log Level when showing unencrypted databag [\#4524](https://github.com/chef/chef/pull/4524) ([PatrickWalker](https://github.com/PatrickWalker))
- RFC-060 gem metadata MVP [\#4478](https://github.com/chef/chef/pull/4478) ([lamont-granquist](https://github.com/lamont-granquist))
- chef-client: add --\[no\]skip-cookbook-sync option [\#4316](https://github.com/chef/chef/pull/4316) ([josb](https://github.com/josb))
- Extend service resource to support masking [\#4307](https://github.com/chef/chef/pull/4307) ([davide125](https://github.com/davide125))
- launchd for osx [\#4111](https://github.com/chef/chef/pull/4111) ([mikedodge04](https://github.com/mikedodge04))

**Fixed bugs:**

- Chef::DataBagItem.to\_hash is modifying Chef::DataBagItem.raw\_data [\#4614](https://github.com/chef/chef/issues/4614)
- Chef 12 seeing a ton of these in debug mode [\#2396](https://github.com/chef/chef/issues/2396)
- Data bag item hash can have name key [\#4664](https://github.com/chef/chef/pull/4664) ([chefsalim](https://github.com/chefsalim))
- Clearer exception for loading non-existent data bag items in solo mode. [\#4655](https://github.com/chef/chef/pull/4655) ([coderanger](https://github.com/coderanger))
- Always rehash from gem source and not existing hash file [\#4651](https://github.com/chef/chef/pull/4651) ([tyler-ball](https://github.com/tyler-ball))
- Handle negative content length headers too. [\#4646](https://github.com/chef/chef/pull/4646) ([coderanger](https://github.com/coderanger))
- if no module name is found for a valid dsc resource default to PSDesiredStateConfiguration [\#4638](https://github.com/chef/chef/pull/4638) ([mwrock](https://github.com/mwrock))
- removing disabling of readline in chef-shell [\#4635](https://github.com/chef/chef/pull/4635) ([mwrock](https://github.com/mwrock))
- Fix a bug that was causing DataBagItem.to\_hash to mutate the data bag item [\#4631](https://github.com/chef/chef/pull/4631) ([itmustbejj](https://github.com/itmustbejj))
- ensure paths maintain utf-8ness in non ascii encodings [\#4626](https://github.com/chef/chef/pull/4626) ([mwrock](https://github.com/mwrock))
- Fix the Chocolatey-missing error again [\#4621](https://github.com/chef/chef/pull/4621) ([randomcamel](https://github.com/randomcamel))
- fixes exe package downloads [\#4612](https://github.com/chef/chef/pull/4612) ([mwrock](https://github.com/mwrock))
- fallback to netmsg.dll error table if error message is not found in system errors [\#4600](https://github.com/chef/chef/pull/4600) ([mwrock](https://github.com/mwrock))
- zypper multipackage performance fix [\#4591](https://github.com/chef/chef/pull/4591) ([lamont-granquist](https://github.com/lamont-granquist))
- bugfix \#2865 check for validation\_key [\#4581](https://github.com/chef/chef/pull/4581) ([thommay](https://github.com/thommay))
- remove bogus recalculation of cookbook upload failures [\#4580](https://github.com/chef/chef/pull/4580) ([thommay](https://github.com/thommay))
- Make sure we have a valid object before calling close! [\#4579](https://github.com/chef/chef/pull/4579) ([thommay](https://github.com/thommay))
- Fix policyfile\_zero provisioner in 12.7 [\#4571](https://github.com/chef/chef/pull/4571) ([andy-dufour](https://github.com/andy-dufour))
- do not include source parameter when removing a chocolatey package and ensure source is used on all functional tests [\#4570](https://github.com/chef/chef/pull/4570) ([mwrock](https://github.com/mwrock))
- Fix databag globbing issues for chef-solo on windows [\#4569](https://github.com/chef/chef/pull/4569) ([jaym](https://github.com/jaym))
- remove Chef::Mixin::Command use [\#4566](https://github.com/chef/chef/pull/4566) ([lamont-granquist](https://github.com/lamont-granquist))

## 12.7.2

* [pr#4559](https://github.com/chef/chef/pull/4559) Remove learnchef acceptance tests until we make them more reliable
* [pr#4545](https://github.com/chef/chef/pull/4545) Removing rm -rf in chef-solo recipe_url

## 12.7.1
* [**Daniel Steen**](https://github.com/dansteen)
  * [pr#3183](https://github.com/chef/chef/pull/3183) Provide more helpful error message when accidentally using --secret instead of --secret-file

* [pr#4532](https://github.com/chef/chef/pull/4532) Bump Bundler + Rubygems
* [pr#4550](https://github.com/chef/chef/pull/4550) Use a streaming request to download cookbook

## 12.7.0

* [**Nate Walck**](https://github.com/natewalck)
  * [pr#4078](https://github.com/chef/chef/pull/4078) Add `osx_profile` resource for OS X
* [**Timothy Cyrus**](https://github.com/tcyrus)
  * [pr#4420](https://github.com/chef/chef/pull/4420) Update code climate badge and code climate blocks in README.md
* [**Jordan Running**](https://github.com/jrunning)
  * [pr#4399](https://github.com/chef/chef/pull/4399) Correctly save policy_name and policy_group with `knife node edit`
* [**Brian Goad**](https://github.com/bbbco)
  * [pr#4315](https://github.com/chef/chef/pull/4315) Add extra tests around whether to skip with multiple guards

* [pr#4516](https://github.com/chef/chef/pull/4516) Return propper error messages when using windows based `mount`, `user` and `group` resources
* [pr#4500](https://github.com/chef/chef/pull/4500) Explicitly declare directory permissions of chef install on windows to restrict rights on Windows client versions
* [pr#4498](https://github.com/chef/chef/pull/4498) Correct major and minor OS versions for Windows 10 and add versions for Windows 2016 Server
* [pr#4375](https://github.com/chef/chef/pull/4375) No longer try to auto discover package version of `exe` based windows packages
* [pr#4369](https://github.com/chef/chef/pull/4396) Import omnibus-chef chef project definition and history
* [pr#4399](https://github.com/chef/chef/pull/4399) Correctly save `policy_name` and `policy_group` with `knife node edit`
* [pr#4278](https://github.com/chef/chef/pull/4278) make file resource use properties
* [pr#4479](https://github.com/chef/chef/pull/4479) Remove incorrect cookbook artifact normalization
* [pr#4470](https://github.com/chef/chef/pull/4470) Fix sh spacing issues
* [pr#4434](https://github.com/chef/chef/pull/4434) adds EOFError message to handlers
* [pr#4422](https://github.com/chef/chef/pull/4422) Add an apt_update resource
* [pr#4287](https://github.com/chef/chef/pull/4287) Default Chef with FIPS OpenSSL to use sign v1.3
* [pr#4461](https://github.com/chef/chef/pull/4461) debian-6 is EOL next month
* [pr#4460](https://github.com/chef/chef/pull/4460) Set range of system user/group id to max of 200
* [pr#4231](https://github.com/chef/chef/pull/4231) zypper multipackage patch
* [pr#4459](https://github.com/chef/chef/pull/4459) use require_paths and not path so bundler grabs all paths from a git reference
* [pr#4450](https://github.com/chef/chef/pull/4450) don't warn about ambiguous property usage
* [pr#4445](https://github.com/chef/chef/pull/4445) Add CBGB to the repository
* [pr#4423](https://github.com/chef/chef/pull/4423) Add deprecation warnings to Chef::REST and all json_creates
* [pr#4439](https://github.com/chef/chef/pull/4439) Sometimes chocolately doesn't appear on the path
* [pr#4432](https://github.com/chef/chef/pull/4432) add get_rest etc calls to ServerAPI
* [pr#4435](https://github.com/chef/chef/pull/4435) add nokogiri to omnibus-chef
* [pr#4419](https://github.com/chef/chef/pull/4419) explicitly adding .bat to service executable called by service in case users remove .bat from PATHEXT
* [pr#4413](https://github.com/chef/chef/pull/4413) configure chef client windows service to the correct chef directory
* [pr#4377](https://github.com/chef/chef/pull/4377) fixing candidate filtering and adding functional tests for chocolatey_package
* [pr#4406](https://github.com/chef/chef/pull/4406) Updating to the latest release of net-ssh to consume https://github.com/net-ssh/net-ssh/pull/280
* [pr#4405](https://github.com/chef/chef/pull/4405) ServerAPI will return a raw hash, so do that
* [pr#4400](https://github.com/chef/chef/pull/4400) inflate an environment after loading it
* [pr#4396](https://github.com/chef/chef/pull/4396) Remove duplicate initialization of @password in user_v1
* [pr#4344](https://github.com/chef/chef/pull/4344) Warn (v. info) when reloading resources
* [pr#4369](https://github.com/chef/chef/pull/4369) Migrate omnibus-chef project/software definitions for chef in here
* [pr#4106](https://github.com/chef/chef/pull/4106) add chocolatey_package to core chef
* [pr#4321](https://github.com/chef/chef/pull/4321) fix run_as_user of windows_service
* [pr#4333](https://github.com/chef/chef/pull/4333) no longer wait on node search to refresh vault but pass created ApiCient instead
* [pr#4325](https://github.com/chef/chef/pull/4325) Pin win32-eventlog to 0.6.3 to avoid clashing CreateEvent definition
* [pr#4312](https://github.com/chef/chef/pull/4312) Updates the template to use omnitruck-direct.chef.io
* [pr#4277](https://github.com/chef/chef/pull/4277) non msi packages must explicitly provide a source attribute on install
* [pr#4309](https://github.com/chef/chef/pull/4309) tags always an array; fix set_unless
* [pr#4278](https://github.com/chef/chef/pull/4278) make file resource use properties
* [pr#4288](https://github.com/chef/chef/pull/4288) Fix no_proxy setting in chef-config
* [pr#4273](https://github.com/chef/chef/pull/4273) Use signing protocol 1.1 by default
* [pr#4520](https://github.com/chef/chef/pull/4520) Fix a few `dsc_resource` bugs

## 12.6.0

* [**Dave Eddy**](https://github.com/bahamas10)
  [pr#3187](https://github.com/chef/chef/pull/3187) overhaul solaris SMF service provider
* [**Mikhail Zholobov**](https://github.com/legal90)
  - [pr#3192](https://github.com/chef/chef/pull/3192) provider/user/dscl: Set default gid to 20
  - [pr#3193](https://github.com/chef/chef/pull/3193) provider/user/dscl: Set "comment" default value
* [**Jordan Evans**](https://github.com/jordane)
  - [pr#3263](https://github.com/chef/chef/pull/3263) `value_for_platform` should use `Chef::VersionConstraint::Platform`
  - [pr#3633](https://github.com/chef/chef/pull/3633) add the word group to `converge_by` call for group provider
* [**Scott McGillivray**](https://github.com/thechile)
  [pr#3450](https://github.com/chef/chef/pull/3450) Fix 'knife cookbook show' to work on root files
* [**Aubrey Holland**](https://github.com/aub)
  [pr#3986](https://github.com/chef/chef/pull/3986) fix errors when files go away during chown
* [**James Michael DuPont**](https://github.com/h4ck3rm1k3)
  [pr#3973](https://github.com/chef/chef/pull/3973) better error reporting
* [**Michael Pereira**](https://github.com/MichaelPereira)
  [pr#3968](https://github.com/chef/chef/pull/3968) Fix cookbook installation from supermarket on windows
* [**Yukihiko SAWANOBORI**](https://github.com/sawanoboly)
  - [pr#3941](https://github.com/chef/chef/pull/3941) allow reboot by reboot resource with chef-apply
  - [pr#3900](https://github.com/chef/chef/pull/3900) Add new option json attributes file to bootstraping
* [**permyakovsv**](https://github.com/permyakovsv)
  [pr#3901](https://github.com/chef/chef/pull/3901) Add tmux-split parameter to knife ssh
* [**Evan Gilman**](https://github.com/evan2645)
  [pr#3864](https://github.com/chef/chef/pull/3864) Knife `bootstrap_environment` should use Explicit config before Implicit
* [**Ranjib Dey**](https://github.com/ranjib)
  [pr#3834](https://github.com/chef/chef/pull/3834) Dont spit out stdout and stderr for execute resource failure, if its declared sensitive
* [**Jeff Blaine**](https://github.com/jblaine)
  - [pr#3776](https://github.com/chef/chef/pull/3776) Changes --hide-healthy to --hide-by-mins MINS
  - [pr#3848](https://github.com/chef/chef/pull/3848) Migrate to --ssh-identity-file instead of --identity-file
* [**dbresson**](https://github.com/dbresson)
  [pr#3650](https://github.com/chef/chef/pull/3650) Define == for node objects
* [**Patrick Connolly**](https://github.com/patcon)
  [pr#3529](https://github.com/chef/chef/pull/3529) Allow user@hostname format for knife-bootstrap
* [**Justin Seubert**](https://github.com/dude051)
  [pr#4160](https://github.com/chef/chef/pull/4160) Correcting regex for upstart_state
* [**Sarah Michaelson**](https://github.com/skmichaelson)
  [pr#3810](https://github.com/chef/chef/pull/3810) GH-1909 Add validation for chef_server_url
* [**Maxime Brugidou**](https://github.com/brugidou)
  [pr#4052](https://github.com/chef/chef/pull/4052) Add make_child_entry in ChefFS CookbookSubdir
* [**Nathan Williams**](https://github.com/nathwill)
  [pr#3836](https://github.com/chef/chef/pull/3836) simplify service helpers
* [**Paul Welch**](https://github.com/pwelch)
  [pr#4066](https://github.com/chef/chef/pull/4066) Fix chef-apply usage banner
* [**Mat Schaffer**](https://github.com/matschaffer)
  [pr#4153](https://github.com/chef/chef/pull/4153) Require ShellOut before Knife::SSH definition
* [**Donald Guy**](https://github.com/donaldguy)
  [pr#4158](https://github.com/chef/chef/pull/4158) Allow named_run_list to be loaded from config
* [**Jos Backus**](https://github.com/josb)
  [pr#4064](https://github.com/chef/chef/pull/4064) Ensure that tags are properly initialized
* [**John Bellone**](https://github.com/johnbellone)
  [pr#4101](https://github.com/chef/chef/pull/4101) Adds alias method upgrade_package for solaris package
* [**Nolan Davidson**](https://github.com/nsdavidson)
  [pr#4014](https://github.com/chef/chef/pull/4014) Adding ksh resource

* [pr#4193](https://github.com/chef/chef/pull/4196) support for inno, nsis, wise and installshield installer types in windows_package resource
* [pr#4196](https://github.com/chef/chef/pull/4196) multipackage dpkg_package and bonus fixes
* [pr#4185](https://github.com/chef/chef/pull/4185) dpkg provider cleanup
* [pr#4165](https://github.com/chef/chef/pull/4165) Multipackage internal API improvements
* [pr#4081](https://github.com/chef/chef/pull/4081) RFC-037: add `chef_version` and `ohai_version` metadata
* [pr#3530](https://github.com/chef/chef/pull/3530) Allow using --sudo option with user's home folder in knife bootstrap
* [pr#3858](https://github.com/chef/chef/pull/3858) Remove duplicate 'Accept' header in spec
* [pr#3911](https://github.com/chef/chef/pull/3911) Avoid subclassing Struct.new
* [pr#3990](https://github.com/chef/chef/pull/3990) Use SHA256 instead of MD5 for `registry_key` when data is not displayable
* [pr#4034](https://github.com/chef/chef/pull/4034) add optional ruby-profiling with --profile-ruby
* [pr#3119](https://github.com/chef/chef/pull/3119) allow removing user, even if their GID isn't resolvable
* [pr#4068](https://github.com/chef/chef/pull/4068) update messaging from LWRP to Custom Resource in logging and spec
* [pr#4021](https://github.com/chef/chef/pull/4021) add missing requires for Chef::DSL::Recipe to LWRPBase
* [pr#3597](https://github.com/chef/chef/pull/3597) print STDOUT from the powershell_script
* [pr#4091](https://github.com/chef/chef/pull/4091) Allow downloading of root_files in a chef repository
* [pr#4112](https://github.com/chef/chef/pull/4112) Update knife bootstrap command to honor --no-color flag in chef-client run that is part of the bootstrap process.
* [pr#4090](https://github.com/chef/chef/pull/4090) Improve detection of ChefFS-based commands in `knife rehash`
* [pr#3991](https://github.com/chef/chef/pull/3991) Modify remote_file cache_control_data to use sha256 for its name
* [pr#4079](https://github.com/chef/chef/pull/4079) add logger to windows service shellout
* [pr#3966](https://github.com/chef/chef/pull/3966) Report expanded run list json tree to reporting
* [pr#4080](https://github.com/chef/chef/pull/4080) Make property modules possible
* [pr#4069](https://github.com/chef/chef/pull/4069) Improvements to log messages
* [pr#4049](https://github.com/chef/chef/pull/4049) Add gemspec files to allow bundler to run from the gem
* [pr#4029](https://github.com/chef/chef/pull/4029) Fix search result pagination
* [pr#4048](https://github.com/chef/chef/pull/4048) Accept coercion as a way to accept nil values
* [pr#4046](https://github.com/chef/chef/pull/4046) ignore gid in the user resource on windows
* [pr#4118](https://github.com/chef/chef/pull/4118) Make Property.derive create derived properties of the same type
* [pr#4133](https://github.com/chef/chef/pull/4133) Add retries to `Chef::HTTP` for transient SSL errors
* [pr#4135](https://github.com/chef/chef/pull/4135) Windows service uses log file location from config if none is given on commandline
* [pr#4142](https://github.com/chef/chef/pull/4142) Use the proper python interpretor for yum-dump.py on Fedora 21
* [pr#4149](https://github.com/chef/chef/pull/4149) Handle nil run list option in knife bootstrap
* [pr#4040](https://github.com/chef/chef/pull/4040) Implement live streaming for execute resources
* [pr#4167](https://github.com/chef/chef/pull/4167) Add `reboot_action` to `dsc_resource`
* [pr#4167](https://github.com/chef/chef/pull/4167) Allow `dsc_resource` to run with the LCM enabled
* [pr#4188](https://github.com/chef/chef/pull/4188) Update `dsc_resource` to use verbose stream output
* [pr#4200](https://github.com/chef/chef/pull/4200) Prevent inspect of PsCredential from printing out plain text password
* [pr#4237](https://github.com/chef/chef/pull/4237) Enabling 'knife ssl check/fetch' commands to respect proxy environment variables and moving proxy environment variables export to Chef::Config
## 12.5.1

* [**Ranjib Dey**](https://github.com/ranjib):
  [pr#3588](https://github.com/chef/chef/pull/3588) Count skipped resources among total resources in doc formatter
* [**John Kerry**](https://github.com/jkerry):
  [pr#3539](https://github.com/chef/chef/pull/3539) Fix issue: registry\_key resource is case sensitive in chef but not on windows
* [**David Eddy**](https://github.com/bahamas10):
  - [pr#3443](https://github.com/chef/chef/pull/3443) remove extraneous space
  - [pr#3091](https://github.com/chef/chef/pull/3091) fix locking/unlocking users on SmartOS
* [**margueritepd**](https://github.com/margueritepd):
  [pr#3693](https://github.com/chef/chef/pull/3693) Interpolate `%{path}` in verify command
* [**Jeremy Fleischman**](https://github.com/jfly):
  [pr#3383](https://github.com/chef/chef/pull/3383) gem\_package should install to the systemwide Ruby when using ChefDK
* [**Stefano Rivera**](https://github.com/stefanor):
  [pr#3657](https://github.com/chef/chef/pull/3657) fix upstart status\_commands
* [**ABE Satoru**](https://github.com/polamjag):
  [pr#3764](https://github.com/chef/chef/pull/3764) uniquify chef\_repo\_path
* [**Renan Vicente**](https://github.com/renanvicente):
  [pr#3771](https://github.com/chef/chef/pull/3771) add depth property for deploy resource
* [**James Belchamber**](https://github.com/JamesBelchamber):
  [pr#1796](https://github.com/chef/chef/pull/1796): make mount options aware
* [**Nate Walck**](https://github.com/natewalck):
  - [pr#3594](https://github.com/chef/chef/pull/3594): Update service provider for OSX 10.11
  - [pr#3704](https://github.com/chef/chef/pull/3704): Add SIP (OS X 10.11) support
* [**Phil Dibowitz**](https://github.com/jaymzh):
  [pr#3805](https://github.com/chef/chef/pull/3805) LWRP parameter validators should use truthiness
* [**Igor Shpakov**](https://github.com/Igorshp):
  [pr#3743](https://github.com/chef/chef/pull/3743) speed improvement for `remote_directory` resource
* [**James FitzGibbon**](https://github.com/jf647):
  [pr#3027](https://github.com/chef/chef/pull/3027) Add warnings to 'knife node run list remove ...'
* [**Backslasher**](https://github.com/backslasher):
  [pr#3172](https://github.com/chef/chef/pull/3172) Migrated deploy resource to use shell\_out instead of run\_command
* [**Sean Walberg**](https://github.com/swalberg):
  [pr#3190](https://github.com/chef/chef/pull/3190) Allow tags to be set on a node during bootstrap
* [**ckaushik**](https://github.com/ckaushik) and [**Sam Dunne**](https://github.com/samdunne):
  [pr#3510](https://github.com/chef/chef/pull/3510) Fix broken rendering
of partial templates.
* [**Simon Detheridge**](https://github.com/gh2k):
  [pr#3806](https://github.com/chef/chef/pull/3806) Replace output\_of\_command with shell\_out! in subversion provider
* [**Joel Handwell**](https://github.com/joelhandwell):
  [pr#3821](https://github.com/chef/chef/pull/3821) Human friendly elapsed time in log

* [pr#3985](https://github.com/chef/chef/pull/3985) Simplify the regex which determines the rpm version to resolve issue #3671
* [pr#3928](https://github.com/chef/chef/pull/3928) Add named run list support when using policyfiles
* [pr#3913](https://github.com/chef/chef/pull/3913) Add `policy_name`and `policy_group` fields to the node object
* [pr#3875](https://github.com/chef/chef/pull/3875) Patch Win32::Registry#delete_key, #delete_value to use wide (W) APIs
* [pr#3850](https://github.com/chef/chef/pull/3850) Patch Win32::Registry#write to fix encoding errors
* [pr#3837](https://github.com/chef/chef/pull/3837) refactor remote_directory provider for mem+perf improvement
* [pr#3799](https://github.com/chef/chef/pull/3799) fix supports hash issues in service providers
* [pr#3797](https://github.com/chef/chef/pull/3797) Fix dsc_script spec failure on 64-bit Ruby
* [pr#3817](https://github.com/chef/chef/pull/3817) Remove now-useless forcing of ruby Garbage Collector run
* [pr#3775](https://github.com/chef/chef/pull/3775) Enable 64-bit support for Powershell and Batch scripts
* [pr#3774](https://github.com/chef/chef/pull/3774) Add support for yum-deprecated in yum provider
* [pr#3793](https://github.com/chef/chef/pull/3793) CHEF-5372: Support specific `run_levels` for RedHat service
* [pr#2460](https://github.com/chef/chef/pull/2460) add privacy flag
* [pr#1259](https://github.com/chef/chef/pull/1259) CHEF-5012: add methods for template breadcrumbs
* [pr#3656](https://github.com/chef/chef/pull/3656) remove use of self.provides?
* [pr#3455](https://github.com/chef/chef/pull/3455) powershell\_script: do not allow suppression of syntax errors
* [pr#3519](https://github.com/chef/chef/pull/3519) The wording seemed odd.
* [pr#3208](https://github.com/chef/chef/pull/3208) Missing require (require what you use).
* [pr#3449](https://github.com/chef/chef/pull/3449) correcting minor typo in user\_edit knife action
* [pr#3572](https://github.com/chef/chef/pull/3572) Use windows paths without case-sensitivity.
* [pr#3666](https://github.com/chef/chef/pull/3666) Support SNI in `knife ssl check`.
* [pr#3667](https://github.com/chef/chef/pull/3667) Change chef service to start as 'Automatic delayed start'.
* [pr#3683](https://github.com/chef/chef/pull/3683) Correct Windows reboot command to delay in minutes, per the property.
* [pr#3698](https://github.com/chef/chef/pull/3698) Add ability to specify dependencies in chef-service-manager.
* [pr#3728](https://github.com/chef/chef/pull/3728) Rewrite NetLocalGroup things to use FFI
* [pr#3754](https://github.com/chef/chef/pull/3754) Fix functional tests for group resource - fix #3728
* [pr#3498](https://github.com/chef/chef/pull/3498) Use dpkg-deb directly rather than regex
* [pr#3759](https://github.com/chef/chef/pull/3759) Repair service convergence test on AIX
* [pr#3329](https://github.com/chef/chef/pull/3329) Use ifconfig target property
* [pr#3652](https://github.com/chef/chef/pull/3652) Fix explanation for configuring audit mode in client.rb
* [pr#3687](https://github.com/chef/chef/pull/3687) Add formatter and force-logger/formatter options to chef-apply
* [pr#3768](https://github.com/chef/chef/pull/3768) Make reboot\_pending? look for CBS RebootPending
* [pr#3815](https://github.com/chef/chef/pull/3815) Fix `powershell_script` validation to use correct architecture
* [pr#3772](https://github.com/chef/chef/pull/3772) Add `ps_credential` dsl method to `dsc_script`
* [pr#3462](https://github.com/chef/chef/pull/3462) Fix issue where `ps_credential` does not work over winrm

## 12.4.1

* [**Noah Kantrowitz**](https://github.com/coderanger):
  [pr#3605](https://github.com/chef/chef/pull/3605) Rework `Resource#action` to match 12.3 API

* [pr#3586](https://github.com/chef/chef/issues/3586) Fix bug preventing light weight resources from being used with heavy weight providers
* [Issue #3593](https://github.com/chef/chef/issues/3593) Fix bug where provider priority map did not take into consideration a provided block
* [pr#3630](https://github.com/chef/chef/pull/3630) Restore Chef::User and Chef::ApiClient namespace to API V0 functionality and move new functionality into Chef::UserV1 and Chef::ApiClientV1 until Chef 13.
* [pr#3611](https://github.com/chef/chef/pull/3611) Call `provides?` even if `provides` is not called
* [pr#3589](https://github.com/chef/chef/pull/3589) Fix errant bashisms
* [pr#3620](https://github.com/chef/chef/pull/3620) Fix issue where recipe names in run list mutate when version constaints are present
* [pr#3623](https://github.com/chef/chef/pull/3623) Allow LWRPs to access the real class when accessed through `Chef::Resource` and `Chef::Provider`
* [pr#3627](https://github.com/chef/chef/pull/3627) Separate priority map and DSL handler map so that `provides` has veto power over priority
* [pr#3638](https://github.com/chef/chef/pull/3638) Deprecate passing more than 1 argument to create a resource

## 12.4.0

* [**Phil Dibowitz**](https://github.com/jaymzh):
  Fix multipackage and architectures
* [**Igor Shpakov**](https://github.com/Igorshp):
  Always run exception handlers
  Prioritise manual ssh attribute over automatic ones for knife
* [**Noah Kantrowitz**](https://github.com/coderanger):
  Cache service\_resource\_providers for the duration of the run. #2953
* [**Slava Kardakov**](https://github.com/ojab):
  Fix installation of yum packages with version constraints #3155
* [**Dave Eddy**](https://github.com/bahamas10):
  fix smartos\_package for new "pkgin" output, fixes #3112 #3165
* [**Yukihiko SAWANOBORI**](https://github.com/sawanoboly):
  Show Chef version on chef shell prompt
* [**Jacob Minshall**](https://github.com/minshallj):
  Ensure suid bit is preserved if group or owner changes
* [**Tim Smith**](https://github.com/tas50):
  Convert wiki links to point to docs.chef.io
* [**SAWANOBORI Yukihiko**](https://github.com/sawanoboly):
  Add Chef::Log::Syslog class for integrating sending logs to syslog
* [**Pavel Yudin**](https://github.com/Kasen):
  Ensure LWRP and HWRP @action variable is consistent #3156
* [**Dan Bjorge**](https://github.com/dbjorge):
  Fix bad Windows securable\_resource functional spec assumptions for default file owners/groups #3266
* [**Yukihiko SAWANOBORI**](https://github.com/sawanoboly): Pass name by
  knife cil attribute [pr#3195](https://github.com/chef/chef/pull/3195)
* [**Torben Knerr**](https://github.com/tknerr):
  Allow knife sub-command loader to match platform specific gems. [pr#3281](https://github.com/chef/chef/pull/3281)
* [**Steve Lowe**](https://github.com/SteveLowe):
  Fix copying ntfs dacl and sacl when they are nil. [pr#3066](https://github.com/chef/chef/pull/3066)

* [pr#3339](https://github.com/chef/chef/pull/3339): Powershell command wrappers to make argument passing to knife/chef-client etc. easier.
* [pr#3720](https://github.com/chef/chef/pull/3270): Extract chef's configuration to a separate gem. Code stays in the Chef git repo.
* [pr#3321](https://github.com/chef/chef/pull/3321): Add an integration test of chef-client with empty ENV.
* [pr#3278](https://github.com/chef/chef/pull/3278): Switch over Windows builds to universal builds.
* [pr#2877](https://github.com/chef/chef/pull/2877): Convert bootstrap template to use sh.
* [Issue #3316](https://github.com/chef/chef/issues/3316): Fix idempotency issues with the `windows_package` resource
* [pr#3295](https://github.com/chef/chef/pull/3295): Stop mutating `new_resource.checksum` in file providers.  Fixes some ChecksumMismatch exceptions like [issue#3168](https://github.com/chef/chef/issues/3168)
* [pr#3320](https://github.com/chef/chef/pull/3320): Sanitize non-UTF8 characters in the node data before doing node.save().  Works around many UTF8 exception issues reported on node.save().
* Implemented X-Ops-Server-API-Version with a API version of 0, as well as error handling when the Chef server does not support the API version that the client supports.
* [pr#3327](https://github.com/chef/chef/pull/3327): Fix unreliable AIX service group parsing mechanism.
* [pr#3333](https://github.com/chef/chef/pull/3333): Fix SSL errors when connecting to private Supermarkets
* [pr#3340](https://github.com/chef/chef/pull/3340): Allow Event dispatch subscribers to be inspected.
* [Issue #3055](https://github.com/chef/chef/issues/3055): Fix regex parsing for recipe failures on Windows
* [pr#3345](https://github.com/chef/chef/pull/3345): Windows Event log logger
* [pr#3336](https://github.com/chef/chef/pull/3336): Remote file understands UNC paths
* [pr#3269](https://github.com/chef/chef/pull/3269): Deprecate automatic recipe DSL for classes in `Chef::Resource`
* [pr#3360](https://github.com/chef/chef/pull/3360): Add check_resource_semantics! lifecycle method to provider
* [pr#3344](https://github.com/chef/chef/pull/3344): Rewrite Windows user resouce code to use ffi instead of win32-api
* [pr#3318](https://github.com/chef/chef/pull/3318): Modify Windows package provider to allow for url source
* [pr#3381](https://github.com/chef/chef/pull/3381): warn on cookbook self-deps
* [pr#2312](https://github.com/chef/chef/pull/2312): fix `node[:recipes]` duplication, add `node[:cookbooks]` and `node[:expanded_run_list]`
* [pr#3325](https://github.com/chef/chef/pull/3325): enforce passing a node name with validatorless bootstrapping
* [pr#3398](https://github.com/chef/chef/pull/3398): Allow spaces in files for the `remote_file` resource
* [Issue #3010](https://github.com/chef/chef/issues/3010) Fixed `knife user` for use with current and future versions of Chef Server 12, with continued backwards compatible support for use with Open Source Server 11.
* [pr#3438](https://github.com/chef/chef/pull/3438) Server API V1 support. Vast improvements to and testing expansion for Chef::User, Chef::ApiClient, and related knife commands. Deprecated Open Source Server 11 user support to the Chef::OscUser and knife osc_user namespace, but with backwards compatible support via knife user.
* [Issue #2247](https://github.com/chef/chef/issues/2247): `powershell_script` returns 0 for scripts with syntax errors
* [pr#3080](https://github.com/chef/chef/pull/3080): Issue 2247: `powershell_script` exit status should be nonzero for syntax errors
* [pr#3441](https://github.com/chef/chef/pull/3441): Add `powershell_out` mixin to core chef
* [pr#3448](https://github.com/chef/chef/pull/3448): Fix `dsc_resource` to work with wmf5 april preview
* [pr#3392](https://github.com/chef/chef/pull/3392): Comment up `Chef::Client` and privatize/deprecate unused things
* [pr#3419](https://github.com/chef/chef/pull/3419): Fix cli issue with `chef_repo_path` when ENV variable is unset
* [pr#3358](https://github.com/chef/chef/pull/3358): Separate audit and converge failures
* [pr#3431](https://github.com/chef/chef/pull/3431): Fix backups on windows for the file resource
* [pr#3397](https://github.com/chef/chef/pull/3397): Validate owner exists in directory resources
* [pr#3418](https://github.com/chef/chef/pull/3418): Add `shell_out` mixin to Chef::Resource class for use in `not_if`/`only_if` conditionals, etc.
* [pr#3406](https://github.com/chef/chef/pull/3406): Add wide-char 'Environment' to `broadcast_env_change` mixin for setting windows environment variables
* [pr#3442](https://github.com/chef/chef/pull/3442): Add `resource_name` to top-level Resource class to make defining resources easier.
* [pr#3447](https://github.com/chef/chef/pull/3447): Add `allowed_actions` and `default_action` to top-level Resource class.
* [pr#3475](https://github.com/chef/chef/pull/3475): Fix `shell_out` timeouts in all package providers to respect timeout property on the resource.
* [pr#3477](https://github.com/chef/chef/pull/3477): Update `zypper_package` to look like the rest of our package classes.
* [pr#3483](https://github.com/chef/chef/pull/3483): Allow `include_recipe` from LWRP providers.
* [pr#3495](https://github.com/chef/chef/pull/3495): Make resource name automatically determined from class name, and provide DSL for it.
* [pr#3497](https://github.com/chef/chef/pull/3497): Issue 3485: Corruption of node's run\_context when non-default guard\_interpreter is evaluated
* [pr#3299](https://github.com/chef/chef/pull/3299): Remove experimental warning on audit mode

## 12.3.0

* [pr#3160](https://github.com/chef/chef/pull/3160): Use Chef Zero in
  socketless mode for local mode, add `--no-listen` flag to disable port
  binding
* [**Nolan Davidson**](https://github.com/nsdavidson):
  Removed after_created and added test to recipe_spec
* [**Tim Sogard**](https://github.com/drags):
  Reset $HOME to user running chef-client when running via sudo
* [**Torben Knerr**](https://github.com/tknerr):
  Allow for the chef gem installation to succeed without elevated privileges #3126
* [**Mike Dodge**](https://github.com/mikedodge04)
  MacOSX services: Load LaunchAgents as console user, adding plist and
  session_type options.
* [**Eric Herot**](https://github.com/eherot)
  Ensure knife ssh doesn't use a non-existant field for hostname #3131
* [**Tom Hughes**](https://github.com/tomhughes)
  Ensure searches progress in the face of incomplete responses #3135

* [pr#3162](https://github.com/chef/chef/pull/3162): Add
  `--minimal-ohai` flag to client/solo/apply; restricts ohai to only the
  bare minimum of plugins.
* Ensure link's path attribute works with delayed #3130
* gem_package, chef_gem should not shell out to using https://rubygems.org #2867
* Add dynamic resource resolution similar to dynamic provider resolution
* Add Chef class fascade to internal structures
* Fix nil pointer for windows event logger #3200
* Use partial search for knife status
* Ensure chef/knife properly honours proxy config

## 12.2.1
* [Issue 3153](https://github.com/chef/chef/issues/3153): Fix bug where unset HOME would cause chef to crash

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
* [Pull 2505](https://github.com/chef/chef/pull/2505) Make Chef handle URIs in a case-insensitive manner
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
[Issue 2594](https://github.com/chef/chef/issues/2594) Restore missing require in `digester`.

## 12.0.2
* [Issue 2578](https://github.com/chef/chef/issues/2578) Check that `installed` is not empty for `keg_only` formula in Homebrew provider
* [Issue 2609](https://github.com/chef/chef/issues/2609) Resolve the circular dependency between ProviderResolver and Resource.
* [Issue 2596](https://github.com/chef/chef/issues/2596) Fix nodes not writing to disk
* [Issue 2580](https://github.com/chef/chef/issues/2580) Make sure the relative paths are preserved when using link resource.
* [Pull 2630](https://github.com/chef/chef/pull/2630) Improve knife's SSL error messaging
* [Issue 2606](https://github.com/chef/chef/issues/2606) chef 12 ignores default_release for apt_package
* [Issue 2602](https://github.com/chef/chef/issues/2602) Fix `subscribes` resource notifications.
* [Issue 2578](https://github.com/chef/chef/issues/2578) Check that `installed` is not empty for `keg_only` formula in Homebrew provider.
* [**gh2k**](https://github.com/gh2k):
  [Issue 2625](https://github.com/chef/chef/issues/2625) Fix missing `shell_out!` for `windows_package` resource
* [**BackSlasher**](https://github.com/BackSlasher):
  [Issue 2634](https://github.com/chef/chef/issues/2634) Fix `option ':command' is not a valid option` error in subversion provider.
* [**Seth Vargo**](https://github.com/sethvargo):
  [Issue 2345](https://github.com/chef/chef/issues/2345) Allow knife to install cookbooks with metadata.json.

## 12.0.1

* [Issue 2552](https://github.com/chef/chef/issues/2552) Create constant for LWRP before calling `provides`
* [Issue 2545](https://github.com/chef/chef/issues/2545) `path` attribute of `execute` resource is restored to provide backwards compatibility with Chef 11.
* [Issue 2565](https://github.com/chef/chef/issues/2565) Fix `Chef::Knife::Core::BootstrapContext` constructor for knife-windows compat.
* [Issue 2566](https://github.com/chef/chef/issues/2566) Make sure Client doesn't raise error when interval is set on Windows.
* [Issue 2560](https://github.com/chef/chef/issues/2560) Fix `uninitialized constant Windows::Constants` in `windows_eventlog`.
* [Issue 2563](https://github.com/chef/chef/issues/2563) Make sure the Chef Client rpm packages are signed with GPG keys correctly.

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
  Implemented [RFC017 - File Specificity Overhaul](https://github.com/chef/chef-rfc/blob/master/rfc017-file-specificity.md).
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
* Added RFC-023 Chef 12 Attribute Changes (https://github.com/chef/chef-rfc/blob/master/rfc023-chef-12-attributes-changes.md)
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
* Deprecate --distro / --template_file options in favor of --bootstrap-template
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