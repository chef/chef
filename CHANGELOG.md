# Change Log

## [12.6.0](https://github.com/chef/chef/tree/12.6.0) (2015-11-30)
[Full Changelog](https://github.com/chef/chef/compare/12.5.1-omnibus...12.6.0)

**Merged pull requests:**

- fix rspecs-ctrl-c [\#4206](https://github.com/chef/chef/pull/4206) ([lamont-granquist](https://github.com/lamont-granquist))
- add better docs on why we mutate the new-resource in the service provider for reporting [\#4203](https://github.com/chef/chef/pull/4203) ([lamont-granquist](https://github.com/lamont-granquist))
- Prevent inspect on PsCredential from printing out plain text password [\#4200](https://github.com/chef/chef/pull/4200) ([jaym](https://github.com/jaym))
- Fix typo in comment [\#4192](https://github.com/chef/chef/pull/4192) ([gregkare](https://github.com/gregkare))
- Update dsc\_resource to use verbose stream output [\#4188](https://github.com/chef/chef/pull/4188) ([chefsalim](https://github.com/chefsalim))
- Documentation update: add README.md links to join IRC channels [\#4187](https://github.com/chef/chef/pull/4187) ([martinb3](https://github.com/martinb3))
- dpkg provider cleanup [\#4185](https://github.com/chef/chef/pull/4185) ([lamont-granquist](https://github.com/lamont-granquist))
- Restore rspec 3.4 by setting project\_source\_dirs [\#4182](https://github.com/chef/chef/pull/4182) ([jkeiser](https://github.com/jkeiser))
- rspec 3.4.0 broke master [\#4177](https://github.com/chef/chef/pull/4177) ([lamont-granquist](https://github.com/lamont-granquist))
- Invitations and members [\#4173](https://github.com/chef/chef/pull/4173) ([jkeiser](https://github.com/jkeiser))
- WMF 5 and Win 10 Threshold 2 Allow dsc\_resource with the LCM enabled. [\#4167](https://github.com/chef/chef/pull/4167) ([smurawski](https://github.com/smurawski))
- Multipackage internal API improvements [\#4165](https://github.com/chef/chef/pull/4165) ([lamont-granquist](https://github.com/lamont-granquist))
- Allow named\_run\_list to be loaded from config [\#4158](https://github.com/chef/chef/pull/4158) ([donaldguy](https://github.com/donaldguy))
- Require ShellOut before Knife::SSH definition [\#4153](https://github.com/chef/chef/pull/4153) ([matschaffer](https://github.com/matschaffer))
- fix log location resolution in windows service [\#4151](https://github.com/chef/chef/pull/4151) ([mwrock](https://github.com/mwrock))
- Handle nil run list option in knife bootstrap [\#4149](https://github.com/chef/chef/pull/4149) ([danielsdeleo](https://github.com/danielsdeleo))
- Fixed knife\_spec unit test [\#4143](https://github.com/chef/chef/pull/4143) ([jaym](https://github.com/jaym))
- Use the proper python interpretor for yum-dump.py on Fedora 21+ [\#4142](https://github.com/chef/chef/pull/4142) ([tas50](https://github.com/tas50))
- Minor tree cleanup I noticed [\#4138](https://github.com/chef/chef/pull/4138) ([jkeiser](https://github.com/jkeiser))
- don't squash Chef::Config\[:verbosity\] on subsequent instances of Chef::Knife::Bootstrap [\#4137](https://github.com/chef/chef/pull/4137) ([btm](https://github.com/btm))
- windows service uses log file location from config if none is given on commandline [\#4135](https://github.com/chef/chef/pull/4135) ([mwrock](https://github.com/mwrock))
- update bundler continuously [\#4134](https://github.com/chef/chef/pull/4134) ([lamont-granquist](https://github.com/lamont-granquist))
- SSL and Connection Reset Error Retries [\#4133](https://github.com/chef/chef/pull/4133) ([danielsdeleo](https://github.com/danielsdeleo))
- lazy the socketless require in Chef::HTTP [\#4130](https://github.com/chef/chef/pull/4130) ([lamont-granquist](https://github.com/lamont-granquist))
- Correct capitalization of GitHub username of a maintainer [\#4120](https://github.com/chef/chef/pull/4120) ([robbkidd](https://github.com/robbkidd))
- Make Property.derive create derived properties of the same type [\#4118](https://github.com/chef/chef/pull/4118) ([jkeiser](https://github.com/jkeiser))
- add md files for chef\_version/ohai\_version merge [\#4116](https://github.com/chef/chef/pull/4116) ([lamont-granquist](https://github.com/lamont-granquist))
- Update knife bootstrap command to honor --no-color flag in chef-client run that is part of the bootstrap process. [\#4112](https://github.com/chef/chef/pull/4112) ([tfitch](https://github.com/tfitch))
- package/solaris: Adds alias method for upgrade\_package. [\#4101](https://github.com/chef/chef/pull/4101) ([johnbellone](https://github.com/johnbellone))
- Improve detection of ChefFS-based commands in `knife rehash` [\#4090](https://github.com/chef/chef/pull/4090) ([stevendanna](https://github.com/stevendanna))
- RFC-037:  add chef\_version and ohai\_version metadata [\#4081](https://github.com/chef/chef/pull/4081) ([lamont-granquist](https://github.com/lamont-granquist))
- Ensure that tags are properly initialized [\#4064](https://github.com/chef/chef/pull/4064) ([josb](https://github.com/josb))
- Implement live streaming for execute resources [\#4040](https://github.com/chef/chef/pull/4040) ([thommay](https://github.com/thommay))
- Adding ksh resource for \#3923 [\#4014](https://github.com/chef/chef/pull/4014) ([nsdavidson](https://github.com/nsdavidson))
- Modify remote\_file cache\_control\_data to use sha256 for its name  [\#3991](https://github.com/chef/chef/pull/3991) ([jaym](https://github.com/jaym))
- simplify service helpers [\#3836](https://github.com/chef/chef/pull/3836) ([nathwill](https://github.com/nathwill))

## [12.5.1-omnibus](https://github.com/chef/chef/tree/12.5.1-omnibus) (2015-10-28)
[Full Changelog](https://github.com/chef/chef/compare/12.5.1...12.5.1-omnibus)

**Merged pull requests:**

- Lcg/merges [\#4105](https://github.com/chef/chef/pull/4105) ([lamont-granquist](https://github.com/lamont-granquist))
- Mailing list has moved to Discourse. [\#4104](https://github.com/chef/chef/pull/4104) ([juliandunn](https://github.com/juliandunn))
- Fix 'knife cookbook show' to work on root files [\#4100](https://github.com/chef/chef/pull/4100) ([lamont-granquist](https://github.com/lamont-granquist))
- value\_for\_platform should use Chef::VersionConstraint::Platform [\#4099](https://github.com/chef/chef/pull/4099) ([lamont-granquist](https://github.com/lamont-granquist))
- provider/user/dscl: Set "comment" default value [\#4098](https://github.com/chef/chef/pull/4098) ([lamont-granquist](https://github.com/lamont-granquist))
- provider/user/dscl: Set default gid to 20 [\#4097](https://github.com/chef/chef/pull/4097) ([lamont-granquist](https://github.com/lamont-granquist))
- overhaul solaris SMF service provider [\#4096](https://github.com/chef/chef/pull/4096) ([lamont-granquist](https://github.com/lamont-granquist))
- Allow downloading of root\_files in a chef repository [\#4091](https://github.com/chef/chef/pull/4091) ([stevendanna](https://github.com/stevendanna))
- Add CHANGELOG for PR \#3597 [\#4087](https://github.com/chef/chef/pull/4087) ([smurawski](https://github.com/smurawski))
- Add CHANGELOG for PR \#4021 [\#4086](https://github.com/chef/chef/pull/4086) ([smurawski](https://github.com/smurawski))
- Add CHANGELOG entry for \#4068 [\#4085](https://github.com/chef/chef/pull/4085) ([smurawski](https://github.com/smurawski))
- Add CHANGELOG entry for \#3119 [\#4082](https://github.com/chef/chef/pull/4082) ([jaymzh](https://github.com/jaymzh))
- Make property modules possible [\#4080](https://github.com/chef/chef/pull/4080) ([jkeiser](https://github.com/jkeiser))
- add logger to windows service shellout [\#4079](https://github.com/chef/chef/pull/4079) ([mwrock](https://github.com/mwrock))
- Improvements to log messages [\#4069](https://github.com/chef/chef/pull/4069) ([tas50](https://github.com/tas50))
- Fix chef-apply usage banner [\#4066](https://github.com/chef/chef/pull/4066) ([pwelch](https://github.com/pwelch))
- bryant-lippert-maintainer [\#4065](https://github.com/chef/chef/pull/4065) ([AgentMeerkat](https://github.com/AgentMeerkat))
- Bump win32-process pin [\#4061](https://github.com/chef/chef/pull/4061) ([ksubrama](https://github.com/ksubrama))
- Add gemspec files to allow bundler to run from the gem [\#4049](https://github.com/chef/chef/pull/4049) ([ksubrama](https://github.com/ksubrama))
- Accept coercion as a way to accept nil values [\#4048](https://github.com/chef/chef/pull/4048) ([jkeiser](https://github.com/jkeiser))
- ignore gid in the user resource on windows [\#4046](https://github.com/chef/chef/pull/4046) ([mwrock](https://github.com/mwrock))
- add optional ruby-profiling with --profile-ruby [\#4034](https://github.com/chef/chef/pull/4034) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix search result pagination [\#4029](https://github.com/chef/chef/pull/4029) ([stevendanna](https://github.com/stevendanna))
- Report expanded run list json tree to reporting [\#3966](https://github.com/chef/chef/pull/3966) ([kmacgugan](https://github.com/kmacgugan))
- Fix condition of removing a group before user error. [\#3119](https://github.com/chef/chef/pull/3119) ([cmluciano](https://github.com/cmluciano))

## [12.5.1](https://github.com/chef/chef/tree/12.5.1) (2015-10-08)
[Full Changelog](https://github.com/chef/chef/compare/12.4.4...12.5.1)

**Merged pull requests:**

- Quote paths. [\#4036](https://github.com/chef/chef/pull/4036) ([mcquin](https://github.com/mcquin))
- Fix dispatch when there are different receivers [\#4033](https://github.com/chef/chef/pull/4033) ([jkeiser](https://github.com/jkeiser))
- Raise error when running 32-bit scripts on Windows Nano. [\#4032](https://github.com/chef/chef/pull/4032) ([mcquin](https://github.com/mcquin))
- Fix forward module.to\_s [\#4030](https://github.com/chef/chef/pull/4030) ([jkeiser](https://github.com/jkeiser))
- pass ssh\_password to session [\#4023](https://github.com/chef/chef/pull/4023) ([sawanoboly](https://github.com/sawanoboly))
- Use -Command flag on Nano [\#4016](https://github.com/chef/chef/pull/4016) ([mcquin](https://github.com/mcquin))
- Un-remove ExpandNodeObject\#load\_node, deprecate it [\#4015](https://github.com/chef/chef/pull/4015) ([danielsdeleo](https://github.com/danielsdeleo))
- Bump revision to 12.5.0 [\#4012](https://github.com/chef/chef/pull/4012) ([jkeiser](https://github.com/jkeiser))
- Add external tests for chefspec, chef-sugar, chef-rewind, foodcritic, halite and poise [\#4007](https://github.com/chef/chef/pull/4007) ([jkeiser](https://github.com/jkeiser))
- Use Chef::FileContentManagement::Tempfile to create temp file [\#4005](https://github.com/chef/chef/pull/4005) ([chefsalim](https://github.com/chefsalim))
- Ensure that our list of recipes is backwards compat [\#4003](https://github.com/chef/chef/pull/4003) ([thommay](https://github.com/thommay))
- Fix for \#3992: Add check for custom command in redhat service provider [\#4000](https://github.com/chef/chef/pull/4000) ([andy-dufour](https://github.com/andy-dufour))
- Better warning for unsharing [\#3999](https://github.com/chef/chef/pull/3999) ([tas50](https://github.com/tas50))
- Update URLs to chef.io [\#3998](https://github.com/chef/chef/pull/3998) ([tas50](https://github.com/tas50))
- Windows cli tools should have color true by default [\#3936](https://github.com/chef/chef/pull/3936) ([adamedx](https://github.com/adamedx))

## [12.4.4](https://github.com/chef/chef/tree/12.4.4) (2015-09-30)
[Full Changelog](https://github.com/chef/chef/compare/12.4.3...12.4.4)

**Merged pull requests:**

- Prepare 12.4.4 [\#4010](https://github.com/chef/chef/pull/4010) ([jaym](https://github.com/jaym))
- Add ability for default to override name\_property [\#4004](https://github.com/chef/chef/pull/4004) ([jkeiser](https://github.com/jkeiser))
- Make sure name\_attribute works on derived properties [\#4002](https://github.com/chef/chef/pull/4002) ([jkeiser](https://github.com/jkeiser))
- Add event logging and more race condition tests [\#3997](https://github.com/chef/chef/pull/3997) ([jkeiser](https://github.com/jkeiser))
- fix omnitruck url [\#3995](https://github.com/chef/chef/pull/3995) ([thommay](https://github.com/thommay))
- Fix provider\_resolver tests on Windows [\#3993](https://github.com/chef/chef/pull/3993) ([jkeiser](https://github.com/jkeiser))
- Make resource\_collection= @api private instead of deprecated [\#3989](https://github.com/chef/chef/pull/3989) ([jkeiser](https://github.com/jkeiser))
- Unpin mixlib-shellout [\#3988](https://github.com/chef/chef/pull/3988) ([jaym](https://github.com/jaym))
- Use much simpler regex for determining the rpm version [\#3985](https://github.com/chef/chef/pull/3985) ([irvingpop](https://github.com/irvingpop))
- Community site -\> Supermarket in knife [\#3978](https://github.com/chef/chef/pull/3978) ([tas50](https://github.com/tas50))
- Bootstrap doc doesnt match reality [\#3976](https://github.com/chef/chef/pull/3976) ([tas50](https://github.com/tas50))
- Fix awkward wording in the contributing doc [\#3975](https://github.com/chef/chef/pull/3975) ([tas50](https://github.com/tas50))
- Test more of provider resolution by mocking the filesystem and commands [\#3972](https://github.com/chef/chef/pull/3972) ([jkeiser](https://github.com/jkeiser))
- I think this was a bad search-and-replace, causes an infinite loop. [\#3971](https://github.com/chef/chef/pull/3971) ([coderanger](https://github.com/coderanger))
- Create empty config context for chefdk [\#3970](https://github.com/chef/chef/pull/3970) ([danielsdeleo](https://github.com/danielsdeleo))
- Do not prefer default: nil over name\_attribute: nil [\#3965](https://github.com/chef/chef/pull/3965) ([jkeiser](https://github.com/jkeiser))
- Derive config locations from absolute path to config file [\#3963](https://github.com/chef/chef/pull/3963) ([danielsdeleo](https://github.com/danielsdeleo))
- Remove experimental feature warning for policyfiles [\#3962](https://github.com/chef/chef/pull/3962) ([danielsdeleo](https://github.com/danielsdeleo))
- Add policyfile support to `knife bootstrap` [\#3958](https://github.com/chef/chef/pull/3958) ([danielsdeleo](https://github.com/danielsdeleo))
- Re-upgrade chef-zero to latest [\#3957](https://github.com/chef/chef/pull/3957) ([jkeiser](https://github.com/jkeiser))
- Fix for \#3942 - change remote\_directory resource file discovery to tr… [\#3944](https://github.com/chef/chef/pull/3944) ([andy-dufour](https://github.com/andy-dufour))
- Windows cookbook dependencies should be updated for Chef 12.5 [\#3912](https://github.com/chef/chef/pull/3912) ([mcquin](https://github.com/mcquin))

## [12.4.3](https://github.com/chef/chef/tree/12.4.3) (2015-09-23)
[Full Changelog](https://github.com/chef/chef/compare/12.4.2...12.4.3)

**Merged pull requests:**

- Run the chef service executable from the bin directory [\#3954](https://github.com/chef/chef/pull/3954) ([jkeiser](https://github.com/jkeiser))
- Run the chef service executable from the bin directory [\#3953](https://github.com/chef/chef/pull/3953) ([jkeiser](https://github.com/jkeiser))
- Honor the ordering of whichever `name\_attribute` or `default` comes first [\#3951](https://github.com/chef/chef/pull/3951) ([jkeiser](https://github.com/jkeiser))
- Lazy load MSI provider, add check for MSI support [\#3939](https://github.com/chef/chef/pull/3939) ([chefsalim](https://github.com/chefsalim))
- Safely clean up Win32 namespace after specs [\#3937](https://github.com/chef/chef/pull/3937) ([mcquin](https://github.com/mcquin))
- adding matt wrock as maintainer [\#3860](https://github.com/chef/chef/pull/3860) ([mwrock](https://github.com/mwrock))
- Refactor knife ssh options stuff [\#3857](https://github.com/chef/chef/pull/3857) ([coderanger](https://github.com/coderanger))

## [12.4.2](https://github.com/chef/chef/tree/12.4.2) (2015-09-21)
[Full Changelog](https://github.com/chef/chef/compare/12.5.0.current.0...12.4.2)

**Merged pull requests:**

- Remove dependency on master of ohai and friends [\#3932](https://github.com/chef/chef/pull/3932) ([jkeiser](https://github.com/jkeiser))
- Create 12.4.2 of Chef with ohai dep restriction [\#3931](https://github.com/chef/chef/pull/3931) ([jkeiser](https://github.com/jkeiser))
- Policyfile named run list support [\#3928](https://github.com/chef/chef/pull/3928) ([danielsdeleo](https://github.com/danielsdeleo))
- Don't add win\_evt logger when on nano. [\#3926](https://github.com/chef/chef/pull/3926) ([mcquin](https://github.com/mcquin))
- Rename current\_resource method on Chef::Resource as current\_value. [\#3921](https://github.com/chef/chef/pull/3921) ([mcquin](https://github.com/mcquin))
- Fix failing specs on Windows [\#3918](https://github.com/chef/chef/pull/3918) ([jaym](https://github.com/jaym))
- Policyfile node integration [\#3913](https://github.com/chef/chef/pull/3913) ([danielsdeleo](https://github.com/danielsdeleo))
- remove pending reboot check for HKLM\SOFTWARE\Microsoft\Updates\UpdateExeVolatile [\#3909](https://github.com/chef/chef/pull/3909) ([mwrock](https://github.com/mwrock))
- Allow windows\_service\_spec to only run in appveyor [\#3907](https://github.com/chef/chef/pull/3907) ([jaym](https://github.com/jaym))
- Modify enforce\_ownership\_and\_permissions\_spec to be more unit-like [\#3898](https://github.com/chef/chef/pull/3898) ([jaym](https://github.com/jaym))
- Add monkey patch for webrick [\#3896](https://github.com/chef/chef/pull/3896) ([jaym](https://github.com/jaym))
- Skip tests unless RefreshMode is Disabled [\#3895](https://github.com/chef/chef/pull/3895) ([mcquin](https://github.com/mcquin))
- Add ruby 2.1 [\#3894](https://github.com/chef/chef/pull/3894) ([ksubrama](https://github.com/ksubrama))
- Add 64 bit testers [\#3893](https://github.com/chef/chef/pull/3893) ([jaym](https://github.com/jaym))
- Update appveyor.yml to correct OS version [\#3892](https://github.com/chef/chef/pull/3892) ([ksubrama](https://github.com/ksubrama))
- sync maintainers with github [\#3886](https://github.com/chef/chef/pull/3886) ([thommay](https://github.com/thommay))
- Update changelog [\#3881](https://github.com/chef/chef/pull/3881) ([chefsalim](https://github.com/chefsalim))
- Update for Windows registry work. [\#3878](https://github.com/chef/chef/pull/3878) ([mcquin](https://github.com/mcquin))
- Modify registry specs to adhere to spec naming conventions [\#3877](https://github.com/chef/chef/pull/3877) ([mcquin](https://github.com/mcquin))
- Put all Win32::Registry monkeypatches together [\#3876](https://github.com/chef/chef/pull/3876) ([mcquin](https://github.com/mcquin))
- Monkeypatch Win32::Registry methods delete\_key, delete\_value [\#3875](https://github.com/chef/chef/pull/3875) ([adamedx](https://github.com/adamedx))
- Reenable latest cheffish [\#3874](https://github.com/chef/chef/pull/3874) ([jkeiser](https://github.com/jkeiser))
- Fix the failing tests [\#3873](https://github.com/chef/chef/pull/3873) ([jaym](https://github.com/jaym))
- Refactor Chef::Mixin::WideString to remove implicit Windows dependency. [\#3855](https://github.com/chef/chef/pull/3855) ([mcquin](https://github.com/mcquin))
- Don't print deprecations to the console until the end [\#3854](https://github.com/chef/chef/pull/3854) ([jkeiser](https://github.com/jkeiser))
- move warning to debug [\#3853](https://github.com/chef/chef/pull/3853) ([lamont-granquist](https://github.com/lamont-granquist))
- Use same mixlib-shellout version pin in chef, ohai, and chef-config [\#3851](https://github.com/chef/chef/pull/3851) ([jaym](https://github.com/jaym))
- Monkeypatch Win32::Registry\#write [\#3850](https://github.com/chef/chef/pull/3850) ([mcquin](https://github.com/mcquin))
- Prep for Registry FFI; Convert RegDeleteKeyEx to FFI [\#3843](https://github.com/chef/chef/pull/3843) ([chefsalim](https://github.com/chefsalim))
- Remove dependency on windows-pr [\#3841](https://github.com/chef/chef/pull/3841) ([jaym](https://github.com/jaym))
- Make win32/api/net.rb look nicer [\#3840](https://github.com/chef/chef/pull/3840) ([jaym](https://github.com/jaym))
- refactor remote\_directory provider [\#3837](https://github.com/chef/chef/pull/3837) ([lamont-granquist](https://github.com/lamont-granquist))
- Update NetUse stuff to use FFI [\#3832](https://github.com/chef/chef/pull/3832) ([jaym](https://github.com/jaym))
- Lcg/3743 [\#3830](https://github.com/chef/chef/pull/3830) ([lamont-granquist](https://github.com/lamont-granquist))
- Add Salim as a windows maintainer [\#3828](https://github.com/chef/chef/pull/3828) ([ksubrama](https://github.com/ksubrama))
- Rewriting volume code to use FFI [\#3827](https://github.com/chef/chef/pull/3827) ([jaym](https://github.com/jaym))
- PSCredential + dsc\_script documentation [\#3822](https://github.com/chef/chef/pull/3822) ([jaym](https://github.com/jaym))
- Human friendly elapsed time in log [\#3821](https://github.com/chef/chef/pull/3821) ([joelhandwell](https://github.com/joelhandwell))
- Add RELEASE\_NOTES entry for `knife rehash` [\#3820](https://github.com/chef/chef/pull/3820) ([stevendanna](https://github.com/stevendanna))
- remove now-useless GC [\#3817](https://github.com/chef/chef/pull/3817) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix powershell\_script validation  [\#3815](https://github.com/chef/chef/pull/3815) ([jaym](https://github.com/jaym))
- Further revision for compile errors due to frozen [\#3809](https://github.com/chef/chef/pull/3809) ([martinb3](https://github.com/martinb3))
- Replace output\_of\_command with shell\_out! in subversion provider [\#3806](https://github.com/chef/chef/pull/3806) ([gh2k](https://github.com/gh2k))
- Validating is comparing to true instead of ruby truthiness [\#3805](https://github.com/chef/chef/pull/3805) ([jaymzh](https://github.com/jaymzh))
- CHANGELOG/RELEASE\_NOTES docs for recent OSX changes [\#3800](https://github.com/chef/chef/pull/3800) ([jaymzh](https://github.com/jaymzh))
- fix supports hash issues in service providers [\#3799](https://github.com/chef/chef/pull/3799) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix dsc\_script spec failure on 64-bit Ruby [\#3797](https://github.com/chef/chef/pull/3797) ([chefsalim](https://github.com/chefsalim))
- Lcg/run levels [\#3793](https://github.com/chef/chef/pull/3793) ([lamont-granquist](https://github.com/lamont-granquist))
- Lcg/making mount options aware [\#3792](https://github.com/chef/chef/pull/3792) ([lamont-granquist](https://github.com/lamont-granquist))
- Don't modify members of new\_resource in pw group implmentation [\#3788](https://github.com/chef/chef/pull/3788) ([jaym](https://github.com/jaym))
- Fix failing directory unit tests on rhel [\#3787](https://github.com/chef/chef/pull/3787) ([jaym](https://github.com/jaym))
- Enable 64-bit support for Powershell and Batch scripts [\#3775](https://github.com/chef/chef/pull/3775) ([chefsalim](https://github.com/chefsalim))
- Lcg/yum deprecated [\#3774](https://github.com/chef/chef/pull/3774) ([lamont-granquist](https://github.com/lamont-granquist))
- Add ps\_credential dsl method to dsc\_script [\#3772](https://github.com/chef/chef/pull/3772) ([jaym](https://github.com/jaym))
- Add support for override depth and adding test in overriding depth [\#3771](https://github.com/chef/chef/pull/3771) ([renanvicente](https://github.com/renanvicente))
- Make reboot\_pending? look for CBS RebootPending [\#3768](https://github.com/chef/chef/pull/3768) ([jeremiahsnapp](https://github.com/jeremiahsnapp))
- uniquify chef\_repo\_path [\#3764](https://github.com/chef/chef/pull/3764) ([polamjag](https://github.com/polamjag))
- highline is used by core Chef; therefore remove this misleading comment [\#3762](https://github.com/chef/chef/pull/3762) ([juliandunn](https://github.com/juliandunn))
- Refactor all the gem building logic into a custom rake task. [\#3760](https://github.com/chef/chef/pull/3760) ([ksubrama](https://github.com/ksubrama))
- Don't use shell\_out! on "lssrc -g"  [\#3759](https://github.com/chef/chef/pull/3759) ([juliandunn](https://github.com/juliandunn))
- Add additional helpful section for frozen objects [\#3757](https://github.com/chef/chef/pull/3757) ([martinb3](https://github.com/martinb3))
- Fix functional tests for group resource - fix \#3728 [\#3754](https://github.com/chef/chef/pull/3754) ([ksubrama](https://github.com/ksubrama))
- Remove old bootstrap templates [\#3751](https://github.com/chef/chef/pull/3751) ([juliandunn](https://github.com/juliandunn))
- Remove freeze of defaults, add warning for array/hash constant defaults [\#3744](https://github.com/chef/chef/pull/3744) ([jkeiser](https://github.com/jkeiser))
- Make Resource.action work with non-standard names [\#3732](https://github.com/chef/chef/pull/3732) ([jkeiser](https://github.com/jkeiser))
- Fix \#3692: flatten regex validation array so nested arrays work [\#3729](https://github.com/chef/chef/pull/3729) ([jkeiser](https://github.com/jkeiser))
- Rewrite NetLocalGroup things to use FFI [\#3728](https://github.com/chef/chef/pull/3728) ([jaym](https://github.com/jaym))
- Add support for OS X 10.11 SIP paths [\#3704](https://github.com/chef/chef/pull/3704) ([natewalck](https://github.com/natewalck))
- Adding omnibus-chef to core maintainer projects [\#3702](https://github.com/chef/chef/pull/3702) ([tyler-ball](https://github.com/tyler-ball))
- Make the doc formatter actually show what version of a cookbook is being used. [\#3700](https://github.com/chef/chef/pull/3700) ([coderanger](https://github.com/coderanger))
- Interpolate `%{path}` in verify command [\#3693](https://github.com/chef/chef/pull/3693) ([margueritepd](https://github.com/margueritepd))
- Add Resource.load\_current\_value [\#3691](https://github.com/chef/chef/pull/3691) ([jkeiser](https://github.com/jkeiser))
- Add ohai configuration context to config. [\#3689](https://github.com/chef/chef/pull/3689) ([mcquin](https://github.com/mcquin))
- Add formatter and force-logger/formatter options to chef-apply [\#3687](https://github.com/chef/chef/pull/3687) ([mivok](https://github.com/mivok))
- Remove warnings about hander overrides. [\#3684](https://github.com/chef/chef/pull/3684) ([coderanger](https://github.com/coderanger))
- Correct Windows reboot command to delay in minutes [\#3683](https://github.com/chef/chef/pull/3683) ([jimmymccrory](https://github.com/jimmymccrory))
- Rewrite nested json test to not use stack [\#3682](https://github.com/chef/chef/pull/3682) ([jaym](https://github.com/jaym))
- avoid windows service spec unless we're on appveyor [\#3680](https://github.com/chef/chef/pull/3680) ([thommay](https://github.com/thommay))
- Set chef\_environment in attributes JSON [\#3668](https://github.com/chef/chef/pull/3668) ([mcquin](https://github.com/mcquin))
- Support SNI in 'knife ssl check'. [\#3666](https://github.com/chef/chef/pull/3666) ([juliandunn](https://github.com/juliandunn))
- Fix error message for providers without `provides` [\#3663](https://github.com/chef/chef/pull/3663) ([docwhat](https://github.com/docwhat))
- shell\_out! returns an object not an integer [\#3657](https://github.com/chef/chef/pull/3657) ([stefanor](https://github.com/stefanor))
- remove use of self.provides? [\#3656](https://github.com/chef/chef/pull/3656) ([lamont-granquist](https://github.com/lamont-granquist))
- fix explanation for configuring audit mode in client.rb [\#3652](https://github.com/chef/chef/pull/3652) ([alexpop](https://github.com/alexpop))
- Added support for 10.11 and added function for evaluating OS X version... [\#3594](https://github.com/chef/chef/pull/3594) ([natewalck](https://github.com/natewalck))
- Fixing Issue \#2513 - the broken render of nested partial templates [\#3510](https://github.com/chef/chef/pull/3510) ([ckaushik](https://github.com/ckaushik))
- Use dpkg-deb directly rather than regex [\#3498](https://github.com/chef/chef/pull/3498) ([thommay](https://github.com/thommay))
- gem\_package should install to the systemwide Ruby when using ChefDK. [\#3383](https://github.com/chef/chef/pull/3383) ([jfly](https://github.com/jfly))
- Use target, not name, if it is specified. [\#3329](https://github.com/chef/chef/pull/3329) ([juliandunn](https://github.com/juliandunn))
- Add knife-rehash command for subcommand location hashing [\#3307](https://github.com/chef/chef/pull/3307) ([stevendanna](https://github.com/stevendanna))
- Allow tags to be set on a node during bootstrap [\#3190](https://github.com/chef/chef/pull/3190) ([swalberg](https://github.com/swalberg))
- A simple change to add periods at the end of sentences. [\#3185](https://github.com/chef/chef/pull/3185) ([juliegund](https://github.com/juliegund))
- Migrated deploy resource to use shell\_out instead of run\_command [\#3172](https://github.com/chef/chef/pull/3172) ([BackSlasher](https://github.com/BackSlasher))
- Update registry\_key.rb [\#3145](https://github.com/chef/chef/pull/3145) ([veetow](https://github.com/veetow))
- Add warnings to 'knife node run list remove ...'  [\#3027](https://github.com/chef/chef/pull/3027) ([jf647](https://github.com/jf647))
- Add privacy flag [\#2460](https://github.com/chef/chef/pull/2460) ([raskchanky](https://github.com/raskchanky))
- CHEF-5012: add methods for template breadcrumbs [\#1259](https://github.com/chef/chef/pull/1259) ([lamont-granquist](https://github.com/lamont-granquist))

## [12.5.0.current.0](https://github.com/chef/chef/tree/12.5.0.current.0) (2015-07-16)
[Full Changelog](https://github.com/chef/chef/compare/11.18.14...12.5.0.current.0)

**Merged pull requests:**

- Update the URL in user agent string [\#3674](https://github.com/chef/chef/pull/3674) ([danielsdeleo](https://github.com/danielsdeleo))
- Fix issue where DSL is not emitted if state\_properties happens before property [\#3672](https://github.com/chef/chef/pull/3672) ([jkeiser](https://github.com/jkeiser))
- Change chef service to start as 'Automatic delayed start'. [\#3667](https://github.com/chef/chef/pull/3667) ([ksubrama](https://github.com/ksubrama))
- Add ability to declare methods inside the action class [\#3660](https://github.com/chef/chef/pull/3660) ([jkeiser](https://github.com/jkeiser))
- Add myself as an Archlinux maintainer [\#3592](https://github.com/chef/chef/pull/3592) ([ryancragun](https://github.com/ryancragun))
- \[RFC-039\] chef handler dsl [\#3242](https://github.com/chef/chef/pull/3242) ([ranjib](https://github.com/ranjib))

## [11.18.14](https://github.com/chef/chef/tree/11.18.14) (2015-07-09)
[Full Changelog](https://github.com/chef/chef/compare/12.4.1...11.18.14)

**Merged pull requests:**

- Release 11.18.14 [\#3654](https://github.com/chef/chef/pull/3654) ([thommay](https://github.com/thommay))
- Merge pull request \#3629 from chef/jdm/update-certs [\#3647](https://github.com/chef/chef/pull/3647) ([jaym](https://github.com/jaym))
- Try fix for failing config test [\#3646](https://github.com/chef/chef/pull/3646) ([jaym](https://github.com/jaym))
- Decommission 12-stable [\#3641](https://github.com/chef/chef/pull/3641) ([grubernaut](https://github.com/grubernaut))

## [12.4.1](https://github.com/chef/chef/tree/12.4.1) (2015-07-07)
[Full Changelog](https://github.com/chef/chef/compare/12.4.0...12.4.1)

**Merged pull requests:**

- 12.4.1 [\#3639](https://github.com/chef/chef/pull/3639) ([jaym](https://github.com/jaym))
- Don't accept multiple parameters in recipe DSL \(just name\) [\#3638](https://github.com/chef/chef/pull/3638) ([jkeiser](https://github.com/jkeiser))
- Make required name attributes work [\#3632](https://github.com/chef/chef/pull/3632) ([jkeiser](https://github.com/jkeiser))
- Move Chef::OscUser back to Chef::User namespace and new user code to Chef::UserV1. [\#3630](https://github.com/chef/chef/pull/3630) ([tylercloke](https://github.com/tylercloke))
- Update certs [\#3629](https://github.com/chef/chef/pull/3629) ([jaym](https://github.com/jaym))
- Re-separate priority map and DSL handler map so that provides has vet… [\#3627](https://github.com/chef/chef/pull/3627) ([jkeiser](https://github.com/jkeiser))
- Revert "FFI 1.9.9 is causing segfaults" [\#3626](https://github.com/chef/chef/pull/3626) ([jaym](https://github.com/jaym))
- Add "property" with identity and desired\_state [\#3624](https://github.com/chef/chef/pull/3624) ([jkeiser](https://github.com/jkeiser))
- Simplify LWRP Deprecations Proposal 1 [\#3623](https://github.com/chef/chef/pull/3623) ([jaym](https://github.com/jaym))
- 3618 run list mutation issue [\#3620](https://github.com/chef/chef/pull/3620) ([danielsdeleo](https://github.com/danielsdeleo))
- Move WorkstationConfigLoader into chef-config [\#3612](https://github.com/chef/chef/pull/3612) ([mcquin](https://github.com/mcquin))
- Call provides? when resolving, reduce number of calls to provides? [\#3611](https://github.com/chef/chef/pull/3611) ([jkeiser](https://github.com/jkeiser))
- Rename powershell spec files to match Ruby conventions [\#3608](https://github.com/chef/chef/pull/3608) ([adamedx](https://github.com/adamedx))
- FFI 1.9.9 is causing segfaults [\#3606](https://github.com/chef/chef/pull/3606) ([jaym](https://github.com/jaym))
- Rework Resource\#action to match the 12.3 API. [\#3605](https://github.com/chef/chef/pull/3605) ([coderanger](https://github.com/coderanger))
- Fix ability to monkey match LWRP through Chef::Resource::MyLwrp [\#3603](https://github.com/chef/chef/pull/3603) ([jaym](https://github.com/jaym))
- Add myself as a core maintainer. [\#3600](https://github.com/chef/chef/pull/3600) ([coderanger](https://github.com/coderanger))
- Fix issue where blocks were not considered in priority mapping [\#3599](https://github.com/chef/chef/pull/3599) ([jaym](https://github.com/jaym))
- Use Mixlib::Shellout instead of Chef::Mixin::Command [\#3591](https://github.com/chef/chef/pull/3591) ([DeWaRs1206](https://github.com/DeWaRs1206))
- add maintainers/Lts for tier 1 & 2 support [\#3525](https://github.com/chef/chef/pull/3525) ([jtimberman](https://github.com/jtimberman))
- Allow properties to be defined on resources [\#3493](https://github.com/chef/chef/pull/3493) ([jkeiser](https://github.com/jkeiser))
- Fix some errant bashisms [\#3589](https://github.com/chef/chef/pull/3589) ([thommay](https://github.com/thommay))
- Fix deprecated setters. [\#3587](https://github.com/chef/chef/pull/3587) ([coderanger](https://github.com/coderanger))
- Fix to allow LW resources to be used with HW providers [\#3586](https://github.com/chef/chef/pull/3586) ([jaym](https://github.com/jaym))

## [12.4.0](https://github.com/chef/chef/tree/12.4.0) (2015-06-23)
[Full Changelog](https://github.com/chef/chef/compare/12.4.0.rc.2...12.4.0)

**Merged pull requests:**

- Update RELEASE\_NOTES.md [\#3580](https://github.com/chef/chef/pull/3580) ([ksubrama](https://github.com/ksubrama))
- Add some doc changes for 12.4.0 [\#3578](https://github.com/chef/chef/pull/3578) ([jkeiser](https://github.com/jkeiser))
- Bump revision to 12.5.0.current.0 [\#3577](https://github.com/chef/chef/pull/3577) ([jkeiser](https://github.com/jkeiser))
- Get rid of warning when defining an LWRP [\#3576](https://github.com/chef/chef/pull/3576) ([jkeiser](https://github.com/jkeiser))
- Proposal to \(re-\)add myself as a core chef maintainer. [\#3564](https://github.com/chef/chef/pull/3564) ([mcquin](https://github.com/mcquin))
- Re-add \#priority. [\#3562](https://github.com/chef/chef/pull/3562) ([coderanger](https://github.com/coderanger))
- add Joe Miller as LT for OpenBSD [\#3555](https://github.com/chef/chef/pull/3555) ([joemiller](https://github.com/joemiller))
- Add missing require statement in resource\_resolver [\#3554](https://github.com/chef/chef/pull/3554) ([ranjib](https://github.com/ranjib))
- Warn when multiple providers try to provide the same thing [\#3543](https://github.com/chef/chef/pull/3543) ([jkeiser](https://github.com/jkeiser))
- Only automatically set resources that do class X \< Chef::Resource [\#3542](https://github.com/chef/chef/pull/3542) ([jkeiser](https://github.com/jkeiser))
- Ensure :nothing is in the list of allowed actions for an LWRP [\#3541](https://github.com/chef/chef/pull/3541) ([jkeiser](https://github.com/jkeiser))
- Exceptions for audits should only get wrapped if audit mode is enabled [\#3538](https://github.com/chef/chef/pull/3538) ([jaym](https://github.com/jaym))
- Proposing myself as Ubuntu LT [\#3522](https://github.com/chef/chef/pull/3522) ([ranjib](https://github.com/ranjib))
- The wording seemed odd. [\#3519](https://github.com/chef/chef/pull/3519) ([jjasghar](https://github.com/jjasghar))
- Fix chef-config gem homepage [\#3512](https://github.com/chef/chef/pull/3512) ([thommay](https://github.com/thommay))
- fix rpm\_package when sourced packages have a tilde character in the version [\#3503](https://github.com/chef/chef/pull/3503) ([irvingpop](https://github.com/irvingpop))
- Add "action" to Resource \(RFC 50\) [\#3437](https://github.com/chef/chef/pull/3437) ([jkeiser](https://github.com/jkeiser))
- Re-allow nameless resources [\#3417](https://github.com/chef/chef/pull/3417) ([coderanger](https://github.com/coderanger))
- Remove experimental warning on audit mode. [\#3299](https://github.com/chef/chef/pull/3299) ([juliandunn](https://github.com/juliandunn))
- don't mutate the new resource [\#3295](https://github.com/chef/chef/pull/3295) ([lamont-granquist](https://github.com/lamont-granquist))
- Make multipackage and arch play nicely together [\#3235](https://github.com/chef/chef/pull/3235) ([jaymzh](https://github.com/jaymzh))

## [12.4.0.rc.2](https://github.com/chef/chef/tree/12.4.0.rc.2) (2015-06-09)
[Full Changelog](https://github.com/chef/chef/compare/12.4.0.rc.1...12.4.0.rc.2)

## [12.4.0.rc.1](https://github.com/chef/chef/tree/12.4.0.rc.1) (2015-06-09)
[Full Changelog](https://github.com/chef/chef/compare/12.4.0.rc.0...12.4.0.rc.1)

**Merged pull requests:**

- Using master of kitchen-ec2 for travis integration tests [\#3501](https://github.com/chef/chef/pull/3501) ([tyler-ball](https://github.com/tyler-ball))
- Issue\#3485: Fix corruption of run\_context when guard interpreters are executed [\#3497](https://github.com/chef/chef/pull/3497) ([adamedx](https://github.com/adamedx))
- Remove use\_automatic\_resource\_name, make resource\_name automatic [\#3495](https://github.com/chef/chef/pull/3495) ([jkeiser](https://github.com/jkeiser))
- Hyphenated LWRP [\#3489](https://github.com/chef/chef/pull/3489) ([danielsdeleo](https://github.com/danielsdeleo))
- switch to an HVM ssd based AMI [\#3488](https://github.com/chef/chef/pull/3488) ([lamont-granquist](https://github.com/lamont-granquist))
- These tests were accidently left out when I moved \#2621 to master [\#3484](https://github.com/chef/chef/pull/3484) ([tyler-ball](https://github.com/tyler-ball))
- allow include\_recipe from LWRP provider code [\#3483](https://github.com/chef/chef/pull/3483) ([lamont-granquist](https://github.com/lamont-granquist))
- Lcg/bundle cache [\#3481](https://github.com/chef/chef/pull/3481) ([lamont-granquist](https://github.com/lamont-granquist))
- We don't need to run ruby 2.0 in travis. [\#3480](https://github.com/chef/chef/pull/3480) ([jaym](https://github.com/jaym))
- try m3.medium over m1.small [\#3479](https://github.com/chef/chef/pull/3479) ([lamont-granquist](https://github.com/lamont-granquist))
- Lcg/retry bundle install [\#3478](https://github.com/chef/chef/pull/3478) ([lamont-granquist](https://github.com/lamont-granquist))
- Lcg/zypper package [\#3477](https://github.com/chef/chef/pull/3477) ([lamont-granquist](https://github.com/lamont-granquist))
- fix package timeout attribute [\#3475](https://github.com/chef/chef/pull/3475) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix copying ntfs dacl and sacl when they are nil [\#3471](https://github.com/chef/chef/pull/3471) ([jaym](https://github.com/jaym))
- add lazy require for 'chef/config' [\#3470](https://github.com/chef/chef/pull/3470) ([lamont-granquist](https://github.com/lamont-granquist))
- Add missing require [\#3467](https://github.com/chef/chef/pull/3467) ([jaym](https://github.com/jaym))
- Fix issue where ps\_credential does not work over winrm [\#3462](https://github.com/chef/chef/pull/3462) ([jaym](https://github.com/jaym))
- Drop support for rubygems 1.x [\#3457](https://github.com/chef/chef/pull/3457) ([danielsdeleo](https://github.com/danielsdeleo))
- Issue \#3455: powershell\_script: do not allow suppression of syntax errors [\#3455](https://github.com/chef/chef/pull/3455) ([adamedx](https://github.com/adamedx))
- Fix subcommand loader test [\#3454](https://github.com/chef/chef/pull/3454) ([danielsdeleo](https://github.com/danielsdeleo))
- Run `gem install` tasks w/o bundler's env [\#3451](https://github.com/chef/chef/pull/3451) ([danielsdeleo](https://github.com/danielsdeleo))
- Fix dsc\_resource to work with wmf5 april preview [\#3448](https://github.com/chef/chef/pull/3448) ([jaym](https://github.com/jaym))
- windows does not have uname [\#3439](https://github.com/chef/chef/pull/3439) ([lamont-granquist](https://github.com/lamont-granquist))
- API V1 Support [\#3438](https://github.com/chef/chef/pull/3438) ([tylercloke](https://github.com/tylercloke))
- Update CHANGELOG.md [\#3429](https://github.com/chef/chef/pull/3429) ([scotthain](https://github.com/scotthain))
- Move `skip` for useradd test to metadata [\#3428](https://github.com/chef/chef/pull/3428) ([danielsdeleo](https://github.com/danielsdeleo))
- Fix overridden method `skip` causing arity failures [\#3425](https://github.com/chef/chef/pull/3425) ([danielsdeleo](https://github.com/danielsdeleo))
- RSpec isn't a bug database or kanban board [\#3420](https://github.com/chef/chef/pull/3420) ([danielsdeleo](https://github.com/danielsdeleo))
- Fix cli issue with unset chef\_repo\_path [\#3419](https://github.com/chef/chef/pull/3419) ([scotthain](https://github.com/scotthain))
- add shell\_out to resources [\#3418](https://github.com/chef/chef/pull/3418) ([lamont-granquist](https://github.com/lamont-granquist))
- Display Policyfile Name and Revision ID [\#3415](https://github.com/chef/chef/pull/3415) ([danielsdeleo](https://github.com/danielsdeleo))
- Make sure the audit mode output is reflected both in the logs and in the formatter output. [\#3412](https://github.com/chef/chef/pull/3412) ([sersut](https://github.com/sersut))
- add unicode WM\_SETTINGCHANGE broadcast [\#3406](https://github.com/chef/chef/pull/3406) ([lamont-granquist](https://github.com/lamont-granquist))
- Allow spaces in files for remote\_file [\#3398](https://github.com/chef/chef/pull/3398) ([jaym](https://github.com/jaym))
- Lcg/directory missing owner validation check [\#3397](https://github.com/chef/chef/pull/3397) ([lamont-granquist](https://github.com/lamont-granquist))
- Comment up Chef::Client and privatize/deprecate unused things [\#3392](https://github.com/chef/chef/pull/3392) ([jkeiser](https://github.com/jkeiser))
- Reduce provider/resource resolution stages down to 1 [\#3374](https://github.com/chef/chef/pull/3374) ([jkeiser](https://github.com/jkeiser))

## [12.4.0.rc.0](https://github.com/chef/chef/tree/12.4.0.rc.0) (2015-05-21)
[Full Changelog](https://github.com/chef/chef/compare/11.18.12...12.4.0.rc.0)

**Merged pull requests:**

- Make native mode the default for policyfiles [\#3407](https://github.com/chef/chef/pull/3407) ([danielsdeleo](https://github.com/danielsdeleo))
- Enable caching of rubygems in appveyor [\#3405](https://github.com/chef/chef/pull/3405) ([danielsdeleo](https://github.com/danielsdeleo))
- Run rubygems from master for perf improvements [\#3404](https://github.com/chef/chef/pull/3404) ([danielsdeleo](https://github.com/danielsdeleo))
- Don't call get\_last\_error for net api [\#3402](https://github.com/chef/chef/pull/3402) ([jaym](https://github.com/jaym))
- fix an lwrp default action test [\#3400](https://github.com/chef/chef/pull/3400) ([thommay](https://github.com/thommay))
- Show trace for RecipeNotFound errors when it originates from include recipe [\#3396](https://github.com/chef/chef/pull/3396) ([danielsdeleo](https://github.com/danielsdeleo))
- bump timeout up to 300 seconds [\#3393](https://github.com/chef/chef/pull/3393) ([lamont-granquist](https://github.com/lamont-granquist))
- Add install\_components task for forward compat w/ 12 [\#3391](https://github.com/chef/chef/pull/3391) ([danielsdeleo](https://github.com/danielsdeleo))
- Integration tests fix ipv6 [\#3388](https://github.com/chef/chef/pull/3388) ([danielsdeleo](https://github.com/danielsdeleo))
- Lcg/integ fixes [\#3386](https://github.com/chef/chef/pull/3386) ([lamont-granquist](https://github.com/lamont-granquist))
- warn on cookbook self-deps [\#3381](https://github.com/chef/chef/pull/3381) ([lamont-granquist](https://github.com/lamont-granquist))
- Jdm/3318 [\#3380](https://github.com/chef/chef/pull/3380) ([jaym](https://github.com/jaym))
- Jdm/3345 [\#3369](https://github.com/chef/chef/pull/3369) ([jaym](https://github.com/jaym))
- Add check\_resource\_semantics! lifecycle method to provider [\#3360](https://github.com/chef/chef/pull/3360) ([jaym](https://github.com/jaym))
- Escape string inside regex [\#3357](https://github.com/chef/chef/pull/3357) ([jaym](https://github.com/jaym))
- Fix failing kitchen tests [\#3355](https://github.com/chef/chef/pull/3355) ([jaym](https://github.com/jaym))
- fixes the timing on the chef-shell specs [\#3348](https://github.com/chef/chef/pull/3348) ([lamont-granquist](https://github.com/lamont-granquist))
- Diagnose failing tests [\#3346](https://github.com/chef/chef/pull/3346) ([jaym](https://github.com/jaym))
- Added a logger for Windows Event Log [\#3345](https://github.com/chef/chef/pull/3345) ([jaym](https://github.com/jaym))
- Changing Net User things to use ffi instead of win32-api [\#3344](https://github.com/chef/chef/pull/3344) ([jaym](https://github.com/jaym))
- Check if proxy env\_var is empty [\#3342](https://github.com/chef/chef/pull/3342) ([jonsmorrow](https://github.com/jonsmorrow))
- Allow inspection of event dispatch's subscribers [\#3340](https://github.com/chef/chef/pull/3340) ([danielsdeleo](https://github.com/danielsdeleo))
- Powershell command wrappers to make argument passing to knife/chef-client etc. easier. [\#3339](https://github.com/chef/chef/pull/3339) ([ksubrama](https://github.com/ksubrama))
- remote\_file support for windows network shares [\#3336](https://github.com/chef/chef/pull/3336) ([jaym](https://github.com/jaym))
- let the ruby patchlevels float [\#3335](https://github.com/chef/chef/pull/3335) ([lamont-granquist](https://github.com/lamont-granquist))
- Apply an SSL Policy to CookbookSiteStreamingUploader, fixing SSL errors uploading to private Supermarkets [\#3333](https://github.com/chef/chef/pull/3333) ([irvingpop](https://github.com/irvingpop))
- Convert wiki links to docs.chef.io links [\#3328](https://github.com/chef/chef/pull/3328) ([tas50](https://github.com/tas50))
- Enforce passing a node name with validatorless bootstrapping [\#3325](https://github.com/chef/chef/pull/3325) ([ryancragun](https://github.com/ryancragun))
- Replace of \#3284 add chef log syslog avoid windows [\#3322](https://github.com/chef/chef/pull/3322) ([sawanoboly](https://github.com/sawanoboly))
- Lcg/node utf8 sanitize [\#3320](https://github.com/chef/chef/pull/3320) ([lamont-granquist](https://github.com/lamont-granquist))
- Implemented X-Ops-Server-API-Version in Chef requests [\#3319](https://github.com/chef/chef/pull/3319) ([tylercloke](https://github.com/tylercloke))
- Modify windows package provider to allow url [\#3318](https://github.com/chef/chef/pull/3318) ([jaym](https://github.com/jaym))
- windows\_package is idempotent again [\#3317](https://github.com/chef/chef/pull/3317) ([jaym](https://github.com/jaym))
- Implemented `knife user key edit` and `knife client key edit` [\#3311](https://github.com/chef/chef/pull/3311) ([tylercloke](https://github.com/tylercloke))
- fix AIX package installs using a 'source' attribute [\#3298](https://github.com/chef/chef/pull/3298) ([juliandunn](https://github.com/juliandunn))
- Pull Config from external Gem [\#3270](https://github.com/chef/chef/pull/3270) ([danielsdeleo](https://github.com/danielsdeleo))
- Remove method\_missing and make Chef::Resource unspecial [\#3269](https://github.com/chef/chef/pull/3269) ([jkeiser](https://github.com/jkeiser))
- \#3266 Fix bad Windows securable\_resource functional spec assumptions for default file owners/groups [\#3267](https://github.com/chef/chef/pull/3267) ([dbjorge](https://github.com/dbjorge))
- add Chef::Log::Syslog class [\#3262](https://github.com/chef/chef/pull/3262) ([lamont-granquist](https://github.com/lamont-granquist))
- Show Chef::VERSION at prompt\_c and prompt\_i on shell session [\#3227](https://github.com/chef/chef/pull/3227) ([sawanoboly](https://github.com/sawanoboly))
- Prioritise manual ssh attribute over defaults [\#2851](https://github.com/chef/chef/pull/2851) ([Igorshp](https://github.com/Igorshp))
- fix node recipes, add run\_list\_expansion and cookbooks [\#2312](https://github.com/chef/chef/pull/2312) ([lamont-granquist](https://github.com/lamont-granquist))

## [11.18.12](https://github.com/chef/chef/tree/11.18.12) (2015-04-30)
[Full Changelog](https://github.com/chef/chef/compare/11.18.10...11.18.12)

**Merged pull requests:**

- Updating to released test kitchen and kitchen vagrant [\#3314](https://github.com/chef/chef/pull/3314) ([tyler-ball](https://github.com/tyler-ball))

## [11.18.10](https://github.com/chef/chef/tree/11.18.10) (2015-04-30)
[Full Changelog](https://github.com/chef/chef/compare/12.3.0...11.18.10)

**Merged pull requests:**

- Implemented `knife user key delete` and `knife client key delete`. [\#3306](https://github.com/chef/chef/pull/3306) ([tylercloke](https://github.com/tylercloke))
- Revert "Disable Travis CI container infrastructure due to broken IPv6 su... [\#3301](https://github.com/chef/chef/pull/3301) ([juliandunn](https://github.com/juliandunn))
- Implemented `knife user key list` and `knife client key list`. [\#3297](https://github.com/chef/chef/pull/3297) ([tylercloke](https://github.com/tylercloke))
- Disable Travis CI container infrastructure due to broken IPv6 support [\#3296](https://github.com/chef/chef/pull/3296) ([juliandunn](https://github.com/juliandunn))
- Implement `knife user key create` and `knife client key create` [\#3271](https://github.com/chef/chef/pull/3271) ([tylercloke](https://github.com/tylercloke))
- Update kitchen tests to use latest official test-kitchen [\#3260](https://github.com/chef/chef/pull/3260) ([jaym](https://github.com/jaym))
- patch to always run exception handlers [\#3207](https://github.com/chef/chef/pull/3207) ([Igorshp](https://github.com/Igorshp))

## [12.3.0](https://github.com/chef/chef/tree/12.3.0) (2015-04-27)
[Full Changelog](https://github.com/chef/chef/compare/12.3.0.rc.1...12.3.0)

## [12.3.0.rc.1](https://github.com/chef/chef/tree/12.3.0.rc.1) (2015-04-27)
[Full Changelog](https://github.com/chef/chef/compare/12.4.0.dev.0...12.3.0.rc.1)

**Merged pull requests:**

- Cherry pick changes for reboot pending [\#3288](https://github.com/chef/chef/pull/3288) ([jaym](https://github.com/jaym))
- Configure serverspec correctly on windows. [\#3280](https://github.com/chef/chef/pull/3280) ([sersut](https://github.com/sersut))
- Lcg/fix provider resolver api break [\#3279](https://github.com/chef/chef/pull/3279) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix syntax nits in Maintainers file [\#3268](https://github.com/chef/chef/pull/3268) ([thommay](https://github.com/thommay))
- send message with Severity to syslog [\#3265](https://github.com/chef/chef/pull/3265) ([sawanoboly](https://github.com/sawanoboly))
- Use the same python interpreter as yum when possible [\#3166](https://github.com/chef/chef/pull/3166) ([stevendanna](https://github.com/stevendanna))

## [12.4.0.dev.0](https://github.com/chef/chef/tree/12.4.0.dev.0) (2015-04-22)
[Full Changelog](https://github.com/chef/chef/compare/11.18.8...12.4.0.dev.0)

**Merged pull requests:**

- 12.4.0.dev.0 for master [\#3254](https://github.com/chef/chef/pull/3254) ([jaym](https://github.com/jaym))

## [11.18.8](https://github.com/chef/chef/tree/11.18.8) (2015-04-22)
[Full Changelog](https://github.com/chef/chef/compare/12.3.0.rc.0...11.18.8)

**Merged pull requests:**

- prepare 11.18.8 [\#3259](https://github.com/chef/chef/pull/3259) ([thommay](https://github.com/thommay))

## [12.3.0.rc.0](https://github.com/chef/chef/tree/12.3.0.rc.0) (2015-04-21)
[Full Changelog](https://github.com/chef/chef/compare/12.2.1...12.3.0.rc.0)

**Merged pull requests:**

- Reduce size of nested JSON test to 252 deep [\#3247](https://github.com/chef/chef/pull/3247) ([btm](https://github.com/btm))
- Unit testify shell\_spec [\#3238](https://github.com/chef/chef/pull/3238) ([jaym](https://github.com/jaym))
- Fix failing specs [\#3236](https://github.com/chef/chef/pull/3236) ([jaym](https://github.com/jaym))
- New bundler released [\#3222](https://github.com/chef/chef/pull/3222) ([jaym](https://github.com/jaym))
- Changelog for PR\#3051 [\#3221](https://github.com/chef/chef/pull/3221) ([jaymzh](https://github.com/jaymzh))
- Pin bundler to 1.9.2 in appveyor.yml [\#3220](https://github.com/chef/chef/pull/3220) ([jaym](https://github.com/jaym))
- explicitly require node presenter [\#3217](https://github.com/chef/chef/pull/3217) ([thommay](https://github.com/thommay))
- Chef Key Object [\#3214](https://github.com/chef/chef/pull/3214) ([tylercloke](https://github.com/tylercloke))
- Fixes 2140 - Honor Proxy from Env [\#3213](https://github.com/chef/chef/pull/3213) ([jonsmorrow](https://github.com/jonsmorrow))
- Awesome Community Chefs [\#3210](https://github.com/chef/chef/pull/3210) ([nathenharvey](https://github.com/nathenharvey))
- Missing require \(require what you use\) [\#3208](https://github.com/chef/chef/pull/3208) ([jkeiser](https://github.com/jkeiser))
- Volunteer myself as FreeBSD maintainer. [\#3181](https://github.com/chef/chef/pull/3181) ([Aevin1387](https://github.com/Aevin1387))
- Add minimal ohai mode option flag [\#3162](https://github.com/chef/chef/pull/3162) ([danielsdeleo](https://github.com/danielsdeleo))
- Initial socketless local mode [\#3160](https://github.com/chef/chef/pull/3160) ([danielsdeleo](https://github.com/danielsdeleo))
- Ensure that a search query makes progress [\#3135](https://github.com/chef/chef/pull/3135) ([tomhughes](https://github.com/tomhughes))
- For knife ssh: Do not try to use item\[:cloud\]\[:public\_hostname\] for the hostname if it is empty [\#3131](https://github.com/chef/chef/pull/3131) ([eherot](https://github.com/eherot))
- \[WIP\] Switch MAINTAINERS to be a TOML doc [\#3114](https://github.com/chef/chef/pull/3114) ([thommay](https://github.com/thommay))
- Reduce size of json nested entries [\#3102](https://github.com/chef/chef/pull/3102) ([btm](https://github.com/btm))
- add resource\_resolver and resource\_priority\_map [\#3077](https://github.com/chef/chef/pull/3077) ([lamont-granquist](https://github.com/lamont-granquist))
- Allow knife status to filter by environment [\#3067](https://github.com/chef/chef/pull/3067) ([thommay](https://github.com/thommay))
- Load LaunchAgents as console user, adding plist and session\_type options [\#3051](https://github.com/chef/chef/pull/3051) ([mikedodge04](https://github.com/mikedodge04))

## [12.2.1](https://github.com/chef/chef/tree/12.2.1) (2015-03-27)
[Full Changelog](https://github.com/chef/chef/compare/12.2.0...12.2.1)

**Merged pull requests:**

- Not consistent behavior of methods `default\_action` in `Chef::Resource::LWRPBase` class and `action` in `Chef::Resource` class. [\#3156](https://github.com/chef/chef/pull/3156) ([Kasen](https://github.com/Kasen))
- Fix bug where unset HOME would cause chef to crash [\#3154](https://github.com/chef/chef/pull/3154) ([jaym](https://github.com/jaym))

## [12.2.0](https://github.com/chef/chef/tree/12.2.0) (2015-03-26)
[Full Changelog](https://github.com/chef/chef/compare/12.2.0.rc.2...12.2.0)

**Merged pull requests:**

- Use opscode.com rather than chef.io in the bootstrap script. [\#3118](https://github.com/chef/chef/pull/3118) ([stevendanna](https://github.com/stevendanna))
- Fix openbsd package provider [\#3109](https://github.com/chef/chef/pull/3109) ([jaym](https://github.com/jaym))
- Change all accesses to ENV\['HOME'\] or ~ to PathHelper.home instead. [\#3088](https://github.com/chef/chef/pull/3088) ([ksubrama](https://github.com/ksubrama))
- Add --exit-on-error option to knife ssh [\#2941](https://github.com/chef/chef/pull/2941) ([ryancragun](https://github.com/ryancragun))
- DscResource in core chef [\#2881](https://github.com/chef/chef/pull/2881) ([jaym](https://github.com/jaym))

## [12.2.0.rc.2](https://github.com/chef/chef/tree/12.2.0.rc.2) (2015-03-26)
[Full Changelog](https://github.com/chef/chef/compare/12.2.0.rc.1...12.2.0.rc.2)

**Merged pull requests:**

- Revert nillable resource attributes [\#3147](https://github.com/chef/chef/pull/3147) ([jaym](https://github.com/jaym))
- Fixed bug where module\_name would return an object instead of string [\#3144](https://github.com/chef/chef/pull/3144) ([jaym](https://github.com/jaym))

## [12.2.0.rc.1](https://github.com/chef/chef/tree/12.2.0.rc.1) (2015-03-25)
[Full Changelog](https://github.com/chef/chef/compare/12.2.0.rc.0...12.2.0.rc.1)

**Merged pull requests:**

- Policyfile erchef integration [\#3142](https://github.com/chef/chef/pull/3142) ([danielsdeleo](https://github.com/danielsdeleo))
- Prepare 12.2.0.rc.1 [\#3141](https://github.com/chef/chef/pull/3141) ([jaym](https://github.com/jaym))
- Use unix specific provider for cron on solaris [\#3139](https://github.com/chef/chef/pull/3139) ([jaym](https://github.com/jaym))
- Disable Cmdlet tests on old versions of powershell [\#3138](https://github.com/chef/chef/pull/3138) ([jaym](https://github.com/jaym))

## [12.2.0.rc.0](https://github.com/chef/chef/tree/12.2.0.rc.0) (2015-03-24)
[Full Changelog](https://github.com/chef/chef/compare/12.1.2...12.2.0.rc.0)

**Merged pull requests:**

- prepare 12.2.0 RC 0 [\#3128](https://github.com/chef/chef/pull/3128) ([jaym](https://github.com/jaym))
- Jdm/dsc changelog [\#3127](https://github.com/chef/chef/pull/3127) ([jaym](https://github.com/jaym))
- DSC Resource release notes [\#3117](https://github.com/chef/chef/pull/3117) ([jaym](https://github.com/jaym))
- bumping ffi-yajl to pick up 2.x [\#3098](https://github.com/chef/chef/pull/3098) ([lamont-granquist](https://github.com/lamont-granquist))
- alter messages generated by group provider to show group\_name [\#3094](https://github.com/chef/chef/pull/3094) ([bahamas10](https://github.com/bahamas10))
- Change the default value of syntax cache to the latest value. [\#3093](https://github.com/chef/chef/pull/3093) ([ksubrama](https://github.com/ksubrama))
- Fix faulty umask logic used in spec tests. [\#3086](https://github.com/chef/chef/pull/3086) ([ksubrama](https://github.com/ksubrama))
- Remove UNIX-specific assumptions from audit runner. [\#3048](https://github.com/chef/chef/pull/3048) ([juliandunn](https://github.com/juliandunn))
- Clarify warning [\#2976](https://github.com/chef/chef/pull/2976) ([pburkholder](https://github.com/pburkholder))

## [12.1.2](https://github.com/chef/chef/tree/12.1.2) (2015-03-17)
[Full Changelog](https://github.com/chef/chef/compare/12.1.1...12.1.2)

**Merged pull requests:**

- Revert "Macports provider - provide package" [\#3087](https://github.com/chef/chef/pull/3087) ([btm](https://github.com/btm))
- Mark failing test as pending on versions of powershell \< 4 [\#3069](https://github.com/chef/chef/pull/3069) ([jaym](https://github.com/jaym))
- make audit terminology consistent [\#3064](https://github.com/chef/chef/pull/3064) ([juliandunn](https://github.com/juliandunn))
- Change inspect to string to be more human-readable. [\#3061](https://github.com/chef/chef/pull/3061) ([cmluciano](https://github.com/cmluciano))
- Cleanup user directories if state was leftover from previous run [\#3060](https://github.com/chef/chef/pull/3060) ([jaym](https://github.com/jaym))
- dscl specs should only run on mac [\#3052](https://github.com/chef/chef/pull/3052) ([jaym](https://github.com/jaym))
- Fix dscl issues for osx [\#3050](https://github.com/chef/chef/pull/3050) ([jaym](https://github.com/jaym))
- Propose myself as an EL maintainer. [\#3049](https://github.com/chef/chef/pull/3049) ([jaymzh](https://github.com/jaymzh))
- Use dev version in master [\#3045](https://github.com/chef/chef/pull/3045) ([jaym](https://github.com/jaym))
- Chef-DK nightlies on debian and el6 have been failing on these timing-based tests, doing a quick fix [\#3039](https://github.com/chef/chef/pull/3039) ([tyler-ball](https://github.com/tyler-ball))
- chef\_gem\_compile\_time's nil is the same as true [\#3029](https://github.com/chef/chef/pull/3029) ([cl-lab-k](https://github.com/cl-lab-k))
- add specs for nilling deploy parameters [\#3004](https://github.com/chef/chef/pull/3004) ([lamont-granquist](https://github.com/lamont-granquist))

## [12.1.1](https://github.com/chef/chef/tree/12.1.1) (2015-03-07)
[Full Changelog](https://github.com/chef/chef/compare/12.1.0...12.1.1)

**Merged pull requests:**

- 12.1.1 Release [\#3044](https://github.com/chef/chef/pull/3044) ([jaym](https://github.com/jaym))
- 12.1.1 changelog [\#3043](https://github.com/chef/chef/pull/3043) ([jaym](https://github.com/jaym))
- Remove @thommay as Core Maintainer [\#3021](https://github.com/chef/chef/pull/3021) ([nathenharvey](https://github.com/nathenharvey))
- Updated Changelog [\#3017](https://github.com/chef/chef/pull/3017) ([jaym](https://github.com/jaym))
- make appveyor retry bundle install [\#3015](https://github.com/chef/chef/pull/3015) ([lamont-granquist](https://github.com/lamont-granquist))
- Adding Chef::Command::Mixin back into the package provider [\#3012](https://github.com/chef/chef/pull/3012) ([jaym](https://github.com/jaym))
- Add /lib/chef/ to backtrace exclusion patterns for audit mode [\#3001](https://github.com/chef/chef/pull/3001) ([kmacgugan](https://github.com/kmacgugan))
- provider\_resolver migration from provider\_mapping [\#2970](https://github.com/chef/chef/pull/2970) ([lamont-granquist](https://github.com/lamont-granquist))
- Proposing myself as LT for RHEL and Core [\#2950](https://github.com/chef/chef/pull/2950) ([jonlives](https://github.com/jonlives))
- propose myself as a lieutenant [\#2949](https://github.com/chef/chef/pull/2949) ([thommay](https://github.com/thommay))
- Add myself as a maintainer [\#2948](https://github.com/chef/chef/pull/2948) ([thommay](https://github.com/thommay))
- Fix data fetching when explicit attributes are passed [\#3019](https://github.com/chef/chef/pull/3019) ([ranjib](https://github.com/ranjib))
- Allow people to pass in a 'source' to package rules [\#3013](https://github.com/chef/chef/pull/3013) ([jaymzh](https://github.com/jaymzh))

## [12.1.0](https://github.com/chef/chef/tree/12.1.0) (2015-03-02)
[Full Changelog](https://github.com/chef/chef/compare/12.1.0.rc.0...12.1.0)

**Merged pull requests:**

- Cherry picking changes from master [\#3002](https://github.com/chef/chef/pull/3002) ([jaym](https://github.com/jaym))
- Pr 2988 [\#2999](https://github.com/chef/chef/pull/2999) ([jaym](https://github.com/jaym))
- Adding Chef::Mixin::Command back to Package provider base class [\#2997](https://github.com/chef/chef/pull/2997) ([jaym](https://github.com/jaym))
- Update rel notes, doc changes, and changelog for windows service changes [\#2995](https://github.com/chef/chef/pull/2995) ([jaym](https://github.com/jaym))
- Fix specs on OSX [\#2992](https://github.com/chef/chef/pull/2992) ([jaym](https://github.com/jaym))
- Loosening up some gem dependencies so there are not conflicts in chef-dk [\#2990](https://github.com/chef/chef/pull/2990) ([tyler-ball](https://github.com/tyler-ball))
- Chef client running as a windows service should have a configurable timeout [\#2986](https://github.com/chef/chef/pull/2986) ([jaym](https://github.com/jaym))
- Missing require - causes `missing Constant` error when files are loaded in unexpected order [\#2983](https://github.com/chef/chef/pull/2983) ([tyler-ball](https://github.com/tyler-ball))
- Send search count to stderr [\#2982](https://github.com/chef/chef/pull/2982) ([danielsdeleo](https://github.com/danielsdeleo))
- update mode if group or owner change to keep suid bit [\#2967](https://github.com/chef/chef/pull/2967) ([minshallj](https://github.com/minshallj))
- Nominate promoting myself to OS X Lt. [\#2964](https://github.com/chef/chef/pull/2964) ([jtimberman](https://github.com/jtimberman))
- nillable deploy resource + nillable LWRP args [\#2956](https://github.com/chef/chef/pull/2956) ([lamont-granquist](https://github.com/lamont-granquist))
- Lcg/lint fixes [\#2954](https://github.com/chef/chef/pull/2954) ([lamont-granquist](https://github.com/lamont-granquist))
- fix dpkg regression [\#2942](https://github.com/chef/chef/pull/2942) ([lamont-granquist](https://github.com/lamont-granquist))
- Lcg/fix multipackage [\#2922](https://github.com/chef/chef/pull/2922) ([lamont-granquist](https://github.com/lamont-granquist))
- Completing tests for https://github.com/chef/chef/pull/2310 [\#2900](https://github.com/chef/chef/pull/2900) ([tyler-ball](https://github.com/tyler-ball))
- Finishing tests for https://github.com/chef/chef/pull/2338 [\#2893](https://github.com/chef/chef/pull/2893) ([tyler-ball](https://github.com/tyler-ball))
- Fix error message in yum provider \(related to multipackage refactor\) [\#2862](https://github.com/chef/chef/pull/2862) ([jaymzh](https://github.com/jaymzh))
- Fix up powershell script [\#2774](https://github.com/chef/chef/pull/2774) ([jaym](https://github.com/jaym))
- Suppress SSL warnings if I know what I'm doing [\#2762](https://github.com/chef/chef/pull/2762) ([jaymzh](https://github.com/jaymzh))
- Adding tests for https://github.com/opscode/chef/pull/2688 [\#2746](https://github.com/chef/chef/pull/2746) ([tyler-ball](https://github.com/tyler-ball))
- OS X user provider - fix exception if no salt is found [\#2724](https://github.com/chef/chef/pull/2724) ([patcox](https://github.com/patcox))
- bugfix dscl provider [\#2723](https://github.com/chef/chef/pull/2723) ([patcox](https://github.com/patcox))
- Macports provider - provide package [\#2722](https://github.com/chef/chef/pull/2722) ([patcox](https://github.com/patcox))
- correct filters for MacPorts package provider [\#2721](https://github.com/chef/chef/pull/2721) ([patcox](https://github.com/patcox))
- FIX data\_bag\_item.rb:161: warning: circular argument reference - data\_bag [\#2707](https://github.com/chef/chef/pull/2707) ([habermann24](https://github.com/habermann24))
- Multipackge support [\#2692](https://github.com/chef/chef/pull/2692) ([jaymzh](https://github.com/jaymzh))
- Make search with filtering match partial\_search. [\#2687](https://github.com/chef/chef/pull/2687) ([mcquin](https://github.com/mcquin))
- Fail execute test if it takes too long [\#2686](https://github.com/chef/chef/pull/2686) ([jaym](https://github.com/jaym))
- Removing ole\_initialize/uninitialize [\#2684](https://github.com/chef/chef/pull/2684) ([jaym](https://github.com/jaym))
- Fix bug where errored parsing from what-if output causes resource to be considered converged [\#2654](https://github.com/chef/chef/pull/2654) ([jaym](https://github.com/jaym))
- Lcg/script resource fixes [\#2508](https://github.com/chef/chef/pull/2508) ([lamont-granquist](https://github.com/lamont-granquist))
- Properly load FreeBSD service status [\#2277](https://github.com/chef/chef/pull/2277) ([liseki](https://github.com/liseki))
- Ensure why-run of a FreeBSD service missing init script does not fail [\#2270](https://github.com/chef/chef/pull/2270) ([liseki](https://github.com/liseki))
- Lcg/1923 [\#2030](https://github.com/chef/chef/pull/2030) ([lamont-granquist](https://github.com/lamont-granquist))

## [12.1.0.rc.0](https://github.com/chef/chef/tree/12.1.0.rc.0) (2015-02-20)
[Full Changelog](https://github.com/chef/chef/compare/11.18.6...12.1.0.rc.0)

**Merged pull requests:**

- Merging master into 12-stable [\#2958](https://github.com/chef/chef/pull/2958) ([jaym](https://github.com/jaym))
- Chef 12.1.0 [\#2952](https://github.com/chef/chef/pull/2952) ([jaym](https://github.com/jaym))
- Group spec needs to respond to shell\_out [\#2946](https://github.com/chef/chef/pull/2946) ([jaym](https://github.com/jaym))
- remove unreachable code [\#2940](https://github.com/chef/chef/pull/2940) ([lamont-granquist](https://github.com/lamont-granquist))
- Dont raise exceptions in load\_current\_resource when checking current status [\#2934](https://github.com/chef/chef/pull/2934) ([kaustubh-d](https://github.com/kaustubh-d))
- fix typo in msi provider [\#2933](https://github.com/chef/chef/pull/2933) ([andrewelizondo](https://github.com/andrewelizondo))
- forgot my md files for validatorless bootstraps [\#2928](https://github.com/chef/chef/pull/2928) ([lamont-granquist](https://github.com/lamont-granquist))
- fix aix related providers to replace popen4 with mixlib shell\_out [\#2924](https://github.com/chef/chef/pull/2924) ([btm](https://github.com/btm))
- Move supermarket.getchef.com to supermarket.chef.io [\#2918](https://github.com/chef/chef/pull/2918) ([juliandunn](https://github.com/juliandunn))
- Adding docs for all my 12.1.0 merges [\#2907](https://github.com/chef/chef/pull/2907) ([tyler-ball](https://github.com/tyler-ball))
- Updated version of \#2125 to fix CHEF-2911 [\#2905](https://github.com/chef/chef/pull/2905) ([jonlives](https://github.com/jonlives))
- rspec-3-ify all the env-run-list specs [\#2903](https://github.com/chef/chef/pull/2903) ([lamont-granquist](https://github.com/lamont-granquist))
- Improve changelog note about CHEF-3694 warnings [\#2901](https://github.com/chef/chef/pull/2901) ([juliandunn](https://github.com/juliandunn))
- Bump chef-zero dep to 4.0 [\#2899](https://github.com/chef/chef/pull/2899) ([jkeiser](https://github.com/jkeiser))
- Upload cookbooks as artifacts [\#2889](https://github.com/chef/chef/pull/2889) ([danielsdeleo](https://github.com/danielsdeleo))
- Chef Core maintainers: ++fujin [\#2888](https://github.com/chef/chef/pull/2888) ([fujin](https://github.com/fujin))
- Fix broken tests in jenkins [\#2886](https://github.com/chef/chef/pull/2886) ([jaym](https://github.com/jaym))
- dsc\_script passes timeout to lcm shellout [\#2885](https://github.com/chef/chef/pull/2885) ([jaym](https://github.com/jaym))
- Update chef-shell branding from opscode.com to chef.io [\#2879](https://github.com/chef/chef/pull/2879) ([juliandunn](https://github.com/juliandunn))
- Deprecation warnings as errors [\#2873](https://github.com/chef/chef/pull/2873) ([danielsdeleo](https://github.com/danielsdeleo))
- Lcg/chef gem config option [\#2872](https://github.com/chef/chef/pull/2872) ([lamont-granquist](https://github.com/lamont-granquist))
- Lcg/array name deuglification [\#2869](https://github.com/chef/chef/pull/2869) ([lamont-granquist](https://github.com/lamont-granquist))
- fix warning output [\#2864](https://github.com/chef/chef/pull/2864) ([lamont-granquist](https://github.com/lamont-granquist))
- Nominate myself as Windows Lt. [\#2857](https://github.com/chef/chef/pull/2857) ([btm](https://github.com/btm))
- Volunteer myself as a core maintainer [\#2856](https://github.com/chef/chef/pull/2856) ([btm](https://github.com/btm))
- Fixing Rspec 3.2 update.  We were overriding private APIs which changed. [\#2855](https://github.com/chef/chef/pull/2855) ([tyler-ball](https://github.com/tyler-ball))
- pin rspec to 3.1.x for now [\#2854](https://github.com/chef/chef/pull/2854) ([lamont-granquist](https://github.com/lamont-granquist))
- fix LWRP constant lookups [\#2853](https://github.com/chef/chef/pull/2853) ([lamont-granquist](https://github.com/lamont-granquist))
- Make chef-full bootstrap use chef.io URL. [\#2847](https://github.com/chef/chef/pull/2847) ([juliandunn](https://github.com/juliandunn))
- Merging https://github.com/chef/chef/pull/2698 [\#2833](https://github.com/chef/chef/pull/2833) ([tyler-ball](https://github.com/tyler-ball))
- Fixed typo in test from \#2823. [\#2829](https://github.com/chef/chef/pull/2829) ([juliandunn](https://github.com/juliandunn))
- Lcg/merges [\#2823](https://github.com/chef/chef/pull/2823) ([lamont-granquist](https://github.com/lamont-granquist))
- Convert opscode.com and getchef.com to chef.io in README [\#2822](https://github.com/chef/chef/pull/2822) ([danielsdeleo](https://github.com/danielsdeleo))
- Point appveyor badge at chef instead of opscode [\#2821](https://github.com/chef/chef/pull/2821) ([jaym](https://github.com/jaym))
- Changing Appveyor to use progress formatter [\#2820](https://github.com/chef/chef/pull/2820) ([tyler-ball](https://github.com/tyler-ball))
- Merging https://github.com/chef/chef/pull/2707 [\#2816](https://github.com/chef/chef/pull/2816) ([tyler-ball](https://github.com/tyler-ball))
- Update Changelog to reflect resolution of \#2348 [\#2813](https://github.com/chef/chef/pull/2813) ([jaym](https://github.com/jaym))
- Prepare 11.18.6 [\#2811](https://github.com/chef/chef/pull/2811) ([jaym](https://github.com/jaym))
- Can I maintain things? [\#2793](https://github.com/chef/chef/pull/2793) ([jaym](https://github.com/jaym))
- Disable win32 memory leak tests [\#2780](https://github.com/chef/chef/pull/2780) ([btm](https://github.com/btm))
- Allow dsc\_script to import dsc resources [\#2779](https://github.com/chef/chef/pull/2779) ([jaym](https://github.com/jaym))
- Update knife missing gem message for ChefDK [\#2760](https://github.com/chef/chef/pull/2760) ([troyready](https://github.com/troyready))
- Change audit DSL method controls to control\_group. [\#2758](https://github.com/chef/chef/pull/2758) ([mcquin](https://github.com/mcquin))
- Fix require statement on knife ssl fetch [\#2739](https://github.com/chef/chef/pull/2739) ([ranjib](https://github.com/ranjib))
- Guard resources are executed in why\_run mode [\#2717](https://github.com/chef/chef/pull/2717) ([tyler-ball](https://github.com/tyler-ball))
- appveyor for 12-stable [\#2662](https://github.com/chef/chef/pull/2662) ([btm](https://github.com/btm))
- Add .mailmap for top contributors [\#2521](https://github.com/chef/chef/pull/2521) ([stevendanna](https://github.com/stevendanna))

## [11.18.6](https://github.com/chef/chef/tree/11.18.6) (2015-01-26)
[Full Changelog](https://github.com/chef/chef/compare/11.18.4...11.18.6)

**Merged pull requests:**

- fix master [\#2810](https://github.com/chef/chef/pull/2810) ([lamont-granquist](https://github.com/lamont-granquist))
- Lcg/2448 [\#2808](https://github.com/chef/chef/pull/2808) ([lamont-granquist](https://github.com/lamont-granquist))
- Lcg/2431 [\#2807](https://github.com/chef/chef/pull/2807) ([lamont-granquist](https://github.com/lamont-granquist))
- Lcg/2411 [\#2806](https://github.com/chef/chef/pull/2806) ([lamont-granquist](https://github.com/lamont-granquist))
- Lcg/2406 [\#2805](https://github.com/chef/chef/pull/2805) ([lamont-granquist](https://github.com/lamont-granquist))
- Lcg/2398 [\#2804](https://github.com/chef/chef/pull/2804) ([lamont-granquist](https://github.com/lamont-granquist))
- Lcg/2393 [\#2803](https://github.com/chef/chef/pull/2803) ([lamont-granquist](https://github.com/lamont-granquist))
- Lcg/2212 [\#2802](https://github.com/chef/chef/pull/2802) ([lamont-granquist](https://github.com/lamont-granquist))
- Lcg/2049 [\#2801](https://github.com/chef/chef/pull/2801) ([lamont-granquist](https://github.com/lamont-granquist))
- missing md file [\#2800](https://github.com/chef/chef/pull/2800) ([lamont-granquist](https://github.com/lamont-granquist))
- Lcg/727 [\#2799](https://github.com/chef/chef/pull/2799) ([lamont-granquist](https://github.com/lamont-granquist))
- Policyfile Native API Support and ChefFS Policy Support [\#2797](https://github.com/chef/chef/pull/2797) ([danielsdeleo](https://github.com/danielsdeleo))
- Add lots of comments to Resource, section methods by who uses them [\#2794](https://github.com/chef/chef/pull/2794) ([jkeiser](https://github.com/jkeiser))
- Stub reading of /etc/chef/client.rb in spec [\#2790](https://github.com/chef/chef/pull/2790) ([mcquin](https://github.com/mcquin))
-  Update chef-client help with auto. [\#2771](https://github.com/chef/chef/pull/2771) ([cmluciano](https://github.com/cmluciano))
- Fix typo cab to can [\#2741](https://github.com/chef/chef/pull/2741) ([cmluciano](https://github.com/cmluciano))
- Fix typo resouces to resources [\#2716](https://github.com/chef/chef/pull/2716) ([cmluciano](https://github.com/cmluciano))
- Use the new build env on Travis [\#2489](https://github.com/chef/chef/pull/2489) ([joshk](https://github.com/joshk))
- Add display\_name handling to Chef::ChefFS::DataHandler::UserDataHandler [\#2166](https://github.com/chef/chef/pull/2166) ([charlesjohnson](https://github.com/charlesjohnson))

## [11.18.4](https://github.com/chef/chef/tree/11.18.4) (2015-01-23)
[Full Changelog](https://github.com/chef/chef/compare/11.18.2...11.18.4)

**Merged pull requests:**

- Prepare 11.18.4 [\#2792](https://github.com/chef/chef/pull/2792) ([jaym](https://github.com/jaym))

## [11.18.2](https://github.com/chef/chef/tree/11.18.2) (2015-01-23)
[Full Changelog](https://github.com/chef/chef/compare/11.18.0...11.18.2)

**Merged pull requests:**

- Prepare 11.18.2 release [\#2791](https://github.com/chef/chef/pull/2791) ([jaym](https://github.com/jaym))
- Fix travis badge after org rename [\#2787](https://github.com/chef/chef/pull/2787) ([mivok](https://github.com/mivok))
- Clarify where issues should be filed [\#2785](https://github.com/chef/chef/pull/2785) ([mmzyk](https://github.com/mmzyk))
- deep\_merge\_cache fixes for bugs in 12.0.0 [\#2753](https://github.com/chef/chef/pull/2753) ([lamont-granquist](https://github.com/lamont-granquist))
- make include\_recipe "::foo" use current cookbook [\#2751](https://github.com/chef/chef/pull/2751) ([lamont-granquist](https://github.com/lamont-granquist))
- Add Steven Murawski \(smurawski\) as Windows Maintainer [\#2734](https://github.com/chef/chef/pull/2734) ([smurawski](https://github.com/smurawski))
- Fixes \#2604, update location for Chef Server 12 [\#2605](https://github.com/chef/chef/pull/2605) ([jtimberman](https://github.com/jtimberman))

## [11.18.0](https://github.com/chef/chef/tree/11.18.0) (2015-01-14)
[Full Changelog](https://github.com/chef/chef/compare/12.0.3...11.18.0)

**Merged pull requests:**

- Prepare Chef 11.18.0 release [\#2750](https://github.com/chef/chef/pull/2750) ([jaym](https://github.com/jaym))
- Provide more info when cookbook metadata is not found [\#2749](https://github.com/chef/chef/pull/2749) ([jaym](https://github.com/jaym))
- Allow knife to install cookbooks with metadata.json [\#2748](https://github.com/chef/chef/pull/2748) ([jaym](https://github.com/jaym))
- Update martinisoft to FreeBSD Lieutenant [\#2732](https://github.com/chef/chef/pull/2732) ([martinisoft](https://github.com/martinisoft))
- add a compile\_time flag to chef\_gem resource [\#2730](https://github.com/chef/chef/pull/2730) ([lamont-granquist](https://github.com/lamont-granquist))
- add ruby 2.2.0 to travis [\#2729](https://github.com/chef/chef/pull/2729) ([lamont-granquist](https://github.com/lamont-granquist))
- add forcing of LANG and LANGUAGE env vars [\#2727](https://github.com/chef/chef/pull/2727) ([lamont-granquist](https://github.com/lamont-granquist))
- Merge pull request \#2505 from kwilczynski/http-create-url [\#2708](https://github.com/chef/chef/pull/2708) ([jonlives](https://github.com/jonlives))
- Randomize service display name to fix transient test failure, and mark u... [\#2699](https://github.com/chef/chef/pull/2699) ([randomcamel](https://github.com/randomcamel))
- Clearing out DOC\_CHANGES from 12-stable because all docs have been updated since 12.0.3 release [\#2678](https://github.com/chef/chef/pull/2678) ([tyler-ball](https://github.com/tyler-ball))
- Added AppVeyor build status [\#2676](https://github.com/chef/chef/pull/2676) ([jaym](https://github.com/jaym))
- Clearing out doc\_changes because we're in a new release [\#2675](https://github.com/chef/chef/pull/2675) ([tyler-ball](https://github.com/tyler-ball))
- Audit mode [\#2674](https://github.com/chef/chef/pull/2674) ([tyler-ball](https://github.com/tyler-ball))
- Merge master into audit mode [\#2669](https://github.com/chef/chef/pull/2669) ([mcquin](https://github.com/mcquin))
- Unit tests for audit-mode in chef-solo. [\#2664](https://github.com/chef/chef/pull/2664) ([mcquin](https://github.com/mcquin))
- test appveyor [\#2661](https://github.com/chef/chef/pull/2661) ([btm](https://github.com/btm))
- Unit and functional tests for spec\_formatter [\#2660](https://github.com/chef/chef/pull/2660) ([tyler-ball](https://github.com/tyler-ball))
- Merging `fix subscribes` to master [\#2652](https://github.com/chef/chef/pull/2652) ([tyler-ball](https://github.com/tyler-ball))
- Skip 3694 warnings on trivial resource cloning [\#2624](https://github.com/chef/chef/pull/2624) ([lamont-granquist](https://github.com/lamont-granquist))
- Disable audit-mode by default. [\#2622](https://github.com/chef/chef/pull/2622) ([mcquin](https://github.com/mcquin))
- Add martinisoft to missing FreeBSD platform [\#2592](https://github.com/chef/chef/pull/2592) ([martinisoft](https://github.com/martinisoft))
- Tests for audit runner [\#2549](https://github.com/chef/chef/pull/2549) ([tyler-ball](https://github.com/tyler-ball))
- Enable logon-as-service in windows\_service \(CHEF-4921\). [\#2288](https://github.com/chef/chef/pull/2288) ([randomcamel](https://github.com/randomcamel))
- Chef 11 - Switch JSON dependency for ffi-yajl [\#2120](https://github.com/chef/chef/pull/2120) ([tyler-ball](https://github.com/tyler-ball))
- We now check for powershell/dsc compat in provider. [\#2103](https://github.com/chef/chef/pull/2103) ([jaym](https://github.com/jaym))
- Jdmundrawala/windows env path [\#2024](https://github.com/chef/chef/pull/2024) ([jaym](https://github.com/jaym))

## [12.0.3](https://github.com/chef/chef/tree/12.0.3) (2014-12-16)
[Full Changelog](https://github.com/chef/chef/compare/12.0.2...12.0.3)

**Merged pull requests:**

- Merge pull request \#2594 from jaymzh/digester [\#2658](https://github.com/chef/chef/pull/2658) ([sersut](https://github.com/sersut))

## [12.0.2](https://github.com/chef/chef/tree/12.0.2) (2014-12-16)
[Full Changelog](https://github.com/chef/chef/compare/12.0.1...12.0.2)

**Merged pull requests:**

- Contribution information for https://github.com/opscode/chef/pull/2642. [\#2650](https://github.com/chef/chef/pull/2650) ([sersut](https://github.com/sersut))
- Merge pull request \#2642 from opscode/btm/site\_install\_json [\#2649](https://github.com/chef/chef/pull/2649) ([sersut](https://github.com/sersut))
- Merge pull request \#2645 from opscode/sersut/contrib-2634 [\#2647](https://github.com/chef/chef/pull/2647) ([sersut](https://github.com/sersut))
- Changelog for https://github.com/opscode/chef/pull/2621 [\#2646](https://github.com/chef/chef/pull/2646) ([tyler-ball](https://github.com/tyler-ball))
- Contribution information for https://github.com/opscode/chef/pull/2634. [\#2645](https://github.com/chef/chef/pull/2645) ([sersut](https://github.com/sersut))
- Merge pull request \#2634 from BackSlasher/repair-subversion-command [\#2643](https://github.com/chef/chef/pull/2643) ([sersut](https://github.com/sersut))
- Merge pull request \#2623 from opscode/sersut/revert-1901 [\#2639](https://github.com/chef/chef/pull/2639) ([sersut](https://github.com/sersut))
- Constrain version of database cookbook [\#2631](https://github.com/chef/chef/pull/2631) ([jaym](https://github.com/jaym))
- Improve Error Messages for SSL Errors in Knife [\#2630](https://github.com/chef/chef/pull/2630) ([danielsdeleo](https://github.com/danielsdeleo))
- Cleanup Mixin:ShellOut use/specs [\#2629](https://github.com/chef/chef/pull/2629) ([jaym](https://github.com/jaym))
- Resolve the circular dependency between ProviderResolver and Resource. [\#2610](https://github.com/chef/chef/pull/2610) ([sersut](https://github.com/sersut))
- Adding simple integration test for audit mode output [\#2607](https://github.com/chef/chef/pull/2607) ([tyler-ball](https://github.com/tyler-ball))
- Fix Digester to require its dependencies [\#2594](https://github.com/chef/chef/pull/2594) ([jaymzh](https://github.com/jaymzh))
- Tests for new `1/1 audits succeeded` output [\#2589](https://github.com/chef/chef/pull/2589) ([tyler-ball](https://github.com/tyler-ball))
- Adding audit DSL coverage [\#2586](https://github.com/chef/chef/pull/2586) ([tyler-ball](https://github.com/tyler-ball))
- Adding test for recipe DSL audit additions [\#2585](https://github.com/chef/chef/pull/2585) ([tyler-ball](https://github.com/tyler-ball))
- Stub windows? check in the unit test to make sure specs are green on windows [\#2584](https://github.com/chef/chef/pull/2584) ([sersut](https://github.com/sersut))
- Updating serverspec to pull in PR I submitted [\#2564](https://github.com/chef/chef/pull/2564) ([tyler-ball](https://github.com/tyler-ball))
- Add unit tests for Audit::ControlGroupData [\#2556](https://github.com/chef/chef/pull/2556) ([mcquin](https://github.com/mcquin))
- Add unit tests for Audit::AuditReporter [\#2555](https://github.com/chef/chef/pull/2555) ([mcquin](https://github.com/mcquin))
- Add unit tests for Audit::AuditEventProxy [\#2553](https://github.com/chef/chef/pull/2553) ([mcquin](https://github.com/mcquin))
- \[WIP\] Audit mode specs [\#2533](https://github.com/chef/chef/pull/2533) ([mcquin](https://github.com/mcquin))
- Updating chef output to include audit information [\#2494](https://github.com/chef/chef/pull/2494) ([tyler-ball](https://github.com/tyler-ball))
- knife cookbook site install json support w/tests [\#2642](https://github.com/chef/chef/pull/2642) ([btm](https://github.com/btm))
- fix apt default\_release attribute broken in 12.0 [\#2640](https://github.com/chef/chef/pull/2640) ([lamont-granquist](https://github.com/lamont-granquist))
- Jdm/issue 2626 rebase [\#2637](https://github.com/chef/chef/pull/2637) ([jaym](https://github.com/jaym))
- Subversion failes with "option ':command' is not a valid option for Mixlib::ShellOut" [\#2634](https://github.com/chef/chef/pull/2634) ([BackSlasher](https://github.com/BackSlasher))
- Preserve relative paths in Link resource [\#2623](https://github.com/chef/chef/pull/2623) ([sersut](https://github.com/sersut))
- Fixing broken `subscribes` notifications [\#2621](https://github.com/chef/chef/pull/2621) ([tyler-ball](https://github.com/tyler-ball))
- Fix attribute whitelisting [\#2616](https://github.com/chef/chef/pull/2616) ([jaymzh](https://github.com/jaymzh))
- Fix \#2596: parse instead of from\_json [\#2613](https://github.com/chef/chef/pull/2613) ([jkeiser](https://github.com/jkeiser))
- Catch 'unknown protocol' errors in ssl fetch and explain them [\#2611](https://github.com/chef/chef/pull/2611) ([danielsdeleo](https://github.com/danielsdeleo))
- Merge pull request \#2582 from jtimberman/jtimberman/brew-info-installed [\#2588](https://github.com/chef/chef/pull/2588) ([sersut](https://github.com/sersut))
- Fixes \#2578, check that `installed` isn't empty [\#2582](https://github.com/chef/chef/pull/2582) ([jtimberman](https://github.com/jtimberman))

## [12.0.1](https://github.com/chef/chef/tree/12.0.1) (2014-12-09)
[Full Changelog](https://github.com/chef/chef/compare/12.0.0...12.0.1)

**Merged pull requests:**

- Update Net::HTTP IPv6 monkey patch w/ version info [\#2567](https://github.com/chef/chef/pull/2567) ([danielsdeleo](https://github.com/danielsdeleo))
- Merging master [\#2557](https://github.com/chef/chef/pull/2557) ([tyler-ball](https://github.com/tyler-ball))
- Adding cookbook and recipe location information to JSON analytics payload [\#2528](https://github.com/chef/chef/pull/2528) ([tyler-ball](https://github.com/tyler-ball))
- Backport bug fixes for 12.0.1. [\#2576](https://github.com/chef/chef/pull/2576) ([sersut](https://github.com/sersut))
- Fix issue where Windows::Constants could potentially not exist, causing win event log module to crash [\#2574](https://github.com/chef/chef/pull/2574) ([jaym](https://github.com/jaym))
- Restore compatibility with knife-windows [\#2573](https://github.com/chef/chef/pull/2573) ([sersut](https://github.com/sersut))
- Fix windows service when :interval is set [\#2572](https://github.com/chef/chef/pull/2572) ([sersut](https://github.com/sersut))
- Restore path attribute in execute resource with deprecation warning [\#2571](https://github.com/chef/chef/pull/2571) ([sersut](https://github.com/sersut))
- Fix issue where LWRP resources using `provides` fails [\#2554](https://github.com/chef/chef/pull/2554) ([jaym](https://github.com/jaym))

## [12.0.0](https://github.com/chef/chef/tree/12.0.0) (2014-12-04)
[Full Changelog](https://github.com/chef/chef/compare/12.0.0.rc.3...12.0.0)

**Merged pull requests:**

- Remove unused "agent". [\#2532](https://github.com/chef/chef/pull/2532) ([juliandunn](https://github.com/juliandunn))
- fix searching upwards for knife plugins [\#2527](https://github.com/chef/chef/pull/2527) ([lamont-granquist](https://github.com/lamont-granquist))
- Make me a maintainer [\#2526](https://github.com/chef/chef/pull/2526) ([mcquin](https://github.com/mcquin))
- Updating to use audit syntax rather than control [\#2524](https://github.com/chef/chef/pull/2524) ([tyler-ball](https://github.com/tyler-ball))
- A memorial for Ezra Zygmuntowicz [\#2516](https://github.com/chef/chef/pull/2516) ([adamhjk](https://github.com/adamhjk))
- Add myself to MAINTAINERS [\#2512](https://github.com/chef/chef/pull/2512) ([danielsdeleo](https://github.com/danielsdeleo))
- Adding myself as a maintainer [\#2510](https://github.com/chef/chef/pull/2510) ([tyler-ball](https://github.com/tyler-ball))
- Remove all parts of 'shef' [\#2499](https://github.com/chef/chef/pull/2499) ([juliandunn](https://github.com/juliandunn))
- Remove 1.8 and 1.9 specific monkey patches [\#2498](https://github.com/chef/chef/pull/2498) ([danielsdeleo](https://github.com/danielsdeleo))
- Drop 1.9 from 12 stable [\#2496](https://github.com/chef/chef/pull/2496) ([danielsdeleo](https://github.com/danielsdeleo))
- Adding myself to relevant component maintainer [\#2490](https://github.com/chef/chef/pull/2490) ([jtimberman](https://github.com/jtimberman))
- Drop 1.9 [\#2488](https://github.com/chef/chef/pull/2488) ([danielsdeleo](https://github.com/danielsdeleo))
- suppress locale -a warnings on windows [\#2487](https://github.com/chef/chef/pull/2487) ([lamont-granquist](https://github.com/lamont-granquist))
- Add Steven Danna as a maintainer of Dev Tools [\#2485](https://github.com/chef/chef/pull/2485) ([stevendanna](https://github.com/stevendanna))
- Merging community contributions [\#2484](https://github.com/chef/chef/pull/2484) ([tyler-ball](https://github.com/tyler-ball))
- Merge pass for contributions. [\#2483](https://github.com/chef/chef/pull/2483) ([sersut](https://github.com/sersut))
- add partial deep merge cache [\#2459](https://github.com/chef/chef/pull/2459) ([lamont-granquist](https://github.com/lamont-granquist))
- Adding MAINTAINERS.md file per RFC-030 and proposing myself as maintainer for Core & Enterprise Linux [\#2423](https://github.com/chef/chef/pull/2423) ([jonlives](https://github.com/jonlives))

## [12.0.0.rc.3](https://github.com/chef/chef/tree/12.0.0.rc.3) (2014-11-24)
[Full Changelog](https://github.com/chef/chef/compare/12.0.0.rc.2...12.0.0.rc.3)

**Merged pull requests:**

- Revert rubygems 2.2.0 with bundler 1.5 with Ruby 1.8.7 fix [\#2445](https://github.com/chef/chef/pull/2445) ([juliandunn](https://github.com/juliandunn))

## [12.0.0.rc.2](https://github.com/chef/chef/tree/12.0.0.rc.2) (2014-11-24)
[Full Changelog](https://github.com/chef/chef/compare/12.2.0.alpha.0...12.0.0.rc.2)

**Merged pull requests:**

- Merge pull request \#2462 from opscode/lcg/remove-knockout-merge [\#2477](https://github.com/chef/chef/pull/2477) ([sersut](https://github.com/sersut))
- remove old knockout merge exception [\#2462](https://github.com/chef/chef/pull/2462) ([lamont-granquist](https://github.com/lamont-granquist))

## [12.2.0.alpha.0](https://github.com/chef/chef/tree/12.2.0.alpha.0) (2014-11-23)
[Full Changelog](https://github.com/chef/chef/compare/11.18.0.rc.1...12.2.0.alpha.0)

**Merged pull requests:**

- Fix copy pasta error. [\#2475](https://github.com/chef/chef/pull/2475) ([sersut](https://github.com/sersut))
- Audit mode rebase [\#2472](https://github.com/chef/chef/pull/2472) ([mcquin](https://github.com/mcquin))
- Test include\_recipe with controls [\#2468](https://github.com/chef/chef/pull/2468) ([mcquin](https://github.com/mcquin))
- adding some more specs around to\_hash [\#2464](https://github.com/chef/chef/pull/2464) ([lamont-granquist](https://github.com/lamont-granquist))
- Merge pull request \#2447 from opscode/lcg/lazy-deep-merge2 [\#2454](https://github.com/chef/chef/pull/2454) ([sersut](https://github.com/sersut))
- Remove compression since the server doesn't support it yet. [\#2453](https://github.com/chef/chef/pull/2453) ([sersut](https://github.com/sersut))
- Setting version to an empty string in tests [\#2452](https://github.com/chef/chef/pull/2452) ([lucywyman](https://github.com/lucywyman))
- Merge pull request \#2073 from opscode/ryan/group\_post-master [\#2450](https://github.com/chef/chef/pull/2450) ([sersut](https://github.com/sersut))
- Lcg/lazy deep merge2 [\#2447](https://github.com/chef/chef/pull/2447) ([lamont-granquist](https://github.com/lamont-granquist))
- Merge pull request \#2424 from opscode/sersut/chef-2356 [\#2440](https://github.com/chef/chef/pull/2440) ([sersut](https://github.com/sersut))
- Fix installer\_version\_string to be an array on prerelease parameter. [\#2439](https://github.com/chef/chef/pull/2439) ([Daegalus](https://github.com/Daegalus))
- Fix "log writing failed. closed stream" errors after audit phase [\#2428](https://github.com/chef/chef/pull/2428) ([sersut](https://github.com/sersut))
- Use platform\_specific\_path in chef shell [\#2427](https://github.com/chef/chef/pull/2427) ([jaym](https://github.com/jaym))
- stop recomputing locale -a constantly [\#2425](https://github.com/chef/chef/pull/2425) ([lamont-granquist](https://github.com/lamont-granquist))
- :auto mode for :file\_staging\_uses\_destdir [\#2424](https://github.com/chef/chef/pull/2424) ([sersut](https://github.com/sersut))
- skip expensive spec tests by default [\#2421](https://github.com/chef/chef/pull/2421) ([lamont-granquist](https://github.com/lamont-granquist))
- Populate the actors when creating groups [\#2074](https://github.com/chef/chef/pull/2074) ([ryancragun](https://github.com/ryancragun))
- Populate the actors when creating groups [\#2073](https://github.com/chef/chef/pull/2073) ([ryancragun](https://github.com/ryancragun))
- Audit Tests [\#2465](https://github.com/chef/chef/pull/2465) ([sersut](https://github.com/sersut))
- Adding start\_time and end\_time to array per request [\#2461](https://github.com/chef/chef/pull/2461) ([tyler-ball](https://github.com/tyler-ball))
- Audit tests for `package` DSL duplication [\#2436](https://github.com/chef/chef/pull/2436) ([tyler-ball](https://github.com/tyler-ball))
- Wait until audit phase to load needed files. [\#2426](https://github.com/chef/chef/pull/2426) ([mcquin](https://github.com/mcquin))

## [11.18.0.rc.1](https://github.com/chef/chef/tree/11.18.0.rc.1) (2014-11-14)
[Full Changelog](https://github.com/chef/chef/compare/11.18.0.rc.0...11.18.0.rc.1)

**Merged pull requests:**

- ChefDK 227 fix for master [\#2422](https://github.com/chef/chef/pull/2422) ([danielsdeleo](https://github.com/danielsdeleo))
- Lcg/openbsd package [\#2420](https://github.com/chef/chef/pull/2420) ([lamont-granquist](https://github.com/lamont-granquist))
- Lcg/goalie merging [\#2418](https://github.com/chef/chef/pull/2418) ([lamont-granquist](https://github.com/lamont-granquist))

## [11.18.0.rc.0](https://github.com/chef/chef/tree/11.18.0.rc.0) (2014-11-13)
[Full Changelog](https://github.com/chef/chef/compare/12.0.0.rc.1...11.18.0.rc.0)

**Merged pull requests:**

- Update version and changelog for 11.18.0 RC0 [\#2419](https://github.com/chef/chef/pull/2419) ([danielsdeleo](https://github.com/danielsdeleo))
- Ignore knife subcommands from other chef installs [\#2416](https://github.com/chef/chef/pull/2416) ([danielsdeleo](https://github.com/danielsdeleo))
- Audit mode rebase [\#2415](https://github.com/chef/chef/pull/2415) ([mcquin](https://github.com/mcquin))
- File.exists? is deprecated in favor of File.exist? [\#2331](https://github.com/chef/chef/pull/2331) ([justanshulsharma](https://github.com/justanshulsharma))

## [12.0.0.rc.1](https://github.com/chef/chef/tree/12.0.0.rc.1) (2014-11-13)
[Full Changelog](https://github.com/chef/chef/compare/10.34.6...12.0.0.rc.1)

**Merged pull requests:**

- Merge pull request \#2407 from opscode/sersut/ci-fix-sparc [\#2410](https://github.com/chef/chef/pull/2410) ([sersut](https://github.com/sersut))
- Fix unit specs on Sparc. [\#2407](https://github.com/chef/chef/pull/2407) ([sersut](https://github.com/sersut))
- chef-shell checks platform when looking for client.rb and solo.rb. [\#2395](https://github.com/chef/chef/pull/2395) ([jaym](https://github.com/jaym))
- Windows event logger no longer imports into the global namespace. [\#2394](https://github.com/chef/chef/pull/2394) ([jaym](https://github.com/jaym))
- Audit Mode Formatter Integration [\#2362](https://github.com/chef/chef/pull/2362) ([tyler-ball](https://github.com/tyler-ball))

## [10.34.6](https://github.com/chef/chef/tree/10.34.6) (2014-11-10)
[Full Changelog](https://github.com/chef/chef/compare/12.0.0.rc.0...10.34.6)

**Merged pull requests:**

- Merge pull request \#2336 from opscode/lcg/12-systemd-fixes [\#2389](https://github.com/chef/chef/pull/2389) ([sersut](https://github.com/sersut))
- Merge pull request \#2387 from opscode/sersut/revert-attr-nil-override [\#2388](https://github.com/chef/chef/pull/2388) ([sersut](https://github.com/sersut))
- Revert "CHEF-4101: DeepMerge - support overwriting hash values with nil" [\#2387](https://github.com/chef/chef/pull/2387) ([sersut](https://github.com/sersut))
- Merge pull request \#2097 from opscode/lcg/chef-12-attr [\#2386](https://github.com/chef/chef/pull/2386) ([sersut](https://github.com/sersut))
- Fix some minor typos [\#2385](https://github.com/chef/chef/pull/2385) ([tas50](https://github.com/tas50))
- typo fixes - https://github.com/vlajos/misspell\_fixer [\#2382](https://github.com/chef/chef/pull/2382) ([vlajos](https://github.com/vlajos))
- Merge pull request \#2370 from opscode/ryan/follow\_symlinks [\#2381](https://github.com/chef/chef/pull/2381) ([sersut](https://github.com/sersut))
- Merge pull request \#2368 from opscode/sersut/knife-cloud-bootstrap-options [\#2377](https://github.com/chef/chef/pull/2377) ([sersut](https://github.com/sersut))
- Add CLA\_ARCHIVE -- List of CLAs from pre-supermarket times [\#2376](https://github.com/chef/chef/pull/2376) ([danielsdeleo](https://github.com/danielsdeleo))
- Preparing 10.34.6 release [\#2373](https://github.com/chef/chef/pull/2373) ([jaym](https://github.com/jaym))
- Make client.pem being a symlink a configurable option [\#2370](https://github.com/chef/chef/pull/2370) ([ryancragun](https://github.com/ryancragun))
- Knife cloud plugins bootstrap problem with Chef 12 when using custom templates. [\#2368](https://github.com/chef/chef/pull/2368) ([sersut](https://github.com/sersut))
- Bring in cheffish and provisioning resources if they are installed [\#2364](https://github.com/chef/chef/pull/2364) ([jkeiser](https://github.com/jkeiser))
- Add chef-provisioning to core Chef [\#2357](https://github.com/chef/chef/pull/2357) ([jkeiser](https://github.com/jkeiser))
- Add serverspec types and matchers. [\#2354](https://github.com/chef/chef/pull/2354) ([mcquin](https://github.com/mcquin))
- DSL + Runner [\#2350](https://github.com/chef/chef/pull/2350) ([mcquin](https://github.com/mcquin))
- Getting pedant running with rspec 3 [\#2346](https://github.com/chef/chef/pull/2346) ([tyler-ball](https://github.com/tyler-ball))
- fix systemd for Ubuntu 14.10 [\#2336](https://github.com/chef/chef/pull/2336) ([lamont-granquist](https://github.com/lamont-granquist))
- \[WIP\] Audit-mode runner [\#2329](https://github.com/chef/chef/pull/2329) ([mcquin](https://github.com/mcquin))
- Updating travis to run builds on 12-stable [\#2326](https://github.com/chef/chef/pull/2326) ([tyler-ball](https://github.com/tyler-ball))
- Update to RSpec 3 [\#2324](https://github.com/chef/chef/pull/2324) ([mcquin](https://github.com/mcquin))
- First pass at DSL additions for chef-client audit mode [\#2321](https://github.com/chef/chef/pull/2321) ([tyler-ball](https://github.com/tyler-ball))
- Only include chef-service-manager on windows [\#2273](https://github.com/chef/chef/pull/2273) ([jaym](https://github.com/jaym))
- knife node run\_list remove issue \#2186 [\#2242](https://github.com/chef/chef/pull/2242) ([justanshulsharma](https://github.com/justanshulsharma))
- Lcg/chef 12 attr [\#2097](https://github.com/chef/chef/pull/2097) ([lamont-granquist](https://github.com/lamont-granquist))

## [12.0.0.rc.0](https://github.com/chef/chef/tree/12.0.0.rc.0) (2014-10-30)
[Full Changelog](https://github.com/chef/chef/compare/11.16.4...12.0.0.rc.0)

**Merged pull requests:**

- Merge pull request \#2328 from opscode/sersut/win-spec-fix [\#2330](https://github.com/chef/chef/pull/2330) ([sersut](https://github.com/sersut))
- Fix windows specs for windows package type. [\#2328](https://github.com/chef/chef/pull/2328) ([sersut](https://github.com/sersut))
- RC Spec fixes for 12-stable [\#2327](https://github.com/chef/chef/pull/2327) ([sersut](https://github.com/sersut))
- Fixing documentation error \(leftovers, no longer correct\) [\#2322](https://github.com/chef/chef/pull/2322) ([tyler-ball](https://github.com/tyler-ball))
- Disable workstation tests for aix. [\#2320](https://github.com/chef/chef/pull/2320) ([kaustubh-d](https://github.com/kaustubh-d))
- add 14.04 to supported vagrant distros [\#2315](https://github.com/chef/chef/pull/2315) ([lamont-granquist](https://github.com/lamont-granquist))
- 64-bit Windows functional script resource specs should not execute on 32-bit Windows [\#2314](https://github.com/chef/chef/pull/2314) ([adamedx](https://github.com/adamedx))
- Make sure windows\_service and windows\_package resources are found with the new dynamic provider resolver. [\#2313](https://github.com/chef/chef/pull/2313) ([sersut](https://github.com/sersut))
- Fix test failures with latest AIX build. [\#2309](https://github.com/chef/chef/pull/2309) ([kaustubh-d](https://github.com/kaustubh-d))
- Chef::Application outer lexical scope [\#2308](https://github.com/chef/chef/pull/2308) ([lamont-granquist](https://github.com/lamont-granquist))
- Pick pull request \#2252 from master [\#2305](https://github.com/chef/chef/pull/2305) ([jaym](https://github.com/jaym))
- Remove old, outdated distro initscripts. [\#2301](https://github.com/chef/chef/pull/2301) ([juliandunn](https://github.com/juliandunn))
- updating resources/providers unit tests to rpsec3 [\#2300](https://github.com/chef/chef/pull/2300) ([lamont-granquist](https://github.com/lamont-granquist))
- Cherrypick pull request \#2264 from opscode/jdmundrawala/issue-2225 [\#2298](https://github.com/chef/chef/pull/2298) ([jaym](https://github.com/jaym))
- Using released chef-zero which uses ffi-yajl instead of JSON gem [\#2297](https://github.com/chef/chef/pull/2297) ([tyler-ball](https://github.com/tyler-ball))
- Last contribution pass before Chef 12. [\#2296](https://github.com/chef/chef/pull/2296) ([sersut](https://github.com/sersut))
- add md files for ProviderResolver features [\#2295](https://github.com/chef/chef/pull/2295) ([lamont-granquist](https://github.com/lamont-granquist))
- Renamed output\_has\_dsc\_module\_failure to dsc\_module\_import\_failure [\#2294](https://github.com/chef/chef/pull/2294) ([jaym](https://github.com/jaym))
- remove force of utf-8 [\#2287](https://github.com/chef/chef/pull/2287) ([lamont-granquist](https://github.com/lamont-granquist))
- force ffi-yajl to use C ext [\#2284](https://github.com/chef/chef/pull/2284) ([lamont-granquist](https://github.com/lamont-granquist))
- Notes for Windows Event Log feature [\#2282](https://github.com/chef/chef/pull/2282) ([jaym](https://github.com/jaym))
- Renamed output\_has\_dsc\_module\_failure to dsc\_module\_import\_failure [\#2281](https://github.com/chef/chef/pull/2281) ([jaym](https://github.com/jaym))
- Rearrange changelog [\#2280](https://github.com/chef/chef/pull/2280) ([juliandunn](https://github.com/juliandunn))
- Added release notes for AIX service provider. [\#2275](https://github.com/chef/chef/pull/2275) ([juliandunn](https://github.com/juliandunn))
- Contribution info for last pass before Chef 12 Release. [\#2271](https://github.com/chef/chef/pull/2271) ([sersut](https://github.com/sersut))
- Missed one spec in rpm\_spec.rb. [\#2266](https://github.com/chef/chef/pull/2266) ([sersut](https://github.com/sersut))
- Add missing specs for List [\#2265](https://github.com/chef/chef/pull/2265) ([sersut](https://github.com/sersut))
- Improve detection missing WhatIf support [\#2264](https://github.com/chef/chef/pull/2264) ([jaym](https://github.com/jaym))
- Misc RC spec fixes that we ran into in CI. [\#2263](https://github.com/chef/chef/pull/2263) ([sersut](https://github.com/sersut))
- Fix value of retries shown in the error report. [\#2259](https://github.com/chef/chef/pull/2259) ([kwilczynski](https://github.com/kwilczynski))
- speed up rest test [\#2257](https://github.com/chef/chef/pull/2257) ([lamont-granquist](https://github.com/lamont-granquist))
- Make empty run\_list to produce an empty array when using node.to\_hash [\#2255](https://github.com/chef/chef/pull/2255) ([xeron](https://github.com/xeron))
- Modified env resource to break values up by delimiter before comparing [\#2252](https://github.com/chef/chef/pull/2252) ([jaym](https://github.com/jaym))
- use group\_name when checking if the group exists on mac osx with dscl [\#2251](https://github.com/chef/chef/pull/2251) ([chilicheech](https://github.com/chilicheech))
- Ensure delete ENV\[var\] from current process [\#2249](https://github.com/chef/chef/pull/2249) ([jaym](https://github.com/jaym))
- Adding a bin for windows service so that we can appbundle [\#2248](https://github.com/chef/chef/pull/2248) ([jaym](https://github.com/jaym))
- aesthetics: that trailing space missing makes me uncomfortable [\#2246](https://github.com/chef/chef/pull/2246) ([rottenbytes](https://github.com/rottenbytes))
- Don't leave spec tempfiles in people's source roots. [\#2241](https://github.com/chef/chef/pull/2241) ([randomcamel](https://github.com/randomcamel))
- Backport cookbooks.opscode.com -\> supermarket change to 11-stable. [\#2240](https://github.com/chef/chef/pull/2240) ([sersut](https://github.com/sersut))
- Fix Inconsistent knife from file globbing [\#2239](https://github.com/chef/chef/pull/2239) ([justanshulsharma](https://github.com/justanshulsharma))
- Return correct value for tagged? when node\[:tags\] is nil. [\#2238](https://github.com/chef/chef/pull/2238) ([sersut](https://github.com/sersut))
- mount resource : allow to mount cgroups [\#2237](https://github.com/chef/chef/pull/2237) ([rottenbytes](https://github.com/rottenbytes))
- Port Issue \#2209: DSC parameters should be passed even when there is no config data file [\#2236](https://github.com/chef/chef/pull/2236) ([adamedx](https://github.com/adamedx))
- Added Windows 10 \(Server and workstation\) to the marketing names version table. [\#2233](https://github.com/chef/chef/pull/2233) ([juliandunn](https://github.com/juliandunn))
- remove chef/shell\_out dep [\#2231](https://github.com/chef/chef/pull/2231) ([lamont-granquist](https://github.com/lamont-granquist))
- Add \#empty? method to the ChefFS base dir class. [\#2230](https://github.com/chef/chef/pull/2230) ([curiositycasualty](https://github.com/curiositycasualty))
- Logging events to the Windows Event Log [\#2229](https://github.com/chef/chef/pull/2229) ([jaym](https://github.com/jaym))
- remove 1.8.7 support from README [\#2227](https://github.com/chef/chef/pull/2227) ([lamont-granquist](https://github.com/lamont-granquist))
- Guards of execute resource doesn't inherit command options from its parent resource [\#2223](https://github.com/chef/chef/pull/2223) ([sersut](https://github.com/sersut))
- Better handling of locale -a output [\#2222](https://github.com/chef/chef/pull/2222) ([mcquin](https://github.com/mcquin))
- Cherry-pick \#2190 from opscode/jdmundrawala/issue-2169 [\#2218](https://github.com/chef/chef/pull/2218) ([jaym](https://github.com/jaym))
- Cherry-pick \#2208 from opscode/jdmundrawala/env-path-spec-fix [\#2217](https://github.com/chef/chef/pull/2217) ([jaym](https://github.com/jaym))
- Notify a resource by the `resource\[name\]` key it was written as [\#2216](https://github.com/chef/chef/pull/2216) ([tyler-ball](https://github.com/tyler-ball))
- Fixing bug where  tried to use the homebrew provider on OSX and didn't correctly check for lack of homebrew-specific attribute on the resource [\#2215](https://github.com/chef/chef/pull/2215) ([tyler-ball](https://github.com/tyler-ball))
- Rebase CHEF-2187: change default group mapping for SLES to gpasswd [\#2211](https://github.com/chef/chef/pull/2211) ([sersut](https://github.com/sersut))
- Updates to CHANGELOG and RELEASE\_NOTES for the last month's contributions. [\#2210](https://github.com/chef/chef/pull/2210) ([sersut](https://github.com/sersut))
- DSC parameters should be passed even when there is no config data file [\#2209](https://github.com/chef/chef/pull/2209) ([adamedx](https://github.com/adamedx))
- restore ENV\['PATH'\] in env\_spec after test is complete [\#2208](https://github.com/chef/chef/pull/2208) ([jaym](https://github.com/jaym))
- Rebase CHEF-1971: Report a more appropriate error when no recipe is given [\#2207](https://github.com/chef/chef/pull/2207) ([sersut](https://github.com/sersut))
- Upgrading to latest ffi-yajl which contains fixes for Object\#to\_json [\#2205](https://github.com/chef/chef/pull/2205) ([tyler-ball](https://github.com/tyler-ball))
- Upgrading to latest ffi-yajl which contains fixes for Object\#to\_json [\#2204](https://github.com/chef/chef/pull/2204) ([tyler-ball](https://github.com/tyler-ball))
- Allow `knife cookbook site share` to omit category [\#2203](https://github.com/chef/chef/pull/2203) ([martinb3](https://github.com/martinb3))
- CHANGELOG update and spec for gem\_package upgrade fix [\#2201](https://github.com/chef/chef/pull/2201) ([sersut](https://github.com/sersut))
- Keep deprecation of valid\_actions until Chef 13. [\#2197](https://github.com/chef/chef/pull/2197) ([sersut](https://github.com/sersut))
- \[knife-ec2\]Command-line options do not take precedence over knife.rb configuration \(\#247\) [\#2196](https://github.com/chef/chef/pull/2196) ([siddheshwar-more](https://github.com/siddheshwar-more))
- Don't override LWRP resources or providers anymore in Chef 12. [\#2193](https://github.com/chef/chef/pull/2193) ([sersut](https://github.com/sersut))
- Try to apply dsc configuration even if what-if fails [\#2190](https://github.com/chef/chef/pull/2190) ([jaym](https://github.com/jaym))
- Cherry pick dsc\_script bug fix into 11-stable [\#2188](https://github.com/chef/chef/pull/2188) ([jaym](https://github.com/jaym))
- return whatever the definition returns [\#2185](https://github.com/chef/chef/pull/2185) ([lamont-granquist](https://github.com/lamont-granquist))
- Add some useful github queries. [\#2184](https://github.com/chef/chef/pull/2184) ([sersut](https://github.com/sersut))
- Remove Ruby 1.8.7 from travis config. [\#2183](https://github.com/chef/chef/pull/2183) ([sersut](https://github.com/sersut))
- Add JSON output to knife status command [\#2170](https://github.com/chef/chef/pull/2170) ([vaxvms](https://github.com/vaxvms))
- print the path to the configuration file used [\#2167](https://github.com/chef/chef/pull/2167) ([alexpop](https://github.com/alexpop))
- RFC 17 implementation [\#2165](https://github.com/chef/chef/pull/2165) ([coderanger](https://github.com/coderanger))
- \[issue-2163\] display new cookbook path [\#2164](https://github.com/chef/chef/pull/2164) ([alexpop](https://github.com/alexpop))
- knife upload fails due to "wrong" ruby syntax in files/\* file [\#2149](https://github.com/chef/chef/pull/2149) ([JeanMertz](https://github.com/JeanMertz))
- \[CHEF-672\] load library folder recursively [\#2129](https://github.com/chef/chef/pull/2129) ([JeanMertz](https://github.com/JeanMertz))
- Remove node\_name lookup in knife ssh error handler [\#2126](https://github.com/chef/chef/pull/2126) ([trvrnrth](https://github.com/trvrnrth))
- Replacing all JSON gem usage with Chef::JSONCompat usage [\#2114](https://github.com/chef/chef/pull/2114) ([tyler-ball](https://github.com/tyler-ball))
- Reading crontab of non-root unix user should read as that user [\#2107](https://github.com/chef/chef/pull/2107) ([sax](https://github.com/sax))
- `brew` command now ran as user owning executable [\#2102](https://github.com/chef/chef/pull/2102) ([tyler-ball](https://github.com/tyler-ball))
- Use exact match to locate remote git-reference [\#2079](https://github.com/chef/chef/pull/2079) ([jbence](https://github.com/jbence))
- change default service mapping for SLES to systemd [\#2052](https://github.com/chef/chef/pull/2052) ([mapleoin](https://github.com/mapleoin))
- Installing bind with pacman\_package fails [\#2051](https://github.com/chef/chef/pull/2051) ([wacky612](https://github.com/wacky612))
- Added exec method to Recipe, addressing Issue 1689 [\#2041](https://github.com/chef/chef/pull/2041) ([nsdavidson](https://github.com/nsdavidson))
- aix service provider [\#2028](https://github.com/chef/chef/pull/2028) ([kaustubh-d](https://github.com/kaustubh-d))
- Support sensitive in execute resources. [\#2013](https://github.com/chef/chef/pull/2013) ([nvwls](https://github.com/nvwls))
- fix FreeBSD pkgng provider \(version detection\) [\#1980](https://github.com/chef/chef/pull/1980) ([bahamas10](https://github.com/bahamas10))
- honor package category for paludis packages [\#1957](https://github.com/chef/chef/pull/1957) ([tbe](https://github.com/tbe))
- Should use client\_name instead of node\_name [\#1924](https://github.com/chef/chef/pull/1924) ([justanshulsharma](https://github.com/justanshulsharma))
- Stop ignoring colored knife output config on Windows [\#1905](https://github.com/chef/chef/pull/1905) ([adamedx](https://github.com/adamedx))
- CHEF-3404: Provider Resolver [\#1596](https://github.com/chef/chef/pull/1596) ([lamont-granquist](https://github.com/lamont-granquist))
- guard\_interpreter default change for powershell\_script, batch resources [\#1495](https://github.com/chef/chef/pull/1495) ([adamedx](https://github.com/adamedx))

## [11.16.4](https://github.com/chef/chef/tree/11.16.4) (2014-10-07)
[Full Changelog](https://github.com/chef/chef/compare/10.34.4...11.16.4)

**Merged pull requests:**

- CHANGELOG and version updates for 11.16.4. [\#2182](https://github.com/chef/chef/pull/2182) ([sersut](https://github.com/sersut))
- Make FileVendor configuration specific to the two implementations [\#2179](https://github.com/chef/chef/pull/2179) ([sersut](https://github.com/sersut))
- serverspec 2 fixes [\#2178](https://github.com/chef/chef/pull/2178) ([lamont-granquist](https://github.com/lamont-granquist))
- add changelog for 50x errors [\#2156](https://github.com/chef/chef/pull/2156) ([lamont-granquist](https://github.com/lamont-granquist))
- Match group func tests to specification [\#2154](https://github.com/chef/chef/pull/2154) ([btm](https://github.com/btm))
- Merge pull request \#1912 from jessehu/CHEF-ISSUE-1904 [\#2151](https://github.com/chef/chef/pull/2151) ([sersut](https://github.com/sersut))
- Work around breaking change in git clone [\#2148](https://github.com/chef/chef/pull/2148) ([mal](https://github.com/mal))
- Jdmundrawala/11 windows env fix [\#2142](https://github.com/chef/chef/pull/2142) ([jaym](https://github.com/jaym))
- Deprecate CookbookVersion\#latest\_cookbooks [\#2141](https://github.com/chef/chef/pull/2141) ([mcquin](https://github.com/mcquin))
- Jdmundrawala/provider specs [\#2136](https://github.com/chef/chef/pull/2136) ([jaym](https://github.com/jaym))
- Make knife unit tests pass on windows [\#2135](https://github.com/chef/chef/pull/2135) ([jaym](https://github.com/jaym))
- Databag spec specifies not windows [\#2134](https://github.com/chef/chef/pull/2134) ([jaym](https://github.com/jaym))
- Remote directory should pass specs [\#2133](https://github.com/chef/chef/pull/2133) ([jaym](https://github.com/jaym))
- Windows can have git as well [\#2131](https://github.com/chef/chef/pull/2131) ([jaym](https://github.com/jaym))
- Fixing cookbook loading for windows [\#2130](https://github.com/chef/chef/pull/2130) ([jaym](https://github.com/jaym))
- adding CHANGELOG for omnibus-chef 2.1.3 update [\#2128](https://github.com/chef/chef/pull/2128) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix RHEL pre 7 provider service mapping [\#2123](https://github.com/chef/chef/pull/2123) ([andytson](https://github.com/andytson))
- Quietly keep locale en\_US.UTF-8 on Windows [\#2122](https://github.com/chef/chef/pull/2122) ([btm](https://github.com/btm))
- Delay evaluation of guard\_interpreter [\#2119](https://github.com/chef/chef/pull/2119) ([btm](https://github.com/btm))
- Finishing encrypted data bag UX [\#2118](https://github.com/chef/chef/pull/2118) ([tyler-ball](https://github.com/tyler-ball))
- Support checkout for git \< 1.7.3 [\#2116](https://github.com/chef/chef/pull/2116) ([jaym](https://github.com/jaym))
- Disable unforked interval runs. [\#2101](https://github.com/chef/chef/pull/2101) ([mcquin](https://github.com/mcquin))
- Restoring https://github.com/opscode/chef/pull/1921 to master [\#2094](https://github.com/chef/chef/pull/2094) ([tyler-ball](https://github.com/tyler-ball))
- Escape file paths for globbing [\#2092](https://github.com/chef/chef/pull/2092) ([mcquin](https://github.com/mcquin))
- Platform/dsc phase 1 rebase [\#2091](https://github.com/chef/chef/pull/2091) ([jaym](https://github.com/jaym))
- Fix test failure happening only on Jenkins 12.04+1.9.3: don't call File.... [\#2088](https://github.com/chef/chef/pull/2088) ([randomcamel](https://github.com/randomcamel))
- Fix Debian ifconfig unit test on Windows. [\#2080](https://github.com/chef/chef/pull/2080) ([randomcamel](https://github.com/randomcamel))
- Doc changes for the core reboot resource. [\#2067](https://github.com/chef/chef/pull/2067) ([randomcamel](https://github.com/randomcamel))
- removing shelling out to erubis/ruby [\#2046](https://github.com/chef/chef/pull/2046) ([lamont-granquist](https://github.com/lamont-granquist))
- Verify X509 properties of trusted certificates [\#2036](https://github.com/chef/chef/pull/2036) ([mcquin](https://github.com/mcquin))

## [10.34.4](https://github.com/chef/chef/tree/10.34.4) (2014-09-17)
[Full Changelog](https://github.com/chef/chef/compare/11.16.2...10.34.4)

## [11.16.2](https://github.com/chef/chef/tree/11.16.2) (2014-09-17)
[Full Changelog](https://github.com/chef/chef/compare/12.0.0.alpha.2...11.16.2)

**Merged pull requests:**

- Thanks to Lamont, fix trusted certs test failures on Windows. [\#2064](https://github.com/chef/chef/pull/2064) ([randomcamel](https://github.com/randomcamel))
- Fix the integration tests so they pass on Windows. [\#2059](https://github.com/chef/chef/pull/2059) ([randomcamel](https://github.com/randomcamel))

## [12.0.0.alpha.2](https://github.com/chef/chef/tree/12.0.0.alpha.2) (2014-09-15)
[Full Changelog](https://github.com/chef/chef/compare/11.16.0...12.0.0.alpha.2)

**Merged pull requests:**

- Spec fixes for Windows [\#2035](https://github.com/chef/chef/pull/2035) ([randomcamel](https://github.com/randomcamel))
- Rebase and ChangeLOG of pr/1898 [\#2033](https://github.com/chef/chef/pull/2033) ([lamont-granquist](https://github.com/lamont-granquist))
- Rebase and ChangeLOG for pr/1785 [\#2032](https://github.com/chef/chef/pull/2032) ([lamont-granquist](https://github.com/lamont-granquist))
- Rebase and ChangeLog for PR 1577 [\#2031](https://github.com/chef/chef/pull/2031) ([lamont-granquist](https://github.com/lamont-granquist))
- pull ohai rc release [\#2025](https://github.com/chef/chef/pull/2025) ([lamont-granquist](https://github.com/lamont-granquist))
- Add ChefFS rdoc, format existing ChefFS rdoc correctly [\#2023](https://github.com/chef/chef/pull/2023) ([jkeiser](https://github.com/jkeiser))
- \[master/12\] Fix whyrun\_safe\_ruby\_block regression [\#2022](https://github.com/chef/chef/pull/2022) ([jaymzh](https://github.com/jaymzh))
- \[11\] Fix whyrun\_safe\_ruby\_block regression [\#2021](https://github.com/chef/chef/pull/2021) ([jaymzh](https://github.com/jaymzh))
- fixing travis LC\_ALL errors [\#2020](https://github.com/chef/chef/pull/2020) ([lamont-granquist](https://github.com/lamont-granquist))
- Add a Reboot resource into core. [\#1979](https://github.com/chef/chef/pull/1979) ([randomcamel](https://github.com/randomcamel))
- Unicode fixes for Chef 12 [\#1977](https://github.com/chef/chef/pull/1977) ([lamont-granquist](https://github.com/lamont-granquist))
- Don't prepend \\?\ to relative paths, it produces an invalid path argument. [\#1901](https://github.com/chef/chef/pull/1901) ([randomcamel](https://github.com/randomcamel))

## [11.16.0](https://github.com/chef/chef/tree/11.16.0) (2014-09-07)
[Full Changelog](https://github.com/chef/chef/compare/11.16.0.rc.2...11.16.0)

## [11.16.0.rc.2](https://github.com/chef/chef/tree/11.16.0.rc.2) (2014-09-06)
[Full Changelog](https://github.com/chef/chef/compare/11.16.0.rc.1...11.16.0.rc.2)

**Merged pull requests:**

- Depend on released Ohai 7.4 for Chef 11.16.0.rc.2 [\#2008](https://github.com/chef/chef/pull/2008) ([adamedx](https://github.com/adamedx))
- Port Chef 1982 to 10-stable [\#1989](https://github.com/chef/chef/pull/1989) ([sersut](https://github.com/sersut))
- Use homebrew for default package provider on OS X [\#1921](https://github.com/chef/chef/pull/1921) ([jtimberman](https://github.com/jtimberman))
- Result filtering on search \(also known as Partial Search\) [\#1555](https://github.com/chef/chef/pull/1555) ([scotthain](https://github.com/scotthain))

## [11.16.0.rc.1](https://github.com/chef/chef/tree/11.16.0.rc.1) (2014-09-05)
[Full Changelog](https://github.com/chef/chef/compare/11.16.0.rc.0...11.16.0.rc.1)

**Merged pull requests:**

- Port Chef 1982 DSCL provider [\#1996](https://github.com/chef/chef/pull/1996) ([adamedx](https://github.com/adamedx))
- Print out request and response body on non-2xx response [\#1995](https://github.com/chef/chef/pull/1995) ([jkeiser](https://github.com/jkeiser))
- Update documentation / release notes [\#1990](https://github.com/chef/chef/pull/1990) ([btm](https://github.com/btm))
- Update documentation / release notes [\#1987](https://github.com/chef/chef/pull/1987) ([adamedx](https://github.com/adamedx))
- DscScript resource will raise an error if dsc is not available [\#1985](https://github.com/chef/chef/pull/1985) ([jaym](https://github.com/jaym))
- Fix dscl user provider to be able to manage home and password at the same time. [\#1982](https://github.com/chef/chef/pull/1982) ([sersut](https://github.com/sersut))
- lcm parser is a lot more forgiving [\#1978](https://github.com/chef/chef/pull/1978) ([jaym](https://github.com/jaym))
- configuration\_generator\_spec uses newer rspec conventions [\#1967](https://github.com/chef/chef/pull/1967) ([jaym](https://github.com/jaym))

## [11.16.0.rc.0](https://github.com/chef/chef/tree/11.16.0.rc.0) (2014-09-04)
[Full Changelog](https://github.com/chef/chef/compare/10.34.2...11.16.0.rc.0)

**Merged pull requests:**

- Platform/11 dsc [\#1975](https://github.com/chef/chef/pull/1975) ([btm](https://github.com/btm))
- Check the group membership using dscl on Mac in specs. [\#1973](https://github.com/chef/chef/pull/1973) ([sersut](https://github.com/sersut))
- Cleanup dsc\_script\_spec to use newer rspec conventions [\#1968](https://github.com/chef/chef/pull/1968) ([jaym](https://github.com/jaym))
- DSC resource modules that have not been imported can cause failures [\#1958](https://github.com/chef/chef/pull/1958) ([adamedx](https://github.com/adamedx))
- Fix Windows path bugs, run all config tests against Windows [\#1954](https://github.com/chef/chef/pull/1954) ([adamedx](https://github.com/adamedx))
- Better logging for dsc scripts with multiple resources [\#1952](https://github.com/chef/chef/pull/1952) ([jaym](https://github.com/jaym))
- Switch back to ChefZero::RSpec version 3 [\#1951](https://github.com/chef/chef/pull/1951) ([jkeiser](https://github.com/jkeiser))
- DSC spec platform detection via WMI [\#1949](https://github.com/chef/chef/pull/1949) ([adamedx](https://github.com/adamedx))
- Clean up acl data handler, add username to user handler for cheffish [\#1939](https://github.com/chef/chef/pull/1939) ([jkeiser](https://github.com/jkeiser))
- Remove deprecated @node ivars [\#1938](https://github.com/chef/chef/pull/1938) ([jkeiser](https://github.com/jkeiser))
- response.body may be nil [\#1896](https://github.com/chef/chef/pull/1896) ([lamont-granquist](https://github.com/lamont-granquist))
- Add --ssl-verify-mode and --\[no-\]verify-api-cert options. [\#1895](https://github.com/chef/chef/pull/1895) ([mcquin](https://github.com/mcquin))
- Lcg/1781 [\#1889](https://github.com/chef/chef/pull/1889) ([lamont-granquist](https://github.com/lamont-granquist))
- Make sure to call chef-client and knife that we just built [\#1583](https://github.com/chef/chef/pull/1583) ([juliandunn](https://github.com/juliandunn))

## [10.34.2](https://github.com/chef/chef/tree/10.34.2) (2014-08-21)
[Full Changelog](https://github.com/chef/chef/compare/12.0.0.alpha.1...10.34.2)

## [12.0.0.alpha.1](https://github.com/chef/chef/tree/12.0.0.alpha.1) (2014-08-21)
[Full Changelog](https://github.com/chef/chef/compare/10.34.0...12.0.0.alpha.1)

## [10.34.0](https://github.com/chef/chef/tree/10.34.0) (2014-08-19)
[Full Changelog](https://github.com/chef/chef/compare/11.14.6...10.34.0)

## [11.14.6](https://github.com/chef/chef/tree/11.14.6) (2014-08-18)
[Full Changelog](https://github.com/chef/chef/compare/11.14.4...11.14.6)

## [11.14.4](https://github.com/chef/chef/tree/11.14.4) (2014-08-15)
[Full Changelog](https://github.com/chef/chef/compare/11.14.2...11.14.4)

**Merged pull requests:**

- Don't modify variable passed to env resource when updating [\#1597](https://github.com/chef/chef/pull/1597) ([linkfanel](https://github.com/linkfanel))
- \[CHEF-5356-gcm\(2\)\] Encrypted data bags should use different HMAC key and include the IV in the HMAC [\#1591](https://github.com/chef/chef/pull/1591) ([zuazo](https://github.com/zuazo))
- use systemd for recent fedora and rhel 7 [\#1552](https://github.com/chef/chef/pull/1552) ([jordane](https://github.com/jordane))
- Fix ResourceReporter\#post\_reporting\_data http error handling. Fixes \#1550 [\#1551](https://github.com/chef/chef/pull/1551) ([hltbra](https://github.com/hltbra))
- \[OC-11667\] Don't overwrite the :default provider map if :default is passed as the platform [\#1527](https://github.com/chef/chef/pull/1527) ([ryancragun](https://github.com/ryancragun))
- OC-10832 - AIX - group provider implementation [\#1180](https://github.com/chef/chef/pull/1180) ([kaustubh-d](https://github.com/kaustubh-d))
- \[CHEF-3399\] Make data\_bag\_path an array like cookbook\_path [\#1177](https://github.com/chef/chef/pull/1177) ([xeron](https://github.com/xeron))

## [11.14.2](https://github.com/chef/chef/tree/11.14.2) (2014-07-31)
[Full Changelog](https://github.com/chef/chef/compare/12.0.0.alpha.0...11.14.2)

## [12.0.0.alpha.0](https://github.com/chef/chef/tree/12.0.0.alpha.0) (2014-07-30)
[Full Changelog](https://github.com/chef/chef/compare/11.14.0...12.0.0.alpha.0)

## [11.14.0](https://github.com/chef/chef/tree/11.14.0) (2014-07-30)
[Full Changelog](https://github.com/chef/chef/compare/10.34.0.rc.1...11.14.0)

## [10.34.0.rc.1](https://github.com/chef/chef/tree/10.34.0.rc.1) (2014-07-22)
[Full Changelog](https://github.com/chef/chef/compare/10.34.0.rc.0...10.34.0.rc.1)

**Merged pull requests:**

- remove rest-client gem [\#1409](https://github.com/chef/chef/pull/1409) ([lamont-granquist](https://github.com/lamont-granquist))

## [10.34.0.rc.0](https://github.com/chef/chef/tree/10.34.0.rc.0) (2014-07-17)
[Full Changelog](https://github.com/chef/chef/compare/11.14.0.rc.2...10.34.0.rc.0)

**Merged pull requests:**

- vtolstov: reload service only if it running, if not - start [\#1581](https://github.com/chef/chef/pull/1581) ([mcquin](https://github.com/mcquin))
- Allow lazy attribute defaults in LWRPs [\#1559](https://github.com/chef/chef/pull/1559) ([sethvargo](https://github.com/sethvargo))

## [11.14.0.rc.2](https://github.com/chef/chef/tree/11.14.0.rc.2) (2014-07-02)
[Full Changelog](https://github.com/chef/chef/compare/11.14.0.rc.1...11.14.0.rc.2)

**Merged pull requests:**

- Revert the provider indirection logic in Chef::Provider::Package::Apt. [\#1598](https://github.com/chef/chef/pull/1598) ([sersut](https://github.com/sersut))
- Backport CHEF-5223 to 10-stable [\#1594](https://github.com/chef/chef/pull/1594) ([jaymzh](https://github.com/jaymzh))
- remove inheritance from apt\_package [\#1589](https://github.com/chef/chef/pull/1589) ([lamont-granquist](https://github.com/lamont-granquist))
- Do not update the path in the cookbook\_manifest with the full file name. [\#1588](https://github.com/chef/chef/pull/1588) ([sersut](https://github.com/sersut))
- Disable upstart provider on ubuntu \>= 13.10. [\#1582](https://github.com/chef/chef/pull/1582) ([sersut](https://github.com/sersut))
- Add missing requires to HTTP and HTTP::Simple [\#1575](https://github.com/chef/chef/pull/1575) ([danielsdeleo](https://github.com/danielsdeleo))
- Add note about office hours to CONTRIBUTING.md [\#1573](https://github.com/chef/chef/pull/1573) ([btm](https://github.com/btm))
- Pick the ffi version compliant ohai version. [\#1572](https://github.com/chef/chef/pull/1572) ([sersut](https://github.com/sersut))
- Chef 4994: knife cookbook site share fails on windows [\#1565](https://github.com/chef/chef/pull/1565) ([jmink](https://github.com/jmink))
- Add shell\_out\_with\_systems\_locale to ShellOut [\#1548](https://github.com/chef/chef/pull/1548) ([mcquin](https://github.com/mcquin))

## [11.14.0.rc.1](https://github.com/chef/chef/tree/11.14.0.rc.1) (2014-06-27)
[Full Changelog](https://github.com/chef/chef/compare/11.14.0.rc.0...11.14.0.rc.1)

## [11.14.0.rc.0](https://github.com/chef/chef/tree/11.14.0.rc.0) (2014-06-27)
[Full Changelog](https://github.com/chef/chef/compare/11.14.0.alpha.4...11.14.0.rc.0)

**Merged pull requests:**

- Merge master into 11-stable for 11.14.0 release. [\#1571](https://github.com/chef/chef/pull/1571) ([sersut](https://github.com/sersut))
- Change --yum-lock-timeout option action to store. [\#1564](https://github.com/chef/chef/pull/1564) ([mcquin](https://github.com/mcquin))
- Only check WOW64 process when system architecture is x64. [\#1560](https://github.com/chef/chef/pull/1560) ([sersut](https://github.com/sersut))
- Delegate DSL method values to their superclass [\#1553](https://github.com/chef/chef/pull/1553) ([sethvargo](https://github.com/sethvargo))
- Remove confusing gemspec comment about the no-longer-used json gem [\#1547](https://github.com/chef/chef/pull/1547) ([juliandunn](https://github.com/juliandunn))
- replace ruby-yajl with ffi-yajl gem  [\#1540](https://github.com/chef/chef/pull/1540) ([lamont-granquist](https://github.com/lamont-granquist))
- CHEF-5287: batch resource: can't convert nil into String due to invalid ENV hash [\#1531](https://github.com/chef/chef/pull/1531) ([adamedx](https://github.com/adamedx))
- CHEF-5158: Prefer CLI argument over configuration file setting for ssh\_attribute [\#1530](https://github.com/chef/chef/pull/1530) ([btm](https://github.com/btm))
- Bump ffi version since chef-dk depends on chef and dep-selector and dep-selector uses ~\> 1.9. [\#1528](https://github.com/chef/chef/pull/1528) ([sersut](https://github.com/sersut))
- remove setting proxy environment variables [\#1526](https://github.com/chef/chef/pull/1526) ([mcquin](https://github.com/mcquin))
- Use FFI binders to attach :SendMessageTimeout instead of Win32API in ord... [\#1525](https://github.com/chef/chef/pull/1525) ([mcquin](https://github.com/mcquin))
- Allow cssh\(X\) to respect identity\_file [\#1520](https://github.com/chef/chef/pull/1520) ([curiositycasualty](https://github.com/curiositycasualty))
- \[chef\_fs/file\_system\] Ignore missing entry at destination when purging [\#1519](https://github.com/chef/chef/pull/1519) ([stevendanna](https://github.com/stevendanna))
- Updated changelog [\#1502](https://github.com/chef/chef/pull/1502) ([scotthain](https://github.com/scotthain))
- Updated tests with more complicated data, fixed regex [\#1501](https://github.com/chef/chef/pull/1501) ([scotthain](https://github.com/scotthain))
- Updated selinux path check to allow for directories that have a space in... [\#1500](https://github.com/chef/chef/pull/1500) ([scotthain](https://github.com/scotthain))
- Update the expired cert for specs. [\#1498](https://github.com/chef/chef/pull/1498) ([sersut](https://github.com/sersut))
- \[trivial\] typo [\#1497](https://github.com/chef/chef/pull/1497) ([atomic-penguin](https://github.com/atomic-penguin))
- CHEF-5365 - chef local crashes if home directory is not set [\#1494](https://github.com/chef/chef/pull/1494) ([brettcave](https://github.com/brettcave))
- update for today's merges [\#1493](https://github.com/chef/chef/pull/1493) ([mcquin](https://github.com/mcquin))
- Skip all unsupported platforms in remount test [\#1489](https://github.com/chef/chef/pull/1489) ([danielsdeleo](https://github.com/danielsdeleo))
- \[CHEF-5366\] Install on ArchLinux as a system gem explicitly [\#1487](https://github.com/chef/chef/pull/1487) ([aespinosa](https://github.com/aespinosa))
- update for merges [\#1486](https://github.com/chef/chef/pull/1486) ([mcquin](https://github.com/mcquin))
- Chef 4600 [\#1483](https://github.com/chef/chef/pull/1483) ([mcquin](https://github.com/mcquin))
- Add .project to .gitignore [\#1482](https://github.com/chef/chef/pull/1482) ([ekrupnik](https://github.com/ekrupnik))
- update for merges [\#1480](https://github.com/chef/chef/pull/1480) ([mcquin](https://github.com/mcquin))
- chef community merges [\#1478](https://github.com/chef/chef/pull/1478) ([mcquin](https://github.com/mcquin))
- CHEF-5347: Allow for undefined solaris services in the service resource. [\#1477](https://github.com/chef/chef/pull/1477) ([MarkGibbons](https://github.com/MarkGibbons))
- Fix CHEF-5355. Don't pass on default HTTP port \(80\) in Host header. \[rebased on master\] [\#1471](https://github.com/chef/chef/pull/1471) ([kjwierenga](https://github.com/kjwierenga))
- save non-utf-8 encodable registry key data to node as an md5 checksum [\#1470](https://github.com/chef/chef/pull/1470) ([mcquin](https://github.com/mcquin))
- \[CHEF-5168\] Apt Package provider times out [\#1462](https://github.com/chef/chef/pull/1462) ([pdf](https://github.com/pdf))
- \[CHEF-5328\] Chef::User.list API error with inflate=true  [\#1456](https://github.com/chef/chef/pull/1456) ([zuazo](https://github.com/zuazo))
- Only modify password when one has been specified [\#1455](https://github.com/chef/chef/pull/1455) ([anandsuresh](https://github.com/anandsuresh))
- \[CHEF-5314\] Support override\_runlist CLI option in shef/chef-shell [\#1444](https://github.com/chef/chef/pull/1444) ([ryancragun](https://github.com/ryancragun))
- \[CHEF-5314\] Support override\_runlist CLI option in shef/chef-shell [\#1443](https://github.com/chef/chef/pull/1443) ([ryancragun](https://github.com/ryancragun))
- \[CHEF-5309\] add exception that happens nowadays when JSON parsing fails [\#1439](https://github.com/chef/chef/pull/1439) ([srenatus](https://github.com/srenatus))
- CHEF-3193: LOCK\_TIMEOUT in yum-dump.py should be configurable [\#1436](https://github.com/chef/chef/pull/1436) ([kramvan1](https://github.com/kramvan1))
- git resource status checking saves 1 shell\_out system call [\#1425](https://github.com/chef/chef/pull/1425) ([rvalyi](https://github.com/rvalyi))
- CHEF-5247: Fix Useradd\#manage\_user backdoor [\#1423](https://github.com/chef/chef/pull/1423) ([btm](https://github.com/btm))
- CHEF-5265 - upstart service not working correctly when called with parameters [\#1418](https://github.com/chef/chef/pull/1418) ([tarrall](https://github.com/tarrall))
- next try to add exherbo linux support [\#1414](https://github.com/chef/chef/pull/1414) ([vtolstov](https://github.com/vtolstov))
- CHEF-5276, use upstart on ubuntu 13.10+ [\#1412](https://github.com/chef/chef/pull/1412) ([jtimberman](https://github.com/jtimberman))
- CHEF-5273 - Corretly detect when rpm\_package does not exist in upgrade action [\#1407](https://github.com/chef/chef/pull/1407) ([robbydyer](https://github.com/robbydyer))
- \[CHEF-4224\] tracing? throws an exception when chef-shell is first started [\#1404](https://github.com/chef/chef/pull/1404) ([juliandunn](https://github.com/juliandunn))
- CHEF-5261 Added some tests to prevent double slashes [\#1396](https://github.com/chef/chef/pull/1396) ([svanharmelen](https://github.com/svanharmelen))
- Warning if target hostname resembles "knife bootstrap windows winrm" command. [\#1364](https://github.com/chef/chef/pull/1364) ([curiositycasualty](https://github.com/curiositycasualty))
- Fix resource\_spec.rb: it's only\_if and not\_if [\#1263](https://github.com/chef/chef/pull/1263) ([srenatus](https://github.com/srenatus))
- OC-9954 - aix: use 'guest' user for rspec tests instead of 'nobody' user... [\#1164](https://github.com/chef/chef/pull/1164) ([kaustubh-d](https://github.com/kaustubh-d))
- CHEF-4778: Doc fix to highlight that -E is not respected by knife ssh \[search\]  [\#1130](https://github.com/chef/chef/pull/1130) ([philsturgeon](https://github.com/philsturgeon))
- Add Code Climate badge to README [\#1039](https://github.com/chef/chef/pull/1039) ([mrb](https://github.com/mrb))
- \[CHEF-4562\] Remove leading underscore [\#1000](https://github.com/chef/chef/pull/1000) ([ljagiello](https://github.com/ljagiello))
- \[CHEF-4298\] dependencies in metadata.rb require a space [\#848](https://github.com/chef/chef/pull/848) ([zuazo](https://github.com/zuazo))
- \[CHEF-4193\] Enabling storage of roles in subdirectories [\#759](https://github.com/chef/chef/pull/759) ([bensomers](https://github.com/bensomers))
- \[CHEF-3637\] Add support for automatically using the Systemd service provider [\#506](https://github.com/chef/chef/pull/506) ([ctennis](https://github.com/ctennis))

## [11.14.0.alpha.4](https://github.com/chef/chef/tree/11.14.0.alpha.4) (2014-06-06)
[Full Changelog](https://github.com/chef/chef/compare/11.12.8...11.14.0.alpha.4)

**Merged pull requests:**

- Delete duplicate :host default [\#1475](https://github.com/chef/chef/pull/1475) ([jkeiser](https://github.com/jkeiser))

## [11.12.8](https://github.com/chef/chef/tree/11.12.8) (2014-06-05)
[Full Changelog](https://github.com/chef/chef/compare/11.12.6...11.12.8)

**Merged pull requests:**

- Pin chef-zero to \< 2.1 in order not to pick up default port changes in chef-zero 2.1.x [\#1473](https://github.com/chef/chef/pull/1473) ([sersut](https://github.com/sersut))
- Update CONTRIBUTING.md per new Github process. [\#1463](https://github.com/chef/chef/pull/1463) ([sersut](https://github.com/sersut))
- CHEF-5322: Add utility for validating Windows paths [\#1449](https://github.com/chef/chef/pull/1449) ([btm](https://github.com/btm))

## [11.12.6](https://github.com/chef/chef/tree/11.12.6) (2014-06-05)
[Full Changelog](https://github.com/chef/chef/compare/11.14.0.alpha.3...11.12.6)

**Merged pull requests:**

- fix for rspec 2.99 [\#1469](https://github.com/chef/chef/pull/1469) ([lamont-granquist](https://github.com/lamont-granquist))
- Do not wait for clean exit when Exception is thrown [\#1467](https://github.com/chef/chef/pull/1467) ([jkeiser](https://github.com/jkeiser))
- omnios uses solaris2-like usermod for groups [\#1466](https://github.com/chef/chef/pull/1466) ([rjbs](https://github.com/rjbs))
- automatically enable verify\_api\_cert when in local-mode [\#1464](https://github.com/chef/chef/pull/1464) ([mcquin](https://github.com/mcquin))
- set ENV vars for http proxies [\#1459](https://github.com/chef/chef/pull/1459) ([mcquin](https://github.com/mcquin))
- Add mount provider for Solaris OS and derivates [\#1451](https://github.com/chef/chef/pull/1451) ([lamont-granquist](https://github.com/lamont-granquist))

## [11.14.0.alpha.3](https://github.com/chef/chef/tree/11.14.0.alpha.3) (2014-05-30)
[Full Changelog](https://github.com/chef/chef/compare/11.14.0.alpha.2...11.14.0.alpha.3)

**Merged pull requests:**

- Add "knife serve" to serve up chef repo in chef-zero [\#1458](https://github.com/chef/chef/pull/1458) ([jkeiser](https://github.com/jkeiser))
- Fix some mount provider rage [\#1454](https://github.com/chef/chef/pull/1454) ([lamont-granquist](https://github.com/lamont-granquist))
- Updates to CHANGELOG and CONTRIBUTIONS [\#1450](https://github.com/chef/chef/pull/1450) ([sersut](https://github.com/sersut))
- Remove unneeded requires when using CookbookVersionLoader [\#1445](https://github.com/chef/chef/pull/1445) ([danielsdeleo](https://github.com/danielsdeleo))
- Put cache at HOME/.chef if /var/chef can't be accessed. [\#1442](https://github.com/chef/chef/pull/1442) ([mcquin](https://github.com/mcquin))
- Parallelizer improvements [\#1440](https://github.com/chef/chef/pull/1440) ([jkeiser](https://github.com/jkeiser))
- Replace ruby-wmi dependency with wmi-lite to address Ruby 2.0 faults [\#1435](https://github.com/chef/chef/pull/1435) ([adamedx](https://github.com/adamedx))
- Cookbook synchronization speedup \(CHEF-4423\) [\#1434](https://github.com/chef/chef/pull/1434) ([mcquin](https://github.com/mcquin))
- CHEF-4911: Use the :bootstrap\_version if set by the user. [\#1432](https://github.com/chef/chef/pull/1432) ([sersut](https://github.com/sersut))
- add whitelist config options for attributes saved by the node [\#1431](https://github.com/chef/chef/pull/1431) ([mcquin](https://github.com/mcquin))
- \[CHEF-5289\] Remove 'Opscode' from service description [\#1422](https://github.com/chef/chef/pull/1422) ([juliandunn](https://github.com/juliandunn))
- CHEF-4637 - Add support for the new generation FreeBSD package manager [\#1421](https://github.com/chef/chef/pull/1421) ([sersut](https://github.com/sersut))
- Give -p option to install.sh if we are bootstrapping a pre-release version [\#1420](https://github.com/chef/chef/pull/1420) ([sersut](https://github.com/sersut))
- add knife options for chef-full customization [\#1419](https://github.com/chef/chef/pull/1419) ([mcquin](https://github.com/mcquin))
- Contribution information for some tickets. [\#1417](https://github.com/chef/chef/pull/1417) ([sersut](https://github.com/sersut))
- \[CHEF-5269\] Added additional ruby environment files to .gitignore. [\#1403](https://github.com/chef/chef/pull/1403) ([alex-ethier](https://github.com/alex-ethier))
- Lcg/chef 5015 [\#1383](https://github.com/chef/chef/pull/1383) ([lamont-granquist](https://github.com/lamont-granquist))
- \[CHEF-5163\] Support lazy evaluation the mount resource's options attr [\#1366](https://github.com/chef/chef/pull/1366) ([stevendanna](https://github.com/stevendanna))
- \[CHEF-5163\] Support lazy evaluation the mount resource's options attr [\#1356](https://github.com/chef/chef/pull/1356) ([stevendanna](https://github.com/stevendanna))
- Don't eat the authentication failed exception on bootstrap [\#1333](https://github.com/chef/chef/pull/1333) ([hongbin](https://github.com/hongbin))
- CHEF-5092: chef\_gem should use omnibus `gem` binary [\#1300](https://github.com/chef/chef/pull/1300) ([lamont-granquist](https://github.com/lamont-granquist))
- Enable Travis CI notifications [\#1287](https://github.com/chef/chef/pull/1287) ([schisamo](https://github.com/schisamo))
- CHEF-4791 Add more windows service states to the start/stop control flow [\#1166](https://github.com/chef/chef/pull/1166) ([deployable](https://github.com/deployable))
- OC-9274 - Knife bootstrap support for AIX [\#1032](https://github.com/chef/chef/pull/1032) ([kaustubh-d](https://github.com/kaustubh-d))

## [11.14.0.alpha.2](https://github.com/chef/chef/tree/11.14.0.alpha.2) (2014-05-07)
[Full Changelog](https://github.com/chef/chef/compare/11.12.4...11.14.0.alpha.2)

**Merged pull requests:**

- Fix issue with tests and Windows line endings [\#1413](https://github.com/chef/chef/pull/1413) ([jkeiser](https://github.com/jkeiser))
- \[CHEF-4636\] Removed dead code [\#1406](https://github.com/chef/chef/pull/1406) ([alex-ethier](https://github.com/alex-ethier))
- Add option to abandon chef run if blocked by another for too long. [\#1401](https://github.com/chef/chef/pull/1401) ([mcquin](https://github.com/mcquin))
- Switch to ruby 2.1.1 to workaround travis rvm issue [\#1400](https://github.com/chef/chef/pull/1400) ([danielsdeleo](https://github.com/danielsdeleo))
- Bump win32-api to a ruby 2.0 compatible version [\#1399](https://github.com/chef/chef/pull/1399) ([danielsdeleo](https://github.com/danielsdeleo))
- collect :user\_home at correct time, for windows [\#1398](https://github.com/chef/chef/pull/1398) ([mcquin](https://github.com/mcquin))
- Make command output indentable [\#1397](https://github.com/chef/chef/pull/1397) ([jkeiser](https://github.com/jkeiser))

## [11.12.4](https://github.com/chef/chef/tree/11.12.4) (2014-04-30)
[Full Changelog](https://github.com/chef/chef/compare/11.12.4.rc.2...11.12.4)

**Merged pull requests:**

- Contribution info for CC-113 [\#1394](https://github.com/chef/chef/pull/1394) ([sersut](https://github.com/sersut))
- \[CHEF-5180\] For consistency, use the username attribute to print the name of the resource in why-run mode. [\#1357](https://github.com/chef/chef/pull/1357) ([juliandunn](https://github.com/juliandunn))
- Fixed environment chop -\> chomp issue which truncated single character e... [\#1349](https://github.com/chef/chef/pull/1349) ([viyh](https://github.com/viyh))

## [11.12.4.rc.2](https://github.com/chef/chef/tree/11.12.4.rc.2) (2014-04-29)
[Full Changelog](https://github.com/chef/chef/compare/11.12.4.rc.1...11.12.4.rc.2)

**Merged pull requests:**

- Make it possible to include Chef::Provider / Chef::Resource [\#1392](https://github.com/chef/chef/pull/1392) ([jkeiser](https://github.com/jkeiser))
- Tidy tests [\#1391](https://github.com/chef/chef/pull/1391) ([danielsdeleo](https://github.com/danielsdeleo))
- Get local mode passing against Pedant [\#1386](https://github.com/chef/chef/pull/1386) ([jkeiser](https://github.com/jkeiser))

## [11.12.4.rc.1](https://github.com/chef/chef/tree/11.12.4.rc.1) (2014-04-23)
[Full Changelog](https://github.com/chef/chef/compare/11.12.4.rc.0...11.12.4.rc.1)

**Merged pull requests:**

- CHEF-5211: fix configure hostname guessing [\#1389](https://github.com/chef/chef/pull/1389) ([lamont-granquist](https://github.com/lamont-granquist))

## [11.12.4.rc.0](https://github.com/chef/chef/tree/11.12.4.rc.0) (2014-04-23)
[Full Changelog](https://github.com/chef/chef/compare/11.12.2...11.12.4.rc.0)

**Merged pull requests:**

- Merge for release 11.12.4.rc.0 [\#1388](https://github.com/chef/chef/pull/1388) ([adamedx](https://github.com/adamedx))
- CHEF-5211: 'knife configure --initial' fails to load 'os' and 'hostname' ohai plugins properly [\#1387](https://github.com/chef/chef/pull/1387) ([adamedx](https://github.com/adamedx))
- CHEF-5100: moar func tests [\#1385](https://github.com/chef/chef/pull/1385) ([lamont-granquist](https://github.com/lamont-granquist))
- Make OS X service resource work when the plist doesn't exist yet. [\#1380](https://github.com/chef/chef/pull/1380) ([danielsdeleo](https://github.com/danielsdeleo))
- CHEF-5198: adding func tests for Chef::HTTP clients [\#1377](https://github.com/chef/chef/pull/1377) ([lamont-granquist](https://github.com/lamont-granquist))
- Use the released versions of mixlib-shellout and ohai. [\#1376](https://github.com/chef/chef/pull/1376) ([sersut](https://github.com/sersut))
- CHEF-5198: add func tests for remote\_file [\#1370](https://github.com/chef/chef/pull/1370) ([lamont-granquist](https://github.com/lamont-granquist))
- CHEF-5116 - Catch HTTPServerException for 404 in remote\_file retry [\#1358](https://github.com/chef/chef/pull/1358) ([johntdyer](https://github.com/johntdyer))

## [11.12.2](https://github.com/chef/chef/tree/11.12.2) (2014-04-09)
[Full Changelog](https://github.com/chef/chef/compare/10.32.2...11.12.2)

**Merged pull requests:**

- CHEF-5198: a better fix [\#1369](https://github.com/chef/chef/pull/1369) ([lamont-granquist](https://github.com/lamont-granquist))
- reorder middleware in chef::http::simple [\#1368](https://github.com/chef/chef/pull/1368) ([lamont-granquist](https://github.com/lamont-granquist))
- Wrap code in an instance\_eval context for syntax check. [\#1367](https://github.com/chef/chef/pull/1367) ([danielsdeleo](https://github.com/danielsdeleo))

## [10.32.2](https://github.com/chef/chef/tree/10.32.2) (2014-04-09)
[Full Changelog](https://github.com/chef/chef/compare/10.32.0...10.32.2)

**Merged pull requests:**

- pin sdoc to make solaris builds happy [\#1365](https://github.com/chef/chef/pull/1365) ([lamont-granquist](https://github.com/lamont-granquist))

## [10.32.0](https://github.com/chef/chef/tree/10.32.0) (2014-04-08)
[Full Changelog](https://github.com/chef/chef/compare/11.12.0...10.32.0)

## [11.12.0](https://github.com/chef/chef/tree/11.12.0) (2014-04-08)
[Full Changelog](https://github.com/chef/chef/compare/11.14.0.alpha.1...11.12.0)

**Merged pull requests:**

- \[CHEF-4632\] backport \#1179 - bump up upper limit on json gem to 1.8.1 [\#1363](https://github.com/chef/chef/pull/1363) ([jaymzh](https://github.com/jaymzh))
- CHEF-5189 Correct link provider debug output [\#1362](https://github.com/chef/chef/pull/1362) ([jeremiahsnapp](https://github.com/jeremiahsnapp))

## [11.14.0.alpha.1](https://github.com/chef/chef/tree/11.14.0.alpha.1) (2014-04-07)
[Full Changelog](https://github.com/chef/chef/compare/11.12.0.rc.2...11.14.0.alpha.1)

## [11.12.0.rc.2](https://github.com/chef/chef/tree/11.12.0.rc.2) (2014-04-04)
[Full Changelog](https://github.com/chef/chef/compare/10.32.0.rc.1...11.12.0.rc.2)

**Merged pull requests:**

- \[11\] Don't catch SIGTERM if not in daemon mode [\#1315](https://github.com/chef/chef/pull/1315) ([jaymzh](https://github.com/jaymzh))
- \[10-stable\] Don't trap TERM if not in daemon mode [\#1314](https://github.com/chef/chef/pull/1314) ([jaymzh](https://github.com/jaymzh))

## [10.32.0.rc.1](https://github.com/chef/chef/tree/10.32.0.rc.1) (2014-04-01)
[Full Changelog](https://github.com/chef/chef/compare/11.12.0.rc.1...10.32.0.rc.1)

## [11.12.0.rc.1](https://github.com/chef/chef/tree/11.12.0.rc.1) (2014-03-31)
[Full Changelog](https://github.com/chef/chef/compare/10.32.0.rc.0...11.12.0.rc.1)

**Merged pull requests:**

- added require for config\_fetcher: CHEF-5169 [\#1354](https://github.com/chef/chef/pull/1354) ([josephrdsmith](https://github.com/josephrdsmith))
- Fix / Mark volatile the transient failures on Solaris. [\#1353](https://github.com/chef/chef/pull/1353) ([sersut](https://github.com/sersut))
- CVT: Mount spec should use File::expand\_path for symmetry on Windows [\#1352](https://github.com/chef/chef/pull/1352) ([adamedx](https://github.com/adamedx))

## [10.32.0.rc.0](https://github.com/chef/chef/tree/10.32.0.rc.0) (2014-03-31)
[Full Changelog](https://github.com/chef/chef/compare/11.14.0.alpha.0...10.32.0.rc.0)

## [11.14.0.alpha.0](https://github.com/chef/chef/tree/11.14.0.alpha.0) (2014-03-30)
[Full Changelog](https://github.com/chef/chef/compare/11.12.0.rc.0...11.14.0.alpha.0)

## [11.12.0.rc.0](https://github.com/chef/chef/tree/11.12.0.rc.0) (2014-03-30)
[Full Changelog](https://github.com/chef/chef/compare/11.12.0.alpha.1...11.12.0.rc.0)

**Merged pull requests:**

- Fix Windows 2003 CI issues [\#1348](https://github.com/chef/chef/pull/1348) ([sersut](https://github.com/sersut))
- CHEF-5015 force\_unlink should only unlink if the file exists [\#1347](https://github.com/chef/chef/pull/1347) ([jeremiahsnapp](https://github.com/jeremiahsnapp))
- Chef 4373 10x [\#1345](https://github.com/chef/chef/pull/1345) ([danielsdeleo](https://github.com/danielsdeleo))
- Fix unit tests to not access /etc/chef/encrypted\_data\_bag\_secret [\#1342](https://github.com/chef/chef/pull/1342) ([danielsdeleo](https://github.com/danielsdeleo))
- Restore shadowing warning [\#1341](https://github.com/chef/chef/pull/1341) ([danielsdeleo](https://github.com/danielsdeleo))
- Fix few typo [\#1339](https://github.com/chef/chef/pull/1339) ([nishigori](https://github.com/nishigori))
- Chef 4373 [\#1338](https://github.com/chef/chef/pull/1338) ([danielsdeleo](https://github.com/danielsdeleo))
- Restrict rake to 10.1.x because ruby 1.8 support was dropped in 10.2 [\#1336](https://github.com/chef/chef/pull/1336) ([danielsdeleo](https://github.com/danielsdeleo))
- Rescue TypeError duping un-dupable types in deep merge [\#1335](https://github.com/chef/chef/pull/1335) ([danielsdeleo](https://github.com/danielsdeleo))
- CHEF-4888: Call WIN32OLE.ole\_initialize in sub-threads [\#1334](https://github.com/chef/chef/pull/1334) ([btm](https://github.com/btm))
- Chef 5134 [\#1331](https://github.com/chef/chef/pull/1331) ([danielsdeleo](https://github.com/danielsdeleo))
- Lcg/chef 5041 content length [\#1329](https://github.com/chef/chef/pull/1329) ([lamont-granquist](https://github.com/lamont-granquist))
- CHEF-5087: Add Windows Installer package provider [\#1328](https://github.com/chef/chef/pull/1328) ([btm](https://github.com/btm))
- Community contributions merge [\#1327](https://github.com/chef/chef/pull/1327) ([btm](https://github.com/btm))
- Remove Usermod group provider from Suse after fixing OHAI-339. [\#1325](https://github.com/chef/chef/pull/1325) ([sersut](https://github.com/sersut))
- CHEF-5057: Allow confirm prompt to have a default choice [\#1324](https://github.com/chef/chef/pull/1324) ([sersut](https://github.com/sersut))
- CC-53: More contribution info. [\#1322](https://github.com/chef/chef/pull/1322) ([sersut](https://github.com/sersut))
- CHEF-3714: add a file\_edited? method [\#1321](https://github.com/chef/chef/pull/1321) ([btm](https://github.com/btm))
- CC-52: Contribution information for the tickets merged from community. [\#1320](https://github.com/chef/chef/pull/1320) ([sersut](https://github.com/sersut))
- \[10-stable\] Fix crashes on invalid cache files [\#1319](https://github.com/chef/chef/pull/1319) ([jaymzh](https://github.com/jaymzh))
- Contributions merge [\#1318](https://github.com/chef/chef/pull/1318) ([btm](https://github.com/btm))
- CHEF-4553: Guard interpreter and powershell boolean awareness [\#1316](https://github.com/chef/chef/pull/1316) ([adamedx](https://github.com/adamedx))
- CHEF-3698: Do not set log\_level by default [\#1310](https://github.com/chef/chef/pull/1310) ([btm](https://github.com/btm))
- Don't honor splay setting when sent USR1 signal. [\#1308](https://github.com/chef/chef/pull/1308) ([sersut](https://github.com/sersut))
- Logic proposal for --force flag to delete the validators during client bulk delete. [\#1306](https://github.com/chef/chef/pull/1306) ([sersut](https://github.com/sersut))
- Emit a warning when loading recipe from cookbooks not in dependency graph \[CHEF-4367\] [\#1302](https://github.com/chef/chef/pull/1302) ([danielsdeleo](https://github.com/danielsdeleo))
- \[CHEF-5118\] Add docs for Chef::EncryptedDataBag.load [\#1301](https://github.com/chef/chef/pull/1301) ([sethvargo](https://github.com/sethvargo))
- CHEF-5064: ensure Chef::REST does not modify options in-place [\#1280](https://github.com/chef/chef/pull/1280) ([josephholsten](https://github.com/josephholsten))
- \[CHEF-5037\] default to IPS packages on Solaris 5.11+ [\#1268](https://github.com/chef/chef/pull/1268) ([ccope](https://github.com/ccope))
- \[CHEF-5017\]\[Chef::Mixin::ShellOut\] Create a method to get IO for live stream. [\#1260](https://github.com/chef/chef/pull/1260) ([ryotarai](https://github.com/ryotarai))
- Update to allow boolean and numeric attributes [\#1245](https://github.com/chef/chef/pull/1245) ([slantview](https://github.com/slantview))
- CHEF-4990 Fix provider for the state of 'maintenance' Solaris  services. [\#1235](https://github.com/chef/chef/pull/1235) ([sawanoboly](https://github.com/sawanoboly))
- CHEF-4962, knife ssh will use a cloud attribute for port if available. [\#1213](https://github.com/chef/chef/pull/1213) ([jeffmendoza](https://github.com/jeffmendoza))
- Correct the Arch Linux mapping to use Systemd Service Provider [\#1191](https://github.com/chef/chef/pull/1191) ([andreasrs](https://github.com/andreasrs))
- CHEF-4643 Add cookbook versions to chef-client INFO and DEBUG logs [\#1059](https://github.com/chef/chef/pull/1059) ([jeremiahsnapp](https://github.com/jeremiahsnapp))
- CHEF-4443 - Always save the correct run list [\#948](https://github.com/chef/chef/pull/948) ([thommay](https://github.com/thommay))

## [11.12.0.alpha.1](https://github.com/chef/chef/tree/11.12.0.alpha.1) (2014-03-14)
[Full Changelog](https://github.com/chef/chef/compare/11.10.4.ohai7.0...11.12.0.alpha.1)

**Merged pull requests:**

- CC-51: Merging Chef Contributions. [\#1299](https://github.com/chef/chef/pull/1299) ([sersut](https://github.com/sersut))
- Make the initial  bootstrap message more user friendly. [\#1295](https://github.com/chef/chef/pull/1295) ([sersut](https://github.com/sersut))
- Upgrade ohai to 7.0.0.rc.0. [\#1294](https://github.com/chef/chef/pull/1294) ([sersut](https://github.com/sersut))
- Add enable/disable to MacOSX service provider [\#1292](https://github.com/chef/chef/pull/1292) ([jaymzh](https://github.com/jaymzh))
- New policy files for Chef 10.x branch. [\#1291](https://github.com/chef/chef/pull/1291) ([sersut](https://github.com/sersut))
- Update md files for three merged issues [\#1290](https://github.com/chef/chef/pull/1290) ([lamont-granquist](https://github.com/lamont-granquist))
- CHEF-5030:  improve debian ifconfig provider code [\#1289](https://github.com/chef/chef/pull/1289) ([lamont-granquist](https://github.com/lamont-granquist))
- New policy files for Chef Client. [\#1285](https://github.com/chef/chef/pull/1285) ([sersut](https://github.com/sersut))
- CouchDB Creation Speedup [\#1284](https://github.com/chef/chef/pull/1284) ([sdelano](https://github.com/sdelano))
- Add enable/disable to MacOSX service provider [\#1267](https://github.com/chef/chef/pull/1267) ([jaymzh](https://github.com/jaymzh))
- CHEF-5001: tests for multiple rollbacks [\#1254](https://github.com/chef/chef/pull/1254) ([lamont-granquist](https://github.com/lamont-granquist))
- add ohai\[:machinename\] [\#1216](https://github.com/chef/chef/pull/1216) ([lamont-granquist](https://github.com/lamont-granquist))
- CHEF-4773: ruby-shadow supports darwin+freebsd now [\#1126](https://github.com/chef/chef/pull/1126) ([lamont-granquist](https://github.com/lamont-granquist))

## [11.10.4.ohai7.0](https://github.com/chef/chef/tree/11.10.4.ohai7.0) (2014-02-25)
[Full Changelog](https://github.com/chef/chef/compare/11.10.4...11.10.4.ohai7.0)

**Merged pull requests:**

- Add a --force option to protect against accidental deletion of validators [\#1272](https://github.com/chef/chef/pull/1272) ([jamesc](https://github.com/jamesc))
- New command line option for knife client create to create validator [\#1270](https://github.com/chef/chef/pull/1270) ([jamesc](https://github.com/jamesc))
- knife client show does not show validator/admin correctly [\#1269](https://github.com/chef/chef/pull/1269) ([jamesc](https://github.com/jamesc))

## [11.10.4](https://github.com/chef/chef/tree/11.10.4) (2014-02-20)
[Full Changelog](https://github.com/chef/chef/compare/11.10.4.rc.0...11.10.4)

**Merged pull requests:**

- Add an note about addtional bootstrap templates being deprecated [\#1274](https://github.com/chef/chef/pull/1274) ([btm](https://github.com/btm))

## [11.10.4.rc.0](https://github.com/chef/chef/tree/11.10.4.rc.0) (2014-02-20)
[Full Changelog](https://github.com/chef/chef/compare/10.30.4...11.10.4.rc.0)

**Merged pull requests:**

- Correctly order setup of reporting state in registry specs [\#1277](https://github.com/chef/chef/pull/1277) ([danielsdeleo](https://github.com/danielsdeleo))
- CHEF-5052 Correctly set cookbook\_name and recipe\_name when cloning [\#1275](https://github.com/chef/chef/pull/1275) ([danielsdeleo](https://github.com/danielsdeleo))
- CHEF-5032 Add permanent run list modification CLI option [\#1271](https://github.com/chef/chef/pull/1271) ([danielsdeleo](https://github.com/danielsdeleo))

## [10.30.4](https://github.com/chef/chef/tree/10.30.4) (2014-02-17)
[Full Changelog](https://github.com/chef/chef/compare/11.10.2...10.30.4)

## [11.10.2](https://github.com/chef/chef/tree/11.10.2) (2014-02-17)
[Full Changelog](https://github.com/chef/chef/compare/10.30.4.rc.0...11.10.2)

## [10.30.4.rc.0](https://github.com/chef/chef/tree/10.30.4.rc.0) (2014-02-14)
[Full Changelog](https://github.com/chef/chef/compare/11.10.2.rc.0...10.30.4.rc.0)

## [11.10.2.rc.0](https://github.com/chef/chef/tree/11.10.2.rc.0) (2014-02-14)
[Full Changelog](https://github.com/chef/chef/compare/11.10.0...11.10.2.rc.0)

**Merged pull requests:**

- Contributions merge [\#1323](https://github.com/chef/chef/pull/1323) ([btm](https://github.com/btm))
- Lcg/chef 5018 [\#1262](https://github.com/chef/chef/pull/1262) ([lamont-granquist](https://github.com/lamont-granquist))
- Jc/backport event handlers config [\#1258](https://github.com/chef/chef/pull/1258) ([jamesc](https://github.com/jamesc))
- Localize rescues in Recipe method\_missing DSL [\#1256](https://github.com/chef/chef/pull/1256) ([danielsdeleo](https://github.com/danielsdeleo))
- Adding request\_id to the set of headers for every request that will be sent to erchef [\#1236](https://github.com/chef/chef/pull/1236) ([PrajaktaPurohit](https://github.com/PrajaktaPurohit))

## [11.10.0](https://github.com/chef/chef/tree/11.10.0) (2014-02-06)
[Full Changelog](https://github.com/chef/chef/compare/11.10.0.rc.1...11.10.0)

**Merged pull requests:**

- Use RubyVM to syntax check in-process where possible [\#1252](https://github.com/chef/chef/pull/1252) ([danielsdeleo](https://github.com/danielsdeleo))

## [11.10.0.rc.1](https://github.com/chef/chef/tree/11.10.0.rc.1) (2014-02-05)
[Full Changelog](https://github.com/chef/chef/compare/11.10.0.rc.0...11.10.0.rc.1)

**Merged pull requests:**

- OC-11191: Workaround for apparent memory leak in CHEF-5004 [\#1251](https://github.com/chef/chef/pull/1251) ([adamedx](https://github.com/adamedx))
- \[CHEF-3506\] suppress final node save when using override run list [\#1248](https://github.com/chef/chef/pull/1248) ([danielsdeleo](https://github.com/danielsdeleo))
- Delegate sync\_cookbooks to policy\_builder, subclasses rely on it [\#1247](https://github.com/chef/chef/pull/1247) ([danielsdeleo](https://github.com/danielsdeleo))
- Make sure --concurrency 1 works while uploading multiple cookbooks. [\#1246](https://github.com/chef/chef/pull/1246) ([sersut](https://github.com/sersut))
- Expose resource creation via more static methods [\#1241](https://github.com/chef/chef/pull/1241) ([danielsdeleo](https://github.com/danielsdeleo))
- Making sure that the resource\_name and resource\_id while being sent to reporting are always strings. [\#1240](https://github.com/chef/chef/pull/1240) ([PrajaktaPurohit](https://github.com/PrajaktaPurohit))
- Lcg/rspec 2.14 deprecation warnings [\#1238](https://github.com/chef/chef/pull/1238) ([lamont-granquist](https://github.com/lamont-granquist))

## [11.10.0.rc.0](https://github.com/chef/chef/tree/11.10.0.rc.0) (2014-01-30)
[Full Changelog](https://github.com/chef/chef/compare/11.8.4.ohai7.0...11.10.0.rc.0)

**Merged pull requests:**

- Lcg/rspec 2.14 [\#1237](https://github.com/chef/chef/pull/1237) ([lamont-granquist](https://github.com/lamont-granquist))
- CHEF-4885: Chef::ReservedNames::Win32::Version has invalid methods [\#1234](https://github.com/chef/chef/pull/1234) ([adamedx](https://github.com/adamedx))
- Remove most references to wiki from the README [\#1232](https://github.com/chef/chef/pull/1232) ([danielsdeleo](https://github.com/danielsdeleo))
- \[Chef 4983\] Undo changes to Chef::Client public API and add new public API for expanding the run list [\#1231](https://github.com/chef/chef/pull/1231) ([danielsdeleo](https://github.com/danielsdeleo))
- Experimental Policyfile support [\#1230](https://github.com/chef/chef/pull/1230) ([danielsdeleo](https://github.com/danielsdeleo))
- CHEF-4502:  Validate Content-Length Field in HTTP requests [\#1227](https://github.com/chef/chef/pull/1227) ([lamont-granquist](https://github.com/lamont-granquist))
- OC-2192: change error message to suggest namespace collision between nod... [\#1222](https://github.com/chef/chef/pull/1222) ([lamont-granquist](https://github.com/lamont-granquist))

## [11.8.4.ohai7.0](https://github.com/chef/chef/tree/11.8.4.ohai7.0) (2014-01-20)
[Full Changelog](https://github.com/chef/chef/compare/11.10.0.alpha.1...11.8.4.ohai7.0)

**Merged pull requests:**

- CHEF-4963 - Mixlib-shellout library is incorrect for Chef 11.8.2 [\#1221](https://github.com/chef/chef/pull/1221) ([sersut](https://github.com/sersut))
- CHEF-4639: writing credentials files with `file` or `template` may leak credentials in diffs [\#1220](https://github.com/chef/chef/pull/1220) ([sersut](https://github.com/sersut))
- WIP: attempt to save CHEF-2418 [\#1218](https://github.com/chef/chef/pull/1218) ([lamont-granquist](https://github.com/lamont-granquist))
- fix platform\_family check for fedora [\#1215](https://github.com/chef/chef/pull/1215) ([lamont-granquist](https://github.com/lamont-granquist))
- Ohai 7 Compatibility for Chef [\#1214](https://github.com/chef/chef/pull/1214) ([sersut](https://github.com/sersut))
- Lock `sdoc` down to `~\> 0.3.0` [\#1211](https://github.com/chef/chef/pull/1211) ([schisamo](https://github.com/schisamo))
- Extract policy building concerns from Chef::Client [\#1210](https://github.com/chef/chef/pull/1210) ([danielsdeleo](https://github.com/danielsdeleo))
- \[CHEF-4946\] Don't try to install ruby-shadow on cygwin [\#1209](https://github.com/chef/chef/pull/1209) ([linkfanel](https://github.com/linkfanel))
- CHEF-3012: Windows group provider is not idempotent for domain users [\#1207](https://github.com/chef/chef/pull/1207) ([adamedx](https://github.com/adamedx))
- CHEF-4927 - coerce group GID to string [\#1202](https://github.com/chef/chef/pull/1202) ([jtimberman](https://github.com/jtimberman))
- Add Ruby 2.1.0 to travis matrix [\#1201](https://github.com/chef/chef/pull/1201) ([danielsdeleo](https://github.com/danielsdeleo))
- CHEF-4913: ffi 1.3.1 is too low a version when using Ruby 2.0.0 with Windows [\#1199](https://github.com/chef/chef/pull/1199) ([adamedx](https://github.com/adamedx))
- multiple dep lines no longer supported by bundler [\#1196](https://github.com/chef/chef/pull/1196) ([lamont-granquist](https://github.com/lamont-granquist))
- Temporarily for travis to use rubygems 2.1.x [\#1194](https://github.com/chef/chef/pull/1194) ([danielsdeleo](https://github.com/danielsdeleo))
- Always run `chef-client` via `ruby PATH/TO/chef-client` in tests. [\#1193](https://github.com/chef/chef/pull/1193) ([danielsdeleo](https://github.com/danielsdeleo))
- \[CHEF-4913\] Bump ffi version to 1.5.0 [\#1192](https://github.com/chef/chef/pull/1192) ([lushc](https://github.com/lushc))
- Add support for loading a static list of plugin files. [\#1186](https://github.com/chef/chef/pull/1186) ([danielsdeleo](https://github.com/danielsdeleo))
- CHEF-4762: http\_request with action :head does not behave correctly in 1.8.0 [\#1183](https://github.com/chef/chef/pull/1183) ([zuazo](https://github.com/zuazo))
- bump up upper limit on json gem to 1.8.1 [\#1179](https://github.com/chef/chef/pull/1179) ([lamont-granquist](https://github.com/lamont-granquist))
- CHEF-4850 Close file in Chef::Util::FileEdit after reading contents [\#1161](https://github.com/chef/chef/pull/1161) ([deployable](https://github.com/deployable))
- \[CHEF-4799\] Handle non-dupable elements when duping attribute arrays [\#1135](https://github.com/chef/chef/pull/1135) ([brugidou](https://github.com/brugidou))
- CHEF-4777: add include\_recipes to recipes node attr [\#1128](https://github.com/chef/chef/pull/1128) ([lamont-granquist](https://github.com/lamont-granquist))
- CHEF-4734: Stop enforcing group/owner regular expressions [\#1115](https://github.com/chef/chef/pull/1115) ([lamont-granquist](https://github.com/lamont-granquist))

## [11.10.0.alpha.1](https://github.com/chef/chef/tree/11.10.0.alpha.1) (2013-12-09)
[Full Changelog](https://github.com/chef/chef/compare/10.30.2...11.10.0.alpha.1)

## [10.30.2](https://github.com/chef/chef/tree/10.30.2) (2013-12-06)
[Full Changelog](https://github.com/chef/chef/compare/10.30.2.rc.0...10.30.2)

**Merged pull requests:**

- \[CHEF-4852\]Print total number of resources in doc formatter [\#1162](https://github.com/chef/chef/pull/1162) ([ranjib](https://github.com/ranjib))

## [10.30.2.rc.0](https://github.com/chef/chef/tree/10.30.2.rc.0) (2013-12-04)
[Full Changelog](https://github.com/chef/chef/compare/10.30.0...10.30.2.rc.0)

**Merged pull requests:**

- Do not attempt to JSON parse the body of a 204 response. [\#1163](https://github.com/chef/chef/pull/1163) ([danielsdeleo](https://github.com/danielsdeleo))

## [10.30.0](https://github.com/chef/chef/tree/10.30.0) (2013-12-03)
[Full Changelog](https://github.com/chef/chef/compare/11.8.2...10.30.0)

**Merged pull requests:**

- CHEF-4441: emit reasonable error when default data bag secret does not exist [\#1158](https://github.com/chef/chef/pull/1158) ([jkeiser](https://github.com/jkeiser))

## [11.8.2](https://github.com/chef/chef/tree/11.8.2) (2013-12-03)
[Full Changelog](https://github.com/chef/chef/compare/10.30.0.rc.2...11.8.2)

**Merged pull requests:**

- \[CHEF-4842\] Fix comparison of user resources with non-ASCII comments [\#1156](https://github.com/chef/chef/pull/1156) ([grobie](https://github.com/grobie))

## [10.30.0.rc.2](https://github.com/chef/chef/tree/10.30.0.rc.2) (2013-12-02)
[Full Changelog](https://github.com/chef/chef/compare/10.30.0.rc.1...10.30.0.rc.2)

**Merged pull requests:**

- Make sure the attributes with value nil are not converted to { } when they are being merged at the same precedence level. [\#1155](https://github.com/chef/chef/pull/1155) ([sersut](https://github.com/sersut))
- Always set a correct Host header to avoid net/http bug [\#1151](https://github.com/chef/chef/pull/1151) ([danielsdeleo](https://github.com/danielsdeleo))
- Skip IPv6 tests on Solaris [\#1150](https://github.com/chef/chef/pull/1150) ([danielsdeleo](https://github.com/danielsdeleo))
- Chef 3940 [\#1149](https://github.com/chef/chef/pull/1149) ([btm](https://github.com/btm))
- search for prerelease knife gems as well [\#1099](https://github.com/chef/chef/pull/1099) ([lamont-granquist](https://github.com/lamont-granquist))

## [10.30.0.rc.1](https://github.com/chef/chef/tree/10.30.0.rc.1) (2013-11-26)
[Full Changelog](https://github.com/chef/chef/compare/10.30.0.rc.0...10.30.0.rc.1)

**Merged pull requests:**

- Ipv6 host header [\#1147](https://github.com/chef/chef/pull/1147) ([danielsdeleo](https://github.com/danielsdeleo))
- Don't change content type in Chef::REST if one was provided [\#1146](https://github.com/chef/chef/pull/1146) ([danielsdeleo](https://github.com/danielsdeleo))
- OC-10380: skip checksumming for no-content files [\#1111](https://github.com/chef/chef/pull/1111) ([lamont-granquist](https://github.com/lamont-granquist))

## [10.30.0.rc.0](https://github.com/chef/chef/tree/10.30.0.rc.0) (2013-11-22)
[Full Changelog](https://github.com/chef/chef/compare/11.8.2.rc.0...10.30.0.rc.0)

**Merged pull requests:**

- Windows Spec Fixes [\#1143](https://github.com/chef/chef/pull/1143) ([sersut](https://github.com/sersut))
- back port of OC-10380 to 10-stable [\#1141](https://github.com/chef/chef/pull/1141) ([lamont-granquist](https://github.com/lamont-granquist))
- Pick mixlib-shellout 1.3.0.rc.0 to prepare for 10.30.0.rc.0 [\#1140](https://github.com/chef/chef/pull/1140) ([sersut](https://github.com/sersut))
- Make Chef::DataBag.save use POST instead of PUT [\#1138](https://github.com/chef/chef/pull/1138) ([sersut](https://github.com/sersut))
- Porting CHEF-3297 to 10-stable. [\#1136](https://github.com/chef/chef/pull/1136) ([sersut](https://github.com/sersut))
- \[CHEF-4110-10stable\] Add a whyrun\_safe\_ruby\_block resource [\#1116](https://github.com/chef/chef/pull/1116) ([jaymzh](https://github.com/jaymzh))
-  	\[CHEF-4110\] Add whyrun\_safe\_ruby\_block resource [\#743](https://github.com/chef/chef/pull/743) ([jaymzh](https://github.com/jaymzh))

## [11.8.2.rc.0](https://github.com/chef/chef/tree/11.8.2.rc.0) (2013-11-21)
[Full Changelog](https://github.com/chef/chef/compare/11.8.0...11.8.2.rc.0)

**Merged pull requests:**

- \[CHEF-4616\] \(10-stable\) Support IPv6 Literals in `chef\_server\_url` [\#1137](https://github.com/chef/chef/pull/1137) ([danielsdeleo](https://github.com/danielsdeleo))
- CHEF-3297: Add excluded\_members property to the group resources [\#1134](https://github.com/chef/chef/pull/1134) ([sersut](https://github.com/sersut))
- raw\_http\_request was aliased to send\_http\_request [\#1132](https://github.com/chef/chef/pull/1132) ([jamesc](https://github.com/jamesc))
- \[CHEF-4616\] Improve IPv6 support [\#1131](https://github.com/chef/chef/pull/1131) ([danielsdeleo](https://github.com/danielsdeleo))
- Add excluded\_members support to the rest of the group providers. [\#1127](https://github.com/chef/chef/pull/1127) ([sersut](https://github.com/sersut))
- Core Group Provider + Dscl / Windows / Ubuntu providers changes for CHEF-3297 [\#1124](https://github.com/chef/chef/pull/1124) ([sersut](https://github.com/sersut))
- Handle sections without text parameters [\#1121](https://github.com/chef/chef/pull/1121) ([bossmc](https://github.com/bossmc))
- CHEF-4380: package resource with "source" is broken on EL6 using 11.6.0rc3 [\#1119](https://github.com/chef/chef/pull/1119) ([sersut](https://github.com/sersut))
- CHEF-4596 / CHEF-4631 : Pick the array that is higher in the precedence order instead of merging during deep merge [\#1118](https://github.com/chef/chef/pull/1118) ([sersut](https://github.com/sersut))
- Pass custom headers when following redirects [\#1112](https://github.com/chef/chef/pull/1112) ([danielsdeleo](https://github.com/danielsdeleo))
- Fix windows gem dependencies on 10-stable [\#1110](https://github.com/chef/chef/pull/1110) ([sersut](https://github.com/sersut))
- Enable integration tests in CI and fix the way tests are launched. [\#1109](https://github.com/chef/chef/pull/1109) ([sersut](https://github.com/sersut))
- Merge 11.8.0 changes into master [\#1105](https://github.com/chef/chef/pull/1105) ([sersut](https://github.com/sersut))
- \[CHEF-4700\] Remove an unused variable in spec/unit/client\_spec.rb [\#1102](https://github.com/chef/chef/pull/1102) ([ryotarai](https://github.com/ryotarai))

## [11.8.0](https://github.com/chef/chef/tree/11.8.0) (2013-10-31)
[Full Changelog](https://github.com/chef/chef/compare/10.28.4.rc.0...11.8.0)

## [10.28.4.rc.0](https://github.com/chef/chef/tree/10.28.4.rc.0) (2013-10-30)
[Full Changelog](https://github.com/chef/chef/compare/11.8.0.rc.4...10.28.4.rc.0)

**Merged pull requests:**

- Add SSL Tooling to improve UX around cert validation \(WIP\) [\#1100](https://github.com/chef/chef/pull/1100) ([danielsdeleo](https://github.com/danielsdeleo))

## [11.8.0.rc.4](https://github.com/chef/chef/tree/11.8.0.rc.4) (2013-10-29)
[Full Changelog](https://github.com/chef/chef/compare/11.8.0.rc.3...11.8.0.rc.4)

**Merged pull requests:**

- Adapt windows\_service to be compatible with win32-service 0.8.2. [\#1098](https://github.com/chef/chef/pull/1098) ([sersut](https://github.com/sersut))
- Pin mime-types to a ruby 1.8 compatible version [\#1097](https://github.com/chef/chef/pull/1097) ([danielsdeleo](https://github.com/danielsdeleo))
- Debug request headers [\#1096](https://github.com/chef/chef/pull/1096) ([danielsdeleo](https://github.com/danielsdeleo))
- Change content type warning to debug [\#1093](https://github.com/chef/chef/pull/1093) ([danielsdeleo](https://github.com/danielsdeleo))
- Check before creating a new system mutex on windows. [\#1092](https://github.com/chef/chef/pull/1092) ([sersut](https://github.com/sersut))
- Solo json fixes [\#1086](https://github.com/chef/chef/pull/1086) ([danielsdeleo](https://github.com/danielsdeleo))
- Correct prompt to increase Knife log verbosity [\#1075](https://github.com/chef/chef/pull/1075) ([benlangfeld](https://github.com/benlangfeld))

## [11.8.0.rc.3](https://github.com/chef/chef/tree/11.8.0.rc.3) (2013-10-24)
[Full Changelog](https://github.com/chef/chef/compare/11.8.0.rc.2...11.8.0.rc.3)

**Merged pull requests:**

- CHEF-4662: fix insecure knife tempfiles [\#1083](https://github.com/chef/chef/pull/1083) ([lamont-granquist](https://github.com/lamont-granquist))
- Update remote\_file to expect nil return for 304 response [\#1079](https://github.com/chef/chef/pull/1079) ([danielsdeleo](https://github.com/danielsdeleo))
- fix solaris path fix [\#1067](https://github.com/chef/chef/pull/1067) ([lamont-granquist](https://github.com/lamont-granquist))

## [11.8.0.rc.2](https://github.com/chef/chef/tree/11.8.0.rc.2) (2013-10-22)
[Full Changelog](https://github.com/chef/chef/compare/11.8.0.rc.1...11.8.0.rc.2)

**Merged pull requests:**

- Fix recursion in self.find\_embedded\_dir\_in on windows. [\#1074](https://github.com/chef/chef/pull/1074) ([sersut](https://github.com/sersut))
- OC-10190: Write a regression test to catch any unexpected messages while running chef-client -v [\#1073](https://github.com/chef/chef/pull/1073) ([sersut](https://github.com/sersut))

## [11.8.0.rc.1](https://github.com/chef/chef/tree/11.8.0.rc.1) (2013-10-21)
[Full Changelog](https://github.com/chef/chef/compare/11.10.0.alpha.0...11.8.0.rc.1)

**Merged pull requests:**

- Remove systemu gem dependency from chef. [\#1072](https://github.com/chef/chef/pull/1072) ([sersut](https://github.com/sersut))
- Auto configure the ssl\_ca\_file on windows under omnibus [\#1071](https://github.com/chef/chef/pull/1071) ([danielsdeleo](https://github.com/danielsdeleo))
- Remove the auto generation of man pages from docs task [\#1070](https://github.com/chef/chef/pull/1070) ([sersut](https://github.com/sersut))
- Mark popen4 tests "volatile" to prevent spurious Ci failures [\#1069](https://github.com/chef/chef/pull/1069) ([danielsdeleo](https://github.com/danielsdeleo))
- Fix the race condition in concurrent chef-solo test [\#1068](https://github.com/chef/chef/pull/1068) ([sersut](https://github.com/sersut))
- Fix error caused by loading duplicate trusted certs [\#1066](https://github.com/chef/chef/pull/1066) ([danielsdeleo](https://github.com/danielsdeleo))
- Add pry as a runtime dependency [\#1065](https://github.com/chef/chef/pull/1065) ([danielsdeleo](https://github.com/danielsdeleo))

## [11.10.0.alpha.0](https://github.com/chef/chef/tree/11.10.0.alpha.0) (2013-10-17)
[Full Changelog](https://github.com/chef/chef/compare/11.8.0.rc.0...11.10.0.alpha.0)

## [11.8.0.rc.0](https://github.com/chef/chef/tree/11.8.0.rc.0) (2013-10-17)
[Full Changelog](https://github.com/chef/chef/compare/10.28.2...11.8.0.rc.0)

**Merged pull requests:**

- Patch webrick timeout handler to avoid test failures [\#1064](https://github.com/chef/chef/pull/1064) ([danielsdeleo](https://github.com/danielsdeleo))
- CHEF-4422 Truncate cache paths for remote files [\#1063](https://github.com/chef/chef/pull/1063) ([adamedx](https://github.com/adamedx))
- CHEF-4625: Explicitly close temp files to prevent sharing violations [\#1062](https://github.com/chef/chef/pull/1062) ([adamedx](https://github.com/adamedx))
- CHEF-4197: Chef::Provider::Mount device\_mount\_regex fails to populate capture groups when device is symlink \(Ubuntu 12\) [\#1061](https://github.com/chef/chef/pull/1061) ([sersut](https://github.com/sersut))
- \[CHEF-4509\] read `secret` `secret\_file` from knife hash [\#1060](https://github.com/chef/chef/pull/1060) ([schisamo](https://github.com/schisamo))
- Add SSL Certificates Directory [\#1058](https://github.com/chef/chef/pull/1058) ([danielsdeleo](https://github.com/danielsdeleo))
- Remove the unstable functional test for windows service which shells out... [\#1056](https://github.com/chef/chef/pull/1056) ([sersut](https://github.com/sersut))
- Fix CVTs in the new CI cluster [\#1054](https://github.com/chef/chef/pull/1054) ([sersut](https://github.com/sersut))
- CHEF-4634: Prettify data when writing it out in --local-mode [\#1052](https://github.com/chef/chef/pull/1052) ([jkeiser](https://github.com/jkeiser))
- Authenticate when downloading cookbooks so that Enterprise Chef will wor... [\#1051](https://github.com/chef/chef/pull/1051) ([jkeiser](https://github.com/jkeiser))
- Fix issue where multiple threads try to create same directory at the sam... [\#1050](https://github.com/chef/chef/pull/1050) ([jkeiser](https://github.com/jkeiser))
- Set cache\_path under the user's home dir rather than the local repo path [\#1049](https://github.com/chef/chef/pull/1049) ([jkeiser](https://github.com/jkeiser))
- Add a category to knife essentials commands [\#1048](https://github.com/chef/chef/pull/1048) ([jkeiser](https://github.com/jkeiser))
- CHEF-4470: Running chef-client fails when chef is running as a service on windows. [\#1046](https://github.com/chef/chef/pull/1046) ([sersut](https://github.com/sersut))
- When reporting a resource, before and after should always be a hash [\#1044](https://github.com/chef/chef/pull/1044) ([jamesc](https://github.com/jamesc))
- Fix --chef-repo-path [\#1043](https://github.com/chef/chef/pull/1043) ([jkeiser](https://github.com/jkeiser))
- Fix DELETE requests for -z for all endpoints, and PUT/POST for cookbooks [\#1042](https://github.com/chef/chef/pull/1042) ([jkeiser](https://github.com/jkeiser))
- OC-8694: Use diff-lcs in knife diff [\#1038](https://github.com/chef/chef/pull/1038) ([adamedx](https://github.com/adamedx))
- Support --local-mode chef-client parameter [\#1037](https://github.com/chef/chef/pull/1037) ([jkeiser](https://github.com/jkeiser))
- CHEF-4556: chef-client service starts at every run of chef-client::service recipe [\#1035](https://github.com/chef/chef/pull/1035) ([sersut](https://github.com/sersut))
- CHEF-4515: upload sometimes inflates JSON.  Fix by using true raw versio... [\#1033](https://github.com/chef/chef/pull/1033) ([jkeiser](https://github.com/jkeiser))
- Fix knife download acls \(was not downloading subdirectories\) [\#1028](https://github.com/chef/chef/pull/1028) ([jkeiser](https://github.com/jkeiser))
- Split Chef::REST into components. [\#1024](https://github.com/chef/chef/pull/1024) ([danielsdeleo](https://github.com/danielsdeleo))
- Fixing ssl\_cert task error message [\#578](https://github.com/chef/chef/pull/578) ([sjoerdmulder](https://github.com/sjoerdmulder))

## [10.28.2](https://github.com/chef/chef/tree/10.28.2) (2013-10-04)
[Full Changelog](https://github.com/chef/chef/compare/11.6.2...10.28.2)

## [11.6.2](https://github.com/chef/chef/tree/11.6.2) (2013-10-04)
[Full Changelog](https://github.com/chef/chef/compare/10.28.0...11.6.2)

**Merged pull requests:**

- OC-9024: Start chef-client in new process when it is run as a service on windows [\#1027](https://github.com/chef/chef/pull/1027) ([adamedx](https://github.com/adamedx))
- CHEF-4426 - knife cookbook upload doesn't work on windows when working with :versioned\_cookbooks [\#1023](https://github.com/chef/chef/pull/1023) ([sersut](https://github.com/sersut))
- \[CHEF-4399\] - Line endings for templates are based on the platform the template was written on not on the node platform [\#1020](https://github.com/chef/chef/pull/1020) ([sersut](https://github.com/sersut))
- OC-10077: Port CHEF-4419 fix to be included in 11.8.  [\#1018](https://github.com/chef/chef/pull/1018) ([sersut](https://github.com/sersut))
- bump win32-process to 0.7.3 [\#1015](https://github.com/chef/chef/pull/1015) ([lamont-granquist](https://github.com/lamont-granquist))
- file cache location changes on windows [\#1011](https://github.com/chef/chef/pull/1011) ([lamont-granquist](https://github.com/lamont-granquist))
- Jk/version constraints 10 stable [\#1010](https://github.com/chef/chef/pull/1010) ([jkeiser](https://github.com/jkeiser))
- use :each, because config is now reset after each [\#1007](https://github.com/chef/chef/pull/1007) ([lamont-granquist](https://github.com/lamont-granquist))
- default case should be same as log\_level :auto [\#1006](https://github.com/chef/chef/pull/1006) ([lamont-granquist](https://github.com/lamont-granquist))
- use separate gemspec for mingw [\#1001](https://github.com/chef/chef/pull/1001) ([lamont-granquist](https://github.com/lamont-granquist))
- Jk/more defaults 2 [\#993](https://github.com/chef/chef/pull/993) ([jkeiser](https://github.com/jkeiser))
- Jk/default fix [\#992](https://github.com/chef/chef/pull/992) ([jkeiser](https://github.com/jkeiser))
- Use default value facilities of mixlib-config to simplify things [\#991](https://github.com/chef/chef/pull/991) ([jkeiser](https://github.com/jkeiser))
- Reset Chef::Config between every test [\#990](https://github.com/chef/chef/pull/990) ([jkeiser](https://github.com/jkeiser))
- Add chef\_zero.enabled configuration option to chef-client and knife [\#989](https://github.com/chef/chef/pull/989) ([jkeiser](https://github.com/jkeiser))
- CHEF-3982: Solaris bootstrap PATH \<\< /opt/sfw/bin [\#987](https://github.com/chef/chef/pull/987) ([lamont-granquist](https://github.com/lamont-granquist))
- Use "default" DSL in Chef::Config to make reset possible [\#986](https://github.com/chef/chef/pull/986) ([jkeiser](https://github.com/jkeiser))
- OC-9226: \[AIX\] Make functional test failures for Chef::Resource::User :pending  [\#974](https://github.com/chef/chef/pull/974) ([adamedx](https://github.com/adamedx))
- OC-8526: Group provider does not respect group\_name on Windows [\#973](https://github.com/chef/chef/pull/973) ([adamedx](https://github.com/adamedx))
- Jk/chef repo path [\#969](https://github.com/chef/chef/pull/969) ([jkeiser](https://github.com/jkeiser))
- \[CHEF-4342\] Use progress formatter on Travis [\#870](https://github.com/chef/chef/pull/870) ([sethvargo](https://github.com/sethvargo))

## [10.28.0](https://github.com/chef/chef/tree/10.28.0) (2013-08-30)
[Full Changelog](https://github.com/chef/chef/compare/10.28.0.rc.0...10.28.0)

**Merged pull requests:**

- OC-8713: AIX: Package provider for AIX [\#957](https://github.com/chef/chef/pull/957) ([adamedx](https://github.com/adamedx))
- OC-9195: OC-9224: OC-9227: Solaris constructor, AIX link and chef-shell tests [\#956](https://github.com/chef/chef/pull/956) ([adamedx](https://github.com/adamedx))

## [10.28.0.rc.0](https://github.com/chef/chef/tree/10.28.0.rc.0) (2013-08-13)
[Full Changelog](https://github.com/chef/chef/compare/11.6.0.hotfix.1...10.28.0.rc.0)

**Merged pull requests:**

- OC-8622: Add support for the cron resource for AIX [\#941](https://github.com/chef/chef/pull/941) ([adamedx](https://github.com/adamedx))

## [11.6.0.hotfix.1](https://github.com/chef/chef/tree/11.6.0.hotfix.1) (2013-08-03)
[Full Changelog](https://github.com/chef/chef/compare/11.6.0...11.6.0.hotfix.1)

**Merged pull requests:**

- CHEF-4422 Truncate cache paths for remote files [\#939](https://github.com/chef/chef/pull/939) ([adamedx](https://github.com/adamedx))
- Convert apt package provider to shellout [\#938](https://github.com/chef/chef/pull/938) ([danielsdeleo](https://github.com/danielsdeleo))
- Make sure config file selection specs can run when HOME is not set. [\#936](https://github.com/chef/chef/pull/936) ([sersut](https://github.com/sersut))
- Chef 4406 11 stable [\#934](https://github.com/chef/chef/pull/934) ([danielsdeleo](https://github.com/danielsdeleo))
- CHEF-4419: Absolute file paths with no drive letter for file resources on Windows fails chef-client run [\#926](https://github.com/chef/chef/pull/926) ([sersut](https://github.com/sersut))
- Avoid using define\_method to stop memory leak. [\#918](https://github.com/chef/chef/pull/918) ([stevendanna](https://github.com/stevendanna))
- OC-8707: Implement ifconfig provider for AIX [\#915](https://github.com/chef/chef/pull/915) ([adamedx](https://github.com/adamedx))
- OC-8621: Add support for the mount resource for AIX [\#912](https://github.com/chef/chef/pull/912) ([adamedx](https://github.com/adamedx))

## [11.6.0](https://github.com/chef/chef/tree/11.6.0) (2013-07-22)
[Full Changelog](https://github.com/chef/chef/compare/11.6.0.rc.4...11.6.0)

**Merged pull requests:**

- backport spec fix for unbundling rspec [\#902](https://github.com/chef/chef/pull/902) ([lamont-granquist](https://github.com/lamont-granquist))
- \[CHEF-4248\] expose scm timeout attribute [\#805](https://github.com/chef/chef/pull/805) ([jfoy](https://github.com/jfoy))

## [11.6.0.rc.4](https://github.com/chef/chef/tree/11.6.0.rc.4) (2013-07-17)
[Full Changelog](https://github.com/chef/chef/compare/11.8.0.alpha.0...11.6.0.rc.4)

**Merged pull requests:**

- \[CHEF-4380\] Fix missing include on shellout mixin [\#900](https://github.com/chef/chef/pull/900) ([sersut](https://github.com/sersut))
- \[CHEF-4380\] Fix missing include on shellout mixin [\#899](https://github.com/chef/chef/pull/899) ([juliandunn](https://github.com/juliandunn))
- OC-8693 [\#898](https://github.com/chef/chef/pull/898) ([mcquin](https://github.com/mcquin))
- CHEF-4314: Pin active\_support \< 4.0.0 due to atomic + CAS issues [\#897](https://github.com/chef/chef/pull/897) ([sersut](https://github.com/sersut))

## [11.8.0.alpha.0](https://github.com/chef/chef/tree/11.8.0.alpha.0) (2013-07-16)
[Full Changelog](https://github.com/chef/chef/compare/11.6.0.rc.3...11.8.0.alpha.0)

**Merged pull requests:**

- get first gem.bat in path rather than last [\#892](https://github.com/chef/chef/pull/892) ([lamont-granquist](https://github.com/lamont-granquist))

## [11.6.0.rc.3](https://github.com/chef/chef/tree/11.6.0.rc.3) (2013-07-12)
[Full Changelog](https://github.com/chef/chef/compare/11.6.0.rc.2...11.6.0.rc.3)

**Merged pull requests:**

- Change error description sections elements to be hashes. [\#893](https://github.com/chef/chef/pull/893) ([sersut](https://github.com/sersut))
- OC--8527: CHEF-3284: shef on Windows 7 & Windows 2008 R2 doesn't support backspace etc [\#889](https://github.com/chef/chef/pull/889) ([adamedx](https://github.com/adamedx))
- Add -E flag to chef-solo in order to enable people use the new environment support in chef-solo. [\#885](https://github.com/chef/chef/pull/885) ([sersut](https://github.com/sersut))

## [11.6.0.rc.2](https://github.com/chef/chef/tree/11.6.0.rc.2) (2013-07-11)
[Full Changelog](https://github.com/chef/chef/compare/11.6.0.rc.1...11.6.0.rc.2)

**Merged pull requests:**

- Upgrade RSpec to 2.13.x [\#890](https://github.com/chef/chef/pull/890) ([danielsdeleo](https://github.com/danielsdeleo))
- Ignore corrupt cache control data; re-download file [\#887](https://github.com/chef/chef/pull/887) ([danielsdeleo](https://github.com/danielsdeleo))
- Increase the default yum timeout to 5 minutes. [\#882](https://github.com/chef/chef/pull/882) ([sersut](https://github.com/sersut))
- Chef 4357 [\#881](https://github.com/chef/chef/pull/881) ([danielsdeleo](https://github.com/danielsdeleo))

## [11.6.0.rc.1](https://github.com/chef/chef/tree/11.6.0.rc.1) (2013-07-03)
[Full Changelog](https://github.com/chef/chef/compare/11.6.0.rc.0...11.6.0.rc.1)

**Merged pull requests:**

- this should have been reverted to old behavior, causes failures on [\#874](https://github.com/chef/chef/pull/874) ([lamont-granquist](https://github.com/lamont-granquist))
- \[CHEF-4341\] Use symlink source when inspecting current permissions [\#869](https://github.com/chef/chef/pull/869) ([danielsdeleo](https://github.com/danielsdeleo))
- \[CHEF-4335\] Buffer ssh output by line to avoid mangling it. [\#866](https://github.com/chef/chef/pull/866) ([danielsdeleo](https://github.com/danielsdeleo))
- Lcg/diff encoding [\#863](https://github.com/chef/chef/pull/863) ([lamont-granquist](https://github.com/lamont-granquist))
- Yum package calls readlines on a string. [\#862](https://github.com/chef/chef/pull/862) ([sersut](https://github.com/sersut))

## [11.6.0.rc.0](https://github.com/chef/chef/tree/11.6.0.rc.0) (2013-06-27)
[Full Changelog](https://github.com/chef/chef/compare/11.5.0.alpha.0...11.6.0.rc.0)

**Merged pull requests:**

- CHEF-4312 Fix compat for file resources managing content via symlink [\#856](https://github.com/chef/chef/pull/856) ([danielsdeleo](https://github.com/danielsdeleo))
- OC-8391: Chef::Provider::User::Windows fails with local password policies [\#855](https://github.com/chef/chef/pull/855) ([adamedx](https://github.com/adamedx))
- OC-8337: Add missing functional tests for powershell\_script, batch resources [\#851](https://github.com/chef/chef/pull/851) ([adamedx](https://github.com/adamedx))
- El usermod test fixes [\#847](https://github.com/chef/chef/pull/847) ([danielsdeleo](https://github.com/danielsdeleo))
- Fix `usermod` test issues [\#846](https://github.com/chef/chef/pull/846) ([danielsdeleo](https://github.com/danielsdeleo))
- Verify that chefignore is a file before reading it. [\#845](https://github.com/chef/chef/pull/845) ([jkeiser](https://github.com/jkeiser))
- to see this on command line with default :auto level we need to warn [\#843](https://github.com/chef/chef/pull/843) ([lamont-granquist](https://github.com/lamont-granquist))
- Lcg/cloexec lockfile [\#840](https://github.com/chef/chef/pull/840) ([lamont-granquist](https://github.com/lamont-granquist))
- add rake task for generating docs with YARD [\#839](https://github.com/chef/chef/pull/839) ([lamont-granquist](https://github.com/lamont-granquist))
- \[CHEF-4204\] Fix issues with shell-significant characters in useradd commands [\#838](https://github.com/chef/chef/pull/838) ([danielsdeleo](https://github.com/danielsdeleo))
- Fix net-ssh-multi concurreny issues [\#835](https://github.com/chef/chef/pull/835) ([sersut](https://github.com/sersut))
- Handle new 412 depsolver errors without any cookbook information. [\#833](https://github.com/chef/chef/pull/833) ([sersut](https://github.com/sersut))
- don't depend on line separator in partial tests [\#828](https://github.com/chef/chef/pull/828) ([danielsdeleo](https://github.com/danielsdeleo))
- Don't call fork when chef is running on windows. [\#827](https://github.com/chef/chef/pull/827) ([sersut](https://github.com/sersut))
- start testing with travis [\#826](https://github.com/chef/chef/pull/826) ([josephrdsmith](https://github.com/josephrdsmith))
- \[CHEF-4275\] Fix rubygems version heuristic to workaround old rubygem code getting loaded. [\#824](https://github.com/chef/chef/pull/824) ([danielsdeleo](https://github.com/danielsdeleo))
- \[CHEF-2741\] Deploy resource re-attempts failed deploys on subsequent runs [\#822](https://github.com/chef/chef/pull/822) ([danielsdeleo](https://github.com/danielsdeleo))
- remove log level special casing from git resource [\#819](https://github.com/chef/chef/pull/819) ([danielsdeleo](https://github.com/danielsdeleo))
- fixes for 'rake install' on ruby-2.0.0 [\#818](https://github.com/chef/chef/pull/818) ([lamont-granquist](https://github.com/lamont-granquist))
- Chef 4233: data bag upload includes extra keys [\#817](https://github.com/chef/chef/pull/817) ([jkeiser](https://github.com/jkeiser))
- OC:7888 Windows mount support for username / domain [\#815](https://github.com/chef/chef/pull/815) ([adamedx](https://github.com/adamedx))
- Prevent integration tests from loading real config [\#813](https://github.com/chef/chef/pull/813) ([danielsdeleo](https://github.com/danielsdeleo))
- CHEF-3307: metadata.name can be empty, which is truthy [\#812](https://github.com/chef/chef/pull/812) ([lamont-granquist](https://github.com/lamont-granquist))
- Fix "undefined method binread" in functional tests on Ruby 1.8.7 [\#811](https://github.com/chef/chef/pull/811) ([danielsdeleo](https://github.com/danielsdeleo))
- Binmode lulz fix [\#808](https://github.com/chef/chef/pull/808) ([danielsdeleo](https://github.com/danielsdeleo))
- Fix ruby 1.8 compatibility with file-refactor changes [\#807](https://github.com/chef/chef/pull/807) ([danielsdeleo](https://github.com/danielsdeleo))
- Some more CI fixes for Solaris & Windows Server 2003 @ SLES 11 SP2. [\#803](https://github.com/chef/chef/pull/803) ([sersut](https://github.com/sersut))
- Fix various issues seen in CI. [\#802](https://github.com/chef/chef/pull/802) ([sersut](https://github.com/sersut))
- Fixes for the issues we've seen in CI run for file-refactor branch. [\#799](https://github.com/chef/chef/pull/799) ([sersut](https://github.com/sersut))
- Add opt-in code coverage reporting [\#798](https://github.com/chef/chef/pull/798) ([danielsdeleo](https://github.com/danielsdeleo))
- remove unused remote file util class [\#797](https://github.com/chef/chef/pull/797) ([danielsdeleo](https://github.com/danielsdeleo))
- Binmode and Template line endings [\#795](https://github.com/chef/chef/pull/795) ([sersut](https://github.com/sersut))
- Add warning when overriding core template functionality [\#794](https://github.com/chef/chef/pull/794) ([danielsdeleo](https://github.com/danielsdeleo))
- Failing selinux spec [\#793](https://github.com/chef/chef/pull/793) ([danielsdeleo](https://github.com/danielsdeleo))
- Run remote\_file functional tests w/ HTTPS [\#788](https://github.com/chef/chef/pull/788) ([danielsdeleo](https://github.com/danielsdeleo))
- Functional tests for selinux functionality. [\#787](https://github.com/chef/chef/pull/787) ([sersut](https://github.com/sersut))
- Add Template Helpers [\#784](https://github.com/chef/chef/pull/784) ([danielsdeleo](https://github.com/danielsdeleo))
- AIX also has no ruby shadow [\#783](https://github.com/chef/chef/pull/783) ([lamont-granquist](https://github.com/lamont-granquist))
- File refactor local cleanup [\#781](https://github.com/chef/chef/pull/781) ([danielsdeleo](https://github.com/danielsdeleo))
- File refactor ftp cleanup [\#780](https://github.com/chef/chef/pull/780) ([danielsdeleo](https://github.com/danielsdeleo))
- Unit specs for selinux. [\#778](https://github.com/chef/chef/pull/778) ([sersut](https://github.com/sersut))
- Specs \(and fixes\) for force\_unlink [\#775](https://github.com/chef/chef/pull/775) ([sersut](https://github.com/sersut))
- Rename file new config parameters for new file resource. [\#772](https://github.com/chef/chef/pull/772) ([sersut](https://github.com/sersut))
- Increased test coverage and fixes for windows ACL handling. [\#771](https://github.com/chef/chef/pull/771) ([sersut](https://github.com/sersut))
- Relocate reusable classes under Chef::Provider::File to its own namespace [\#765](https://github.com/chef/chef/pull/765) ([sersut](https://github.com/sersut))
- Remove ability to override selinux restorecon command. [\#764](https://github.com/chef/chef/pull/764) ([sersut](https://github.com/sersut))
- Add deprecated methods of files and providers during file-refactor back with necessary warnings. [\#763](https://github.com/chef/chef/pull/763) ([sersut](https://github.com/sersut))
- File refactor unit test fix [\#762](https://github.com/chef/chef/pull/762) ([danielsdeleo](https://github.com/danielsdeleo))
- Fix nitpick comments and code typos. [\#761](https://github.com/chef/chef/pull/761) ([sersut](https://github.com/sersut))
- OC-7687: Default to --no-color on Windows [\#758](https://github.com/chef/chef/pull/758) ([adamedx](https://github.com/adamedx))
- File Refactor [\#665](https://github.com/chef/chef/pull/665) ([lamont-opscode](https://github.com/lamont-opscode))

## [11.5.0.alpha.0](https://github.com/chef/chef/tree/11.5.0.alpha.0) (2013-05-13)
[Full Changelog](https://github.com/chef/chef/compare/10.26.0...11.5.0.alpha.0)

**Merged pull requests:**

- Chef 4176 [\#756](https://github.com/chef/chef/pull/756) ([danielsdeleo](https://github.com/danielsdeleo))

## [10.26.0](https://github.com/chef/chef/tree/10.26.0) (2013-05-06)
[Full Changelog](https://github.com/chef/chef/compare/10.26.0.beta.0...10.26.0)

**Merged pull requests:**

- Windows test reliability issues across versions of Windows [\#752](https://github.com/chef/chef/pull/752) ([adamedx](https://github.com/adamedx))
- \[CHEF-4157\] split Platform to prune dep graph [\#747](https://github.com/chef/chef/pull/747) ([danielsdeleo](https://github.com/danielsdeleo))
- CHEF-3615 - Add encrypt-then-mac mode for encrypted data bag items [\#744](https://github.com/chef/chef/pull/744) ([danielsdeleo](https://github.com/danielsdeleo))
- \[CHEF-3858\] rescue bad json errors and re-raise as decryption failures [\#741](https://github.com/chef/chef/pull/741) ([danielsdeleo](https://github.com/danielsdeleo))

## [10.26.0.beta.0](https://github.com/chef/chef/tree/10.26.0.beta.0) (2013-04-24)
[Full Changelog](https://github.com/chef/chef/compare/10.24.4...10.26.0.beta.0)

**Merged pull requests:**

- CHEF-1707:  fix user provider for solaris passwords [\#721](https://github.com/chef/chef/pull/721) ([lamont-granquist](https://github.com/lamont-granquist))

## [10.24.4](https://github.com/chef/chef/tree/10.24.4) (2013-04-24)
[Full Changelog](https://github.com/chef/chef/compare/11.4.4...10.24.4)

## [11.4.4](https://github.com/chef/chef/tree/11.4.4) (2013-04-24)
[Full Changelog](https://github.com/chef/chef/compare/11.4.4.rc.0...11.4.4)

## [11.4.4.rc.0](https://github.com/chef/chef/tree/11.4.4.rc.0) (2013-04-23)
[Full Changelog](https://github.com/chef/chef/compare/10.24.2...11.4.4.rc.0)

**Merged pull requests:**

- \[CHEF-4117\] fix resource attempting to remove constants it doesn't have [\#734](https://github.com/chef/chef/pull/734) ([danielsdeleo](https://github.com/danielsdeleo))

## [10.24.2](https://github.com/chef/chef/tree/10.24.2) (2013-04-22)
[Full Changelog](https://github.com/chef/chef/compare/11.4.2...10.24.2)

## [11.4.2](https://github.com/chef/chef/tree/11.4.2) (2013-04-22)
[Full Changelog](https://github.com/chef/chef/compare/11.4.2.rc.0...11.4.2)

**Merged pull requests:**

- \[CHEF-3432\] fix LWRP class leak in 10-stable [\#730](https://github.com/chef/chef/pull/730) ([danielsdeleo](https://github.com/danielsdeleo))

## [11.4.2.rc.0](https://github.com/chef/chef/tree/11.4.2.rc.0) (2013-04-22)
[Full Changelog](https://github.com/chef/chef/compare/11.4.1.alpha.1...11.4.2.rc.0)

**Merged pull requests:**

- Chef 3432 Fix memory leak w/ LWRP class creation [\#722](https://github.com/chef/chef/pull/722) ([danielsdeleo](https://github.com/danielsdeleo))
- \[CHEF-4011\] use `platform\_specific\_path` helper in specs [\#720](https://github.com/chef/chef/pull/720) ([schisamo](https://github.com/schisamo))
- Typo in symliinks [\#714](https://github.com/chef/chef/pull/714) ([jjasghar](https://github.com/jjasghar))
- OC-5726: Enable password to sudo from stdin for knife ssh bootstrap [\#704](https://github.com/chef/chef/pull/704) ([adamedx](https://github.com/adamedx))
- Fix the service\_manager\_tests on commit verification pipeline [\#695](https://github.com/chef/chef/pull/695) ([sersut](https://github.com/sersut))
- OC-6536: Update Windows Versions library to include latest versions of Windows [\#694](https://github.com/chef/chef/pull/694) ([adamedx](https://github.com/adamedx))
- OC-6536 Need to update Windows versions returned by Chef helper API to support Win 2012 / Win 8 [\#693](https://github.com/chef/chef/pull/693) ([chirag-jog](https://github.com/chirag-jog))
- Disable diffs during file functional tests [\#691](https://github.com/chef/chef/pull/691) ([danielsdeleo](https://github.com/danielsdeleo))
- Oc 6470 - Enable password to sudo from stdin for knife ssh bootstrap [\#680](https://github.com/chef/chef/pull/680) ([chirag-jog](https://github.com/chirag-jog))
- Update the log message in service\_manager. [\#671](https://github.com/chef/chef/pull/671) ([sersut](https://github.com/sersut))
- Refactor windows\_service\_manager slightly so that we can reuse it in dif... [\#663](https://github.com/chef/chef/pull/663) ([sersut](https://github.com/sersut))
- Remove non-trailing optional parameter to fix Ruby 1.8 and general maint... [\#661](https://github.com/chef/chef/pull/661) ([adamedx](https://github.com/adamedx))
- \[CHEF-3935\] Replace stdlib Logger w/ a lock free variant [\#655](https://github.com/chef/chef/pull/655) ([danielsdeleo](https://github.com/danielsdeleo))
- Chef-Client as Windows Service [\#642](https://github.com/chef/chef/pull/642) ([sersut](https://github.com/sersut))
- Remove weird json dependency [\#634](https://github.com/chef/chef/pull/634) ([grosser](https://github.com/grosser))

## [11.4.1.alpha.1](https://github.com/chef/chef/tree/11.4.1.alpha.1) (2013-02-21)
[Full Changelog](https://github.com/chef/chef/compare/10.24.0...11.4.1.alpha.1)

**Merged pull requests:**

- Addition of Batch and Powershell resources for Windows [\#646](https://github.com/chef/chef/pull/646) ([adamedx](https://github.com/adamedx))

## [10.24.0](https://github.com/chef/chef/tree/10.24.0) (2013-02-16)
[Full Changelog](https://github.com/chef/chef/compare/10.22.0...10.24.0)

## [10.22.0](https://github.com/chef/chef/tree/10.22.0) (2013-02-13)
[Full Changelog](https://github.com/chef/chef/compare/11.4.0...10.22.0)

## [11.4.0](https://github.com/chef/chef/tree/11.4.0) (2013-02-12)
[Full Changelog](https://github.com/chef/chef/compare/10.20.0...11.4.0)

**Merged pull requests:**

- Chef 3863 10stable [\#639](https://github.com/chef/chef/pull/639) ([danielsdeleo](https://github.com/danielsdeleo))
- hand cherry-pick json-dos-fix to pl master [\#638](https://github.com/chef/chef/pull/638) ([danielsdeleo](https://github.com/danielsdeleo))
- \[CHEF-3863\] Reimplement json\_class in a constrained way not vuln to DoS [\#637](https://github.com/chef/chef/pull/637) ([danielsdeleo](https://github.com/danielsdeleo))

## [10.20.0](https://github.com/chef/chef/tree/10.20.0) (2013-02-07)
[Full Changelog](https://github.com/chef/chef/compare/11.2.0...10.20.0)

## [11.2.0](https://github.com/chef/chef/tree/11.2.0) (2013-02-07)
[Full Changelog](https://github.com/chef/chef/compare/11.2.0.rc.1...11.2.0)

## [11.2.0.rc.1](https://github.com/chef/chef/tree/11.2.0.rc.1) (2013-02-06)
[Full Changelog](https://github.com/chef/chef/compare/11.0.0...11.2.0.rc.1)

## [11.0.0](https://github.com/chef/chef/tree/11.0.0) (2013-02-01)
[Full Changelog](https://github.com/chef/chef/compare/11.0.0.rc.0...11.0.0)

## [11.0.0.rc.0](https://github.com/chef/chef/tree/11.0.0.rc.0) (2013-02-01)
[Full Changelog](https://github.com/chef/chef/compare/11.0.0.beta.2...11.0.0.rc.0)

## [11.0.0.beta.2](https://github.com/chef/chef/tree/11.0.0.beta.2) (2013-01-30)
[Full Changelog](https://github.com/chef/chef/compare/11.0.0.beta.1...11.0.0.beta.2)

**Merged pull requests:**

- CHEF-3806: set\_unless leaks set\_unless\_value\_present into later calls [\#619](https://github.com/chef/chef/pull/619) ([lamont-opscode](https://github.com/lamont-opscode))

## [11.0.0.beta.1](https://github.com/chef/chef/tree/11.0.0.beta.1) (2013-01-28)
[Full Changelog](https://github.com/chef/chef/compare/11.0.0.beta.0...11.0.0.beta.1)

**Merged pull requests:**

- \[CHEF-3799\] fixes TypeError for puts on VividMash [\#613](https://github.com/chef/chef/pull/613) ([danielsdeleo](https://github.com/danielsdeleo))
- Replace arrays between precedence levels [\#611](https://github.com/chef/chef/pull/611) ([danielsdeleo](https://github.com/danielsdeleo))
- Praj/fixing win 2003 errors [\#608](https://github.com/chef/chef/pull/608) ([PrajaktaPurohit](https://github.com/PrajaktaPurohit))
- \[CHEF-3783\] Make deprecated constants available [\#603](https://github.com/chef/chef/pull/603) ([danielsdeleo](https://github.com/danielsdeleo))
- CHEF-3467: Cookbook file resource permissions not inherited from parent ... [\#597](https://github.com/chef/chef/pull/597) ([adamedx](https://github.com/adamedx))
- Admin privilage check for windows in chef-client [\#585](https://github.com/chef/chef/pull/585) ([sersut](https://github.com/sersut))

## [11.0.0.beta.0](https://github.com/chef/chef/tree/11.0.0.beta.0) (2013-01-21)
[Full Changelog](https://github.com/chef/chef/compare/10.18.2...11.0.0.beta.0)

**Merged pull requests:**

- Integrate Changes from Chef 10.18 into master \(Chef 11\) [\#599](https://github.com/chef/chef/pull/599) ([danielsdeleo](https://github.com/danielsdeleo))

## [10.18.2](https://github.com/chef/chef/tree/10.18.2) (2013-01-18)
[Full Changelog](https://github.com/chef/chef/compare/10.18.0...10.18.2)

**Merged pull requests:**

- CHEF-3731 for Chef 11 [\#832](https://github.com/chef/chef/pull/832) ([danielsdeleo](https://github.com/danielsdeleo))
- \[CHEF-3571\] Add `chef-apply` command to run a single recipe file [\#594](https://github.com/chef/chef/pull/594) ([danielsdeleo](https://github.com/danielsdeleo))
- \[CHEF-3771\] Fix spurious resource clone warnings [\#593](https://github.com/chef/chef/pull/593) ([danielsdeleo](https://github.com/danielsdeleo))
- \[CHEF-3497\] Fix knife configure order, apply any relevant Chef::Config\[:knife\] settings [\#583](https://github.com/chef/chef/pull/583) ([danielsdeleo](https://github.com/danielsdeleo))

## [10.18.0](https://github.com/chef/chef/tree/10.18.0) (2013-01-15)
[Full Changelog](https://github.com/chef/chef/compare/10.18.0.rc.2...10.18.0)

## [10.18.0.rc.2](https://github.com/chef/chef/tree/10.18.0.rc.2) (2013-01-11)
[Full Changelog](https://github.com/chef/chef/compare/10.16.6...10.18.0.rc.2)

**Merged pull requests:**

- race condition that resolves itself? [\#580](https://github.com/chef/chef/pull/580) ([lamont-opscode](https://github.com/lamont-opscode))

## [10.16.6](https://github.com/chef/chef/tree/10.16.6) (2013-01-10)
[Full Changelog](https://github.com/chef/chef/compare/10.16.4...10.16.6)

**Merged pull requests:**

- update mixlib to at least 0.9.16 [\#579](https://github.com/chef/chef/pull/579) ([danielsdeleo](https://github.com/danielsdeleo))
- fix functional test context for permissions. [\#576](https://github.com/chef/chef/pull/576) ([danielsdeleo](https://github.com/danielsdeleo))
- Fixup File security metadata reporting for Unix [\#575](https://github.com/chef/chef/pull/575) ([danielsdeleo](https://github.com/danielsdeleo))

## [10.16.4](https://github.com/chef/chef/tree/10.16.4) (2012-12-25)
[Full Changelog](https://github.com/chef/chef/compare/10.18.0.rc.1...10.16.4)

**Merged pull requests:**

- CHEF-3718: pin systemu version for windows [\#567](https://github.com/chef/chef/pull/567) ([lamont-opscode](https://github.com/lamont-opscode))
- \[CHEF-3715\] Remove Caching of SHA256 checksums in client/solo [\#566](https://github.com/chef/chef/pull/566) ([danielsdeleo](https://github.com/danielsdeleo))
- \[CHEF-3681\] add inline compilation option for LWRP [\#564](https://github.com/chef/chef/pull/564) ([danielsdeleo](https://github.com/danielsdeleo))
- Stress tests randomly fail in Ci. Exclude them [\#563](https://github.com/chef/chef/pull/563) ([danielsdeleo](https://github.com/danielsdeleo))
- Lcg/oc 4660 registry [\#562](https://github.com/chef/chef/pull/562) ([lamont-opscode](https://github.com/lamont-opscode))

## [10.18.0.rc.1](https://github.com/chef/chef/tree/10.18.0.rc.1) (2012-12-19)
[Full Changelog](https://github.com/chef/chef/compare/10.16.2...10.18.0.rc.1)

**Merged pull requests:**

- \[CHEF-3689\] Refactor Client Registration, make it work for existing clients w/ Chef 11 Server [\#558](https://github.com/chef/chef/pull/558) ([danielsdeleo](https://github.com/danielsdeleo))
- Define LWRP Behavior in Subclasses of Resource and Provider [\#556](https://github.com/chef/chef/pull/556) ([danielsdeleo](https://github.com/danielsdeleo))
- explicitly include EnforceOwnershipAndPermissions where it's used [\#555](https://github.com/chef/chef/pull/555) ([danielsdeleo](https://github.com/danielsdeleo))
- Reload original knife config after knife functional tests. [\#551](https://github.com/chef/chef/pull/551) ([sersut](https://github.com/sersut))
- \[Chef 3689\] \(10 stable\) Fix client registration when an inflated ApiClient is returned [\#542](https://github.com/chef/chef/pull/542) ([danielsdeleo](https://github.com/danielsdeleo))
- Chef 2812 [\#540](https://github.com/chef/chef/pull/540) ([btm](https://github.com/btm))
- CHEF-3688 remove stale attribute read protection [\#538](https://github.com/chef/chef/pull/538) ([adamhjk](https://github.com/adamhjk))
- \[CHEF-3662\] ApiClient can set a private key from JSON [\#530](https://github.com/chef/chef/pull/530) ([danielsdeleo](https://github.com/danielsdeleo))
- Chef 3680 - fix StaleAttribute errors when converting node to JSON [\#529](https://github.com/chef/chef/pull/529) ([danielsdeleo](https://github.com/danielsdeleo))
- More Windows Spec Test Fixes [\#523](https://github.com/chef/chef/pull/523) ([sdelano](https://github.com/sdelano))
- \[CHEF-3662\] ApiClient can reregister itself [\#522](https://github.com/chef/chef/pull/522) ([danielsdeleo](https://github.com/danielsdeleo))
- Quote cookbook name/version in error message [\#520](https://github.com/chef/chef/pull/520) ([danielsdeleo](https://github.com/danielsdeleo))
- Removing link tests from Windows 2k3 since symbolic links are not yet supported on this OS [\#519](https://github.com/chef/chef/pull/519) ([sersut](https://github.com/sersut))
- Restructure 'knife index rebuild' task and overhaul tests [\#516](https://github.com/chef/chef/pull/516) ([christophermaier](https://github.com/christophermaier))
- Chef 3660: Deploy Revision Provider Fails on Solaris 9 [\#515](https://github.com/chef/chef/pull/515) ([sdelano](https://github.com/sdelano))
- Deprecate 'knife index rebuild' [\#512](https://github.com/chef/chef/pull/512) ([christophermaier](https://github.com/christophermaier))
- Gracefully handle JSON with a bad 'json\_class' value [\#504](https://github.com/chef/chef/pull/504) ([christophermaier](https://github.com/christophermaier))
- CHEF-3411: Do not try to inspect recipes that do not exist [\#503](https://github.com/chef/chef/pull/503) ([btm](https://github.com/btm))
- Default to 'doc' Output Formatter When STDOUT is a Console [\#493](https://github.com/chef/chef/pull/493) ([danielsdeleo](https://github.com/danielsdeleo))
- \[CHEF-3619\] fix obsolete require of 'rake/rdoctask' [\#489](https://github.com/chef/chef/pull/489) ([aspiers](https://github.com/aspiers))
- \[CHEF-3616\] add cipher field to edbi metadata [\#488](https://github.com/chef/chef/pull/488) ([danielsdeleo](https://github.com/danielsdeleo))
- \[CHEF-3616\] add cipher field to edbi metadata [\#487](https://github.com/chef/chef/pull/487) ([danielsdeleo](https://github.com/danielsdeleo))
- \[CHEF-3392\] \(10-stable\) compat with version 1 encrypted dbi format [\#485](https://github.com/chef/chef/pull/485) ([danielsdeleo](https://github.com/danielsdeleo))
- \[CHEF-3392\] JSON serialize encrypted data bags, use random IV [\#481](https://github.com/chef/chef/pull/481) ([danielsdeleo](https://github.com/danielsdeleo))
- \[CHEF-2903\] load attribute files in run\_list order [\#474](https://github.com/chef/chef/pull/474) ([danielsdeleo](https://github.com/danielsdeleo))
- Verify that resources are updated or not in functional tests [\#473](https://github.com/chef/chef/pull/473) ([danielsdeleo](https://github.com/danielsdeleo))
- Rebased and merged branch immediate-converge-action onto 10-stable from ... [\#472](https://github.com/chef/chef/pull/472) ([tylercloke](https://github.com/tylercloke))
- Add handling of timeouts generated by dep selector. [\#470](https://github.com/chef/chef/pull/470) ([manderson26](https://github.com/manderson26))
- Chef 3499 -- Add platform introspection to node [\#466](https://github.com/chef/chef/pull/466) ([danielsdeleo](https://github.com/danielsdeleo))
- removing daemonize option for windows [\#459](https://github.com/chef/chef/pull/459) ([lamont-opscode](https://github.com/lamont-opscode))

## [10.16.2](https://github.com/chef/chef/tree/10.16.2) (2012-10-26)
[Full Changelog](https://github.com/chef/chef/compare/10.16.0...10.16.2)

**Merged pull requests:**

- \[CHEF-3561\] add template context for template errors [\#454](https://github.com/chef/chef/pull/454) ([danielsdeleo](https://github.com/danielsdeleo))
- work around CHEF-3554 in windows by disabling this information collectio... [\#450](https://github.com/chef/chef/pull/450) ([timh](https://github.com/timh))
- CHEF-3547, fixed bug for permissions in cookbook provider. [\#445](https://github.com/chef/chef/pull/445) ([tylercloke](https://github.com/tylercloke))

## [10.16.0](https://github.com/chef/chef/tree/10.16.0) (2012-10-22)
[Full Changelog](https://github.com/chef/chef/compare/10.16.0.rc.2...10.16.0)

**Merged pull requests:**

- Save reporting data to disk on HTTP failure [\#440](https://github.com/chef/chef/pull/440) ([btm](https://github.com/btm))
- \[CHEF-2737\] remove subtractive merge [\#439](https://github.com/chef/chef/pull/439) ([danielsdeleo](https://github.com/danielsdeleo))
- \[CHEF-2992\] [\#436](https://github.com/chef/chef/pull/436) ([danielsdeleo](https://github.com/danielsdeleo))

## [10.16.0.rc.2](https://github.com/chef/chef/tree/10.16.0.rc.2) (2012-10-19)
[Full Changelog](https://github.com/chef/chef/compare/10.16.0.rc.1...10.16.0.rc.2)

## [10.16.0.rc.1](https://github.com/chef/chef/tree/10.16.0.rc.1) (2012-10-17)
[Full Changelog](https://github.com/chef/chef/compare/10.16.0.rc.0...10.16.0.rc.1)

**Merged pull requests:**

- Chef 3520: add knife-essentials \(knife diff/download/upload/raw/show/list/delete\) to core Chef [\#430](https://github.com/chef/chef/pull/430) ([jkeiser](https://github.com/jkeiser))

## [10.16.0.rc.0](https://github.com/chef/chef/tree/10.16.0.rc.0) (2012-10-11)
[Full Changelog](https://github.com/chef/chef/compare/10.14.4...10.16.0.rc.0)

**Merged pull requests:**

- Lcg/reporting ignores 500s [\#423](https://github.com/chef/chef/pull/423) ([lamont-opscode](https://github.com/lamont-opscode))
- Reporting with summary only [\#421](https://github.com/chef/chef/pull/421) ([PrajaktaPurohit](https://github.com/PrajaktaPurohit))
- Pull all rebased resource updating changes into 10-stable [\#405](https://github.com/chef/chef/pull/405) ([tylercloke](https://github.com/tylercloke))

## [10.14.4](https://github.com/chef/chef/tree/10.14.4) (2012-09-27)
[Full Changelog](https://github.com/chef/chef/compare/10.14.4.rc.0...10.14.4)

**Merged pull requests:**

- disable reporting in why-run [\#412](https://github.com/chef/chef/pull/412) ([sersut](https://github.com/sersut))
- Compressing data for reporting [\#406](https://github.com/chef/chef/pull/406) ([sersut](https://github.com/sersut))

## [10.14.4.rc.0](https://github.com/chef/chef/tree/10.14.4.rc.0) (2012-09-24)
[Full Changelog](https://github.com/chef/chef/compare/10.14.2...10.14.4.rc.0)

**Merged pull requests:**

- CHEF-3375: remote\_file support for URL lists to use as mirrors [\#372](https://github.com/chef/chef/pull/372) ([zuazo](https://github.com/zuazo))

## [10.14.2](https://github.com/chef/chef/tree/10.14.2) (2012-09-10)
[Full Changelog](https://github.com/chef/chef/compare/10.14.0...10.14.2)

## [10.14.0](https://github.com/chef/chef/tree/10.14.0) (2012-09-07)
[Full Changelog](https://github.com/chef/chef/compare/10.14.0.rc.4...10.14.0)

## [10.14.0.rc.4](https://github.com/chef/chef/tree/10.14.0.rc.4) (2012-09-06)
[Full Changelog](https://github.com/chef/chef/compare/10.14.0.rc.3...10.14.0.rc.4)

## [10.14.0.rc.3](https://github.com/chef/chef/tree/10.14.0.rc.3) (2012-09-06)
[Full Changelog](https://github.com/chef/chef/compare/10.14.0.rc.2...10.14.0.rc.3)

## [10.14.0.rc.2](https://github.com/chef/chef/tree/10.14.0.rc.2) (2012-09-06)
[Full Changelog](https://github.com/chef/chef/compare/10.14.0.rc.1...10.14.0.rc.2)

**Merged pull requests:**

- Reporting updates [\#386](https://github.com/chef/chef/pull/386) ([sersut](https://github.com/sersut))
- fixes CHEF-3400 and pulls forwards reporting diff generation fixes [\#382](https://github.com/chef/chef/pull/382) ([lamont-opscode](https://github.com/lamont-opscode))

## [10.14.0.rc.1](https://github.com/chef/chef/tree/10.14.0.rc.1) (2012-08-28)
[Full Changelog](https://github.com/chef/chef/compare/10.14.0.rc.0...10.14.0.rc.1)

**Merged pull requests:**

- Oc 3152: throttle diff output [\#375](https://github.com/chef/chef/pull/375) ([lamont-opscode](https://github.com/lamont-opscode))
- CHEF-3276 [\#374](https://github.com/chef/chef/pull/374) ([PrajaktaPurohit](https://github.com/PrajaktaPurohit))

## [10.14.0.rc.0](https://github.com/chef/chef/tree/10.14.0.rc.0) (2012-08-21)
[Full Changelog](https://github.com/chef/chef/compare/10.14.0.beta.3...10.14.0.rc.0)

**Merged pull requests:**

- needs config to point at client key, revert config when we're done [\#369](https://github.com/chef/chef/pull/369) ([lamont-opscode](https://github.com/lamont-opscode))
- make restoring the config state more resiliant [\#367](https://github.com/chef/chef/pull/367) ([lamont-opscode](https://github.com/lamont-opscode))
- fix spec for operating systems where gid 0 name is not "wheel" [\#366](https://github.com/chef/chef/pull/366) ([lamont-opscode](https://github.com/lamont-opscode))
- 10 stable bugsfix [\#365](https://github.com/chef/chef/pull/365) ([PrajaktaPurohit](https://github.com/PrajaktaPurohit))
- Chef 3235 [\#361](https://github.com/chef/chef/pull/361) ([lamont-opscode](https://github.com/lamont-opscode))
- Fix knife functional tests to correctly reset the config state and ... [\#358](https://github.com/chef/chef/pull/358) ([sersut](https://github.com/sersut))
- Fixed config\_file\_selection path error seen when HOME is set to / [\#357](https://github.com/chef/chef/pull/357) ([PrajaktaPurohit](https://github.com/PrajaktaPurohit))
- Enforce ownership and permissions spec [\#356](https://github.com/chef/chef/pull/356) ([lamont-opscode](https://github.com/lamont-opscode))

## [10.14.0.beta.3](https://github.com/chef/chef/tree/10.14.0.beta.3) (2012-07-26)
[Full Changelog](https://github.com/chef/chef/compare/10.12.0...10.14.0.beta.3)

## [10.12.0](https://github.com/chef/chef/tree/10.12.0) (2012-06-18)
[Full Changelog](https://github.com/chef/chef/compare/10.12.0.rc.1...10.12.0)

## [10.12.0.rc.1](https://github.com/chef/chef/tree/10.12.0.rc.1) (2012-05-31)
[Full Changelog](https://github.com/chef/chef/compare/0.10.10...10.12.0.rc.1)

**Merged pull requests:**

- Proposed changes for \[CHEF-3142\] [\#306](https://github.com/chef/chef/pull/306) ([schisamo](https://github.com/schisamo))
- Fix link provider: Chef 2389, 3102, 3110, 3111, 3112 and others [\#299](https://github.com/chef/chef/pull/299) ([jkeiser](https://github.com/jkeiser))

## [0.10.10](https://github.com/chef/chef/tree/0.10.10) (2012-05-11)
[Full Changelog](https://github.com/chef/chef/compare/0.10.10.rc.3...0.10.10)

**Merged pull requests:**

- CHEF-3090: shellout loglevel compat [\#288](https://github.com/chef/chef/pull/288) ([hosh](https://github.com/hosh))

## [0.10.10.rc.3](https://github.com/chef/chef/tree/0.10.10.rc.3) (2012-05-02)
[Full Changelog](https://github.com/chef/chef/compare/0.10.10.rc.2...0.10.10.rc.3)

## [0.10.10.rc.2](https://github.com/chef/chef/tree/0.10.10.rc.2) (2012-05-01)
[Full Changelog](https://github.com/chef/chef/compare/0.10.10.rc.1...0.10.10.rc.2)

## [0.10.10.rc.1](https://github.com/chef/chef/tree/0.10.10.rc.1) (2012-04-30)
[Full Changelog](https://github.com/chef/chef/compare/0.10.10.beta.1...0.10.10.rc.1)

**Merged pull requests:**

- \[CHEF-1681\] Fix cron provider to handle commented out crontab lines [\#251](https://github.com/chef/chef/pull/251) ([alext](https://github.com/alext))

## [0.10.10.beta.1](https://github.com/chef/chef/tree/0.10.10.beta.1) (2012-04-06)
[Full Changelog](https://github.com/chef/chef/compare/0.10.8...0.10.10.beta.1)

**Merged pull requests:**

- \[CHEF-2824\] Add mount provider for Solaris OS and derivatives [\#203](https://github.com/chef/chef/pull/203) ([hfichter](https://github.com/hfichter))
- Exit with status 1 for knife cookbook upload errors [\#171](https://github.com/chef/chef/pull/171) ([andrewle](https://github.com/andrewle))

## [0.10.8](https://github.com/chef/chef/tree/0.10.8) (2011-12-16)
[Full Changelog](https://github.com/chef/chef/compare/0.10.6...0.10.8)

## [0.10.6](https://github.com/chef/chef/tree/0.10.6) (2011-12-13)
[Full Changelog](https://github.com/chef/chef/compare/0.10.6.rc.5...0.10.6)

## [0.10.6.rc.5](https://github.com/chef/chef/tree/0.10.6.rc.5) (2011-12-07)
[Full Changelog](https://github.com/chef/chef/compare/0.10.6.rc.4...0.10.6.rc.5)

## [0.10.6.rc.4](https://github.com/chef/chef/tree/0.10.6.rc.4) (2011-12-02)
[Full Changelog](https://github.com/chef/chef/compare/0.10.6.rc.3...0.10.6.rc.4)

## [0.10.6.rc.3](https://github.com/chef/chef/tree/0.10.6.rc.3) (2011-11-28)
[Full Changelog](https://github.com/chef/chef/compare/0.10.6.rc.2...0.10.6.rc.3)

## [0.10.6.rc.2](https://github.com/chef/chef/tree/0.10.6.rc.2) (2011-11-21)
[Full Changelog](https://github.com/chef/chef/compare/0.10.6.rc.1...0.10.6.rc.2)

## [0.10.6.rc.1](https://github.com/chef/chef/tree/0.10.6.rc.1) (2011-11-16)
[Full Changelog](https://github.com/chef/chef/compare/0.10.6.beta.3...0.10.6.rc.1)

## [0.10.6.beta.3](https://github.com/chef/chef/tree/0.10.6.beta.3) (2011-11-10)
[Full Changelog](https://github.com/chef/chef/compare/0.10.6.beta.2...0.10.6.beta.3)

**Merged pull requests:**

- Fixed typo in chef-solr Rakefile [\#177](https://github.com/chef/chef/pull/177) ([iafonov](https://github.com/iafonov))
- Don't depend on the value of an masgn [\#174](https://github.com/chef/chef/pull/174) ([dje](https://github.com/dje))

## [0.10.6.beta.2](https://github.com/chef/chef/tree/0.10.6.beta.2) (2011-11-01)
[Full Changelog](https://github.com/chef/chef/compare/0.10.6.beta.1...0.10.6.beta.2)

## [0.10.6.beta.1](https://github.com/chef/chef/tree/0.10.6.beta.1) (2011-10-31)
[Full Changelog](https://github.com/chef/chef/compare/0.10.4...0.10.6.beta.1)

**Merged pull requests:**

- Chef-2357/2358: support cwd and environment on Windows shell\_out [\#170](https://github.com/chef/chef/pull/170) ([jkeiser-oc](https://github.com/jkeiser-oc))
- Chef 2655 [\#166](https://github.com/chef/chef/pull/166) ([andreacampi](https://github.com/andreacampi))
- Chef 2549 new [\#157](https://github.com/chef/chef/pull/157) ([ctdk](https://github.com/ctdk))
- Robustify git resource, add development\_mode and update\_method, add tests  [\#105](https://github.com/chef/chef/pull/105) ([jkeiser-oc](https://github.com/jkeiser-oc))
- dev:features doesn't really want to call start\_chef\_solr\_indexer anymore [\#63](https://github.com/chef/chef/pull/63) ([jtimberman](https://github.com/jtimberman))

## [0.10.4](https://github.com/chef/chef/tree/0.10.4) (2011-08-11)
[Full Changelog](https://github.com/chef/chef/compare/0.10.2...0.10.4)

**Merged pull requests:**

- Changes documentation to account for change from \(-d to -D\) in knife cookbook site install.  [\#115](https://github.com/chef/chef/pull/115) ([stevendanna](https://github.com/stevendanna))

## [0.10.2](https://github.com/chef/chef/tree/0.10.2) (2011-06-29)
[Full Changelog](https://github.com/chef/chef/compare/0.9.18...0.10.2)

## [0.9.18](https://github.com/chef/chef/tree/0.9.18) (2011-06-29)
[Full Changelog](https://github.com/chef/chef/compare/0.10.0...0.9.18)

**Merged pull requests:**

- Add 'additional\_remotes' property to 'git' resource [\#91](https://github.com/chef/chef/pull/91) ([jkeiser-oc](https://github.com/jkeiser-oc))
- Fix for CHEF-2378 [\#90](https://github.com/chef/chef/pull/90) ([wolfpakz](https://github.com/wolfpakz))
- add support for reading key from remote url [\#77](https://github.com/chef/chef/pull/77) ([lusis](https://github.com/lusis))

## [0.10.0](https://github.com/chef/chef/tree/0.10.0) (2011-05-02)
[Full Changelog](https://github.com/chef/chef/compare/0.10.0.rc.2...0.10.0)

**Merged pull requests:**

- PATH issue for groupadd/useradd [\#38](https://github.com/chef/chef/pull/38) ([lusis](https://github.com/lusis))

## [0.10.0.rc.2](https://github.com/chef/chef/tree/0.10.0.rc.2) (2011-04-29)
[Full Changelog](https://github.com/chef/chef/compare/0.10.0.rc.1...0.10.0.rc.2)

## [0.10.0.rc.1](https://github.com/chef/chef/tree/0.10.0.rc.1) (2011-04-28)
[Full Changelog](https://github.com/chef/chef/compare/0.10.0.rc.0...0.10.0.rc.1)

**Merged pull requests:**

- mount support for fuse filesystems in chef [\#54](https://github.com/chef/chef/pull/54) ([wfelipe](https://github.com/wfelipe))

## [0.10.0.rc.0](https://github.com/chef/chef/tree/0.10.0.rc.0) (2011-04-15)
[Full Changelog](https://github.com/chef/chef/compare/0.9.16...0.10.0.rc.0)

## [0.9.16](https://github.com/chef/chef/tree/0.9.16) (2011-04-15)
[Full Changelog](https://github.com/chef/chef/compare/0.10.0.beta.10...0.9.16)

## [0.10.0.beta.10](https://github.com/chef/chef/tree/0.10.0.beta.10) (2011-04-14)
[Full Changelog](https://github.com/chef/chef/compare/0.10.0.beta.9...0.10.0.beta.10)

## [0.10.0.beta.9](https://github.com/chef/chef/tree/0.10.0.beta.9) (2011-04-11)
[Full Changelog](https://github.com/chef/chef/compare/0.10.0.beta.8...0.10.0.beta.9)

## [0.10.0.beta.8](https://github.com/chef/chef/tree/0.10.0.beta.8) (2011-04-08)
[Full Changelog](https://github.com/chef/chef/compare/0.10.0.beta.7...0.10.0.beta.8)

## [0.10.0.beta.7](https://github.com/chef/chef/tree/0.10.0.beta.7) (2011-04-06)
[Full Changelog](https://github.com/chef/chef/compare/0.10.0.beta.6...0.10.0.beta.7)

## [0.10.0.beta.6](https://github.com/chef/chef/tree/0.10.0.beta.6) (2011-04-04)
[Full Changelog](https://github.com/chef/chef/compare/0.10.0.beta.5...0.10.0.beta.6)

## [0.10.0.beta.5](https://github.com/chef/chef/tree/0.10.0.beta.5) (2011-03-31)
[Full Changelog](https://github.com/chef/chef/compare/0.10.0.beta.4...0.10.0.beta.5)

## [0.10.0.beta.4](https://github.com/chef/chef/tree/0.10.0.beta.4) (2011-03-31)
[Full Changelog](https://github.com/chef/chef/compare/0.10.0.beta.3...0.10.0.beta.4)

## [0.10.0.beta.3](https://github.com/chef/chef/tree/0.10.0.beta.3) (2011-03-30)
[Full Changelog](https://github.com/chef/chef/compare/0.10.0.beta.2...0.10.0.beta.3)

## [0.10.0.beta.2](https://github.com/chef/chef/tree/0.10.0.beta.2) (2011-03-30)
[Full Changelog](https://github.com/chef/chef/compare/0.10.0.beta.1...0.10.0.beta.2)

## [0.10.0.beta.1](https://github.com/chef/chef/tree/0.10.0.beta.1) (2011-03-29)
[Full Changelog](https://github.com/chef/chef/compare/0.10.0.beta.0...0.10.0.beta.1)

## [0.10.0.beta.0](https://github.com/chef/chef/tree/0.10.0.beta.0) (2011-03-28)
[Full Changelog](https://github.com/chef/chef/compare/0.9.14...0.10.0.beta.0)

## [0.9.14](https://github.com/chef/chef/tree/0.9.14) (2011-03-04)
[Full Changelog](https://github.com/chef/chef/compare/0.9.14.rc.1...0.9.14)

## [0.9.14.rc.1](https://github.com/chef/chef/tree/0.9.14.rc.1) (2011-03-03)
[Full Changelog](https://github.com/chef/chef/compare/0.9.14.beta.1...0.9.14.rc.1)

## [0.9.14.beta.1](https://github.com/chef/chef/tree/0.9.14.beta.1) (2011-02-09)
[Full Changelog](https://github.com/chef/chef/compare/pl-rel-1.0.0...0.9.14.beta.1)

## [pl-rel-1.0.0](https://github.com/chef/chef/tree/pl-rel-1.0.0) (2010-11-25)
[Full Changelog](https://github.com/chef/chef/compare/nofields-deploy...pl-rel-1.0.0)

## [nofields-deploy](https://github.com/chef/chef/tree/nofields-deploy) (2010-10-25)
[Full Changelog](https://github.com/chef/chef/compare/rel-0.9.12...nofields-deploy)

## [rel-0.9.12](https://github.com/chef/chef/tree/rel-0.9.12) (2010-10-22)
[Full Changelog](https://github.com/chef/chef/compare/0.9.12...rel-0.9.12)

## [0.9.12](https://github.com/chef/chef/tree/0.9.12) (2010-10-22)
[Full Changelog](https://github.com/chef/chef/compare/0.9.10...0.9.12)

## [0.9.10](https://github.com/chef/chef/tree/0.9.10) (2010-10-19)
[Full Changelog](https://github.com/chef/chef/compare/0.9.10.rc.3...0.9.10)

## [0.9.10.rc.3](https://github.com/chef/chef/tree/0.9.10.rc.3) (2010-10-12)
[Full Changelog](https://github.com/chef/chef/compare/0.9.10.rc.2...0.9.10.rc.3)

## [0.9.10.rc.2](https://github.com/chef/chef/tree/0.9.10.rc.2) (2010-10-08)
[Full Changelog](https://github.com/chef/chef/compare/0.9.10.rc.1...0.9.10.rc.2)

## [0.9.10.rc.1](https://github.com/chef/chef/tree/0.9.10.rc.1) (2010-10-08)
[Full Changelog](https://github.com/chef/chef/compare/0.9.10.rc.0...0.9.10.rc.1)

## [0.9.10.rc.0](https://github.com/chef/chef/tree/0.9.10.rc.0) (2010-10-07)
[Full Changelog](https://github.com/chef/chef/compare/beta-1...0.9.10.rc.0)

## [beta-1](https://github.com/chef/chef/tree/beta-1) (2010-09-21)
[Full Changelog](https://github.com/chef/chef/compare/beta-1-pre...beta-1)

## [beta-1-pre](https://github.com/chef/chef/tree/beta-1-pre) (2010-09-15)
[Full Changelog](https://github.com/chef/chef/compare/0.9.8...beta-1-pre)

## [0.9.8](https://github.com/chef/chef/tree/0.9.8) (2010-08-05)
[Full Changelog](https://github.com/chef/chef/compare/0.9.8.rc.0...0.9.8)

## [0.9.8.rc.0](https://github.com/chef/chef/tree/0.9.8.rc.0) (2010-07-31)
[Full Changelog](https://github.com/chef/chef/compare/0.9.8.beta.2...0.9.8.rc.0)

## [0.9.8.beta.2](https://github.com/chef/chef/tree/0.9.8.beta.2) (2010-07-29)
[Full Changelog](https://github.com/chef/chef/compare/0.9.8.beta.1...0.9.8.beta.2)

## [0.9.8.beta.1](https://github.com/chef/chef/tree/0.9.8.beta.1) (2010-07-23)
[Full Changelog](https://github.com/chef/chef/compare/0.9.6...0.9.8.beta.1)

## [0.9.6](https://github.com/chef/chef/tree/0.9.6) (2010-07-02)
[Full Changelog](https://github.com/chef/chef/compare/0.9.4...0.9.6)

## [0.9.4](https://github.com/chef/chef/tree/0.9.4) (2010-06-30)
[Full Changelog](https://github.com/chef/chef/compare/0.9.2...0.9.4)

## [0.9.2](https://github.com/chef/chef/tree/0.9.2) (2010-06-29)
[Full Changelog](https://github.com/chef/chef/compare/0.9.0...0.9.2)

## [0.9.0](https://github.com/chef/chef/tree/0.9.0) (2010-06-21)
[Full Changelog](https://github.com/chef/chef/compare/0.9.0.rc02...0.9.0)

## [0.9.0.rc02](https://github.com/chef/chef/tree/0.9.0.rc02) (2010-06-17)
[Full Changelog](https://github.com/chef/chef/compare/0.9.0.rc01...0.9.0.rc02)

## [0.9.0.rc01](https://github.com/chef/chef/tree/0.9.0.rc01) (2010-06-16)
[Full Changelog](https://github.com/chef/chef/compare/0.9.0.b02...0.9.0.rc01)

## [0.9.0.b02](https://github.com/chef/chef/tree/0.9.0.b02) (2010-06-13)
[Full Changelog](https://github.com/chef/chef/compare/0.8.16...0.9.0.b02)

## [0.8.16](https://github.com/chef/chef/tree/0.8.16) (2010-05-12)
[Full Changelog](https://github.com/chef/chef/compare/0.8.14...0.8.16)

## [0.8.14](https://github.com/chef/chef/tree/0.8.14) (2010-05-07)
[Full Changelog](https://github.com/chef/chef/compare/0.8.12...0.8.14)

## [0.8.12](https://github.com/chef/chef/tree/0.8.12) (2010-05-06)
[Full Changelog](https://github.com/chef/chef/compare/alpha_deploy_4...0.8.12)

## [alpha_deploy_4](https://github.com/chef/chef/tree/alpha_deploy_4) (2010-04-14)
[Full Changelog](https://github.com/chef/chef/compare/0.8.10...alpha_deploy_4)

## [0.8.10](https://github.com/chef/chef/tree/0.8.10) (2010-04-01)
[Full Changelog](https://github.com/chef/chef/compare/0.8.8...0.8.10)

## [0.8.8](https://github.com/chef/chef/tree/0.8.8) (2010-03-18)
[Full Changelog](https://github.com/chef/chef/compare/0.8.6...0.8.8)

## [0.8.6](https://github.com/chef/chef/tree/0.8.6) (2010-03-05)
[Full Changelog](https://github.com/chef/chef/compare/0.8.4...0.8.6)

## [0.8.4](https://github.com/chef/chef/tree/0.8.4) (2010-03-02)
[Full Changelog](https://github.com/chef/chef/compare/alpha_deploy_3...0.8.4)

## [alpha_deploy_3](https://github.com/chef/chef/tree/alpha_deploy_3) (2010-02-28)
[Full Changelog](https://github.com/chef/chef/compare/0.8.2...alpha_deploy_3)

## [0.8.2](https://github.com/chef/chef/tree/0.8.2) (2010-02-28)
[Full Changelog](https://github.com/chef/chef/compare/alpha_deploy_2...0.8.2)

## [alpha_deploy_2](https://github.com/chef/chef/tree/alpha_deploy_2) (2010-02-28)
[Full Changelog](https://github.com/chef/chef/compare/0.7.16...alpha_deploy_2)

## [0.7.16](https://github.com/chef/chef/tree/0.7.16) (2009-12-22)
[Full Changelog](https://github.com/chef/chef/compare/0.7.14...0.7.16)

## [0.7.14](https://github.com/chef/chef/tree/0.7.14) (2009-10-26)
[Full Changelog](https://github.com/chef/chef/compare/0.7.12rc0...0.7.14)

## [0.7.12rc0](https://github.com/chef/chef/tree/0.7.12rc0) (2009-10-03)
[Full Changelog](https://github.com/chef/chef/compare/0.7.10...0.7.12rc0)

## [0.7.10](https://github.com/chef/chef/tree/0.7.10) (2009-09-04)
[Full Changelog](https://github.com/chef/chef/compare/0.7.8...0.7.10)

## [0.7.8](https://github.com/chef/chef/tree/0.7.8) (2009-08-12)
[Full Changelog](https://github.com/chef/chef/compare/0.7.6...0.7.8)

## [0.7.6](https://github.com/chef/chef/tree/0.7.6) (2009-08-07)
[Full Changelog](https://github.com/chef/chef/compare/0.7.4...0.7.6)

## [0.7.4](https://github.com/chef/chef/tree/0.7.4) (2009-06-26)
[Full Changelog](https://github.com/chef/chef/compare/0.7.2...0.7.4)

## [0.7.2](https://github.com/chef/chef/tree/0.7.2) (2009-06-24)
[Full Changelog](https://github.com/chef/chef/compare/0.7.0...0.7.2)

## [0.7.0](https://github.com/chef/chef/tree/0.7.0) (2009-06-10)
[Full Changelog](https://github.com/chef/chef/compare/0.6.2...0.7.0)

## [0.6.2](https://github.com/chef/chef/tree/0.6.2) (2009-04-29)
[Full Changelog](https://github.com/chef/chef/compare/0.6.0...0.6.2)

## [0.6.0](https://github.com/chef/chef/tree/0.6.0) (2009-04-28)
[Full Changelog](https://github.com/chef/chef/compare/0.5.6...0.6.0)

## [0.5.6](https://github.com/chef/chef/tree/0.5.6) (2009-03-06)
[Full Changelog](https://github.com/chef/chef/compare/0.5.4...0.5.6)

## [0.5.4](https://github.com/chef/chef/tree/0.5.4) (2009-02-13)
[Full Changelog](https://github.com/chef/chef/compare/0.5.2...0.5.4)

## [0.5.2](https://github.com/chef/chef/tree/0.5.2) (2009-02-01)
[Full Changelog](https://github.com/chef/chef/compare/chef-server-package...0.5.2)

## [chef-server-package](https://github.com/chef/chef/tree/chef-server-package) (2008-06-16)
[Full Changelog](https://github.com/chef/chef/compare/Unreleased...chef-server-package)


## Unreleased

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


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*