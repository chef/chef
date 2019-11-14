# Chef Utils gem

**Umbrella Project**: [Chef Infra](https://github.com/chef/chef-oss-practices/blob/master/projects/chef-infra.md)

**Project State**: [Active](https://github.com/chef/chef-oss-practices/blob/master/repo-management/repo-states.md#active)

**Issues [Response Time Maximum](https://github.com/chef/chef-oss-practices/blob/master/repo-management/repo-states.md)**: 14 days

**Pull Request [Response Time Maximum](https://github.com/chef/chef-oss-practices/blob/master/repo-management/repo-states.md)**: 14 days

## Getting Started

Chef Utils gem is common code and mixins for the core Chef Infra ruby gems.  This should be are "core library" or "foundations" library
for the chef ecosystem (and external related gems) which allows the use of core code and utility functions of the chef gem without requiring
all the heaviness of the chef gem.

### Platform Helpers

Individual platforms for when code MUST be different on a case-by-case basis.  It is generally encouraged to not use these and to use
the `platform_family` helpers unless it is known that code must be special cased for individual platforms.

* `aix_platform?`
* `amazon_platform?`
* `arch_platform?`
* `centos_platform?`
* `clearos_platform?`
* `debian_platform?`
* `dragonfly_platform?`
* `fedora_platform?`
* `freebsd_platform?`
* `gentoo_platform?`
* `leap_platform?`
* `linuxmint_platform?`
* `macos_platform?`
* `netbsd_platform?`
* `nexentacore_platform?`
* `omnios_platform?`
* `openbsd_platform?`
* `openindiana_platform?`
* `opensolaris_platform?`
* `opensuse_platform?`
* `oracle_platform?`
* `raspbian_platform?`
* `redhat_platform?`
* `scientific_platform?`
* `slackware_platform?`
* `smartos_platform?`
* `solaris2_platform?`
* `suse_platform?`
* `ubuntu_platform?`
* `windows_platform?`

For campatibility with old chef-sugar code the following aliases work for backwards compatibility, but will be DEPRECATED in the future.

* `centos?`
* `clearos?`
* `linuxmint?`
* `nexentacore?`
* `omnios?`
* `openindiana?`
* `opensolaris?`
* `opensuse?`
* `oracle?`
* `raspbian?`
* `redhat?`
* `scientific?`
* `ubuntu?`

### Platform Family Helpers

These should be the most commonly used helpers to identify the type of node which group somewhat similar or nearly identical types of platforms.
There are helpers here which are also meta-families which group together multiple types into supertypes.

* `aix?`
* `amazon?`
* `arch?`
* `debian?` - includes debian, ubuntu, linuxmint, raspbian, etc
* `dragonflybsd?`
* `fedora?`
* `freebsd?`
* `gentoo?`
* `macos?`
* `netbsd?`
* `openbsd?`
* `rhel?` - includes redhat, centos, scientific, oracle, clearos
* `rhel6?` - includes redhat6, centos6, scientifc6, oracle6, clearos6
* `rhel7?` - includes redhat7, centos7, scientifc7, oracle7, clearos7
* `rhel8?` - includes redhat8, centos8, scientifc8, oracle8, clearos8
* `smartos?`
* `solaris2?`
* `suse?`
* `windows?` - in a class context when called without a node object (ChefUtils.windows?) this is not stubbable by chefspec, when called with a node as the first argument or when called from the DSL it is stubabble by chefspec
* `windows_ruby?` - this is always true if the ruby VM is running on a windows host and is not stubbed by chefspec

Super Families:

* `fedora_based?` - anything of fedora lineage (fedora, fedhat, centos, amazon, pidora, etc)
* `rpm_based?`- all `fedora_based` systems plus `suse` and any future linux distros based on RPM (excluding AIX)
* `solaris_based?`- all solaris-derived systems (opensolaris, nexentacore, omnios, smartos, etc)
* `bsd_based?`- all bsd-derived systems (freebsd, netbsd, openbsd, dragonflybsd).

### OS Helpers

OS helpers are only provided for OS types that contain multiple platform families ("linux"), or for unique OS values ("darwin").  Users should
use the Platform Family helper level instead.

* linux?
* darwin?

### Architecture Helpers

* `_64_bit?`
* `_32_bit?`
* `i386?`
* `intel?`
* `sparc?`
* `ppc64?`
* `ppc64le?`
* `powerpc?`
* `armhf?`
* `s390x?`
* `s390?`

### Train Helpers

**EXPERIMENTAL**: APIs may have breaking changes any time without warning

* `file_exist?`
* `file_open`

### Introspection Helpers

* `docker?` - if the node is running inside of docker
* `systemd?` - if the init system is systemd
* `kitchen?` - if ENV['TEST_KITCHEN'] is set
* `ci?` - if ENV['CI'] is set

### Service Helpers

* `debianrcd?` - if the `update-rc.d` binary is present
* `invokercd?` - if the `invoke-rc.d` binary is present
* `upstart?` - if the `initctl` binary is present
* `insserv?` - if the `insserv` binary is present
* `redhatrcd?` - if the `chkconfig` binary is present

* `service_script_exist?(type, service)`

### Which/Where Helpers

* `which`
* `where`

### Path Sanity Helpers

* `sanitized_path`

## Documentation for Software Developers

The design of the DSL helper libraries in this gem are designed around the Chef Infra Client use cases.  Most of the helpers are
accessible through the Chef DSL directly via the `ChefUtils::DSL` module.  They are also available via class method calls on
the ChefUtils module directly (e.g. `ChefUtils.debian?`).  For that to be possible there is Chef Infra Client specific wiring in
the `ChefUtils::Internal` class allowing the helpers to access the `Chef.run_context` global values.  This allows them to be
used from library helpers in cookbooks inside Chef Infra Client.

For external use in other gems, this automatic wiring will not work correctly, and so it will not generally be possible to
call helpers off of the `ChefUtils` class (somee exceptions that do not require a node-like object or a train connection will
may still work).  For use in other gems you should create your own module and mixin the helper class.  If you have a node
method in your class/module then that method will be used.

You can wire up a module which implements the Chef DSL with your own wiring using this template:

```ruby
module MyDSL
  include ChefUtils::DSL # or any individual module with DSL methods in it

  private

  def __getnode
    # return something Mash-like with node semantics with a node["platform"], etc.
  end

  def __transport_connection
    # return a Train::Transport connection
  end

  extend self # if your wiring is to global state to make `MyDSL.helper?` work.
end
```

Those methods are marked API private for the purposes of end-users, but are public APIs for the purposes of software development.

## Getting Involved

We'd love to have your help developing Chef Infra. See our [Contributing Document](./CONTRIBUTING.md) for more information on getting started.

## License and Copyright

Copyright 2008-2019, Chef Software, Inc.

```
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
