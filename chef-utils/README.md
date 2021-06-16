# Chef Utils gem

**Umbrella Project**: [Chef Infra](https://github.com/chef/chef-oss-practices/blob/master/projects/chef-infra.md)

**Project State**: [Active](https://github.com/chef/chef-oss-practices/blob/master/repo-management/repo-states.md#active)

**Issues [Response Time Maximum](https://github.com/chef/chef-oss-practices/blob/master/repo-management/repo-states.md)**: 14 days

**Pull Request [Response Time Maximum](https://github.com/chef/chef-oss-practices/blob/master/repo-management/repo-states.md)**: 14 days

## Getting Started

Chef Utils gem contains common code and mixins for the core Chef Infra Ruby gems. This is intended to be a "core" or "foundations" library
for the chef ecosystem (and external related gems) which allows the use of core code and utility functions of the chef gem without requiring
all the heaviness of the chef gem.

### Platform Family Helpers

The Platform Family helpers provide an alternative to comparing values from `node['platform_family']` or using the `platform_family?()` helper method. They allow you to write simpler logic that checks for specific platform family. Additionally we've provided several super families listed below, which bundle together common platform families into a single helper.

* `aix?`
* `amazon?`
* `arch?` - includes arch, manjaro, and antergos platforms
* `debian?` - includes debian, ubuntu, linuxmint, raspbian, and devuan platforms
* `dragonflybsd?`
* `fedora?` - includes arista_eos, fedora, and pidora platforms
* `freebsd?`
* `gentoo?`
* `macos?`
* `macos_ruby?` - this is always true if the ruby VM is running on a mac host and is not stubbed by ChefSpec
* `netbsd?`
* `openbsd?`
* `rhel?` - includes redhat, centos, scientific, oracle, and clearos platforms
* `rhel6?` - includes redhat6, centos6, scientific6, oracle6, and clearos6 platforms
* `rhel7?` - includes redhat7, centos7, scientific7, oracle7, and clearos7 platforms
* `rhel8?` - includes redhat8, centos8, scientific8, oracle8, and clearos8 platforms
* `smartos?`
* `solaris2?`
* `suse?` - includes suse and opensuseleap platforms
* `windows?` - NOTE: in a class context when called without a node object (ChefUtils.windows?) this is not stubbable by ChefSpec, but when called with a node as the first argument or when called from the DSL it is stubabble by chefspec
* `windows_ruby?` - this is always true if the ruby VM is running on a windows host and is not stubbed by ChefSpec

Super Families:

* `fedora_based?` - anything of fedora lineage (fedora, redhat, centos, amazon, pidora, etc)
* `rpm_based?`- all `fedora_based` systems plus `suse` and any future linux distros based on RPM (excluding AIX)
* `solaris_based?`- all solaris-derived systems (omnios, smartos, openindiana, etc)
* `bsd_based?`- all bsd-derived systems (freebsd, netbsd, openbsd, dragonflybsd).

### Platform Helpers

The Platform helpers provide an alternative to comparing values from `node['platform']` or using the `platform?()` helper method. In general we'd highly suggest writing code using the Platform Family helpers, but these helpers can be used when it's necessary to target specific platforms.

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
* `omnios_platform?`
* `openbsd_platform?`
* `openindiana_platform?`
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

For compatibility with old chef-sugar code the following aliases work for backwards compatibility, but will be DEPRECATED in the future.

* `centos?`
* `clearos?`
* `linuxmint?`
* `omnios?`
* `openindiana?`
* `opensuse?`
* `oracle?`
* `raspbian?`
* `redhat?`
* `scientific?`
* `ubuntu?`

### OS Helpers

The OS helpers provide an alternative to comparing data from `node['os']`.

* `linux?` - Any Linux distribution
* `darwin?` - Darwin or macOS platforms

### Architecture Helpers

Architecture Helpers allow you to determine the processor architecture of your node.

* `_32_bit?`
* `_64_bit?`
* `arm?`
* `armhf?`
* `i386?`
* `intel?`
* `powerpc?`
* `ppc64?`
* `ppc64le?`
* `s390?`
* `s390x?`
* `sparc?`

### Cloud Helpers

* `cloud?` - if the node is running in any cloud, including internal ones
* `alibaba?` - if the node is running in alibaba cloud
* `ec2?` - if the node is running in ec2
* `gce?` - if the node is running in gce
* `rackspace?` - if the node is running in rackspace
* `eucalyptus?` - if the node is running under eucalyptus
* `linode?` - if the node is running in linode
* `openstack?` - if the node is running under openstack
* `azure?` - if the node is running in azure
* `digital_ocean?` - if the node is running in digital ocean
* `softlayer?` - if the node is running in softlayer

### Virtualization Helpers

* `kvm?` - if the node is a kvm guest
* `kvm_host?` - if the node is a kvm host
* `lxc?` - if the node is an lxc guest
* `lxc_host?` - if the node is an lxc host
* `parallels?`- if the node is a parallels guest
* `parallels_host?`- if the node is a parallels host
* `vbox?` - if the node is a virtualbox guest
* `vbox_host?` - if the node is a virtualbox host
* `vmware?` - if the node is a vmware guest
* `vmware_host?` - if the node is a vmware host
* `openvz?` - if the node is an openvz guest
* `openvz_host?` - if the node is an openvz host
* `guest?` - if the node is detected as any kind of guest
* `hypervisor?` - if the node is detected as being any kind of hypervisor
* `physical?` - the node is not running as a guest (may be a hypervisor or may be bare-metal)
* `vagrant?` - attempts to identify the node as a vagrant guest (this check may be error prone)

### Train Helpers

**EXPERIMENTAL**: APIs may have breaking changes any time without warning

* `file_exist?`
* `file_open`

### Introspection Helpers

* `docker?` - if the node is running inside of docker
* `systemd?` - if the init system is systemd
* `kitchen?` - if ENV['TEST_KITCHEN'] is set
* `ci?` - if ENV['CI'] is set
* `include_recipe?(recipe_name)` - if the `recipe_name` is in the run list, the expanded run list, or has been `include_recipe`'d.

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

## Documentation for Cookbook library authors

To use the helpers in a class or module in a cookbook library file you can include the ChefUtils DSL:

```ruby
module MyHelper
  include ChefUtils # or any individual module with DSL methods in it

  def do_something
    puts "RHEL" if rhel?
  end

  extend self
end
```

Now you can include MyHelper in another class/module, or you can call MyHelper.do_something directly.

## Documentation for Software Developers

The design of the DSL helper libraries in this gem are designed around the Chef Infra Client use cases. Most of the helpers are
accessible through the Chef DSL directly via the `ChefUtils` module. They are also available via class method calls on
the ChefUtils module directly (e.g. `ChefUtils.debian?`). For that to be possible there is Chef Infra Client specific wiring in
the `ChefUtils::Internal` class allowing the helpers to access the `Chef.run_context` global values. This allows them to be
used from library helpers in cookbooks inside Chef Infra Client.

For external use in other gems, this automatic wiring will not work correctly, and so it will not generally be possible to
call helpers off of the `ChefUtils` class (some exceptions that do not require a node-like object or a train connection will
may still work). For use in other gems you should create your own module and mixin the helper class. If you have a node
method in your class/module then that method will be used.

You can wire up a module which implements the Chef DSL with your own wiring using this template:

```ruby
module MyDSL
  include ChefUtils # or any individual module with DSL methods in it

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

We'd love to have your help developing Chef Infra. See our [Contributing Document](../CONTRIBUTING.md) for more information on getting started.

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
