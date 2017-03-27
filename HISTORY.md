## [v12.19.33](https://github.com/chef/chef/tree/v12.19.33) (2017-02-16)
[Full Changelog](https://github.com/chef/chef/compare/v12.18.31...v12.19.33)

**Closed issues:**

- Package resource fails chefspec on RHEL starting with Chef 12.18. [\#5769](https://github.com/chef/chef/issues/5769)

**Merged pull requests:**

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