# Chef Infra Client Resources Reference

> **Warning:** Progress Chef is currently reviewing the Chef Infra Client 19 resource documentation
> for accuracy and updating it. Please test your cookbooks accordingly.

> **Audit Date:** 2026-04-11  
> **Source:** `lib/chef/resource/` on the chef2 repository (Chef 19 branch)  
> **Reference:** https://deploy-preview-152--chef-infra-client.netlify.app/resources/bundled/

This reference describes each of the resources available to Chef Infra Client, including a list of actions, properties, and usage examples.

---

## Discrepancies & Audit Findings

### Resources in local code NOT documented on the webpage

These resources exist in `lib/chef/resource/` (including subdirectories) but were **not found** in the bundled resources webpage. They require new documentation entries:

| Resource | File | Introduced | Notes |
|---|---|---|---|
| `cron` | cron/cron.rb | unknown | Manage cron table entries |
| `cron_d` | cron/cron_d.rb | 14.4 | Manage /etc/cron.d files |
| `freebsd_package` | freebsd_package.rb | unknown | Package manager for FreeBSD |
| `git` | scm/git.rb | unknown | Manage Git source control checkouts |
| `group` | group.rb | unknown | Manage local groups |
| `habitat_config` | habitat_config.rb | 17.3 | Apply configuration to a Habitat service |
| `habitat_package` | habitat/habitat_package.rb | 17.3 | Manage Habitat packages |
| `habitat_sup` | habitat/habitat_sup.rb | 17.3 | Manage the Habitat supervisor |
| `habitat_user_toml` | habitat_user_toml.rb | 17.3 | Template user.toml for Habitat services |
| `homebrew_cask` | homebrew_cask.rb | 14.0 | Install macOS apps via Homebrew Cask |
| `homebrew_update` | homebrew_update.rb | 16.2 | Manage Homebrew repository updates on macOS |
| `hostname` | hostname.rb | 14.0 | Set the system hostname |
| `ips_package` | ips_package.rb | unknown | Solaris IPS package manager |
| `macos_pkg` | macos_pkg.rb | 18.1 | Install macOS .pkg files |
| `chef_client_hab_ca_cert` | chef_client_hab_ca_cert.rb | 19.1 | Add certificates to Habitat CA bundle |
| `plist` | plist.rb | 16.0 | Set config values in macOS plist files |
| `route` | route.rb | unknown | Manage the Linux system routing table |
| `selinux_boolean` | selinux_boolean.rb | 18.0 | Set SELinux boolean values |
| `selinux_fcontext` | selinux_fcontext.rb | 18.0 | Manage SELinux file contexts |
| `selinux_install` | selinux_install.rb | 18.0 | Install SELinux packages |
| `selinux_login` | selinux_login.rb | 18.1 | Manage SELinux user-to-OS login mappings |
| `selinux_module` | selinux_module.rb | 18.0 | Manage SELinux policy modules |
| `selinux_permissive` | selinux_permissive.rb | 18.0 | Set SELinux domains to permissive mode |
| `selinux_port` | selinux_port.rb | 18.0 | Assign network ports to SELinux contexts |
| `selinux_state` | selinux_state.rb | 18.0 | Manage the SELinux enforcing state |
| `selinux_user` | selinux_user.rb | 18.1 | Manage SELinux users |
| `smartos_package` | smartos_package.rb | unknown | Package manager for SmartOS |
| `ssh_known_hosts_entry` | ssh_known_hosts_entry.rb | 14.3 | Manage SSH known_hosts file entries |
| `subversion` | scm/subversion.rb | unknown | Manage Subversion source control checkouts |
| `swap_file` | swap_file.rb | 14.0 | Create or delete Linux swap files |
| `user_ulimit` | user_ulimit.rb | 16.0 | Manage per-user ulimit configuration files |
| `windows_audit_policy` | windows_audit_policy.rb | 16.2 | Configure Windows advanced audit policy |
| `windows_defender_exclusion` | windows_defender_exclusion.rb | 17.3 | Manage Windows Defender scan exclusions |
| `windows_firewall_profile` | windows_firewall_profile.rb | 16.3 | Configure Windows Firewall profiles |
| `windows_pagefile` | windows_pagefile.rb | 14.0 | Configure Windows pagefile settings |
| `windows_update_settings` | windows_update_settings.rb | 17.3 | Manage Windows Update patching options |

### Resources in the webpage that are NOT in local code

None. All resources shown on the web docs page have corresponding Ruby source files in the repository.

> **Note:** `script` appears in the web docs but is an **internal base class** used by bash/csh/ksh/perl/python/ruby — it is not a directly usable public resource.

### Version Number Discrepancies

The following resources have different "introduced in" versions between the web docs and local code. **Local code is authoritative:**

| Resource | Web Docs | Local Code | Correct Version |
|---|---|---|---|
| `chef_client_config` | 17.5 | 16.6 | **16.6** |
| `chef_client_cron` | 15.1 | 16.0 | **16.0** |
| `chef_client_hab_ca_cert` | 19.0 | 19.1 | **19.1** |
| `rhsm_errata` | 17.8 | 14.0 | **14.0** |
| `rhsm_errata_level` | 17.8 | 14.0 | **14.0** |
| `snap_package` | 14.0 | 15.0 | **15.0** |
| `windows_dfs_folder` | 16.0 | 15.0 | **15.0** |
| `windows_dfs_namespace` | 16.0 | 15.0 | **15.0** |
| `windows_dfs_server` | 16.0 | 15.0 | **15.0** |
| `windows_security_policy` | 17.0 | 16.0 | **16.0** |
| `windows_uac` | 17.3 | 15.0 | **15.0** |

### New Properties Added Since Last Documentation Update

| Resource | New Property | Type | Introduced |
|---|---|---|---|
| `apt_package` | `environment` | Hash | 19.0 |
| `apt_package` | `response_file` | String | 18.3 |
| `bash`, `csh`, `ksh`, `perl`, `python`, `ruby` | `cgroup` | String | 19.0 |
| `dnf_package` | `environment` | Hash | 19.0 |
| `dpkg_package` | `environment` | Hash | 19.0 |
| `execute` | `cgroup` | String | 19.0 |
| `execute` | `login` | true, false | 17.0 |
| `gem_package` | `environment` | Hash | 19.0 |
| `rpm_package` | `allow_downgrade` | true, false | 19.0 |
| `yum_package` | `environment` | Hash | 19.0 |

---

## Complete Resources Reference

All **169 resources** from the local codebase, in alphabetical order.
Source: `lib/chef/resource/` (including subdirectories)

Jump to a resource:

| Resource | Resource | Resource | Resource |
|---|---|---|---|
| [`alternatives`](#alternatives-resource) | [`apt_package`](#apt-package-resource) | [`apt_preference`](#apt-preference-resource) | [`apt_repository`](#apt-repository-resource) |
| [`apt_update`](#apt-update-resource) | [`archive_file`](#archive-file-resource) | [`bash`](#bash-resource) | [`batch`](#batch-resource) |
| [`bff_package`](#bff-package-resource) | [`breakpoint`](#breakpoint-resource) | [`build_essential`](#build-essential-resource) | [`cab_package`](#cab-package-resource) |
| [`chef_client_config`](#chef-client-config-resource) | [`chef_client_cron`](#chef-client-cron-resource) | [`chef_client_hab_ca_cert`](#chef-client-hab-ca-cert-resource) | [`chef_client_launchd`](#chef-client-launchd-resource) |
| [`chef_client_scheduled_task`](#chef-client-scheduled-task-resource) | [`chef_client_systemd_timer`](#chef-client-systemd-timer-resource) | [`chef_client_trusted_certificate`](#chef-client-trusted-certificate-resource) | [`chef_gem`](#chef-gem-resource) |
| [`chef_handler`](#chef-handler-resource) | [`chef_sleep`](#chef-sleep-resource) | [`chef_vault_secret`](#chef-vault-secret-resource) | [`chocolatey_config`](#chocolatey-config-resource) |
| [`chocolatey_feature`](#chocolatey-feature-resource) | [`chocolatey_installer`](#chocolatey-installer-resource) | [`chocolatey_package`](#chocolatey-package-resource) | [`chocolatey_source`](#chocolatey-source-resource) |
| [`cookbook_file`](#cookbook-file-resource) | [`cron`](#cron-resource) | [`cron_access`](#cron-access-resource) | [`cron_d`](#cron-d-resource) |
| [`csh`](#csh-resource) | [`directory`](#directory-resource) | [`dmg_package`](#dmg-package-resource) | [`dnf_package`](#dnf-package-resource) |
| [`dpkg_package`](#dpkg-package-resource) | [`dsc_resource`](#dsc-resource-resource) | [`dsc_script`](#dsc-script-resource) | [`execute`](#execute-resource) |
| [`file`](#file-resource) | [`freebsd_package`](#freebsd-package-resource) | [`gem_package`](#gem-package-resource) | [`git`](#git-resource) |
| [`group`](#group-resource) | [`habitat_config`](#habitat-config-resource) | [`habitat_install`](#habitat-install-resource) | [`habitat_package`](#habitat-package-resource) |
| [`habitat_service`](#habitat-service-resource) | [`habitat_sup`](#habitat-sup-resource) | [`habitat_user_toml`](#habitat-user-toml-resource) | [`homebrew_cask`](#homebrew-cask-resource) |
| [`homebrew_package`](#homebrew-package-resource) | [`homebrew_tap`](#homebrew-tap-resource) | [`homebrew_update`](#homebrew-update-resource) | [`hostname`](#hostname-resource) |
| [`http_request`](#http-request-resource) | [`ifconfig`](#ifconfig-resource) | [`inspec_input`](#inspec-input-resource) | [`inspec_waiver`](#inspec-waiver-resource) |
| [`inspec_waiver_file_entry`](#inspec-waiver-file-entry-resource) | [`ips_package`](#ips-package-resource) | [`kernel_module`](#kernel-module-resource) | [`ksh`](#ksh-resource) |
| [`launchd`](#launchd-resource) | [`link`](#link-resource) | [`locale`](#locale-resource) | [`log`](#log-resource) |
| [`macos_pkg`](#macos-pkg-resource) | [`macos_userdefaults`](#macos-userdefaults-resource) | [`macosx_service`](#macosx-service-resource) | [`macports_package`](#macports-package-resource) |
| [`mdadm`](#mdadm-resource) | [`mount`](#mount-resource) | [`msu_package`](#msu-package-resource) | [`notify_group`](#notify-group-resource) |
| [`ohai`](#ohai-resource) | [`ohai_hint`](#ohai-hint-resource) | [`openbsd_package`](#openbsd-package-resource) | [`openssl_dhparam`](#openssl-dhparam-resource) |
| [`openssl_ec_private_key`](#openssl-ec-private-key-resource) | [`openssl_ec_public_key`](#openssl-ec-public-key-resource) | [`openssl_rsa_private_key`](#openssl-rsa-private-key-resource) | [`openssl_rsa_public_key`](#openssl-rsa-public-key-resource) |
| [`openssl_x509_certificate`](#openssl-x509-certificate-resource) | [`openssl_x509_crl`](#openssl-x509-crl-resource) | [`openssl_x509_request`](#openssl-x509-request-resource) | [`package`](#package-resource) |
| [`pacman_package`](#pacman-package-resource) | [`paludis_package`](#paludis-package-resource) | [`perl`](#perl-resource) | [`plist`](#plist-resource) |
| [`portage_package`](#portage-package-resource) | [`powershell_package`](#powershell-package-resource) | [`powershell_package_source`](#powershell-package-source-resource) | [`powershell_script`](#powershell-script-resource) |
| [`python`](#python-resource) | [`reboot`](#reboot-resource) | [`registry_key`](#registry-key-resource) | [`remote_directory`](#remote-directory-resource) |
| [`remote_file`](#remote-file-resource) | [`rhsm_errata`](#rhsm-errata-resource) | [`rhsm_errata_level`](#rhsm-errata-level-resource) | [`rhsm_register`](#rhsm-register-resource) |
| [`rhsm_repo`](#rhsm-repo-resource) | [`rhsm_subscription`](#rhsm-subscription-resource) | [`route`](#route-resource) | [`rpm_package`](#rpm-package-resource) |
| [`ruby`](#ruby-resource) | [`ruby_block`](#ruby-block-resource) | [`selinux_boolean`](#selinux-boolean-resource) | [`selinux_fcontext`](#selinux-fcontext-resource) |
| [`selinux_install`](#selinux-install-resource) | [`selinux_login`](#selinux-login-resource) | [`selinux_module`](#selinux-module-resource) | [`selinux_permissive`](#selinux-permissive-resource) |
| [`selinux_port`](#selinux-port-resource) | [`selinux_state`](#selinux-state-resource) | [`selinux_user`](#selinux-user-resource) | [`service`](#service-resource) |
| [`smartos_package`](#smartos-package-resource) | [`snap_package`](#snap-package-resource) | [`solaris_package`](#solaris-package-resource) | [`ssh_known_hosts_entry`](#ssh-known-hosts-entry-resource) |
| [`subversion`](#subversion-resource) | [`sudo`](#sudo-resource) | [`swap_file`](#swap-file-resource) | [`sysctl`](#sysctl-resource) |
| [`systemd_unit`](#systemd-unit-resource) | [`template`](#template-resource) | [`timezone`](#timezone-resource) | [`user`](#user-resource) |
| [`user_ulimit`](#user-ulimit-resource) | [`windows_ad_join`](#windows-ad-join-resource) | [`windows_audit_policy`](#windows-audit-policy-resource) | [`windows_auto_run`](#windows-auto-run-resource) |
| [`windows_certificate`](#windows-certificate-resource) | [`windows_defender`](#windows-defender-resource) | [`windows_defender_exclusion`](#windows-defender-exclusion-resource) | [`windows_dfs_folder`](#windows-dfs-folder-resource) |
| [`windows_dfs_namespace`](#windows-dfs-namespace-resource) | [`windows_dfs_server`](#windows-dfs-server-resource) | [`windows_dns_record`](#windows-dns-record-resource) | [`windows_dns_zone`](#windows-dns-zone-resource) |
| [`windows_env`](#windows-env-resource) | [`windows_feature`](#windows-feature-resource) | [`windows_feature_dism`](#windows-feature-dism-resource) | [`windows_feature_powershell`](#windows-feature-powershell-resource) |
| [`windows_firewall_profile`](#windows-firewall-profile-resource) | [`windows_firewall_rule`](#windows-firewall-rule-resource) | [`windows_font`](#windows-font-resource) | [`windows_package`](#windows-package-resource) |
| [`windows_pagefile`](#windows-pagefile-resource) | [`windows_path`](#windows-path-resource) | [`windows_printer`](#windows-printer-resource) | [`windows_printer_port`](#windows-printer-port-resource) |
| [`windows_security_policy`](#windows-security-policy-resource) | [`windows_service`](#windows-service-resource) | [`windows_share`](#windows-share-resource) | [`windows_shortcut`](#windows-shortcut-resource) |
| [`windows_task`](#windows-task-resource) | [`windows_uac`](#windows-uac-resource) | [`windows_update_settings`](#windows-update-settings-resource) | [`windows_user_privilege`](#windows-user-privilege-resource) |
| [`windows_workgroup`](#windows-workgroup-resource) | [`yum_package`](#yum-package-resource) | [`yum_repository`](#yum-repository-resource) | [`zypper_package`](#zypper-package-resource) |
| [`zypper_repository`](#zypper-repository-resource) |

---

## alternatives resource

[alternatives resource page](alternatives/)

Use the **alternatives** resource to configure command alternatives in Linux using the alternatives or update-alternatives packages.

**New in Chef Infra Client 16.0.**

> Source: `lib/chef/resource/alternatives.rb`

### Syntax

The full syntax for all of the properties that are available to the **alternatives** resource is:

```ruby
alternatives 'name' do
  link_name  # String
  link  # String  # default: lazy { |n| "/usr/bin/#{n.link_name}" }
  path  # String
  priority  # [String, Integer]
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **alternatives** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:set` |  |
| `:auto` |  |
| `:refresh` |  |
| `:remove` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `link_name` | `String` |  | The name of the link to create. This will be the command you type on the command line such as `ruby` or `gcc`. |
| `link` | `String` | `lazy { |n| "/usr/bin/#{n.link_name}" }` | /usr/bin/LINK_NAME |
| `path` | `String` |  | The absolute path to the original application binary such as `/usr/bin/ruby27`. |
| `priority` | `[String, Integer]` |  | The priority of the alternative. |

### Agentless Mode

The **alternatives** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **alternatives** resource:

      **Install an alternative**:

      ```ruby
      alternatives 'python install 2' do
        link_name 'python'
        path '/usr/bin/python2.7'
        priority 100
        action :install
      end
      ```

      **Set an alternative**:

      ```ruby
      alternatives 'python set version 3' do
        link_name 'python'
        path '/usr/bin/python3'
        action :set
      end
      ```

      **Set the automatic alternative state**:

      ```ruby
      alternatives 'python auto' do
        link_name 'python'
        action :auto
      end
      ```

      **Refresh an alternative**:

      ```ruby
      alternatives 'python refresh' do
        link_name 'python'
        action :refresh
      end
      ```

      **Remove an alternative**:

      ```ruby
      alternatives 'python remove' do
        link_name 'python'
        path '/usr/bin/python3'
        action :remove
      end
      ```


---

## apt_package resource

[apt_package resource page](apt_package/)

Use the **apt_package** resource to manage packages on Debian, Ubuntu, and other platforms that use the APT package system.

**New in Chef Infra Client 15.1.** *(catalog version; not declared in local source)*

> Source: `lib/chef/resource/apt_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **apt_package** resource is:

```ruby
apt_package 'name' do
  default_release  # String
  overwrite_config_files  # [TrueClass, FalseClass]  # default: false
  response_file  # String
  response_file_variables  # Hash  # default: {}
  anchor_package_regex  # [TrueClass, FalseClass]  # default: false
  environment  # Hash  # default: {}
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **apt_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:upgrade` |  |
| `:remove` |  |
| `:purge` |  |
| `:reconfig` |  |
| `:lock` |  |
| `:unlock` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `default_release` | `String` |  | The default release. For example: `stable`. |
| `overwrite_config_files` | `[TrueClass, FalseClass]` | `false` | Overwrite existing configuration files with those supplied by the package, if prompted by APT. |
| `response_file` | `String` |  | The direct path to the file used to pre-seed a package. |
| `response_file_variables` | `Hash` | `{}` | A Hash of response file variables in the form of {'VARIABLE' => 'VALUE'}. |
| `anchor_package_regex` | `[TrueClass, FalseClass]` | `false` |  |
| `environment` | `Hash` | `{}` | A Hash of environment variables in the form of {'ENV_VARIABLE' => 'VALUE'} to be set before running the command. |

### Agentless Mode

The **apt_package** resource has **full** support for Agentless Mode.

Support was added in Chef Infra Client 15.1.

### Examples

The following examples demonstrate various approaches for using the **apt_package** resource:

      **Install a package using package manager**:

      ```ruby
      apt_package 'name of package' do
        action :install
      end
      ```

      **Install a package without specifying the default action**:

      ```ruby
      apt_package 'name of package'
      ```

      **Install multiple packages at once**:

      ```ruby
      apt_package %w(package1 package2 package3)
      ```

      **Install without using recommend packages as a dependency**:

      ```ruby
      package 'apache2' do
        options '--no-install-recommends'
      end
      ```

      **Prevent the apt_package resource from installing packages with pattern matching names**:

      By default, the apt_package resource will install the named package.
      If it can't find a package with the exact same name, it will treat the package name as regular expression string and match with any package that matches that regular expression.
      This may lead Chef Infra Client to install one or more packages with names that match that regular expression.

      In this example, `anchor_package_regex true` prevents the apt_package resource from installing matching packages if it can't find the `lua5.3` package.

      ```ruby
      apt_package 'lua5.3' do
        version '5.3.3-1.1ubuntu2'
        anchor_package_regex true
      end
      ```


---

## apt_preference resource

[apt_preference resource page](apt_preference/)

Use the **apt_preference** resource to create APT [preference files](https://wiki.debian.org/AptPreferences). Preference files are used to control which package versions and sources are prioritized during installation.

**New in Chef Infra Client 13.3.**

> Source: `lib/chef/resource/apt_preference.rb`

### Syntax

The full syntax for all of the properties that are available to the **apt_preference** resource is:

```ruby
apt_preference 'name' do
  package_name  # String
  glob  # String
  pin  # String
  pin_priority  # [String, Integer]
  action  :symbol # defaults to :add if not specified
end
```

### Actions

The **apt_preference** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:remove` |  |
| `:add` **(default)** |  |
| `:create` |  |
| `:delete` |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `package_name` | `String` |  | An optional property to set the package name if it differs from the resource block's name. |
| `glob` | `String` |  | Pin by a `glob()` expression or with a regular expression surrounded by `/`. |
| `pin` | `String` |  | The package version or repository to pin. |
| `pin_priority` | `[String, Integer]` |  | Sets the Pin-Priority for a package. See <https://wiki.debian.org/AptPreferences> for more details. |

### Agentless Mode

The **apt_preference** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **apt_preference** resource:

      **Pin libmysqlclient16 to a version 5.1.49-3**:

      ```ruby
      apt_preference 'libmysqlclient16' do
        pin          'version 5.1.49-3'
        pin_priority '700'
      end
      ```

      Note: The `pin_priority` of `700` ensures that this version will be preferred over any other available versions.

      **Unpin a libmysqlclient16**:

      ```ruby
      apt_preference 'libmysqlclient16' do
        action :remove
      end
      ```

      **Pin all packages to prefer the packages.dotdeb.org repository**:

      ```ruby
      apt_preference 'dotdeb' do
        glob         '*'
        pin          'origin packages.dotdeb.org'
        pin_priority '700'
      end
      ```


---

## apt_repository resource

[apt_repository resource page](apt_repository/)

Use the **apt_repository** resource to specify additional APT repositories. Adding a new repository will update the APT package cache immediately.

**New in Chef Infra Client 12.9.**

> Source: `lib/chef/resource/apt_repository.rb`

### Syntax

The full syntax for all of the properties that are available to the **apt_repository** resource is:

```ruby
apt_repository 'name' do
  repo_name  # String
  uri  # String
  distribution  # [ String, nil, FalseClass ]  # default: lazy { node["lsb"]["codename"] }
  components  # Array  # default: []
  arch  # [String, nil, FalseClass]
  trusted  # [TrueClass, FalseClass]  # default: false
  deb_src  # [TrueClass, FalseClass]  # default: false
  keyserver  # [String, nil, FalseClass]  # default: "keyserver.ubuntu.com"
  key  # [String, Array, nil, FalseClass]  # default: []
  key_proxy  # [String, nil, FalseClass]
  signed_by  # [String, true, false, nil]  # default: true
  cookbook  # [String, nil, FalseClass]
  cache_rebuild  # [TrueClass, FalseClass]  # default: true
  options  # [String, Array]  # default: []
  action  :symbol # defaults to :add if not specified
end
```

### Actions

The **apt_repository** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:add` **(default)** |  |
| `:remove` |  |
| `:create` |  |
| `:nothing` |  |
| `:run` |  |
| `:delete` |  |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `repo_name` | `String` |  | An optional property to set the repository name if it differs from the resource block's name. The value of this setting must not contain spaces. |
| `uri` | `String` |  | The base of the Debian distribution. |
| `distribution` | `[ String, nil, FalseClass ]` | `lazy { node["lsb"]["codename"] }` | Usually a distribution's codename, such as `xenial`, `bionic`, or `focal`. |
| `components` | `Array` | `[]` | Package groupings, such as 'main' and 'stable'. |
| `arch` | `[String, nil, FalseClass]` |  | Constrain packages to a particular CPU architecture such as `i386` or `amd64`. |
| `trusted` | `[TrueClass, FalseClass]` | `false` | Determines whether you should treat all packages from this repository as authenticated regardless of signature. |
| `deb_src` | `[TrueClass, FalseClass]` | `false` | Determines whether or not to add the repository as a source repo as well. |
| `keyserver` | `[String, nil, FalseClass]` | `"keyserver.ubuntu.com"` | The GPG keyserver where the key for the repo should be retrieved. |
| `key` | `[String, Array, nil, FalseClass]` | `[]` | If a keyserver is provided, this is assumed to be the fingerprint; otherwise it can be either the URI of GPG key for the repo, or a cookbook_file. |
| `key_proxy` | `[String, nil, FalseClass]` |  | If set, a specified proxy is passed to GPG via `http-proxy=`. |
| `signed_by` | `[String, true, false, nil]` | `true` | If a string, specify the file and/or fingerprint the repo is signed with. If true, set Signed-With to use the specified key |
| `cookbook` | `[String, nil, FalseClass]` |  | If key should be a cookbook_file, specify a cookbook where the key is located for files/default. Default value is nil, so it will use the cookbook whe |
| `cache_rebuild` | `[TrueClass, FalseClass]` | `true` | Determines whether to rebuild the APT package cache. |
| `options` | `[String, Array]` | `[]` | Additional options to set for the repository |

### Agentless Mode

The **apt_repository** resource has **full** support for Agentless Mode.

Support was added in Chef Infra Client 14.1.

### Examples

The following examples demonstrate various approaches for using the **apt_repository** resource:

        **Add repository with basic settings**:

        ```ruby
        apt_repository 'nginx' do
          uri        'http://nginx.org/packages/ubuntu/'
          components ['nginx']
        end
        ```

        **Enable Ubuntu multiverse repositories**:

        ```ruby
        apt_repository 'security-ubuntu-multiverse' do
          uri          'http://security.ubuntu.com/ubuntu'
          distribution 'xenial-security'
          components   ['multiverse']
          deb_src      true
        end
        ```

        **Add the Nginx PPA, autodetect the key and repository url**:

        ```ruby
        apt_repository 'nginx-php' do
          uri          'ppa:nginx/stable'
        end
        ```

        **Add the JuJu PPA, grab the key from the Ubuntu keyserver, and add source repo**:

        ```ruby
        apt_repository 'juju' do
          uri 'ppa:juju/stable'
          components ['main']
          distribution 'xenial'
          key 'C8068B11'
          action :add
          deb_src true
        end
        ```

        **Add repository that requires multiple keys to authenticate packages**:

        ```ruby
        apt_repository 'rundeck' do
          uri 'https://dl.bintray.com/rundeck/rundeck-deb'
          distribution '/'
          key ['379CE192D401AB61', 'http://rundeck.org/keys/BUILD-GPG-KEY-Rundeck.org.key']
          keyserver 'keyserver.ubuntu.com'
          action :add
        end
        ```

        **Add the Cloudera Repo of CDH4 packages for Ubuntu 16.04 on AMD64**:

        ```ruby
        apt_repository 'cloudera' do
          uri          'http://archive.cloudera.com/cdh4/ubuntu/xenial/amd64/cdh'
          arch         'amd64'
          distribution 'xenial-cdh4'
          components   ['contrib']
          key          'http://archive.cloudera.com/debian/archive.key'
        end
        ```

        **Add repository that needs custom options**:
        ```ruby
        apt_repository 'corretto' do
          uri          'https://apt.corretto.aws'
          arch         'amd64'
          distribution 'stable'
          components   ['main']
          options      ['target-=Contents-deb']
          key          'https://apt.corretto.aws/corretto.key'
        end
        ```

        **Remove a repository from the list**:

        ```ruby
        apt_repository 'zenoss' do
          action :remove
        end
        ```


---

## apt_update resource

[apt_update resource page](apt_update/)

Use the **apt_update** resource to manage APT repository updates on Debian and Ubuntu platforms.

**New in Chef Infra Client 12.7.**

> Source: `lib/chef/resource/apt_update.rb`

### Syntax

The full syntax for all of the properties that are available to the **apt_update** resource is:

```ruby
apt_update 'name' do
  name  # String  # default: ""
  frequency  # Integer  # default: 86_400  default_action :periodic
  action  :symbol # defaults to :periodic if not specified
end
```

### Actions

The **apt_update** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:periodic` **(default)** |  |
| `:update` |  |
| `:create_if_missing` |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `name` | `String` | `""` |  |
| `frequency` | `Integer` | `86_400  default_action :periodic` | Determines how frequently (in seconds) APT repository updates are made. Use this property when the `:periodic` action is specified. |

### Agentless Mode

The **apt_update** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **apt_update** resource:

        **Update the Apt repository at a specified interval**:

        ```ruby
        apt_update 'all platforms' do
          frequency 86400
          action :periodic
        end
        ```

        **Update the Apt repository at the start of a Chef Infra Client run**:

        ```ruby
        apt_update 'update'
        ```


---

## archive_file resource

[archive_file resource page](archive_file/)

Use the **archive_file** resource to extract archive files to disk. This resource uses the libarchive library to extract multiple archive formats including tar, gzip, bzip, and zip formats.

**New in Chef Infra Client 15.0.**

> Source: `lib/chef/resource/archive_file.rb`

### Syntax

The full syntax for all of the properties that are available to the **archive_file** resource is:

```ruby
archive_file 'name' do
  path  # String
  owner  # String
  group  # String
  mode  # [String, Integer]  # default: "755"
  destination  # String
  options  # [Array, Symbol]  # default: lazy { [:time] }
  overwrite  # [TrueClass, FalseClass, :auto]  # default: false
  strip_components  # Integer  # default: 0
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **archive_file** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:extract` | Extract and archive file. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `path` | `String` |  | An optional property to set the file path to the archive to extract if it differs from the resource block's name. |
| `owner` | `String` |  | The owner of the extracted files. |
| `group` | `String` |  | The group of the extracted files. |
| `mode` | `[String, Integer]` | `"755"` | The mode of the extracted files. Integer values are deprecated as octal values (ex. 0755) would not be interpreted correctly. |
| `destination` | `String` |  | The file path to extract the archive file to. |
| `options` | `[Array, Symbol]` | `lazy { [:time] }` |  |
| `overwrite` | `[TrueClass, FalseClass, :auto]` | `false` |  |
| `strip_components` | `Integer` | `0` | Remove the specified number of leading path elements. Pathnames with fewer elements will be silently skipped. This behaves similarly to tar's --strip- |

### Examples

The following examples demonstrate various approaches for using the **archive_file** resource:

        **Extract a zip file to a specified directory**:

        ```ruby
        archive_file 'Precompiled.zip' do
          path '/tmp/Precompiled.zip'
          destination '/srv/files'
        end
        ```

        **Set specific permissions on the extracted files**:

        ```ruby
        archive_file 'Precompiled.zip' do
          owner 'tsmith'
          group 'staff'
          mode '700'
          path '/tmp/Precompiled.zip'
          destination '/srv/files'
        end
        ```


---

## bash resource

[bash resource page](bash/)

Use the **bash** resource to execute scripts using the Bash interpreter. This resource may also use any of the actions and properties that are available to the **execute** resource. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use `not_if` and `only_if` to guard this resource for idempotence.


> Source: `lib/chef/resource/bash.rb`

### Syntax

The full syntax for all of the properties that are available to the **bash** resource is:

```ruby
bash 'name' do
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **bash** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:sync` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

No resource-specific properties.

> This resource inherits all properties from the `execute` resource via the `script` base class, including:
> `code` (required), `cwd`, `environment`, `flags`, `group`, `input`, `interpreter`,
> `live_stream`, `login`, `password`, `returns`, `timeout`, `user`, `domain`, `elevated`.

### Agentless Mode

The **bash** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **bash** resource:

      **Compile an application**

      ```ruby
      bash 'install_something' do
        user 'root'
        cwd '/tmp'
        code <<-EOH
          wget http://www.example.com/tarball.tar.gz
          tar -zxf tarball.tar.gz
          cd tarball
          ./configure
          make
          make install
        EOH
      end
      ```

      **Using escape characters in a string of code**

      In the following example, the `find` command uses an escape character (`\`). Use a second escape character (`\\`) to preserve the escape character in the code string:

      ```ruby
      bash 'delete some archives ' do
        code <<-EOH
          find ./ -name "*.tar.Z" -mtime +180 -exec rm -f {} \\;
        EOH
        ignore_failure true
      end
      ```

      **Install a file from a remote location**

      The following is an example of how to install the foo123 module for Nginx. This module adds shell-style functionality to an Nginx configuration file and does the following:

        - Declares three variables
        - Gets the Nginx file from a remote location
        - Installs the file using Bash to the path specified by the `src_filepath` variable

      ```ruby
      src_filename = "foo123-nginx-module-v#{node['nginx']['foo123']['version']}.tar.gz"
      src_filepath = "#{Chef::Config['file_cache_path']}/#{src_filename}"
      extract_path = "#{Chef::Config['file_cache_path']}/nginx_foo123_module/#{node['nginx']['foo123']['checksum']}"

      remote_file 'src_filepath' do
        source node['nginx']['foo123']['url']
        checksum node['nginx']['foo123']['checksum']
        owner 'root'
        group 'root'
        mode '0755'
      end

      bash 'extract_module' do
        cwd ::File.dirname(src_filepath)
        code <<-EOH
          mkdir -p #{extract_path}
          tar xzf #{src_filename} -C #{extract_path}
          mv #{extract_path}/*/* #{extract_path}/
        EOH
        not_if { ::File.exist?(extract_path) }
      end
      ```

      **Install an application from git**

      ```ruby
      git "#{Chef::Config[:file_cache_path]}/ruby-build" do
        repository 'git://github.com/rbenv/ruby-build.git'
        revision 'master'
        action :sync
      end

      bash 'install_ruby_build' do
        cwd "#{Chef::Config[:file_cache_path]}/ruby-build"
        user 'rbenv'
        group 'rbenv'
        code <<-EOH
          ./install.sh
        EOH
        environment 'PREFIX' => '/usr/local'
      end
      ```

      **Using Attributes in Bash Code**

      The following recipe shows how an attributes file can be used to store certain settings. An attributes file is located in the `attributes/`` directory in the same cookbook as the recipe which calls the attributes file. In this example, the attributes file specifies certain settings for Python that are then used across all nodes against which this recipe will run.

      Python packages have versions, installation directories, URLs, and checksum files. An attributes file that exists to support this type of recipe would include settings like the following:

      ```ruby
      default['python']['version'] = '2.7.1'

      if python['install_method'] == 'package'
        default['python']['prefix_dir'] = '/usr'
      else
        default['python']['prefix_dir'] = '/usr/local'
      end

      default['python']['url'] = 'http://www.python.org/ftp/python'
      default['python']['checksum'] = '80e387...85fd61'
      ```

      and then the methods in the recipe may refer to these values. A recipe that is used to install Python will need to do the following:

        - Identify each package to be installed (implied in this example, not shown)
        - Define variables for the package `version` and the `install_path`
        - Get the package from a remote location, but only if the package does not already exist on the target system
        - Use the **bash** resource to install the package on the node, but only when the package is not already installed

      ```ruby
      version = node['python']['version']
      install_path = "#{node['python']['prefix_dir']}/lib/python#{version.split(/(^\d+\.\d+)/)[1]}"

      remote_file "#{Chef::Config[:file_cache_path]}/Python-#{version}.tar.bz2" do
        source "#{node['python']['url']}/#{version}/Python-#{version}.tar.bz2"
        checksum node['python']['checksum']
        mode '0755'
        not_if { ::File.exist?(install_path) }
      end

      bash 'build-and-install-python' do
        cwd Chef::Config[:file_cache_path]
        code <<-EOF
          tar -jxvf Python-#{version}.tar.bz2
          (cd Python-#{version} && ./configure #{configure_options})
          (cd Python-#{version} && make && make install)
        EOF
        not_if { ::File.exist?(install_path) }
      end
      ```


---

## batch resource

[batch resource page](batch/)

Use the **batch** resource to execute a batch script using the cmd.exe interpreter on Windows. The batch resource creates and executes a temporary file (similar to how the script resource behaves), rather than running the command inline. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use `not_if` and `only_if` to guard this resource for idempotence.


> Source: `lib/chef/resource/batch.rb`

### Syntax

The full syntax for all of the properties that are available to the **batch** resource is:

```ruby
batch 'name' do
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **batch** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

No resource-specific properties.


---

## bff_package resource

[bff_package resource page](bff_package/)

Use the **bff_package** resource to manage packages for the AIX platform using the installp utility. When a package is installed from a local file, it must be added to the node using the **remote_file** or **cookbook_file** resources.

**New in Chef Infra Client 12.0.**

> Source: `lib/chef/resource/bff_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **bff_package** resource is:

```ruby
bff_package 'name' do
  package_name  # String
  version  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **bff_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `package_name` | `String` |  | An optional property to set the package name if it differs from the resource block's name. |
| `version` | `String` |  | The version of a package to be installed or upgraded. |

### Agentless Mode

The **bff_package** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **bff_package** resource:

      The **bff_package** resource is the default package provider on the AIX platform. The base **package** resource may be used, and then when the platform is AIX, #{ChefUtils::Dist::Infra::PRODUCT} will identify the correct package provider. The following examples show how to install part of the IBM XL C/C++ compiler.

      **Installing using the base package resource**

      ```ruby
      package 'xlccmp.13.1.0' do
        source '/var/tmp/IBM_XL_C_13.1.0/usr/sys/inst.images/xlccmp.13.1.0'
        action :install
      end
      ```

      **Installing using the bff_package resource**

      ```ruby
      bff_package 'xlccmp.13.1.0' do
        source '/var/tmp/IBM_XL_C_13.1.0/usr/sys/inst.images/xlccmp.13.1.0'
        action :install
      end
      ```


---

## breakpoint resource

[breakpoint resource page](breakpoint/)

Use the **breakpoint** resource to add breakpoints to recipes. Run the #{ChefUtils::Dist::Infra::SHELL} in #{ChefUtils::Dist::Infra::PRODUCT} mode, and then use those breakpoints to debug recipes. Breakpoints are ignored by the #{ChefUtils::Dist::Infra::CLIENT} during an actual #{ChefUtils::Dist::Infra::CLIENT} run. That said, breakpoints are typically used to debug recipes only when running them in a non-production environment, after which they are removed from those recipes before the parent cookbook is uploaded to the Chef server.

**New in Chef Infra Client 12.0.**

> Source: `lib/chef/resource/breakpoint.rb`

### Syntax

The full syntax for all of the properties that are available to the **breakpoint** resource is:

```ruby
breakpoint 'name' do
  action  :symbol # defaults to :break if not specified
end
```

### Actions

The **breakpoint** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:add` |  |
| `:create` |  |
| `:break` **(default)** |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

No resource-specific properties.

### Agentless Mode

The **breakpoint** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **breakpoint** resource:

      **A recipe without a breakpoint**

      ```ruby
      yum_key node['yum']['elrepo']['key'] do
        url  node['yum']['elrepo']['key_url']
        action :add
      end

      yum_repository 'elrepo' do
        description 'ELRepo.org Community Enterprise Linux Extras Repository'
        key node['yum']['elrepo']['key']
        mirrorlist node['yum']['elrepo']['url']
        includepkgs node['yum']['elrepo']['includepkgs']
        exclude node['yum']['elrepo']['exclude']
        action :create
      end
      ```

      **The same recipe with breakpoints**

      In the following example, the name of each breakpoint is an arbitrary string.

      ```ruby
      breakpoint "before yum_key node['yum']['repo_name']['key']" do
        action :break
      end

      yum_key node['yum']['repo_name']['key'] do
        url  node['yum']['repo_name']['key_url']
        action :add
      end

      breakpoint "after yum_key node['yum']['repo_name']['key']" do
        action :break
      end

      breakpoint "before yum_repository 'repo_name'" do
        action :break
      end

      yum_repository 'repo_name' do
        description 'description'
        key node['yum']['repo_name']['key']
        mirrorlist node['yum']['repo_name']['url']
        includepkgs node['yum']['repo_name']['includepkgs']
        exclude node['yum']['repo_name']['exclude']
        action :create
      end

      breakpoint "after yum_repository 'repo_name'" do
        action :break
      end
      ```

      In the previous examples, the names are used to indicate if the breakpoint is before or after a resource and also to specify which resource it is before or after.


---

## build_essential resource

[build_essential resource page](build_essential/)

Use the **build_essential** resource to install the packages required for compiling C software from source.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/build_essential.rb`

### Syntax

The full syntax for all of the properties that are available to the **build_essential** resource is:

```ruby
build_essential 'name' do
  name  # String  # default: ""
  raise_if_unsupported  # [TrueClass, FalseClass]  # default: false
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **build_essential** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:upgrade` |  |
| `:install` | Install build essential packages. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `name` | `String` | `""` |  |
| `raise_if_unsupported` | `[TrueClass, FalseClass]` | `false` | Raise a hard error on platforms where this resource is unsupported. |

### Examples

The following examples demonstrate various approaches for using the **build_essential** resource:

        **Install compilation packages**:

        ```ruby
        build_essential
        ```

        **Install compilation packages during the compilation phase**:

        ```ruby
        build_essential 'Install compilation tools' do
          compile_time true
        end
        ```

        **Upgrade compilation packages on macOS systems**:

        ```ruby
        build_essential 'Install compilation tools' do
          action :upgrade
        end
        ```


---

## cab_package resource

[cab_package resource page](cab_package/)

Use the **cab_package** resource to install or remove Microsoft Windows cabinet (.cab) packages.

**New in Chef Infra Client 12.15.**

> Source: `lib/chef/resource/cab_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **cab_package** resource is:

```ruby
cab_package 'name' do
  package_name  # String
  version  # String
  source  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **cab_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:remove` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `package_name` | `String` |  | An optional property to set the package name if it differs from the resource block's name. |
| `version` | `String` |  | The version of a package to be installed or upgraded. |
| `source` | `String` |  | The local file path or URL for the CAB package. |

### Examples

The following examples demonstrate various approaches for using the **cab_package** resource:

      **Using local path in source**

      ```ruby
      cab_package 'Install .NET 3.5 sp1 via KB958488' do
        source 'C:\Users\xyz\AppData\Local\Temp\Windows6.1-KB958488-x64.cab'
        action :install
      end

      cab_package 'Remove .NET 3.5 sp1 via KB958488' do
        source 'C:\Users\xyz\AppData\Local\Temp\Windows6.1-KB958488-x64.cab'
        action :remove
      end
      ```

      **Using URL in source**

      ```ruby
      cab_package 'Install .NET 3.5 sp1 via KB958488' do
        source 'https://s3.amazonaws.com/my_bucket/Windows6.1-KB958488-x64.cab'
        action :install
      end

      cab_package 'Remove .NET 3.5 sp1 via KB958488' do
        source 'https://s3.amazonaws.com/my_bucket/Temp\Windows6.1-KB958488-x64.cab'
        action :remove
      end
      ```


---

## chef_client_config resource

[chef_client_config resource page](chef_client_config/)

Use the **chef_client_config** resource to create a client.rb file in the #{ChefUtils::Dist::Infra::PRODUCT} configuration directory. See the [client.rb docs](https://docs.chef.io/config_rb_client/) for more details on options available in the client.rb configuration file.

**New in Chef Infra Client 16.6.**

> Source: `lib/chef/resource/chef_client_config.rb`

### Syntax

The full syntax for all of the properties that are available to the **chef_client_config** resource is:

```ruby
chef_client_config 'name' do
  config_directory  # String  # default: ChefConfig::Config.etc_chef_dir
  user  # String
  group  # String
  node_name  # [String, NilClass]  # default: lazy { node.name }
  chef_server_url  # String
  ssl_verify_mode  # [Symbol, String]
  formatters  # Array  # default: []
  event_loggers  # Array  # default: []
  log_level  # Symbol
  log_location  # [String, Symbol]
  http_proxy  # String
  https_proxy  # String
  ftp_proxy  # String
  no_proxy  # [String, Array]  # default: []
  ohai_disabled_plugins  # Array  # default: []
  ohai_optional_plugins  # Array  # default: []
  policy_persist_run_list  # [true, false]  # default: false
  minimal_ohai  # [true, false]  # default: false
  start_handlers  # Array  # default: []
  report_handlers  # Array  # default: []
  rubygems_url  # [String, Array]
  exception_handlers  # Array  # default: []
  chef_license  # String
  policy_name  # String
  policy_group  # String
  named_run_list  # String
  pid_file  # String
  file_cache_path  # String
  file_backup_path  # String
  file_staging_uses_destdir  # String
  additional_config  # String
  data_collector_server_url  # String
  data_collector_token  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **chef_client_config** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` | Create a client.rb config file and folders for configuring #{ChefUtils::Dist::Infra::PRODUCT}. |
| `:remove` | Remove a client.rb config file for configuring #{ChefUtils::Dist::Infra::PRODUCT}. |
| `:delete` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `config_directory` | `String` | `ChefConfig::Config.etc_chef_dir` | The directory to store the client.rb in. |
| `user` | `String` |  |  |
| `group` | `String` |  |  |
| `node_name` | `[String, NilClass]` | `lazy { node.name }` | The `node.name` value reported by #{ChefUtils::Dist::Infra::PRODUCT}. |
| `chef_server_url` | `String` |  | The URL for the #{ChefUtils::Dist::Server::PRODUCT}. |
| `ssl_verify_mode` | `[Symbol, String]` |  |  |
| `formatters` | `Array` | `[]` | Client logging formatters to load. |
| `event_loggers` | `Array` | `[]` |  |
| `log_level` | `Symbol` |  | The level of logging performed by the #{ChefUtils::Dist::Infra::PRODUCT}. |
| `log_location` | `[String, Symbol]` |  |  |
| `http_proxy` | `String` |  | The proxy server to use for HTTP connections. |
| `https_proxy` | `String` |  | The proxy server to use for HTTPS connections. |
| `ftp_proxy` | `String` |  | The proxy server to use for FTP connections. |
| `no_proxy` | `[String, Array]` | `[]` | A comma-separated list or an array of URLs that do not need a proxy. |
| `ohai_disabled_plugins` | `Array` | `[]` | Ohai plugins that should be disabled in order to speed up the #{ChefUtils::Dist::Infra::PRODUCT} run and reduce the size of node data sent to #{ChefUt |
| `ohai_optional_plugins` | `Array` | `[]` | Optional Ohai plugins that should be enabled to provide additional Ohai data for use in cookbooks. |
| `policy_persist_run_list` | `[true, false]` | `false` | Override run lists defined in a Policyfile with the `run_list` defined on the #{ChefUtils::Dist::Server::PRODUCT}. |
| `minimal_ohai` | `[true, false]` | `false` |  |
| `start_handlers` | `Array` | `[]` |  |
| `report_handlers` | `Array` | `[]` |  |
| `rubygems_url` | `[String, Array]` |  |  |
| `exception_handlers` | `Array` | `[]` |  |
| `chef_license` | `String` |  | Accept the [Chef EULA](https://www.chef.io/end-user-license-agreement/) |
| `policy_name` | `String` |  | The name of a policy, as identified by the `name` setting in a Policyfile.rb file. `policy_group`  when setting this property. |
| `policy_group` | `String` |  | The name of a `policy group` that exists on the #{ChefUtils::Dist::Server::PRODUCT}. `policy_name` must also be specified when setting this property. |
| `named_run_list` | `String` |  | A specific named runlist defined in the node's applied Policyfile, which the should be used when running #{ChefUtils::Dist::Infra::PRODUCT}. |
| `pid_file` | `String` |  | The location in which a process identification number (pid) is saved. An executable, when started as a daemon, writes the pid to the specified file.  |
| `file_cache_path` | `String` |  | The location in which cookbooks (and other transient data) files are stored when they are synchronized. This value can also be used in recipes to down |
| `file_backup_path` | `String` |  | The location in which backup files are stored. If this value is empty, backup files are stored in the directory of the target file |
| `file_staging_uses_destdir` | `String` |  | How file staging (via temporary files) is done. When `true`, temporary files are created in the directory in which files will reside. When `false`, te |
| `additional_config` | `String` |  | Additional text to add at the bottom of the client.rb config. This can be used to run custom Ruby or to add less common config options |
| `data_collector_server_url` | `String` |  |  |
| `data_collector_token` | `String` |  |  |

### Agentless Mode

The **chef_client_config** resource has **full** support for Agentless Mode.

Support was added in Chef Infra Client 17.3.

### Examples

The following examples demonstrate various approaches for using the **chef_client_config** resource:

      **Bare minimum #{ChefUtils::Dist::Infra::PRODUCT} client.rb**:

      The absolute minimum configuration necessary for a node to communicate with the #{ChefUtils::Dist::Server::PRODUCT} is the URL of the #{ChefUtils::Dist::Server::PRODUCT}. All other configuration options either have values at the server side (Policyfiles, Roles, Environments, etc) or have default values determined at client startup.

      ```ruby
      chef_client_config 'Create client.rb' do
        chef_server_url 'https://chef.example.dmz'
      end
      ```

      **More complex #{ChefUtils::Dist::Infra::PRODUCT} client.rb**:

      ```ruby
      chef_client_config 'Create client.rb' do
        chef_server_url 'https://chef.example.dmz'
        log_level :info
        log_location :syslog
        http_proxy 'proxy.example.dmz'
        https_proxy 'proxy.example.dmz'
        no_proxy %w(internal.example.dmz)
      end
      ```

      **Adding additional config content to the client.rb**:

      This resource aims to provide common configuration options. Some configuration options are missing and some users may want to use arbitrary Ruby code within their configuration. For this we offer an `additional_config` property that can be used to add any configuration or code to the bottom of the `client.rb` file. Also keep in mind that within the configuration directory is a `client.d` directory where you can put additional `.rb` files containing configuration options. These can be created using `file` or `template` resources within your cookbooks as necessary.

      ```ruby
      chef_client_config 'Create client.rb' do
        chef_server_url 'https://chef.example.dmz'
        additional_config <<~CONFIG
          # Extra config code to safely load a gem into the client run.
          # Since the config is Ruby you can run any Ruby code you want via the client.rb.
          # It's a great way to break things, so be careful
          begin
            require 'aws-sdk'
          rescue LoadError
            Chef::Log.warn "Failed to load aws-sdk."
          end
        CONFIG
      end
      ```

      **Setup two report handlers in the client.rb**:

      ```ruby
      chef_client_config 'Create client.rb' do
        chef_server_url 'https://chef.example.dmz'
        report_handlers [
          {
           'class' => 'ReportHandler1Class',
           'arguments' => ["'FirstArgument'", "'SecondArgument'"],
          },
          {
           'class' => 'ReportHandler2Class',
           'arguments' => ["'FirstArgument'", "'SecondArgument'"],
          },
        ]
      end
      ```

      **Report directly to the [Chef Automate data collector endpoint](/automate/data_collection/#configure-chef-infra-client-to-use-the-data-collector-endpoint-in-chef-automate).**

      ```ruby
      chef_client_config 'Create client.rb' do
        chef_server_url 'https://chef.example.dmz'
        data_collector_server_url 'https://automate.example.dmz'
        data_collector_token 'TEST_TOKEN_TEST'
      end
      ```


---

## chef_client_cron resource

[chef_client_cron resource page](chef_client_cron/)

Use the **chef_client_cron** resource to setup the #{ChefUtils::Dist::Infra::PRODUCT} to run as a cron job. This resource will also create the specified log directory if it doesn't already exist.

**New in Chef Infra Client 16.0.**

> Source: `lib/chef/resource/chef_client_cron.rb`

### Syntax

The full syntax for all of the properties that are available to the **chef_client_cron** resource is:

```ruby
chef_client_cron 'name' do
  job_name  # String  # default: ChefUtils::Dist::Infra::CLIENT
  comment  # String
  user  # String  # default: "root"
  minute  # [Integer, String]
  hour  # [Integer, String]  # default: "*"
  day  # [Integer, String]  # default: "*"
  month  # [Integer, String]  # default: "*"
  weekday  # [Integer, String]  # default: "*"
  splay  # [Integer, String]  # default: 300
  mailto  # String
  accept_chef_license  # [true, false]  # default: false
  config_directory  # String  # default: ChefConfig::Config.etc_chef_dir
  log_directory  # String  # default: lazy { platform?("mac_os_x") ? "/Library/Logs/#{ChefUtils::Dist::Infra::DIR_SUFFIX.capitalize}" : "/var/log/#{ChefUtils::Dist::Infra::DIR_SUFFIX}" }
  log_file_name  # String  # default: "client.log"
  append_log_file  # [true, false]  # default: true
  chef_binary_path  # String  # default: lazy { Chef::ResourceHelpers::PathHelpers.chef_client_hab_binary_path }
  daemon_options  # Array  # default: []
  environment  # Hash  # default: {}
  nice  # [Integer, String]
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **chef_client_cron** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:add` | Add a cron job to run #{ChefUtils::Dist::Infra::PRODUCT}. |
| `:remove` | Remove a cron job for #{ChefUtils::Dist::Infra::PRODUCT}. |
| `:delete` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `job_name` | `String` | `ChefUtils::Dist::Infra::CLIENT` | The name of the cron job to create. |
| `comment` | `String` |  | A comment to place in the cron.d file. |
| `user` | `String` | `"root"` | The name of the user that #{ChefUtils::Dist::Infra::PRODUCT} runs as. |
| `minute` | `[Integer, String]` |  | The minute at which #{ChefUtils::Dist::Infra::PRODUCT} is to run (0 - 59) or a cron pattern such as '0,30'. |
| `hour` | `[Integer, String]` | `"*"` | The hour at which #{ChefUtils::Dist::Infra::PRODUCT} is to run (0 - 23) or a cron pattern such as '0,12'. |
| `day` | `[Integer, String]` | `"*"` | The day of month at which #{ChefUtils::Dist::Infra::PRODUCT} is to run (1 - 31) or a cron pattern such as '1,7,14,21,28'. |
| `month` | `[Integer, String]` | `"*"` | The month in the year on which #{ChefUtils::Dist::Infra::PRODUCT} is to run (1 - 12, jan-dec, or *). |
| `weekday` | `[Integer, String]` | `"*"` | The day of the week on which #{ChefUtils::Dist::Infra::PRODUCT} is to run (0-7, mon-sun, or *), where Sunday is both 0 and 7. |
| `splay` | `[Integer, String]` | `300` | A random number of seconds between 0 and X to add to interval so that all #{ChefUtils::Dist::Infra::CLIENT} commands don't execute at the same time. |
| `mailto` | `String` |  | The e-mail address to e-mail any cron task failures to. |
| `accept_chef_license` | `[true, false]` | `false` | Accept the Chef Online Master License and Services Agreement. See <https://www.chef.io/online-master-agreement> |
| `config_directory` | `String` | `ChefConfig::Config.etc_chef_dir` | The path of the config directory. |
| `log_directory` | `String` | `lazy { platform?("mac_os_x") ? "/Library/Logs/#{Ch` | /Library/Logs/#{ChefUtils::Dist::Infra::DIR_SUFFIX.capitalize} on macOS and /var/log/#{ChefUtils::Dist::Infra::DIR_SUFFIX} otherwise |
| `log_file_name` | `String` | `"client.log"` | The name of the log file to use. |
| `append_log_file` | `[true, false]` | `true` | Append to the log file instead of overwriting the log file on each run. |
| `chef_binary_path` | `String` | `lazy { Chef::ResourceHelpers::PathHelpers.chef_cli` | The path to the #{ChefUtils::Dist::Infra::CLIENT} binary. |
| `daemon_options` | `Array` | `[]` | An array of options to pass to the #{ChefUtils::Dist::Infra::CLIENT} command. |
| `environment` | `Hash` | `{}` | A Hash containing additional arbitrary environment variables under which the cron job will be run in the form of `({'ENV_VARIABLE' => 'VALUE'})`. |
| `nice` | `[Integer, String]` |  | The process priority to run the #{ChefUtils::Dist::Infra::CLIENT} process at. A value of -20 is the highest priority and 19 is the lowest priority. |

### Examples

The following examples demonstrate various approaches for using the **chef_client_cron** resource:

      **Setup #{ChefUtils::Dist::Infra::PRODUCT} to run using the default 30 minute cadence**:

      ```ruby
      chef_client_cron 'Run #{ChefUtils::Dist::Infra::PRODUCT} as a cron job'
      ```

      **Run #{ChefUtils::Dist::Infra::PRODUCT} twice a day**:

      ```ruby
      chef_client_cron 'Run #{ChefUtils::Dist::Infra::PRODUCT} every 12 hours' do
        minute 0
        hour '0,12'
      end
      ```

      **Run #{ChefUtils::Dist::Infra::PRODUCT} with extra options passed to the client**:

      ```ruby
      chef_client_cron 'Run an override recipe' do
        daemon_options ['--override-runlist mycorp_base::default']
      end
      ```


---

## chef_client_hab_ca_cert resource

[chef_client_hab_ca_cert resource page](chef_client_hab_ca_cert/)

Use the **chef_client_hab_ca_cert** resource to add certificates to habitat #{ChefUtils::Dist::Infra::PRODUCT}'s CA bundle. This allows the #{ChefUtils::Dist::Infra::PRODUCT} to communicate with internal encrypted resources without errors. To make sure these CA certs take effect the `ssl_ca_file` should be configured to point to the CA Cert file path of `core/cacerts` habitat package.

**New in Chef Infra Client 19.1.**

> Source: `lib/chef/resource/chef_client_hab_ca_cert.rb`

### Syntax

The full syntax for all of the properties that are available to the **chef_client_hab_ca_cert** resource is:

```ruby
chef_client_hab_ca_cert 'name' do
  cert_name  # String
  certificate  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **chef_client_hab_ca_cert** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:add` | Add a local certificate to habitat based #{ChefUtils::Dist::Infra::PRODUCT}'s CA bundle. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `cert_name` | `String` |  | The name to use for the certificate. If not provided the name of the resource block will be used instead. |
| `certificate` | `String` |  | The text of the certificate file including the BEGIN/END comment lines. |

### Examples

The following examples demonstrate various approaches for using the **chef_client_hab_ca_cert** resource:

      **Trust a self signed certificate**:

      ```ruby
      chef_client_hab_ca_cert 'self-signed.badssl.com' do
        certificate <<~CERT
        -----BEGIN CERTIFICATE-----
        MIIDeTCCAmGgAwIBAgIJAPziuikCTox4MA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNV
        BAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMRYwFAYDVQQHDA1TYW4gRnJhbmNp
        c2NvMQ8wDQYDVQQKDAZCYWRTU0wxFTATBgNVBAMMDCouYmFkc3NsLmNvbTAeFw0x
        OTEwMDkyMzQxNTJaFw0yMTEwMDgyMzQxNTJaMGIxCzAJBgNVBAYTAlVTMRMwEQYD
        VQQIDApDYWxpZm9ybmlhMRYwFAYDVQQHDA1TYW4gRnJhbmNpc2NvMQ8wDQYDVQQK
        DAZCYWRTU0wxFTATBgNVBAMMDCouYmFkc3NsLmNvbTCCASIwDQYJKoZIhvcNAQEB
        BQADggEPADCCAQoCggEBAMIE7PiM7gTCs9hQ1XBYzJMY61yoaEmwIrX5lZ6xKyx2
        PmzAS2BMTOqytMAPgLaw+XLJhgL5XEFdEyt/ccRLvOmULlA3pmccYYz2QULFRtMW
        hyefdOsKnRFSJiFzbIRMeVXk0WvoBj1IFVKtsyjbqv9u/2CVSndrOfEk0TG23U3A
        xPxTuW1CrbV8/q71FdIzSOciccfCFHpsKOo3St/qbLVytH5aohbcabFXRNsKEqve
        ww9HdFxBIuGa+RuT5q0iBikusbpJHAwnnqP7i/dAcgCskgjZjFeEU4EFy+b+a1SY
        QCeFxxC7c3DvaRhBB0VVfPlkPz0sw6l865MaTIbRyoUCAwEAAaMyMDAwCQYDVR0T
        BAIwADAjBgNVHREEHDAaggwqLmJhZHNzbC5jb22CCmJhZHNzbC5jb20wDQYJKoZI
        hvcNAQELBQADggEBAGlwCdbPxflZfYOaukZGCaxYK6gpincX4Lla4Ui2WdeQxE95
        w7fChXvP3YkE3UYUE7mupZ0eg4ZILr/A0e7JQDsgIu/SRTUE0domCKgPZ8v99k3A
        vka4LpLK51jHJJK7EFgo3ca2nldd97GM0MU41xHFk8qaK1tWJkfrrfcGwDJ4GQPI
        iLlm6i0yHq1Qg1RypAXJy5dTlRXlCLd8ufWhhiwW0W75Va5AEnJuqpQrKwl3KQVe
        wGj67WWRgLfSr+4QG1mNvCZb2CkjZWmxkGPuoP40/y7Yu5OFqxP5tAjj4YixCYTW
        EVA0pmzIzgBg+JIe3PdRy27T0asgQW/F4TY61Yk=
        -----END CERTIFICATE-----
        CERT
      end
      ```


---

## chef_client_launchd resource

[chef_client_launchd resource page](chef_client_launchd/)

Use the **chef_client_launchd** resource to configure the #{ChefUtils::Dist::Infra::PRODUCT} to run on a schedule on macOS systems.

**New in Chef Infra Client 16.5.**

> Source: `lib/chef/resource/chef_client_launchd.rb`

### Syntax

The full syntax for all of the properties that are available to the **chef_client_launchd** resource is:

```ruby
chef_client_launchd 'name' do
  user  # String  # default: "root"
  working_directory  # String  # default: "/var/root"
  interval  # [Integer, String]  # default: 30
  splay  # [Integer, String]  # default: 300
  accept_chef_license  # [true, false]  # default: false
  config_directory  # String  # default: ChefConfig::Config.etc_chef_dir
  log_directory  # String  # default: "/Library/Logs/Chef"
  log_file_name  # String  # default: "client.log"
  chef_binary_path  # String  # default: lazy { Chef::ResourceHelpers::PathHelpers.chef_client_hab_binary_path }
  daemon_options  # Array  # default: []
  environment  # Hash  # default: {}
  nice  # [Integer, String]
  low_priority_io  # [true, false]  # default: true
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **chef_client_launchd** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:enable` |  |
| `:disable` |  |
| `:create` |  |
| `:nothing` **(default)** |  |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `user` | `String` | `"root"` | The name of the user that #{ChefUtils::Dist::Infra::PRODUCT} runs as. |
| `working_directory` | `String` | `"/var/root"` | The working directory to run the #{ChefUtils::Dist::Infra::PRODUCT} from. |
| `interval` | `[Integer, String]` | `30` | Time in minutes between #{ChefUtils::Dist::Infra::PRODUCT} executions. |
| `splay` | `[Integer, String]` | `300` | A random number of seconds between 0 and X to add to interval so that all #{ChefUtils::Dist::Infra::CLIENT} commands don't execute at the same time. |
| `accept_chef_license` | `[true, false]` | `false` | Accept the Chef Online Master License and Services Agreement. See <https://www.chef.io/online-master-agreement> |
| `config_directory` | `String` | `ChefConfig::Config.etc_chef_dir` | The path of the config directory. |
| `log_directory` | `String` | `"/Library/Logs/Chef"` | The path of the directory to create the log file in. |
| `log_file_name` | `String` | `"client.log"` | The name of the log file to use. |
| `chef_binary_path` | `String` | `lazy { Chef::ResourceHelpers::PathHelpers.chef_cli` | The path to the #{ChefUtils::Dist::Infra::CLIENT} binary. |
| `daemon_options` | `Array` | `[]` | An array of options to pass to the #{ChefUtils::Dist::Infra::CLIENT} command. |
| `environment` | `Hash` | `{}` | A Hash containing additional arbitrary environment variables under which the launchd daemon will be run in the form of `({'ENV_VARIABLE' => 'VALUE'})` |
| `nice` | `[Integer, String]` |  | The process priority to run the #{ChefUtils::Dist::Infra::CLIENT} process at. A value of -20 is the highest priority and 19 is the lowest priority. |
| `low_priority_io` | `[true, false]` | `true` | Run the #{ChefUtils::Dist::Infra::CLIENT} process with low priority disk IO |

### Examples

The following examples demonstrate various approaches for using the **chef_client_launchd** resource:

        **Set the #{ChefUtils::Dist::Infra::PRODUCT} to run on a schedule**:

        ```ruby
        chef_client_launchd 'Setup the #{ChefUtils::Dist::Infra::PRODUCT} to run every 30 minutes' do
          interval 30
          action :enable
        end
        ```

        **Disable the #{ChefUtils::Dist::Infra::PRODUCT} running on a schedule**:

        ```ruby
        chef_client_launchd 'Prevent the #{ChefUtils::Dist::Infra::PRODUCT} from running on a schedule' do
          action :disable
        end
        ```


---

## chef_client_scheduled_task resource

[chef_client_scheduled_task resource page](chef_client_scheduled_task/)

Use the **chef_client_scheduled_task** resource to setup the #{ChefUtils::Dist::Infra::PRODUCT} to run as a Windows scheduled task. This resource will also create the specified log directory if it doesn't already exist.

**New in Chef Infra Client 16.0.**

> Source: `lib/chef/resource/chef_client_scheduled_task.rb`

### Syntax

The full syntax for all of the properties that are available to the **chef_client_scheduled_task** resource is:

```ruby
chef_client_scheduled_task 'name' do
  task_name  # String  # default: ChefUtils::Dist::Infra::CLIENT
  user  # String  # default: "System"
  password  # String
  frequency  # String  # default: "minute"
  frequency_modifier  # [Integer, String]
  accept_chef_license  # [true, false]  # default: false
  start_date  # String
  start_time  # String
  splay  # [Integer, String]  # default: 300
  use_consistent_splay  # [true, false]  # default: false
  run_on_battery  # [true, false]  # default: true
  config_directory  # String  # default: ChefConfig::Config.etc_chef_dir
  log_directory  # String  # default: lazy { |r| "#{r.config_directory}/log" }
  log_file_name  # String  # default: "client.log"
  chef_binary_path  # String  # default: lazy { Chef::ResourceHelpers::PathHelpers.chef_client_hab_binary_path }
  daemon_options  # Array  # default: []
  priority  # Integer  # default: 7
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **chef_client_scheduled_task** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:add` | Add a Windows Scheduled Task that runs #{ChefUtils::Dist::Infra::PRODUCT}. |
| `:create` |  |
| `:remove` | Remove a Windows Scheduled Task that runs #{ChefUtils::Dist::Infra::PRODUCT}. |
| `:delete` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `task_name` | `String` | `ChefUtils::Dist::Infra::CLIENT` | The name of the scheduled task to create. |
| `user` | `String` | `"System"` | The name of the user that #{ChefUtils::Dist::Infra::PRODUCT} runs as. |
| `password` | `String` |  | The password for the user that #{ChefUtils::Dist::Infra::PRODUCT} runs as. |
| `frequency` | `String` | `"minute"` | Frequency with which to run the task. |
| `frequency_modifier` | `[Integer, String]` |  | Numeric value to go with the scheduled task frequency |
| `accept_chef_license` | `[true, false]` | `false` | Accept the Chef Online Master License and Services Agreement. See <https://www.chef.io/online-master-agreement> |
| `start_date` | `String` |  | The start date for the task in m:d:Y format (ex: 12/17/2020). |
| `start_time` | `String` |  | The start time for the task in HH:mm format (ex: 14:00). If the frequency is minute default start time will be Time.now plus the frequency_modifier nu |
| `splay` | `[Integer, String]` | `300` | A random number of seconds between 0 and X to add to interval so that all #{ChefUtils::Dist::Infra::CLIENT} commands don't execute at the same time. |
| `use_consistent_splay` | `[true, false]` | `false` | Always use the same random splay amount for each node to ensure consistent frequencies between #{ChefUtils::Dist::Infra::CLIENT} execution. |
| `run_on_battery` | `[true, false]` | `true` | Run the #{ChefUtils::Dist::Infra::PRODUCT} task when the system is on batteries. |
| `config_directory` | `String` | `ChefConfig::Config.etc_chef_dir` | The path of the config directory. |
| `log_directory` | `String` | `lazy { |r| "#{r.config_directory}/log" }` | The path of the directory to create the log file in. |
| `log_file_name` | `String` | `"client.log"` | The name of the log file to use. |
| `chef_binary_path` | `String` | `lazy { Chef::ResourceHelpers::PathHelpers.chef_cli` | The path to the #{ChefUtils::Dist::Infra::CLIENT} binary. |
| `daemon_options` | `Array` | `[]` | An array of options to pass to the #{ChefUtils::Dist::Infra::CLIENT} command. |
| `priority` | `Integer` | `7` | Use to set Priority Levels range from 0 to 10. |

### Examples

The following examples demonstrate various approaches for using the **chef_client_scheduled_task** resource:

      **Setup #{ChefUtils::Dist::Infra::PRODUCT} to run using the default 30 minute cadence**:

      ```ruby
      chef_client_scheduled_task 'Run #{ChefUtils::Dist::Infra::PRODUCT} as a scheduled task'
      ```

      **Run #{ChefUtils::Dist::Infra::PRODUCT} on system start**:

      ```ruby
      chef_client_scheduled_task '#{ChefUtils::Dist::Infra::PRODUCT} on start' do
        frequency 'onstart'
      end
      ```

      **Run #{ChefUtils::Dist::Infra::PRODUCT} with extra options passed to the client**:

      ```ruby
      chef_client_scheduled_task 'Run an override recipe' do
        daemon_options ['--override-runlist mycorp_base::default']
      end
      ```

      **Run #{ChefUtils::Dist::Infra::PRODUCT} daily at 01:00 am, specifying a named run-list**:

      ```ruby
      chef_client_scheduled_task 'Run chef-client named run-list daily' do
        frequency 'daily'
        start_time '01:00'
        daemon_options ['-n audit_only']
      end
      ```

      **Run #{ChefUtils::Dist::Infra::PRODUCT} with a persistent delay on every run calculated once, similar to how chef_client_cron resource works**:

      ```ruby
      chef_client_scheduled_task 'Run chef-client with persistent splay' do
        use_consistent_splay true
      end
      ```


---

## chef_client_systemd_timer resource

[chef_client_systemd_timer resource page](chef_client_systemd_timer/)

Use the **chef_client_systemd_timer** resource to setup the #{ChefUtils::Dist::Infra::PRODUCT} to run as a systemd timer.

**New in Chef Infra Client 16.0.**

> Source: `lib/chef/resource/chef_client_systemd_timer.rb`

### Syntax

The full syntax for all of the properties that are available to the **chef_client_systemd_timer** resource is:

```ruby
chef_client_systemd_timer 'name' do
  job_name  # String  # default: ChefUtils::Dist::Infra::CLIENT
  description  # String  # default: "#{ChefUtils::Dist::Infra::PRODUCT} periodic execution"
  user  # String  # default: "root"
  delay_after_boot  # String  # default: "1min"
  interval  # String  # default: "30min"
  splay  # String  # default: "5min"
  accept_chef_license  # [true, false]  # default: false
  run_on_battery  # [true, false]  # default: true
  config_directory  # String  # default: ChefConfig::Config.etc_chef_dir
  chef_binary_path  # String  # default: lazy { Chef::ResourceHelpers::PathHelpers.chef_client_hab_binary_path }
  daemon_options  # Array  # default: []
  environment  # Hash  # default: {}
  cpu_quota  # [Integer, String]
  service_umask  # [Integer, String]
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **chef_client_systemd_timer** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:add` | Add a systemd timer that runs #{ChefUtils::Dist::Infra::PRODUCT}. |
| `:create` |  |
| `:remove` | Remove a systemd timer that runs #{ChefUtils::Dist::Infra::PRODUCT}. |
| `:delete` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `job_name` | `String` | `ChefUtils::Dist::Infra::CLIENT` | The name of the system timer to create. |
| `description` | `String` | `"#{ChefUtils::Dist::Infra::PRODUCT} periodic execu` | The description to add to the systemd timer. This will be displayed when running `systemctl status` for the timer. |
| `user` | `String` | `"root"` | The name of the user that #{ChefUtils::Dist::Infra::PRODUCT} runs as. |
| `delay_after_boot` | `String` | `"1min"` |  |
| `interval` | `String` | `"30min"` |  |
| `splay` | `String` | `"5min"` |  |
| `accept_chef_license` | `[true, false]` | `false` | Accept the Chef Online Master License and Services Agreement. See <https://www.chef.io/online-master-agreement> |
| `run_on_battery` | `[true, false]` | `true` | Run the timer for #{ChefUtils::Dist::Infra::PRODUCT} if the system is on battery. |
| `config_directory` | `String` | `ChefConfig::Config.etc_chef_dir` | The path of the config directory. |
| `chef_binary_path` | `String` | `lazy { Chef::ResourceHelpers::PathHelpers.chef_cli` | The path to the #{ChefUtils::Dist::Infra::CLIENT} binary. |
| `daemon_options` | `Array` | `[]` | An array of options to pass to the #{ChefUtils::Dist::Infra::CLIENT} command. |
| `environment` | `Hash` | `{}` | A Hash containing additional arbitrary environment variables under which the systemd timer will be run in the form of `({'ENV_VARIABLE' => 'VALUE'})`. |
| `cpu_quota` | `[Integer, String]` |  |  |
| `service_umask` | `[Integer, String]` |  |  |

### Examples

The following examples demonstrate various approaches for using the **chef_client_systemd_timer** resource:

      **Setup #{ChefUtils::Dist::Infra::PRODUCT} to run using the default 30 minute cadence**:

      ```ruby
      chef_client_systemd_timer 'Run #{ChefUtils::Dist::Infra::PRODUCT} as a systemd timer'
      ```

      **Run #{ChefUtils::Dist::Infra::PRODUCT} every 1 hour**:

      ```ruby
      chef_client_systemd_timer 'Run #{ChefUtils::Dist::Infra::PRODUCT} every 1 hour' do
        interval '1hr'
      end
      ```

      **Run #{ChefUtils::Dist::Infra::PRODUCT} with extra options passed to the client**:

      ```ruby
      chef_client_systemd_timer 'Run an override recipe' do
        daemon_options ['--override-runlist mycorp_base::default']
      end
      ```


---

## chef_client_trusted_certificate resource

[chef_client_trusted_certificate resource page](chef_client_trusted_certificate/)

Use the **chef_client_trusted_certificate** resource to add certificates to #{ChefUtils::Dist::Infra::PRODUCT}'s trusted certificate directory. This allows the #{ChefUtils::Dist::Infra::PRODUCT} to communicate with internal encrypted resources without errors.

**New in Chef Infra Client 16.5.**

> Source: `lib/chef/resource/chef_client_trusted_certificate.rb`

### Syntax

The full syntax for all of the properties that are available to the **chef_client_trusted_certificate** resource is:

```ruby
chef_client_trusted_certificate 'name' do
  cert_name  # String
  certificate  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **chef_client_trusted_certificate** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:add` | Add a trusted certificate to #{ChefUtils::Dist::Infra::PRODUCT}'s trusted certificate directory |
| `:remove` | Remove a trusted certificate from #{ChefUtils::Dist::Infra::PRODUCT}'s trusted certificate directory |
| `:delete` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `cert_name` | `String` |  | The name to use for the certificate file on disk. If not provided the name of the resource block will be used instead. |
| `certificate` | `String` |  | The text of the certificate file including the BEGIN/END comment lines. |

### Examples

The following examples demonstrate various approaches for using the **chef_client_trusted_certificate** resource:

      **Trust a self signed certificate**:

      ```ruby
      chef_client_trusted_certificate 'self-signed.badssl.com' do
        certificate <<~CERT
        -----BEGIN CERTIFICATE-----
        MIIDeTCCAmGgAwIBAgIJAPziuikCTox4MA0GCSqGSIb3DQEBCwUAMGIxCzAJBgNV
        BAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMRYwFAYDVQQHDA1TYW4gRnJhbmNp
        c2NvMQ8wDQYDVQQKDAZCYWRTU0wxFTATBgNVBAMMDCouYmFkc3NsLmNvbTAeFw0x
        OTEwMDkyMzQxNTJaFw0yMTEwMDgyMzQxNTJaMGIxCzAJBgNVBAYTAlVTMRMwEQYD
        VQQIDApDYWxpZm9ybmlhMRYwFAYDVQQHDA1TYW4gRnJhbmNpc2NvMQ8wDQYDVQQK
        DAZCYWRTU0wxFTATBgNVBAMMDCouYmFkc3NsLmNvbTCCASIwDQYJKoZIhvcNAQEB
        BQADggEPADCCAQoCggEBAMIE7PiM7gTCs9hQ1XBYzJMY61yoaEmwIrX5lZ6xKyx2
        PmzAS2BMTOqytMAPgLaw+XLJhgL5XEFdEyt/ccRLvOmULlA3pmccYYz2QULFRtMW
        hyefdOsKnRFSJiFzbIRMeVXk0WvoBj1IFVKtsyjbqv9u/2CVSndrOfEk0TG23U3A
        xPxTuW1CrbV8/q71FdIzSOciccfCFHpsKOo3St/qbLVytH5aohbcabFXRNsKEqve
        ww9HdFxBIuGa+RuT5q0iBikusbpJHAwnnqP7i/dAcgCskgjZjFeEU4EFy+b+a1SY
        QCeFxxC7c3DvaRhBB0VVfPlkPz0sw6l865MaTIbRyoUCAwEAAaMyMDAwCQYDVR0T
        BAIwADAjBgNVHREEHDAaggwqLmJhZHNzbC5jb22CCmJhZHNzbC5jb20wDQYJKoZI
        hvcNAQELBQADggEBAGlwCdbPxflZfYOaukZGCaxYK6gpincX4Lla4Ui2WdeQxE95
        w7fChXvP3YkE3UYUE7mupZ0eg4ZILr/A0e7JQDsgIu/SRTUE0domCKgPZ8v99k3A
        vka4LpLK51jHJJK7EFgo3ca2nldd97GM0MU41xHFk8qaK1tWJkfrrfcGwDJ4GQPI
        iLlm6i0yHq1Qg1RypAXJy5dTlRXlCLd8ufWhhiwW0W75Va5AEnJuqpQrKwl3KQVe
        wGj67WWRgLfSr+4QG1mNvCZb2CkjZWmxkGPuoP40/y7Yu5OFqxP5tAjj4YixCYTW
        EVA0pmzIzgBg+JIe3PdRy27T0asgQW/F4TY61Yk=
        -----END CERTIFICATE-----
        CERT
      end
      ```


---

## chef_gem resource

[chef_gem resource page](chef_gem/)

Use the **chef_gem** resource to install a gem only for the instance of Ruby that is dedicated to the #{ChefUtils::Dist::Infra::CLIENT}. When a gem is installed from a local file, it must be added to the node using the **remote_file** or **cookbook_file** resources. The **chef_gem** resource works with all of the same properties and options as the **gem_package** resource, but does not accept the `gem_binary` property because it always uses the `CurrentGemEnvironment` under which the `#{ChefUtils::Dist::Infra::CLIENT}` is running. In addition to performing actions similar to the **gem_package** resource, the **chef_gem** resource does the following: - Runs its actions immediately, before convergence, allowing a gem to be used in a recipe immediately after it is installed. - Runs `Gem.clear_paths` after the action, ensuring that gem is aware of changes so that it can be required immediately after it is installed. Warning: The **chef_gem** and **gem_package** resources are both used to install Ruby gems. For any machine on which #{ChefUtils::Dist::Infra::PRODUCT} is installed, there are two instances of Ruby. One is the standard, system-wide instance of Ruby and the other is a dedicated instance that is available only to #{ChefUtils::Dist::Infra::PRODUCT}. Use the **chef_gem** resource to install gems into the instance of Ruby that is dedicated to #{ChefUtils::Dist::Infra::PRODUCT}. Use the **gem_package** resource to install all other gems (i.e. install gems system-wide).


> Source: `lib/chef/resource/chef_gem.rb`

### Syntax

The full syntax for all of the properties that are available to the **chef_gem** resource is:

```ruby
chef_gem 'name' do
  package_name  # String
  version  # String
  gem_binary  # String  # default: "#{RbConfig::CONFIG["bindir"]}/gem"
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **chef_gem** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `package_name` | `String` |  | An optional property to set the package name if it differs from the resource block's name. |
| `version` | `String` |  | The version of a package to be installed or upgraded. |
| `gem_binary` | `String` | `"#{RbConfig::CONFIG["bindir"]}/gem"` | The `gem` binary included with #{ChefUtils::Dist::Infra::PRODUCT}. |

### Examples

The following examples demonstrate various approaches for using the **chef_gem** resource:

        **Compile time vs. converge time installation of gems**

        To install a gem while #{ChefUtils::Dist::Infra::PRODUCT} is configuring the node (the converge phase), set the `compile_time` property to `false`:
        ```ruby
        chef_gem 'loofah' do
          compile_time false
          action :install
        end
        ```

        To install a gem while the resource collection is being built (the compile phase), set the `compile_time` property to `true`:
        ```ruby
        chef_gem 'loofah' do
          compile_time true
          action :install
        end
        ```

        **Install MySQL gem into #{ChefUtils::Dist::Infra::PRODUCT}**
        ```ruby
        apt_update

        build_essential 'install compilation tools' do
          compile_time true
        end

        chef_gem 'mysql'
        ```


---

## chef_handler resource

[chef_handler resource page](chef_handler/)

Use the **chef_handler** resource to enable handlers during a #{ChefUtils::Dist::Infra::PRODUCT} run. The resource allows arguments to be passed to #{ChefUtils::Dist::Infra::PRODUCT}, which then applies the conditions defined by the custom handler to the node attribute data collected during a #{ChefUtils::Dist::Infra::PRODUCT} run, and then processes the handler based on that data. The **chef_handler** resource is typically defined early in a node's run-list (often being the first item). This ensures that all of the handlers will be available for the entire #{ChefUtils::Dist::Infra::PRODUCT} run.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/chef_handler.rb`

### Syntax

The full syntax for all of the properties that are available to the **chef_handler** resource is:

```ruby
chef_handler 'name' do
  class_name  # String
  source  # String
  arguments  # [Array, Hash]  # default: []
  type  # Hash  # default: { report: true
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **chef_handler** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:enable` |  |
| `:create` |  |
| `:disable` | Disables the handler for the current #{ChefUtils::Dist::Infra::PRODUCT} run on the current node. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `class_name` | `String` |  | The name of the handler class. This can be module name-spaced. |
| `source` | `String` |  | The full path to the handler file. Can also be a gem path if the handler ships as part of a Ruby gem. |
| `arguments` | `[Array, Hash]` | `[]` | Arguments to pass the handler's class initializer. |
| `type` | `Hash` | `{ report: true` | The type of handler to register as, i.e. :report, :exception or both. |

### Examples

The following examples demonstrate various approaches for using the **chef_handler** resource:

      **Enable the 'MyHandler' handler**

      The following example shows how to enable a fictional 'MyHandler' handler which is located on disk at `/etc/chef/my_handler.rb`. The handler will be configured to run with Chef Infra Client and will be passed values to the handler's initializer method:

      ```ruby
      chef_handler 'MyHandler' do
        source '/etc/chef/my_handler.rb' # the file should already be at this path
        arguments path: '/var/chef/reports'
        action :enable
      end
      ```

      **Enable handlers during the compile phase**

      ```ruby
      chef_handler 'Chef::Handler::JsonFile' do
        source 'chef/handler/json_file'
        arguments path: '/var/chef/reports'
        action :enable
        compile_time true
      end
      ```

      **Handle only exceptions**

      ```ruby
      chef_handler 'Chef::Handler::JsonFile' do
        source 'chef/handler/json_file'
        arguments path: '/var/chef/reports'
        type exception: true
        action :enable
      end
      ```

      **Cookbook Versions (a custom handler)**

      [@juliandunn](https://github.com/juliandunn) created a custom report handler that logs all of the cookbooks and cookbook versions that were used during a Chef Infra Client run, and then reports after the run is complete.

      cookbook_versions.rb:

      The following custom handler defines how cookbooks and cookbook versions that are used during a Chef Infra Client run will be compiled into a report using the `Chef::Log` class in Chef Infra Client:

      ```ruby
      require 'chef/log'

      module Chef
        class CookbookVersionsHandler < Chef::Handler
          def report
            cookbooks = run_context.cookbook_collection
            Chef::Log.info('Cookbooks and versions run: #{cookbooks.map {|x| x.name.to_s + ' ' + x.version }}')
          end
        end
      end
      ```

      default.rb:

      The following recipe is added to the run-list for every node on which a list of cookbooks and versions will be generated as report output after every Chef Infra Client run.

      ```ruby
      cookbook_file '/etc/chef/cookbook_versions.rb' do
        source 'cookbook_versions.rb'
        action :create
      end

      chef_handler 'Chef::CookbookVersionsHandler' do
        source '/etc/chef/cookbook_versions.rb'
        type report: true
        action :enable
      end
      ```

      This recipe will generate report output similar to the following:

      ```
      [2013-11-26T03:11:06+00:00] INFO: Chef Infra Client Run complete in 0.300029878 seconds
      [2013-11-26T03:11:06+00:00] INFO: Running report handlers
      [2013-11-26T03:11:06+00:00] INFO: Cookbooks and versions run: ["cookbook_versions_handler 1.0.0"]
      [2013-11-26T03:11:06+00:00] INFO: Report handlers complete
      ```

      **JsonFile Handler**

      The JsonFile handler is available from the `chef_handler` cookbook and can be used with exceptions and reports. It serializes run status data to a JSON file. This handler may be enabled in one of the following ways.

      By adding the following lines of Ruby code to either the client.rb file or the solo.rb file, depending on how Chef Infra Client is being run:

      ```ruby
      require 'chef/handler/json_file'
      report_handlers << Chef::Handler::JsonFile.new(path: '/var/chef/reports')
      exception_handlers << Chef::Handler::JsonFile.new(path: '/var/chef/reports')
      ```

      By using the `chef_handler` resource in a recipe, similar to the following:

      ```ruby
      chef_handler 'Chef::Handler::JsonFile' do
        source 'chef/handler/json_file'
        arguments path: '/var/chef/reports'
        action :enable
      end
      ```

      After it has run, the run status data can be loaded and inspected via Interactive Ruby (IRb):

      ```
      irb(main):002:0> require 'json' => true
      irb(main):003:0> require 'chef' => true
      irb(main):004:0> r = JSON.parse(IO.read('/var/chef/reports/chef-run-report-20110322060731.json')) => ... output truncated
      irb(main):005:0> r.keys => ['end_time', 'node', 'updated_resources', 'exception', 'all_resources', 'success', 'elapsed_time', 'start_time', 'backtrace']
      irb(main):006:0> r['elapsed_time'] => 0.00246
      ```

      Register the JsonFile handler

      ```ruby
      chef_handler 'Chef::Handler::JsonFile' do
        source 'chef/handler/json_file'
        arguments path: '/var/chef/reports'
        action :enable
      end
      ```

      **ErrorReport Handler**

      The ErrorReport handler is built into Chef Infra Client and can be used for both exceptions and reports. It serializes error report data to a JSON file. This handler may be enabled in one of the following ways.

      By adding the following lines of Ruby code to either the client.rb file or the solo.rb file, depending on how Chef Infra Client is being run:

      ```ruby
      require 'chef/handler/error_report'
      report_handlers << Chef::Handler::ErrorReport.new
      exception_handlers << Chef::Handler::ErrorReport.new
      ```

      By using the `chef_handler` resource in a recipe, similar to the following:

      ```ruby
      chef_handler 'Chef::Handler::ErrorReport' do
        source 'chef/handler/error_report'
        action :enable
      end
      ```


---

## chef_sleep resource

[chef_sleep resource page](chef_sleep/)

Use the **chef_sleep** resource to pause (sleep) for a number of seconds during a #{ChefUtils::Dist::Infra::PRODUCT} run. Only use this resource when a command or service exits successfully but is not ready for the next step in a recipe.

**New in Chef Infra Client 15.5.**

> Source: `lib/chef/resource/chef_sleep.rb`

### Syntax

The full syntax for all of the properties that are available to the **chef_sleep** resource is:

```ruby
chef_sleep 'name' do
  seconds  # [String, Integer]
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **chef_sleep** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:start` |  |
| `:nothing` **(default)** |  |
| `:sleep` | Pause the #{ChefUtils::Dist::Infra::PRODUCT} run for a specified number of seconds. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `seconds` | `[String, Integer]` |  | The number of seconds to sleep. |

### Agentless Mode

The **chef_sleep** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **chef_sleep** resource:

        **Sleep for 10 seconds**:

        ```ruby
        chef_sleep '10'
        ```

        **Sleep for 10 seconds with a descriptive resource name for logging**:

        ```ruby
        chef_sleep 'wait for the service to start' do
          seconds 10
        end
        ```

        **Use a notification from another resource to sleep only when necessary**:

        ```ruby
        service 'Service that is slow to start and reports as started' do
          service_name 'my_database'
          action :start
          notifies :sleep, 'chef_sleep[wait for service start]'
        end

        chef_sleep 'wait for service start' do
          seconds 30
          action :nothing
        end
        ```


---

## chef_vault_secret resource

[chef_vault_secret resource page](chef_vault_secret/)

Use the **chef_vault_secret** resource to store secrets in Chef Vault items. Where possible and relevant, this resource attempts to map behavior and functionality to the knife vault sub-commands.

**New in Chef Infra Client 16.0.**

> Source: `lib/chef/resource/chef_vault_secret.rb`

### Syntax

The full syntax for all of the properties that are available to the **chef_vault_secret** resource is:

```ruby
chef_vault_secret 'name' do
  id  # String
  data_bag  # String
  admins  # [String, Array]
  clients  # [String, Array]
  search  # String  # default: "*:*"
  raw_data  # [Hash, Mash]  # default: {}
  environment  # [String, NilClass]
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **chef_vault_secret** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` | Creates the item, or updates it if it already exists. |
| `:create_if_missing` | Calls the create action unless it exists. |
| `:delete` | Deletes the item and the item's keys ('id'_keys). |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `id` | `String` |  | The name of the data bag item if it differs from the name of the resource block |
| `data_bag` | `String` |  | The data bag that contains the item. |
| `admins` | `[String, Array]` |  | A list of admin users who should have access to the item. Corresponds to the 'admin' option when using the chef-vault knife plugin. Can be specified a |
| `clients` | `[String, Array]` |  | A search query for the nodes' API clients that should have access to the item. |
| `search` | `String` | `"*:*"` | Search query that would match the same used for the clients, gets stored as a field in the item. |
| `raw_data` | `[Hash, Mash]` | `{}` | The raw data, as a Ruby Hash, that will be stored in the item. |
| `environment` | `[String, NilClass]` |  | The Chef environment of the data if storing per environment values. |

### Examples

The following examples demonstrate various approaches for using the **chef_vault_secret** resource:

        **To create a 'foo' item in an existing 'bar' data bag**:

        ```ruby
        chef_vault_secret 'foo' do
          data_bag 'bar'
          raw_data({ 'auth' => 'baz' })
          admins 'jtimberman'
          search '*:*'
        end
        ```

        **To allow multiple admins access to an item**:

        ```ruby
        chef_vault_secret 'root-password' do
          admins 'jtimberman,paulmooring'
          data_bag 'secrets'
          raw_data({ 'auth' => 'DoNotUseThisPasswordForRoot' })
          search '*:*'
        end
        ```


---

## chocolatey_config resource

[chocolatey_config resource page](chocolatey_config/)

Use the **chocolatey_config** resource to add or remove Chocolatey configuration keys. Note: The Chocolatey package manager is not installed on Windows by default. You will need to install it prior to using this resource by adding the [Chocolatey cookbook](https://supermarket.chef.io/cookbooks/chocolatey/) to your node's run list.

**New in Chef Infra Client 14.3.**

> Source: `lib/chef/resource/chocolatey_config.rb`

### Syntax

The full syntax for all of the properties that are available to the **chocolatey_config** resource is:

```ruby
chocolatey_config 'name' do
  config_key  # String
  value  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **chocolatey_config** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:unset` |  |
| `:set` | Sets a Chocolatey config value. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `config_key` | `String` |  | An optional property to set the config key name if it differs from the resource block's name. |
| `value` | `String` |  | The value to set. |

### Examples

The following examples demonstrate various approaches for using the **chocolatey_config** resource:

      **Set the Chocolatey cacheLocation config**:

      ```ruby
      chocolatey_config 'Set cacheLocation config' do
        config_key 'cacheLocation'
        value 'C:\\temp\\choco'
      end
      ```

      **Unset a Chocolatey config**:

      ```ruby
      chocolatey_config 'BogusConfig' do
        action :unset
      end
      ```


---

## chocolatey_feature resource

[chocolatey_feature resource page](chocolatey_feature/)

Use the **chocolatey_feature** resource to enable and disable Chocolatey features. Note: The Chocolatey package manager is not installed on Windows by default. You will need to install it prior to using this resource by adding the [Chocolatey cookbook](https://supermarket.chef.io/cookbooks/chocolatey/) to your node's run list.

**New in Chef Infra Client 15.1.**

> Source: `lib/chef/resource/chocolatey_feature.rb`

### Syntax

The full syntax for all of the properties that are available to the **chocolatey_feature** resource is:

```ruby
chocolatey_feature 'name' do
  feature_name  # String
  feature_state  # [TrueClass, FalseClass]  # default: false
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **chocolatey_feature** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:enable` |  |
| `:disable` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `feature_name` | `String` |  | The name of the Chocolatey feature to enable or disable. |
| `feature_state` | `[TrueClass, FalseClass]` | `false` |  |

### Examples

The following examples demonstrate various approaches for using the **chocolatey_feature** resource:

        **Enable the checksumFiles Chocolatey feature**

        ```ruby
        chocolatey_feature 'checksumFiles' do
          action :enable
        end
        ```

        **Disable the checksumFiles Chocolatey feature**

        ```ruby
        chocolatey_feature 'checksumFiles' do
          action :disable
        end
        ```


---

## chocolatey_installer resource

[chocolatey_installer resource page](chocolatey_installer/)

Use the chocolatey_installer resource to ensure that Chocolatey itself is installed to your specification. Use the Chocolatey Feature resource to customize your install. Then use the Chocolatey Package resource to install packages on Windows via Chocolatey.

**New in Chef Infra Client 18.3.**

> Source: `lib/chef/resource/chocolatey_installer.rb`

### Syntax

The full syntax for all of the properties that are available to the **chocolatey_installer** resource is:

```ruby
chocolatey_installer 'name' do
  download_url  # String
  chocolatey_version  # String
  use_native_unzip  # [TrueClass, FalseClass]  # default: false
  ignore_proxy  # [TrueClass, FalseClass]  # default: false
  proxy_url  # String
  proxy_user  # String
  proxy_password  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **chocolatey_installer** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:uninstall` |  |
| `:upgrade` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `download_url` | `String` |  |  |
| `chocolatey_version` | `String` |  |  |
| `use_native_unzip` | `[TrueClass, FalseClass]` | `false` |  |
| `ignore_proxy` | `[TrueClass, FalseClass]` | `false` | If set, ignores any configured proxy. This will override any proxy environment variables or parameters. This will be set by default if ignore_proxy is |
| `proxy_url` | `String` |  | Specifies the proxy URL to use during the download. |
| `proxy_user` | `String` |  | The username to use to build a proxy credential with. Will be consumed by the proxy_credential property if both this property and proxy_password are s |
| `proxy_password` | `String` |  | The password to use to build a proxy credential with. Will be consumed by the proxy_credential property if both this property and proxy_user are set |

### Examples

The following examples demonstrate various approaches for using the **chocolatey_installer** resource:

          **Install Chocolatey**

          ```ruby
          chocolatey_installer 'latest' do
            action :install
          end
          ```

          **Uninstall Chocolatey**

          ```ruby
          chocolatey_installer 'Some random verbiage' do
            action :uninstall
          end
          ```

          **Install Chocolatey with Parameters**

          ```ruby
          chocolatey_installer 'latest' do
            action :install
            download_url "https://www.contoso.com/foo"
            chocolatey_version '2.12.24'
          end
          ```

          ```ruby
          chocolatey_installer 'latest' do
            action :install
            download_url "c:\\foo\\foo.nupkg"
            chocolatey_version '2.12.24'
          end
          ```

          **Upgrade Chocolatey with Parameters**

          ```ruby
          chocolatey_installer 'latest' do
            action :upgrade
            chocolatey_version '2.12.24'
          end
          ```


---

## chocolatey_package resource

[chocolatey_package resource page](chocolatey_package/)

Use the **chocolatey_package** resource to manage packages using the Chocolatey package manager on the Microsoft Windows platform. Note: The Chocolatey package manager is not installed on Windows by default. You will need to install it prior to using this resource by adding the [chocolatey cookbook](https://supermarket.chef.io/cookbooks/chocolatey/) to your node's run list. Warning: The **chocolatey_package** resource must be specified as `chocolatey_package` and cannot be shortened to `package` in a recipe.

**New in Chef Infra Client 12.7.**

> Source: `lib/chef/resource/chocolatey_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **chocolatey_package** resource is:

```ruby
chocolatey_package 'name' do
  options  # [String, Array]
  list_options  # String
  user  # String
  password  # String
  package_name  # [String, Array]
  bulk_query  # [TrueClass, FalseClass]  # default: false
  use_choco_list  # [TrueClass, FalseClass]  # default: false
  version  # [String, Array]
  returns  # [Integer, Array]
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **chocolatey_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:upgrade` |  |
| `:remove` |  |
| `:purge` |  |
| `:reconfig` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `options` | `[String, Array]` |  | One (or more) additional options that are passed to the command. |
| `list_options` | `String` |  | One (or more) additional list options that are passed to the command. |
| `user` | `String` |  | The username to authenticate feeds. |
| `password` | `String` |  | The password to authenticate to the source. |
| `package_name` | `[String, Array]` |  | The name of the package. Default value: the name of the resource block. |
| `bulk_query` | `[TrueClass, FalseClass]` | `false` | Bulk query the chocolatey server?  This will cause the provider to list all packages instead of doing individual queries. |
| `use_choco_list` | `[TrueClass, FalseClass]` | `false` | Use choco list for getting the locally installed packages, rather than reading the nupkg database directly?  This defaults to false, since reading the |
| `version` | `[String, Array]` |  | The version of a package to be installed or upgraded. |
| `returns` | `[Integer, Array]` |  |  |

### Examples

The following examples demonstrate various approaches for using the **chocolatey_package** resource:

        **Install a Chocolatey package**:

        ```ruby
        chocolatey_package 'name of package' do
          action :install
        end
        ```

        **Install a package with options with Chocolatey's `--checksum` option**:

        ```ruby
        chocolatey_package 'name of package' do
          options '--checksum 1234567890'
          action :install
        end
        ```


---

## chocolatey_source resource

[chocolatey_source resource page](chocolatey_source/)

Use the **chocolatey_source** resource to add, remove, enable, or disable Chocolatey sources. Note: The Chocolatey package manager is not installed on Windows by default. You will need to install it prior to using this resource by adding the [Chocolatey cookbook](https://supermarket.chef.io/cookbooks/chocolatey/) to your node's run list.

**New in Chef Infra Client 14.3.**

> Source: `lib/chef/resource/chocolatey_source.rb`

### Syntax

The full syntax for all of the properties that are available to the **chocolatey_source** resource is:

```ruby
chocolatey_source 'name' do
  source_name  # String
  source  # String
  bypass_proxy  # [TrueClass, FalseClass]  # default: false
  admin_only  # [TrueClass, FalseClass]  # default: false
  allow_self_service  # [TrueClass, FalseClass]  # default: false
  priority  # Integer  # default: 0
  disabled  # [TrueClass, FalseClass]  # default: false
  username  # String
  password  # String
  cert  # String
  cert_password  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **chocolatey_source** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:add` |  |
| `:remove` |  |
| `:disable` | Disables a Chocolatey source. **New in Chef Infra Client 15.1.** |
| `:enable` | Enables a Chocolatey source. **New in Chef Infra Client 15.1.** |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `source_name` | `String` |  | An optional property to set the source name if it differs from the resource block's name. |
| `source` | `String` |  | The source URL. |
| `bypass_proxy` | `[TrueClass, FalseClass]` | `false` | Whether or not to bypass the system's proxy settings to access the source. |
| `admin_only` | `[TrueClass, FalseClass]` | `false` | Whether or not to set the source to be accessible to only admins. |
| `allow_self_service` | `[TrueClass, FalseClass]` | `false` | Whether or not to set the source to be used for self service. |
| `priority` | `Integer` | `0` | The priority level of the source. |
| `disabled` | `[TrueClass, FalseClass]` | `false` |  |
| `username` | `String` |  | The username to use when authenticating against the source |
| `password` | `String` |  | The password to use when authenticating against the source |
| `cert` | `String` |  | The certificate to use when authenticating against the source |
| `cert_password` | `String` |  | The password for the certificate to use when authenticating against the source |

### Examples

The following examples demonstrate various approaches for using the **chocolatey_source** resource:

        **Add a Chocolatey source**

        ```ruby
        chocolatey_source 'MySource' do
          source 'http://example.com/something'
          action :add
        end
        ```

        **Remove a Chocolatey source**

        ```ruby
        chocolatey_source 'MySource' do
          action :remove
        end
        ```


---

## cookbook_file resource

[cookbook_file resource page](cookbook_file/)

Use the **cookbook_file** resource to transfer files from a sub-directory of COOKBOOK_NAME/files/ to a specified path located on a host that is running the #{ChefUtils::Dist::Infra::PRODUCT}. The file is selected according to file specificity, which allows different source files to be used based on the hostname, host platform (operating system, distro, or as appropriate), or platform version. Files that are located in the COOKBOOK_NAME/files/default sub-directory may be used on any platform.  During a #{ChefUtils::Dist::Infra::PRODUCT} run, the checksum for each local file is calculated and then compared against the checksum for the same file as it currently exists in the cookbook on the #{ChefUtils::Dist::Server::PRODUCT}. A file is not transferred when the checksums match. Only files that require an update are transferred from the #{ChefUtils::Dist::Server::PRODUCT} to a node.


> Source: `lib/chef/resource/cookbook_file.rb`

### Syntax

The full syntax for all of the properties that are available to the **cookbook_file** resource is:

```ruby
cookbook_file 'name' do
  source  # [ String, Array ]  # default: lazy { ::File.basename(name) }
  cookbook  # String
  action  :symbol # defaults to :create if not specified
end
```

### Actions

The **cookbook_file** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `source` | `[ String, Array ]` | `lazy { ::File.basename(name) }` |  |
| `cookbook` | `String` |  | The cookbook in which a file is located (if it is not located in the current cookbook). |

### Agentless Mode

The **cookbook_file** resource has **full** support for Agentless Mode.


---

## cron resource

Use the **cron** resource to manage cron entries for time-based job scheduling. Properties for a schedule will default to * if not provided. The cron resource requires access to a crontab program, typically cron. Warning: The cron resource should only be used to modify an entry in a crontab file. The `cron_d` resource directly manages `cron.d` files. This resource ships in #{ChefUtils::Dist::Infra::PRODUCT} 14.4 or later and can also be found in the [cron](https://github.com/chef-cookbooks/cron) cookbook) for previous #{ChefUtils::Dist::Infra::PRODUCT} releases.


> Source: `lib/chef/resource/cron\cron.rb`

### Syntax

The full syntax for all of the properties that are available to the **cron** resource is:

```ruby
cron 'name' do
  time  # Symbol
  action  :symbol # defaults to :create if not specified
end
```

### Actions

The **cron** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` **(default)** |  |
| `:delete` |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `time` | `Symbol` |  | A time interval. |

### Agentless Mode

The **cron** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **cron** resource:

      **Run a program at a specified interval**

      ```ruby
      cron 'noop' do
        hour '5'
        minute '0'
        command '/bin/true'
      end
      ```

      **Run an entry if a folder exists**

      ```ruby
      cron 'ganglia_tomcat_thread_max' do
        command "/usr/bin/gmetric
          -n 'tomcat threads max'
          -t uint32
          -v '/usr/local/bin/tomcat-stat --thread-max'"
        only_if { ::File.exist?('/home/jboss') }
      end
      ```

      **Run every Saturday, 8:00 AM**

      The following example shows a schedule that will run every hour at 8:00 each Saturday morning, and will then send an email to “admin@example.com” after each run.

      ```ruby
      cron 'name_of_cron_entry' do
        minute '0'
        hour '8'
        weekday '6'
        mailto 'admin@example.com'
        action :create
      end
      ```

      **Run once a week**

      ```ruby
      cron 'cookbooks_report' do
        minute '0'
        hour '0'
        weekday '1'
        user 'chefio'
        mailto 'sysadmin@example.com'
        home '/srv/supermarket/shared/system'
        command %W{
          cd /srv/supermarket/current &&
          env RUBYLIB="/srv/supermarket/current/lib"
          RAILS_ASSET_ID=`git rev-parse HEAD` RAILS_ENV="#{rails_env}"
          bundle exec rake cookbooks_report
        }.join(' ')
        action :create
      end
      ```

      **Run only in November**

      The following example shows a schedule that will run at 8:00 PM, every weekday (Monday through Friday), but only in November:

      ```ruby
      cron 'name_of_cron_entry' do
        minute '0'
        hour '20'
        day '*'
        month '11'
        weekday '1-5'
        action :create
      end
      ```


---

## cron_access resource

[cron_access resource page](cron_access/)

Use the **cron_access** resource to manage cron's cron.allow and cron.deny files. Note: This resource previously shipped in the `cron` cookbook as `cron_manage`, which it can still be used as for backwards compatibility with existing Chef Infra Client releases.

**New in Chef Infra Client 14.4.**

> Source: `lib/chef/resource/cron_access.rb`

### Syntax

The full syntax for all of the properties that are available to the **cron_access** resource is:

```ruby
cron_access 'name' do
  user  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **cron_access** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:deny` |  |
| `:allow` | Add the user to the cron.allow file. |
| `:nothing` **(default)** |  |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `user` | `String` |  | An optional property to set the user name if it differs from the resource block's name. |

### Agentless Mode

The **cron_access** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **cron_access** resource:

        **Add the mike user to cron.allow**

        ```ruby
        cron_access 'mike'
        ```

        **Add the mike user to cron.deny**

        ```ruby
        cron_access 'mike' do
          action :deny
        end
        ```

        **Specify the username with the user property**

        ```ruby
        cron_access 'Deny the jenkins user access to cron for security purposes' do
          user 'jenkins'
          action :deny
        end
        ```


---

## cron_d resource

Add a cron definition file to `/etc/cron.d`.

**New in Chef Infra Client 14.4.**

> Source: `lib/chef/resource/cron\cron_d.rb`

### Syntax

The full syntax for all of the properties that are available to the **cron_d** resource is:

```ruby
cron_d 'name' do
  cron_name  # String
  cookbook  # String
  predefined_value  # String
  comment  # String
  mode  # [String, Integer]  # default: "0600"
  random_delay  # Integer
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **cron_d** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` |  |
| `:delete` |  |
| `:create_if_missing` | Add a cron definition file to `/etc/cron.d`, but do not update an existing file. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `cron_name` | `String` |  | An optional property to set the cron name if it differs from the resource block's name. |
| `cookbook` | `String` |  |  |
| `predefined_value` | `String` |  | Schedule your cron job with one of the special predefined value instead of ** * pattern. |
| `comment` | `String` |  | A comment to place in the cron.d file. |
| `mode` | `[String, Integer]` | `"0600"` | The octal mode of the generated crontab file. |
| `random_delay` | `Integer` |  | Set the `RANDOM_DELAY` environment variable in the cron.d file. |

### Agentless Mode

The **cron_d** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **cron_d** resource:

        **Run a program on the fifth hour of the day**

        ```ruby
        cron_d 'noop' do
          hour '5'
          minute '0'
          command '/bin/true'
        end
        ```

        **Run an entry if a folder exists**

        ```ruby
        cron_d 'ganglia_tomcat_thread_max' do
          command "/usr/bin/gmetric
            -n 'tomcat threads max'
            -t uint32
            -v '/usr/local/bin/tomcat-stat
            --thread-max'"
          only_if { ::File.exist?('/home/jboss') }
        end
        ```

        **Run an entry every Saturday, 8:00 AM**

        ```ruby
        cron_d 'name_of_cron_entry' do
          minute '0'
          hour '8'
          weekday '6'
          mailto 'admin@example.com'
          command '/bin/true'
          action :create
        end
        ```

        **Run an entry at 8:00 PM, every weekday (Monday through Friday), but only in November**

        ```ruby
        cron_d 'name_of_cron_entry' do
          minute '0'
          hour '20'
          day '*'
          month '11'
          weekday '1-5'
          command '/bin/true'
          action :create
        end
        ```

        **Remove a cron job by name**:

        ```ruby
        cron_d 'job_to_remove' do
          action :delete
        end
        ```


---

## csh resource

[csh resource page](csh/)

Use the **csh** resource to execute scripts using the csh interpreter." \


> Source: `lib/chef/resource/csh.rb`

### Syntax

The full syntax for all of the properties that are available to the **csh** resource is:

```ruby
csh 'name' do
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **csh** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

No resource-specific properties.

> This resource inherits all properties from the `execute` resource via the `script` base class, including:
> `code` (required), `cwd`, `environment`, `flags`, `group`, `input`, `interpreter`,
> `live_stream`, `login`, `password`, `returns`, `timeout`, `user`, `domain`, `elevated`.

### Agentless Mode

The **csh** resource has **full** support for Agentless Mode.


---

## directory resource

[directory resource page](directory/)

Use the **directory** resource to manage a directory, which is a hierarchy" \


> Source: `lib/chef/resource/directory.rb`

### Syntax

The full syntax for all of the properties that are available to the **directory** resource is:

```ruby
directory 'name' do
  path  # String
  recursive  # [ TrueClass, FalseClass ]  # default: false end end
  action  :symbol # defaults to :create if not specified
end
```

### Actions

The **directory** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` **(default)** |  |
| `:delete` |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `path` | `String` |  | The path to the directory. Using a fully qualified path is recommended, but is not always required. |
| `recursive` | `[ TrueClass, FalseClass ]` | `false end end` | Create parent directories recursively, or delete directory and all children recursively. For the owner, group, and mode properties, the value of this  |

### Agentless Mode

The **directory** resource has **full** support for Agentless Mode.


---

## dmg_package resource

[dmg_package resource page](dmg_package/)

Use the **dmg_package** resource to install a package from a .dmg file. The resource will retrieve the dmg file from a remote URL, mount it using macOS' `hdidutil`, copy the application (.app directory) to the specified destination (`/Applications`), and detach the image using `hdiutil`. The dmg file will be stored in the `Chef::Config[:file_cache_path]`.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/dmg_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **dmg_package** resource is:

```ruby
dmg_package 'name' do
  app  # String
  source  # String
  file  # String
  owner  # [String, Integer]
  destination  # String  # default: "/Applications"
  checksum  # String
  volumes_dir  # String  # default: lazy { app }
  dmg_name  # String  # default: lazy { app }
  type  # String  # default: "app"
  package_id  # String
  dmg_passphrase  # String
  accept_eula  # [TrueClass, FalseClass]  # default: false
  headers  # Hash
  allow_untrusted  # [TrueClass, FalseClass]  # default: false
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **dmg_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `app` | `String` |  | The name of the application as it appears in the `/Volumes` directory if it differs from the resource block's name. |
| `source` | `String` |  | The remote URL that is used to download the `.dmg` file, if specified. |
| `file` | `String` |  | The absolute path to the `.dmg` file on the local system. |
| `owner` | `[String, Integer]` |  | The user that should own the package installation. |
| `destination` | `String` | `"/Applications"` | The directory to copy the `.app` into. |
| `checksum` | `String` |  | The sha256 checksum of the `.dmg` file to download. |
| `volumes_dir` | `String` | `lazy { app }` | The directory under `/Volumes` where the `dmg` is mounted if it differs from the name of the `.dmg` file. |
| `dmg_name` | `String` | `lazy { app }` | The name of the `.dmg` file if it differs from that of the app, or if the name has spaces. |
| `type` | `String` | `"app"` | The type of package. |
| `package_id` | `String` |  | The package ID that is registered with `pkgutil` when a `pkg` or `mpkg` is installed. |
| `dmg_passphrase` | `String` |  | Specify a passphrase to be used to decrypt the `.dmg` file during the mount process. |
| `accept_eula` | `[TrueClass, FalseClass]` | `false` | Specify whether to accept the EULA. Certain dmg files require acceptance of EULA before mounting. |
| `headers` | `Hash` |  | Allows custom HTTP headers (like cookies) to be set on the `remote_file` resource. |
| `allow_untrusted` | `[TrueClass, FalseClass]` | `false` | Allow installation of packages that do not have trusted certificates. |

### Examples

The following examples demonstrate various approaches for using the **dmg_package** resource:

        **Install Google Chrome via the DMG package**:

        ```ruby
        dmg_package 'Google Chrome' do
          dmg_name 'googlechrome'
          source   'https://dl-ssl.google.com/chrome/mac/stable/GGRM/googlechrome.dmg'
          checksum '7daa2dc5c46d9bfb14f1d7ff4b33884325e5e63e694810adc58f14795165c91a'
          action   :install
        end
        ```

        **Install VirtualBox from the .mpkg**:

        ```ruby
        dmg_package 'Virtualbox' do
          source 'http://dlc.sun.com.edgesuite.net/virtualbox/4.0.8/VirtualBox-4.0.8-71778-OSX.dmg'
          type   'mpkg'
        end
        ```

        **Install pgAdmin and automatically accept the EULA**:

        ```ruby
        dmg_package 'pgAdmin3' do
          source   'http://wwwmaster.postgresql.org/redir/198/h/pgadmin3/release/v1.12.3/osx/pgadmin3-1.12.3.dmg'
          checksum '9435f79d5b52d0febeddfad392adf82db9df159196f496c1ab139a6957242ce9'
          accept_eula true
        end
        ```


---

## dnf_package resource

[dnf_package resource page](dnf_package/)

Use the **dnf_package** resource to install, upgrade, and remove packages with DNF for Fedora and RHEL 8+. The dnf_package resource is able to resolve provides data for packages much like DNF can do when it is run from the command line. This allows a variety of options for installing packages, like minimum versions, virtual provides and library names.

**New in Chef Infra Client 12.18.**

> Source: `lib/chef/resource/dnf_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **dnf_package** resource is:

```ruby
dnf_package 'name' do
  arch  # [String, Array]
  flush_cache  # Hash  # default: { before: false
  allow_downgrade  # [ TrueClass, FalseClass ]  # default: true
  environment  # Hash  # default: {}
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **dnf_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:upgrade` |  |
| `:remove` |  |
| `:purge` |  |
| `:reconfig` |  |
| `:lock` |  |
| `:unlock` |  |
| `:flush_cache` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `arch` | `[String, Array]` |  | The architecture of the package to be installed or upgraded. This value can also be passed as part of the package name. |
| `flush_cache` | `Hash` | `{ before: false` |  |
| `allow_downgrade` | `[ TrueClass, FalseClass ]` | `true` | Allow downgrading a package to satisfy requested version requirements. |
| `environment` | `Hash` | `{}` | A Hash of environment variables in the form of {'ENV_VARIABLE' => 'VALUE'} to be set before running the command. |


---

## dpkg_package resource

[dpkg_package resource page](dpkg_package/)

Use the **dpkg_package** resource to manage packages for the dpkg platform. When a package is installed from a local file, it must be added to the node using the **remote_file** or **cookbook_file** resources.

**New in Chef Infra Client 19.0.** *(catalog version; not declared in local source)*

> Source: `lib/chef/resource/dpkg_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **dpkg_package** resource is:

```ruby
dpkg_package 'name' do
  source  # [ String, Array, nil ]
  response_file  # String
  response_file_variables  # Hash  # default: {}
  allow_downgrade  # [ TrueClass, FalseClass ]  # default: true
  environment  # Hash  # default: {}
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **dpkg_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `source` | `[ String, Array, nil ]` |  | The path to a package in the local file system. |
| `response_file` | `String` |  | The direct path to the file used to pre-seed a package. |
| `response_file_variables` | `Hash` | `{}` | A Hash of response file variables in the form of {'VARIABLE' => 'VALUE'}. |
| `allow_downgrade` | `[ TrueClass, FalseClass ]` | `true` | Allow downgrading a package to satisfy requested version requirements. |
| `environment` | `Hash` | `{}` | A Hash of environment variables in the form of {'ENV_VARIABLE' => 'VALUE'} to be set before running the command. |

### Agentless Mode

The **dpkg_package** resource has **full** support for Agentless Mode.

Support was added in Chef Infra Client 19.0.


---

## dsc_resource resource

[dsc_resource resource page](dsc_resource/)

The dsc_resource resource allows any DSC resource to be used in a recipe, as well as any custom resources that have been added to your Windows PowerShell environment. Microsoft frequently adds new resources to the DSC resource collection.

**New in Chef Infra Client 12.2.**

> Source: `lib/chef/resource/dsc_resource.rb`

### Syntax

The full syntax for all of the properties that are available to the **dsc_resource** resource is:

```ruby
dsc_resource 'name' do
  module_version  # String
  reboot_action  # Symbol  # default: :nothing
  timeout  # Integer
  action  :symbol # defaults to :run if not specified
end
```

### Actions

The **dsc_resource** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `module_version` | `String` |  | The version number of the module to use. PowerShell 5.0.10018.0 (or higher) supports having multiple versions of a module installed. This should be sp |
| `reboot_action` | `Symbol` | `:nothing` | Use to request an immediate reboot or to queue a reboot using the :reboot_now (immediate reboot) or :request_reboot (queued reboot) actions built into |
| `timeout` | `Integer` |  | The amount of time (in seconds) a command is to wait before timing out. |


---

## dsc_script resource

[dsc_script resource page](dsc_script/)

Many DSC resources are comparable to built-in #{ChefUtils::Dist::Infra::PRODUCT} resources. For example, both DSC and #{ChefUtils::Dist::Infra::PRODUCT} have file, package, and service resources. The dsc_script resource is most useful for those DSC resources that do not have a direct comparison to a resource in #{ChefUtils::Dist::Infra::PRODUCT}, such as the Archive resource, a custom DSC resource, an existing DSC script that performs an important task, and so on. Use the dsc_script resource to embed the code that defines a DSC configuration directly within a #{ChefUtils::Dist::Infra::PRODUCT} recipe. Warning: The **dsc_script** resource is only available on 64-bit Chef Infra Client.


> Source: `lib/chef/resource/dsc_script.rb`

### Syntax

The full syntax for all of the properties that are available to the **dsc_script** resource is:

```ruby
dsc_script 'name' do
  flags  # Hash
  cwd  # String
  environment  # Hash
  timeout  # Integer
  action  :symbol # defaults to :run if not specified
end
```

### Actions

The **dsc_script** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `flags` | `Hash` |  |  |
| `cwd` | `String` |  | The current working directory. |
| `environment` | `Hash` |  | A Hash of environment variables in the form of ({'ENV_VARIABLE' => 'VALUE'}). (These variables must exist for a command to be run successfully). |
| `timeout` | `Integer` |  | The amount of time (in seconds) a command is to wait before timing out. |


---

## execute resource

[execute resource page](execute/)

Use the **execute** resource to execute a single command. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use `not_if` and `only_if` to guard this resource for idempotence. Note: Use the **script** resource to execute a script using a specific interpreter (Ruby, Python, Perl, csh, or Bash).

**New in Chef Infra Client 15.1.** *(catalog version; not declared in local source)*

> Source: `lib/chef/resource/execute.rb`

### Syntax

The full syntax for all of the properties that are available to the **execute** resource is:

```ruby
execute 'name' do
  command  # [ String, Array ]
  creates  # String
  cwd  # String
  environment  # Hash
  group  # [ String, Integer ]
  live_stream  # [ TrueClass, FalseClass ]  # default: false
  default_env  # [ TrueClass, FalseClass ]  # default: false
  returns  # [ Integer, Array ]  # default: 0
  timeout  # [ Integer, String, Float ]  # default: 3600
  user  # [ String, Integer ]
  domain  # String
  password  # String
  sensitive  # [ TrueClass, FalseClass ]  # default: lazy { password ? true : false }
  elevated  # [ TrueClass, FalseClass ]  # default: false
  input  # [String]
  login  # [ TrueClass, FalseClass ]  # default: false
  cgroup  # [String]
  action  :symbol # defaults to :run if not specified
end
```

### Actions

The **execute** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:nothing` |  |
| `:run` **(default)** |  |
| `:delete` |  |
| `:stop` |  |
| `:start` |  |
| `:add` |  |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `command` | `[ String, Array ]` |  |  |
| `creates` | `String` |  | Prevent a command from creating a file when that file already exists. |
| `cwd` | `String` |  | The current working directory from which the command will be run. |
| `environment` | `Hash` |  | A Hash of environment variables in the form of `({'ENV_VARIABLE' => 'VALUE'})`. **Note**: These variables must exist for a command to be run successfu |
| `group` | `[ String, Integer ]` |  | The group name or group ID that must be changed before running a command. |
| `live_stream` | `[ TrueClass, FalseClass ]` | `false` | Send the output of the command run by this execute resource block to the #{ChefUtils::Dist::Infra::PRODUCT} event stream. |
| `default_env` | `[ TrueClass, FalseClass ]` | `false` | When true this enables ENV magic to add path_sanity to the PATH and force the locale to English+UTF-8 for parsing output |
| `returns` | `[ Integer, Array ]` | `0` | The return value for a command. This may be an array of accepted values. An exception is raised when the return value(s) do not match. |
| `timeout` | `[ Integer, String, Float ]` | `3600` | The amount of time (in seconds) a command is to wait before timing out. |
| `user` | `[ String, Integer ]` |  |  |
| `domain` | `String` |  |  |
| `password` | `String` |  |  |
| `sensitive` | `[ TrueClass, FalseClass ]` | `lazy { password ? true : false }` | Ensure that sensitive resource data is not logged by the #{ChefUtils::Dist::Infra::PRODUCT}. |
| `elevated` | `[ TrueClass, FalseClass ]` | `false` |  |
| `input` | `[String]` |  | An optional property to set the input sent to the command as STDIN. |
| `login` | `[ TrueClass, FalseClass ]` | `false` | Use a login shell to run the commands instead of inheriting the existing execution environment. |
| `cgroup` | `[String]` |  | Linux only: Run the command within a specific cgroup, creating it if it doesn't exist. |

### Agentless Mode

The **execute** resource has **full** support for Agentless Mode.

Support was added in Chef Infra Client 15.1.

### Examples

The following examples demonstrate various approaches for using the **execute** resource:

        **Run a command upon notification**:

        ```ruby
        execute 'slapadd' do
          command 'slapadd < /tmp/something.ldif'
          creates '/var/lib/slapd/uid.bdb'

          action :nothing
        end

        template '/tmp/something.ldif' do
          source 'something.ldif'

          notifies :run, 'execute[slapadd]', :immediately
        end
        ```

        **Run a touch file only once while running a command**:

        ```ruby
        execute 'upgrade script' do
          command 'php upgrade-application.php && touch /var/application/.upgraded'

          creates '/var/application/.upgraded'
          action :run
        end
        ```

        **Run a command which requires an environment variable**:

        ```ruby
        execute 'slapadd' do
          command 'slapadd < /tmp/something.ldif'
          creates '/var/lib/slapd/uid.bdb'

          action :run
          environment ({'HOME' => '/home/my_home'})
        end
        ```

        **Delete a repository using yum to scrub the cache**:

        ```ruby
        # the following code sample thanks to gaffneyc @ https://gist.github.com/918711
        execute 'clean-yum-cache' do
          command 'yum clean all'
          action :nothing
        end

        file '/etc/yum.repos.d/bad.repo' do
          action :delete
          notifies :run, 'execute[clean-yum-cache]', :immediately
        end
        ```

        **Prevent restart and reconfigure if configuration is broken**:

        Use the `:nothing` action (common to all resources) to prevent the test from
        starting automatically, and then use the `subscribes` notification to run a
        configuration test when a change to the template is detected.

        ```ruby
        execute 'test-nagios-config' do
          command 'nagios3 --verify-config'
          action :nothing
          subscribes :run, 'template[/etc/nagios3/configures-nagios.conf]', :immediately
        end
        ```

        **Notify in a specific order**:

        To notify multiple resources, and then have these resources run in a certain
        order, do something like the following.

        ```ruby
        execute 'foo' do
          command '...'
          notifies :create, 'template[baz]', :immediately
          notifies :install, 'package[bar]', :immediately
          notifies :run, 'execute[final]', :immediately
        end

        template 'baz' do
          #...
          notifies :run, 'execute[restart_baz]', :immediately
        end

        package 'bar'
          execute 'restart_baz'
          execute 'final' do
          command '...'
        end
        ```

        where the sequencing will be in the same order as the resources are listed in
        the recipe: `execute 'foo'`, `template 'baz'`, `execute [restart_baz]`,
        `package 'bar'`, and `execute 'final'`.

        **Execute a command using a template**:

        The following example shows how to set up IPv4 packet forwarding using the
        **execute** resource to run a command named `forward_ipv4` that uses a template
        defined by the **template** resource.

        ```ruby
        execute 'forward_ipv4' do
          command 'echo > /proc/.../ipv4/ip_forward'
          action :nothing
        end

        template '/etc/file_name.conf' do
          source 'routing/file_name.conf.erb'

         notifies :run, 'execute[forward_ipv4]', :delayed
        end
        ```

        where the `command` property for the **execute** resource contains the command
        that is to be run and the `source` property for the **template** resource
        specifies which template to use. The `notifies` property for the **template**
        specifies that the `execute[forward_ipv4]` (which is defined by the **execute**
        resource) should be queued up and run at the end of a Chef Infra Client run.

        **Add a rule to an IP table**:

        The following example shows how to add a rule named `test_rule` to an IP table
        using the **execute** resource to run a command using a template that is defined
        by the **template** resource:

        ```ruby
        execute 'test_rule' do
          command "command_to_run
            --option value
            --option value
            --source \#{node[:name_of_node][:ipsec][:local][:subnet]}
            -j test_rule"

          action :nothing
        end

        template '/etc/file_name.local' do
          source 'routing/file_name.local.erb'
          notifies :run, 'execute[test_rule]', :delayed
        end
        ```

        where the `command` property for the **execute** resource contains the command
        that is to be run and the `source` property for the **template** resource
        specifies which template to use. The `notifies` property for the **template**
        specifies that the `execute[test_rule]` (which is defined by the **execute**
        resource) should be queued up and run at the end of a Chef Infra Client run.

        **Stop a service, do stuff, and then restart it**:

        The following example shows how to use the **execute**, **service**, and
        **mount** resources together to ensure that a node running on Amazon EC2 is
        running MySQL. This example does the following:

        - Checks to see if the Amazon EC2 node has MySQL
        - If the node has MySQL, stops MySQL
        - Installs MySQL
        - Mounts the node
        - Restarts MySQL

        ```ruby
        # the following code sample comes from the ``server_ec2``
        # recipe in the following cookbook:
        # https://github.com/chef-cookbooks/mysql

        if (node.attribute?('ec2') && !FileTest.directory?(node['mysql']['ec2_path']))
          service 'mysql' do
            action :stop
          end

          execute 'install-mysql' do
            command "mv \#{node['mysql']['data_dir']} \#{node['mysql']['ec2_path']}"
            not_if { ::File.directory?(node['mysql']['ec2_path']) }
          end

          [node['mysql']['ec2_path'], node['mysql']['data_dir']].each do |dir|
            directory dir do
              owner 'mysql'
              group 'mysql'
            end
          end

          mount node['mysql']['data_dir'] do
            device node['mysql']['ec2_path']
            fstype 'none'
            options 'bind,rw'
            action [:mount, :enable]
          end

          service 'mysql' do
            action :start
          end
        end
        ```

        where

        - the two **service** resources are used to stop, and then restart the MySQL service
        - the **execute** resource is used to install MySQL
        - the **mount** resource is used to mount the node and enable MySQL

        **Use the platform_family? method**:

        The following is an example of using the `platform_family?` method in the Recipe
        DSL to create a variable that can be used with other resources in the same
        recipe. In this example, `platform_family?` is being used to ensure that a
        specific binary is used for a specific platform before using the **remote_file**
        resource to download a file from a remote location, and then using the
        **execute** resource to install that file by running a command.

        ```ruby
        if platform_family?('rhel')
          pip_binary = '/usr/bin/pip'
        else
          pip_binary = '/usr/local/bin/pip'
        end

        remote_file "\#{Chef::Config[:file_cache_path]}/distribute_setup.py" do
          source 'http://python-distribute.org/distribute_setup.py'
          mode '0755'
          not_if { ::File.exist?(pip_binary) }
        end

        execute 'install-pip' do
          cwd Chef::Config[:file_cache_path]
          command <<~EOF
            # command for installing Python goes here
          EOF
          not_if { ::File.exist?(pip_binary) }
        end
        ```

        where a command for installing Python might look something like:

        ```ruby
        \#{node['python']['binary']} distribute_setup.py \#{::File.dirname(pip_binary)}/easy_install pip
        ```

        **Control a service using the execute resource**:

        <div class="admonition-warning">
          <p class="admonition-warning-title">Warning</p>
          <div class="admonition-warning-text">
            This is an example of something that should NOT be done. Use the **service**
            resource to control a service, not the **execute** resource.
          </div>
        </div>

        Do something like this:

        ```ruby
        service 'tomcat' do
          action :start
        end
        ```

        and NOT something like this:

        ```ruby
        execute 'start-tomcat' do
          command '/etc/init.d/tomcat start'
          action :run
        end
        ```

        There is no reason to use the **execute** resource to control a service because
        the **service** resource exposes the `start_command` property directly, which
        gives a recipe full control over the command issued in a much cleaner, more
        direct manner.

        **Use the search Infra Language helper to find users**:

        The following example shows how to use the `search` method in the Chef Infra Language to
        search for users:

        ```ruby
        #  the following code sample comes from the openvpn cookbook:

        search("users", "*:*") do |u|
          execute "generate-openvpn-\#{u['id']}" do
            command "./pkitool \#{u['id']}"
            cwd '/etc/openvpn/easy-rsa'
          end

          %w{ conf ovpn }.each do |ext|
            template "\#{node['openvpn']['key_dir']}/\#{u['id']}.\#{ext}" do
              source 'client.conf.erb'
              variables :username => u['id']
            end
          end
        end
        ```

        where

        - the search data will be used to create **execute** resources
        - the **template** resource tells Chef Infra Client which template to use

        **Enable remote login for macOS**:

        ```ruby
        execute 'enable ssh' do
          command '/usr/sbin/systemsetup -setremotelogin on'
          not_if '/usr/sbin/systemsetup -getremotelogin | /usr/bin/grep On'
          action :run
        end
        ```

        **Execute code immediately, based on the template resource**:

        By default, notifications are `:delayed`, that is they are queued up as they are
        triggered, and then executed at the very end of a Chef Infra Client run. To run
        an action immediately, use `:immediately`:

        ```ruby
        template '/etc/nagios3/configures-nagios.conf' do
          # other parameters
          notifies :run, 'execute[test-nagios-config]', :immediately
        end
        ```

        and then Chef Infra Client would immediately run the following:

        ```ruby
        execute 'test-nagios-config' do
          command 'nagios3 --verify-config'
          action :nothing
        end
        ```

        **Sourcing a file**:

        The **execute** resource cannot be used to source a file (e.g. `command 'source
        filename'`). The following example will fail because `source` is not an
        executable:

        ```ruby
        execute 'foo' do
          command 'source /tmp/foo.sh'
        end
        ```


        Instead, use the **script** resource or one of the **script**-based resources
        (**bash**, **csh**, **perl**, **python**, or **ruby**). For example:

        ```ruby
        bash 'foo' do
          code 'source /tmp/foo.sh'
        end
        ```

        **Run a Knife command**:

        ```ruby
        execute 'create_user' do
          command <<~EOM
            knife user create \#{user}
              --admin
              --password password
              --disable-editing
              --file /home/vagrant/.chef/user.pem
              --config /tmp/knife-admin.rb
            EOM
        end
        ```

        **Run install command into virtual environment**:

        The following example shows how to install a lightweight JavaScript framework
        into Vagrant:

        ```ruby
        execute "install q and zombiejs" do
          cwd "/home/vagrant"
          user "vagrant"
          environment ({'HOME' => '/home/vagrant', 'USER' => 'vagrant'})
          command "npm install -g q zombie should mocha coffee-script"
          action :run
        end
        ```

        **Run a command as a named user**:

        The following example shows how to run `bundle install` from a Chef Infra Client
        run as a specific user. This will put the gem into the path of the user
        (`vagrant`) instead of the root user (under which the Chef Infra Client runs):

        ```ruby
        execute '/opt/chefdk/embedded/bin/bundle install' do
          cwd node['chef_workstation']['bundler_path']
          user node['chef_workstation']['user']

          environment ({
            'HOME' => "/home/\#{node['chef_workstation']['user']}",
            'USER' => node['chef_workstation']['user']
          })
          not_if 'bundle check'
        end
        ```

        **Run a command as an alternate user**:

        *Note*: When Chef is running as a service, this feature requires that the user
        that Chef runs as has 'SeAssignPrimaryTokenPrivilege' (aka
        'SE_ASSIGNPRIMARYTOKEN_NAME') user right. By default only LocalSystem and
        NetworkService have this right when running as a service. This is necessary
        even if the user is an Administrator.

        This right can be added and checked in a recipe using this example (will not take effect in the same Chef run):

        ```ruby
        windows_user_privilege 'add assign token privilege' do
          principal '<user>'
          privilege 'SeAssignPrimaryTokenPrivilege'
          action :add
        end
        ```

        The following example shows how to run `mkdir test_dir` from a Chef Infra Client
        run as an alternate user.

        ```ruby
        # Passing only username and password
        execute 'mkdir test_dir' do
          cwd Chef::Config[:file_cache_path]

          user "username"
          password "password"
        end

        # Passing username and domain
        execute 'mkdir test_dir' do
          cwd Chef::Config[:file_cache_path]

          domain "domain-name"
          user "user"
          password "password"
        end

        # Passing username = 'domain-name\\username'. No domain is passed
        execute 'mkdir test_dir' do
          cwd Chef::Config[:file_cache_path]

          user "domain-name\\username"
          password "password"
        end

        # Passing username = 'username@domain-name'.  No domain is passed
        execute 'mkdir test_dir' do
          cwd Chef::Config[:file_cache_path]

          user "username@domain-name"
          password "password"
        end
        ```

        **Run a command with an external input file**:

        ```ruby
        execute 'md5sum' do
          input File.read(__FILE__)
        end
        ```


---

## file resource

[file resource page](file/)

Use the **file** resource to manage files directly on a node. Note: Use the **cookbook_file** resource to copy a file from a cookbook's `/files` directory. Use the **template** resource to create a file based on a template in a cookbook's `/templates` directory. And use the **remote_file** resource to transfer a file to a node from a remote location.


> Source: `lib/chef/resource/file.rb`

### Syntax

The full syntax for all of the properties that are available to the **file** resource is:

```ruby
file 'name' do
  path  # String
  atomic_update  # [ TrueClass, FalseClass ]  # default: lazy { docker? && special_docker_files?(path) ? false : Chef::Config[:file_atomic_update] }
  backup  # [ Integer, FalseClass ]  # default: 5
  checksum  # [ String, nil ]
  content  # [ String, nil ]
  diff  # [ String, nil ]
  force_unlink  # [ TrueClass, FalseClass ]  # default: false
  manage_symlink_source  # [ TrueClass, FalseClass ]
  verifications  # Array  # default: lazy { [] }
  action  :symbol # defaults to :create if not specified
end
```

### Actions

The **file** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` **(default)** |  |
| `:delete` |  |
| `:touch` |  |
| `:create_if_missing` |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `path` | `String` |  |  |
| `atomic_update` | `[ TrueClass, FalseClass ]` | `lazy { docker? && special_docker_files?(path) ? fa` | False if modifying /etc/hosts, /etc/hostname, or /etc/resolv.conf within Docker containers. Otherwise default to the client.rb 'file_atomic_update' co |
| `backup` | `[ Integer, FalseClass ]` | `5` |  |
| `checksum` | `[ String, nil ]` |  | The SHA-256 checksum of the file. Use to ensure that a specific file is used. If the checksum does not match, the file is not used. |
| `content` | `[ String, nil ]` |  |  |
| `diff` | `[ String, nil ]` |  |  |
| `force_unlink` | `[ TrueClass, FalseClass ]` | `false` |  |
| `manage_symlink_source` | `[ TrueClass, FalseClass ]` |  |  |
| `verifications` | `Array` | `lazy { [] }` |  |

### Agentless Mode

The **file** resource has **full** support for Agentless Mode.


---

## freebsd_package resource

[freebsd_package resource page](freebsd_package/)

Use the **freebsd_package** resource to manage packages for the FreeBSD platform.


> Source: `lib/chef/resource/freebsd_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **freebsd_package** resource is:

```ruby
freebsd_package 'name' do
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **freebsd_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:remove` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

No resource-specific properties.

### Agentless Mode

The **freebsd_package** resource has **full** support for Agentless Mode.


---

## gem_package resource

[gem_package resource page](gem_package/)

Use the **gem_package** resource to manage gem packages that are only included in recipes. When a gem is installed from a local file, it must be added to the node using the **remote_file** or **cookbook_file** resources. Note: The **gem_package** resource must be specified as `gem_package` and cannot be shortened to `package` in a recipe. Warning: The **chef_gem** and **gem_package** resources are both used to install Ruby gems. For any machine on which #{ChefUtils::Dist::Infra::PRODUCT} is installed, there are two instances of Ruby. One is the standard, system-wide instance of Ruby and the other is a dedicated instance that is available only to #{ChefUtils::Dist::Infra::PRODUCT}. Use the **chef_gem** resource to install gems into the instance of Ruby that is dedicated to #{ChefUtils::Dist::Infra::PRODUCT}. Use the **gem_package** resource to install all other gems (i.e. install gems system-wide).

**New in Chef Infra Client 13.0.** *(catalog version; not declared in local source)*

> Source: `lib/chef/resource/gem_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **gem_package** resource is:

```ruby
gem_package 'name' do
  package_name  # String
  version  # String
  source  # [ String, Array ]
  clear_sources  # [ TrueClass, FalseClass, nil ]  # default: lazy { Chef::Config[:clear_gem_sources] }
  gem_binary  # String
  include_default_source  # [ TrueClass, FalseClass, nil ]  # default: nil
  options  # [ String, Hash, Array, nil ]
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **gem_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:upgrade` |  |
| `:remove` |  |
| `:purge` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `package_name` | `String` |  | An optional property to set the package name if it differs from the resource block's name. |
| `version` | `String` |  | The version of a package to be installed or upgraded. |
| `source` | `[ String, Array ]` |  |  |
| `clear_sources` | `[ TrueClass, FalseClass, nil ]` | `lazy { Chef::Config[:clear_gem_sources] }` | Set to `true` to download a gem from the path specified by the `source` property (and not from RubyGems). |
| `gem_binary` | `String` |  | The path of a gem binary to use for the installation. By default, the same version of Ruby that is used by #{ChefUtils::Dist::Infra::PRODUCT} will be  |
| `include_default_source` | `[ TrueClass, FalseClass, nil ]` | `nil` | Set to `false` to not include `Chef::Config[:rubygems_url]` in the sources. |
| `options` | `[ String, Hash, Array, nil ]` |  |  |

### Examples

The following examples demonstrate various approaches for using the **gem_package** resource:

        The following examples demonstrate various approaches for using the **gem_package** resource in recipes:

        **Install a gem file from the local file system**

        ```ruby
        gem_package 'loofah' do
          source '/tmp/loofah-2.7.0.gem'
          action :install
        end
        ```

        **Use the `ignore_failure` common attribute**

        ```ruby
        gem_package 'syntax' do
          action :install
          ignore_failure true
        end
        ```


---

## git resource

Use the **git** resource to manage source control resources that exist in a git repository. git version 1.6.5 (or higher) is required to use all of the functionality in the git resource.


> Source: `lib/chef/resource/scm\git.rb`

### Syntax

The full syntax for all of the properties that are available to the **git** resource is:

```ruby
git 'name' do
  additional_remotes  # Hash  # default: {}
  depth  # Integer
  enable_submodules  # [TrueClass, FalseClass]  # default: false
  enable_checkout  # [TrueClass, FalseClass]  # default: true
  remote  # String  # default: "origin"
  ssh_wrapper  # String
  checkout_branch  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **git** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:sync` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `additional_remotes` | `Hash` | `{}` | A Hash of additional remotes that are added to the git repository configuration. |
| `depth` | `Integer` |  | The number of past revisions to be included in the git shallow clone. Unless specified the default behavior will do a full clone. |
| `enable_submodules` | `[TrueClass, FalseClass]` | `false` | Perform a sub-module initialization and update. |
| `enable_checkout` | `[TrueClass, FalseClass]` | `true` | Check out a repo from master. Set to `false` when using the `checkout_branch` attribute to prevent the git resource from attempting to check out `mast |
| `remote` | `String` | `"origin"` | The remote repository to use when synchronizing an existing clone. |
| `ssh_wrapper` | `String` |  | The path to the wrapper script used when running SSH with git. The `GIT_SSH` environment variable is set to this. |
| `checkout_branch` | `String` |  | Set this to use a local branch to avoid checking SHAs or tags to a detached head state. |

### Agentless Mode

The **git** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **git** resource:

      **Use the git mirror**

      ```ruby
      git '/opt/my_sources/couch' do
        repository 'git://git.apache.org/couchdb.git'
        revision 'master'
        action :sync
      end
      ```

      **Use different branches**

      To use different branches, depending on the environment of the node:

      ```ruby
      branch_name = if node.chef_environment == 'QA'
                      'staging'
                    else
                      'master'
                    end

      git '/home/user/deployment' do
         repository 'git@github.com:git_site/deployment.git'
         revision branch_name
         action :sync
         user 'user'
         group 'test'
      end
      ```

      Where the `branch_name` variable is set to staging or master, depending on the environment of the node. Once this is determined, the `branch_name` variable is used to set the revision for the repository. If the git status command is used after running the example above, it will return the branch name as `deploy`, as this is the default value. Run Chef Infra Client in debug mode to verify that the correct branches are being checked out:

      ```
      sudo chef-client -l debug
      ```

      **Install an application from git using bash**

      The following example shows how Bash can be used to install a plug-in for rbenv named ruby-build, which is located in git version source control. First, the application is synchronized, and then Bash changes its working directory to the location in which ruby-build is located, and then runs a command.

      ```ruby
      git "\#{Chef::Config[:file_cache_path]}/ruby-build" do
        repository 'git://github.com/rbenv/ruby-build.git'
        revision 'master'
        action :sync
      end

      bash 'install_ruby_build' do
        cwd "\#{Chef::Config[:file_cache_path]}/ruby-build"
        user 'rbenv'
        group 'rbenv'
        code <<-EOH
          ./install.sh
          EOH
        environment 'PREFIX' => '/usr/local'
      end
      ```

      **Notify a resource post-checkout**

      ```ruby
      git "\#{Chef::Config[:file_cache_path]}/my_app" do
        repository node['my_app']['git_repository']
        revision node['my_app']['git_revision']
        action :sync
        notifies :run, 'bash[compile_my_app]', :immediately
      end
      ```

      **Pass in environment variables**

      ```ruby
      git '/opt/my_sources/couch' do
        repository 'git://git.apache.org/couchdb.git'
        revision 'master'
        environment 'VAR' => 'whatever'
        action :sync
      end
      ```


---

## group resource

[group resource page](group/)

Use the **group** resource to manage a local group.

**New in Chef Infra Client 14.9.** *(catalog version; not declared in local source)*

> Source: `lib/chef/resource/group.rb`

### Syntax

The full syntax for all of the properties that are available to the **group** resource is:

```ruby
group 'name' do
  group_name  # String
  gid  # [ String, Integer ]
  members  # [String, Array]  # default: []
  excluded_members  # [String, Array]  # default: []
  append  # [ TrueClass, FalseClass ]  # default: false
  system  # [ TrueClass, FalseClass ]  # default: false
  non_unique  # [ TrueClass, FalseClass ]  # default: false
  comment  # String
  action  :symbol # defaults to :create if not specified
end
```

### Actions

The **group** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:modify` |  |
| `:create` **(default)** |  |
| `:remove` |  |
| `:manage` |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `group_name` | `String` |  | The name of the group. |
| `gid` | `[ String, Integer ]` |  | The identifier for the group. |
| `members` | `[String, Array]` | `[]` | Which users should be set or appended to a group. When more than one group member is identified, the list of members should be an array: `members ['us |
| `excluded_members` | `[String, Array]` | `[]` | Remove users from a group. May only be used when `append` is set to `true`. |
| `append` | `[ TrueClass, FalseClass ]` | `false` |  |
| `system` | `[ TrueClass, FalseClass ]` | `false` | Set to `true` if the group belongs to a system group. |
| `non_unique` | `[ TrueClass, FalseClass ]` | `false` | Allow gid duplication. May only be used with the `Groupadd` user resource provider. |
| `comment` | `String` |  | Specifies a comment to associate with the local group. |

### Agentless Mode

The **group** resource has **full** support for Agentless Mode.

Support was added in Chef Infra Client 14.9.

### Examples

The following examples demonstrate various approaches for using the **group** resource:

      The following examples demonstrate various approaches for using the **group** resource in recipes:

      Append users to groups:

      ```ruby
      group 'www-data' do
        action :modify
        members 'maintenance'
        append true
      end
      ```

      Add a user to group on the Windows platform:

      ```ruby
      group 'Administrators' do
        members ['domain\\foo']
        append true
        action :modify
      end
      ```


---

## habitat_config resource

[habitat_config resource page](habitat_config/)

Use the **habitat_config** resource to apply a configuration to a Chef Habitat service.

**New in Chef Infra Client 17.3.**

> Source: `lib/chef/resource/habitat_config.rb`

### Syntax

The full syntax for all of the properties that are available to the **habitat_config** resource is:

```ruby
habitat_config 'name' do
  config  # Mash
  service_group  # String
  remote_sup  # String  # default: "127.0.0.1:9632"
  remote_sup_http  # String  # default: "127.0.0.1:9631"
  gateway_auth_token  # String
  user  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **habitat_config** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:apply` | applies the given configuration |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `config` | `Mash` |  | The configuration to apply as a ruby hash, for example, `{ worker_count: 2, http: { keepalive_timeout: 120 } }`. |
| `service_group` | `String` |  | The service group to apply the configuration to. For example, `nginx.default` |
| `remote_sup` | `String` | `"127.0.0.1:9632"` | Address to a remote supervisor's control gateway. |
| `remote_sup_http` | `String` | `"127.0.0.1:9631"` | Address for remote supervisor http port. Used to pull existing. |
| `gateway_auth_token` | `String` |  | Auth token for accessing the remote supervisor's http port. |
| `user` | `String` |  | Name of user key to use for encryption. Passes `--user` to `hab config apply`. |

### Agentless Mode

The **habitat_config** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **habitat_config** resource:

      **Configure your nginx defaults**

      ```ruby
      habitat_config 'nginx.default' do
        config({
          worker_count: 2,
          http: {
            keepalive_timeout: 120
          }
          })
        end
        ```


---

## habitat_install resource

[habitat_install resource page](habitat_install/)

Use the **habitat_install** resource to install Chef Habitat.

**New in Chef Infra Client 17.3.**

> Source: `lib/chef/resource/habitat_install.rb`

### Syntax

The full syntax for all of the properties that are available to the **habitat_install** resource is:

```ruby
habitat_install 'name' do
  name  # String  # default: "install habitat"
  install_url  # String  # default: "https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.sh"
  bldr_url  # String
  create_user  # [true, false]  # default: true
  tmp_dir  # String
  license  # String
  hab_version  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **habitat_install** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` | Installs Habitat. Does nothing if the `hab` binary is found in the default location for the system (`/bin/hab` on Linux, `/usr/local/bin/hab` on macOS, `C:/habitat/hab.exe` on Windows) |
| `:extract` |  |
| `:nothing` **(default)** |  |
| `:add` |  |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `name` | `String` | `"install habitat"` | Name of the resource block. This has no impact other than logging. |
| `install_url` | `String` | `"https://raw.githubusercontent.com/habitat-sh/habi` | URL to the install script, default is from the [habitat repo](https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.sh) . |
| `bldr_url` | `String` |  | Optional URL to an alternate Habitat Builder. |
| `create_user` | `[true, false]` | `true` | Creates the `hab` system user. |
| `tmp_dir` | `String` |  | Sets TMPDIR environment variable for location to place temp files. Note: This is required if `/tmp` and `/var/tmp` are mounted `noexec`. |
| `license` | `String` |  | Specifies acceptance of habitat license when set to `accept`. |
| `hab_version` | `String` |  | Specify the version of `Habitat` you would like to install. |

### Agentless Mode

The **habitat_install** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **habitat_install** resource:

      **Installation Without a Resource Name**

      ```ruby
      habitat_install
      ```

      **Installation specifying a habitat builder URL**

      ```ruby
      habitat_install 'install habitat' do
        bldr_url 'http://localhost'
      end
      ```

      **Installation specifying version and habitat builder URL**

      ```ruby
      habitat_install 'install habitat' do
        bldr_url 'http://localhost'
        hab_version '1.5.50'
      end
      ```


---

## habitat_package resource

Use the **habitat_package** to install or remove Chef Habitat packages from Habitat Builder.

**New in Chef Infra Client 17.3.**

> Source: `lib/chef/resource/habitat\habitat_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **habitat_package** resource is:

```ruby
habitat_package 'name' do
  bldr_url  # String  # default: "https://bldr.habitat.sh"
  channel  # String  # default: "stable"
  auth_token  # String
  binlink  # [true, false, :force]  # default: false
  options  # String
  keep_latest  # String
  exclude  # String
  no_deps  # [true, false]  # default: false
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **habitat_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:remove` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `bldr_url` | `String` | `"https://bldr.habitat.sh"` | The habitat builder url where packages will be downloaded from. **Defaults to public Habitat Builder** |
| `channel` | `String` | `"stable"` | The release channel to install your package from. |
| `auth_token` | `String` |  | Auth token for installing a package from a private organization on Habitat builder. |
| `binlink` | `[true, false, :force]` | `false` | If habitat should attempt to binlink the package. Acceptable values: `true`, `false`, `:force`. Will fail on binlinking if set to `true` and binary or |
| `options` | `String` |  | Pass any additional parameters to the habitat package command. |
| `keep_latest` | `String` |  | Ability to uninstall while retaining a specified version **This feature only works in Habitat 1.5.86+.** |
| `exclude` | `String` |  | Identifier of one or more packages that should not be uninstalled. (ex: core/redis, core/busybox-static/1.42.2/21120102031201) |
| `no_deps` | `[true, false]` | `false` | Remove package but retain dependencies. |

### Agentless Mode

The **habitat_package** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **habitat_package** resource:

      **Install core/redis**

      ```ruby
      habitat_package 'core/redis'
      ```

      **Install specific version of a package from the unstable channel**

      ```ruby
      habitat_package 'core/redis' do
        version '3.2.3'
        channel 'unstable'
      end
      ```

      **Install a package with specific version and revision**

      ```ruby
      habitat_package 'core/redis' do
        version '3.2.3/20160920131015'
      end
      ```

      **Install a package and force linking it's binary files to the system path**

      ```ruby
      habitat_package 'core/nginx' do
        binlink :force
      end
      ```

      **Install a package and link it's binary files to the system path**

      ```ruby
      habitat_package 'core/nginx' do
        options '--binlink'
      end
      ```

      **Remove package and all of it's versions**

      ```ruby
      habitat_package 'core/nginx'
        action :remove
      end
      ```

      **Remove specified version of a package**

      ```ruby
      habitat_package 'core/nginx/3.2.3'
        action :remove
      end
      ```

      **Remove package but retain some versions Note: Only available as of Habitat 1.5.86**

      ```ruby
      habitat_package 'core/nginx'
        keep_latest '2'
        action :remove
      end
      ```

      ```ruby
      **Remove package but keep dependencies**
      habitat_package 'core/nginx'
        no_deps false
        action :remove
      end
      ```


---

## habitat_service resource

[habitat_service resource page](habitat_service/)

Use the **habitat_service** resource to manage Chef Habitat services. This requires that `core/hab-sup` be running as a service. See the `habitat_sup` resource documentation for more information. Note: Applications may run as a specific user. Often with Habitat, the default is `hab`, or `root`. If the application requires another user, then it should be created with Chef's `user` resource.

**New in Chef Infra Client 17.3.**

> Source: `lib/chef/resource/habitat_service.rb`

### Syntax

The full syntax for all of the properties that are available to the **habitat_service** resource is:

```ruby
habitat_service 'name' do
  service_name  # String
  loaded  # [true, false]  # default: false
  running  # [true, false]  # default: false
  strategy  # [Symbol, String]  # default: :none
  topology  # [Symbol, String]  # default: :standalone
  bldr_url  # String  # default: "https://bldr.habitat.sh/"
  channel  # [Symbol, String]  # default: :stable
  bind  # [String, Array]  # default: []
  binding_mode  # [Symbol, String]  # default: :strict
  service_group  # String  # default: "default"
  shutdown_timeout  # Integer  # default: 8
  health_check_interval  # Integer  # default: 30
  remote_sup  # String  # default: "127.0.0.1:9632"
  remote_sup_http  # String  # default: "127.0.0.1:9631"
  gateway_auth_token  # String
  update_condition  # [Symbol, String]  # default: :latest
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **habitat_service** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:unload` |  |
| `:load` | (default action) runs `hab service load` to load and start the specified application service |
| `:start` | runs `hab service start` to start the specified application service |
| `:stop` | runs `hab service stop` to stop the specified application service |
| `:restart` | runs the `:stop` and then `:start` actions |
| `:reload` | runs the `:unload` and then `:load` actions |
| `:nothing` **(default)** |  |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `service_name` | `String` |  | The name of the service, must be in the form of `origin/name` |
| `loaded` | `[true, false]` | `false` | state property indicating whether the service is loaded in the supervisor |
| `running` | `[true, false]` | `false` | state property indicating whether the service is running in the supervisor |
| `strategy` | `[Symbol, String]` | `:none` | Passes `--strategy` with the specified update strategy to the hab command. Defaults to `:none`. Other options are `:'at-once'` and `:rolling` |
| `topology` | `[Symbol, String]` | `:standalone` | Passes `--topology` with the specified service topology to the hab command |
| `bldr_url` | `String` | `"https://bldr.habitat.sh/"` |  |
| `channel` | `[Symbol, String]` | `:stable` | Passes `--channel` with the specified channel to the hab command |
| `bind` | `[String, Array]` | `[]` | Passes `--bind` with the specified services to bind to the hab command. If an array of multiple service binds are specified then a `--bind` flag is ad |
| `binding_mode` | `[Symbol, String]` | `:strict` | Passes `--binding-mode` with the specified binding mode. Defaults to `:strict`. Options are `:strict` or `:relaxed` |
| `service_group` | `String` | `"default"` |  Passes `--group` with the specified service group to the hab command |
| `shutdown_timeout` | `Integer` | `8` | The timeout in seconds allowed during shutdown. |
| `health_check_interval` | `Integer` | `30` | The interval (seconds) on which to run health checks. |
| `remote_sup` | `String` | `"127.0.0.1:9632"` | Address to a remote Supervisor's Control Gateway |
| `remote_sup_http` | `String` | `"127.0.0.1:9631"` | IP address and port used to communicate with the remote supervisor. If this value is invalid, the resource will update the supervisor configuration ea |
| `gateway_auth_token` | `String` |  | Auth token for accessing the remote supervisor's http port. |
| `update_condition` | `[Symbol, String]` | `:latest` |  |

### Agentless Mode

The **habitat_service** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **habitat_service** resource:

        **Install and load nginx**

        ```ruby
        habitat_package 'core/nginx'
        habitat_service 'core/nginx'

        habitat_service 'core/nginx unload' do
          service_name 'core/nginx'
          action :unload
        end
        ```

        **Pass the `strategy` and `topology` options to hab service commands**

        ```ruby
        habitat_service 'core/redis' do
          strategy 'rolling'
          topology 'standalone'
        end
        ```

        **Using update_condition**

        ```ruby
        habitat_service 'core/redis' do
          strategy 'rolling'
          update_condition 'track-channel'
          topology 'standalone'
        end
        ```

        **If the service has it's own user specified that is not the `hab` user, don't create the `hab` user on install, and instead create the application user with Chef's `user` resource**

        ```ruby
        habitat_install 'install habitat' do
          create_user false
        end

        user 'acme-apps' do
          system true
        end

        habitat_service 'acme/apps'
        ```


---

## habitat_sup resource

Use the **habitat_sup** resource to runs a Chef Habitat supervisor for one or more Chef Habitat services. The resource is commonly used in conjunction with `habitat_service` which will manage the services loaded and started within the supervisor.

**New in Chef Infra Client 17.3.**

> Source: `lib/chef/resource/habitat\habitat_sup.rb`

### Syntax

The full syntax for all of the properties that are available to the **habitat_sup** resource is:

```ruby
habitat_sup 'name' do
  bldr_url  # String
  permanent_peer  # [true, false]  # default: false
  listen_ctl  # String
  listen_gossip  # String
  listen_http  # String
  org  # String  # default: "default"
  peer  # [String, Array]
  ring  # String
  hab_channel  # String
  auto_update  # [true, false]  # default: false
  auth_token  # String
  gateway_auth_token  # String
  update_condition  # String
  limit_no_files  # String
  license  # String
  health_check_interval  # [String, Integer]
  event_stream_application  # String
  event_stream_environment  # String
  event_stream_site  # String
  event_stream_url  # String
  event_stream_token  # String
  event_stream_cert  # String
  sup_version  # String
  launcher_version  # String
  service_version  # String
  keep_latest  # String
  toml_config  # [true, false]  # default: false
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **habitat_sup** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:run` | The `run` action handles installing Habitat using the `habitat_install` resource, ensures that the appropriate versions of the `core/hab-sup` and `core/hab-launcher` packages are installed using `habitat_package`, and then drops off the appropriate init system definitions and manages the service. |
| `:create` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `bldr_url` | `String` |  | The Habitat Builder URL for the `habitat_package` resource, if needed. |
| `permanent_peer` | `[true, false]` | `false` | Only valid for `:run` action, passes `--permanent-peer` to the hab command. |
| `listen_ctl` | `String` |  | Only valid for `:run` action, passes `--listen-ctl` with the specified address and port, e.g., `0.0.0.0:9632`, to the hab command. |
| `listen_gossip` | `String` |  | Only valid for `:run` action, passes `--listen-gossip` with the specified address and port, e.g., `0.0.0.0:9638`, to the hab command. |
| `listen_http` | `String` |  | Only valid for `:run` action, passes `--listen-http` with the specified address and port, e.g., `0.0.0.0:9631`, to the hab command. |
| `org` | `String` | `"default"` | Only valid for `:run` action, passes `--org` with the specified org name to the hab command. |
| `peer` | `[String, Array]` |  | Only valid for `:run` action, passes `--peer` with the specified initial peer to the hab command. |
| `ring` | `String` |  | Only valid for `:run` action, passes `--ring` with the specified ring key name to the hab command. |
| `hab_channel` | `String` |  | The channel to install Habitat from. Defaults to stable |
| `auto_update` | `[true, false]` | `false` | Passes `--auto-update`. This will set the Habitat supervisor to automatically update itself any time a stable version has been released. |
| `auth_token` | `String` |  | Auth token for accessing a private organization on bldr. This value is templated into the appropriate service file. |
| `gateway_auth_token` | `String` |  | Auth token for accessing the supervisor's HTTP gateway. This value is templated into the appropriate service file. |
| `update_condition` | `String` |  |  |
| `limit_no_files` | `String` |  | allows you to set LimitNOFILE in the systemd service when used Note: Linux Only. |
| `license` | `String` |  | Specifies acceptance of habitat license when set to `accept`. |
| `health_check_interval` | `[String, Integer]` |  | The interval (seconds) on which to run health checks. |
| `event_stream_application` | `String` |  | The name of your application that will be displayed in the Chef Automate Applications Dashboard. |
| `event_stream_environment` | `String` |  | The application environment for the supervisor, this is for grouping in the Applications Dashboard. |
| `event_stream_site` | `String` |  | Application Dashboard label for the 'site' of the application - can be filtered in the dashboard. |
| `event_stream_url` | `String` |  | `AUTOMATE_HOSTNAME:4222` - the Chef Automate URL with port 4222 specified Note: The port can be changed if needed. |
| `event_stream_token` | `String` |  | Chef Automate token for sending application event stream data. |
| `event_stream_cert` | `String` |  |  |
| `sup_version` | `String` |  | Allows you to choose which version of supervisor you would like to install. Note: If a version is provided, it will also install that version of habit |
| `launcher_version` | `String` |  | Allows you to choose which version of launcher to install. |
| `service_version` | `String` |  | Allows you to choose which version of the **_Windows Service_** to install. |
| `keep_latest` | `String` |  |  |
| `toml_config` | `[true, false]` | `false` | Supports using the Supervisor toml configuration instead of passing exec parameters to the service, [reference](https://www.habitat.sh/docs/reference/ |

### Agentless Mode

The **habitat_sup** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **habitat_sup** resource:

      **Set up with just the defaults**

      ```ruby
      habitat_sup 'default'
      ```

      **Update listen ports and use Supervisor toml config**

      ```ruby
      habitat_sup 'test-options' do
        listen_http '0.0.0.0:9999'
        listen_gossip '0.0.0.0:9998'
        toml_config true
      end
      ```

      **Use with an on-prem Habitat Builder. Note: Access to public builder may not be available due to your company policies**

      ```ruby
      habitat_sup 'default' do
        bldr_url 'https://bldr.example.com'
      end
      ```

      **Using update_condition**

      ```ruby
      habitat_sup 'default' do
        bldr_url 'https://bldr.example.com'
        habitat_channel 'dev'
        update_condition 'track-channel'
      end
      ```

      **Provide event stream information**

      ```ruby
      habitat_sup 'default' do
        license 'accept'
        event_stream_application 'myapp'
        event_stream_environment 'production'
        event_stream_site 'MySite'
        event_stream_url 'automate.example.com:4222'
        event_stream_token 'myawesomea2clitoken='
        event_stream_cert '/hab/cache/ssl/mycert.crt'
      end
      ```

      **Provide specific versions**

      ```ruby
      habitat_sup 'default' do
        bldr_url 'https://bldr.example.com'
        sup_version '1.5.50'
        launcher_version '13458'
        service_version '0.6.0' # WINDOWS ONLY
      end
      ```

      **Set latest version of packages to retain**

      habitat_sup 'default' do
        bldr_url 'https://bldr.example.com'
        sup_version '1.5.86'
        launcher_version '13458'
        service_version '0.6.0' # WINDOWS ONLY
        keep_latest '2'
      end
      ```


---

## habitat_user_toml resource

[habitat_user_toml resource page](habitat_user_toml/)

Use the **habitat_user_toml** to template a `user.toml` for Chef Habitat services. Configurations set in the  `user.toml` override the `default.toml` for a given package, which makes it an alternative to applying service group level configuration.

**New in Chef Infra Client 17.3.**

> Source: `lib/chef/resource/habitat_user_toml.rb`

### Syntax

The full syntax for all of the properties that are available to the **habitat_user_toml** resource is:

```ruby
habitat_user_toml 'name' do
  config  # Mash
  service_name  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **habitat_user_toml** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` | (default action) Create the user.toml from the specified config. |
| `:delete` | Delete the user.toml |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `config` | `Mash` |  | Only valid for `:create` action. The configuration to apply as a ruby hash, for example, `{ worker_count: 2, http: { keepalive_timeout: 120 } }`. |
| `service_name` | `String` |  | The service group to apply the configuration to, for example, `nginx.default`. |

### Examples

The following examples demonstrate various approaches for using the **habitat_user_toml** resource:

      **Configure user specific settings to nginx**

      ```ruby
      habitat_user_toml 'nginx' do
        config({
          worker_count: 2,
          http: {
            keepalive_timeout: 120
          }
          })
        end
        ```


---

## homebrew_cask resource

[homebrew_cask resource page](homebrew_cask/)

Use the **homebrew_cask** resource to install binaries distributed via the Homebrew package manager.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/homebrew_cask.rb`

### Syntax

The full syntax for all of the properties that are available to the **homebrew_cask** resource is:

```ruby
homebrew_cask 'name' do
  cask_name  # String
  options  # String
  homebrew_path  # String
  owner  # [String, Integer]  # default: lazy { find_homebrew_username }
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **homebrew_cask** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` | Install an application that is packaged as a Homebrew cask. |
| `:remove` | Remove an application that is packaged as a Homebrew cask. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `cask_name` | `String` |  | An optional property to set the cask name if it differs from the resource block's name. |
| `options` | `String` |  | Options to pass to the brew command during installation. |
| `homebrew_path` | `String` |  | The path to the Homebrew binary. |
| `owner` | `[String, Integer]` | `lazy { find_homebrew_username }` | The owner of the Homebrew installation. |


---

## homebrew_package resource

[homebrew_package resource page](homebrew_package/)

Use the **homebrew_package** resource to manage packages for the macOS platform. Note: Starting with #{ChefUtils::Dist::Infra::PRODUCT} 16 the homebrew resource now accepts an array of packages for installing multiple packages at once.

**New in Chef Infra Client 12.0.**

> Source: `lib/chef/resource/homebrew_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **homebrew_package** resource is:

```ruby
homebrew_package 'name' do
  homebrew_user  # [ String, Integer ]
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **homebrew_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:upgrade` |  |
| `:remove` |  |
| `:purge` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `homebrew_user` | `[ String, Integer ]` |  |  |

### Examples

The following examples demonstrate various approaches for using the **homebrew_package** resource:

      **Install a package**:

      ```ruby
      homebrew_package 'git'
      ```

      **Install multiple packages at once**:

      ```ruby
      homebrew_package %w(git fish ruby)
      ```

      **Specify the Homebrew user with a UUID**

      ```ruby
      homebrew_package 'git' do
        homebrew_user 1001
      end
      ```

      **Specify the Homebrew user with a string**:

      ```ruby
      homebrew_package 'vim' do
        homebrew_user 'user1'
      end
      ```


---

## homebrew_tap resource

[homebrew_tap resource page](homebrew_tap/)

Use the **homebrew_tap** resource to add additional formula repositories to the Homebrew package manager.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/homebrew_tap.rb`

### Syntax

The full syntax for all of the properties that are available to the **homebrew_tap** resource is:

```ruby
homebrew_tap 'name' do
  tap_name  # String
  url  # String
  homebrew_path  # String
  owner  # String  # default: lazy { find_homebrew_username }
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **homebrew_tap** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:tap` | Add a Homebrew tap. |
| `:untap` | Remove a Homebrew tap. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `tap_name` | `String` |  | An optional property to set the tap name if it differs from the resource block's name. |
| `url` | `String` |  | The URL of the tap. |
| `homebrew_path` | `String` |  | The path to the Homebrew binary. |
| `owner` | `String` | `lazy { find_homebrew_username }` | The owner of the Homebrew installation. |

### Examples

The following examples demonstrate various approaches for using the **homebrew_tap** resource:

      **Tap a repository**:

      ```ruby
      homebrew_tap 'apple/homebrew-apple'
      ```


---

## homebrew_update resource

[homebrew_update resource page](homebrew_update/)

Use the **homebrew_update** resource to manage Homebrew repository updates on macOS.

**New in Chef Infra Client 16.2.**

> Source: `lib/chef/resource/homebrew_update.rb`

### Syntax

The full syntax for all of the properties that are available to the **homebrew_update** resource is:

```ruby
homebrew_update 'name' do
  name  # String  # default: ""
  frequency  # Integer  # default: 86_400  default_action :periodic
  action  :symbol # defaults to :periodic if not specified
end
```

### Actions

The **homebrew_update** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:periodic` **(default)** |  |
| `:update` |  |
| `:create_if_missing` |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `name` | `String` | `""` |  |
| `frequency` | `Integer` | `86_400  default_action :periodic` | Determines how frequently (in seconds) Homebrew updates are made. Use this property when the `:periodic` action is specified. |

### Examples

The following examples demonstrate various approaches for using the **homebrew_update** resource:

        **Update the homebrew repository data at a specified interval**:
        ```ruby
        homebrew_update 'all platforms' do
          frequency 86400
          action :periodic
        end
        ```
        **Update the Homebrew repository at the start of a #{ChefUtils::Dist::Infra::PRODUCT} run**:
        ```ruby
        homebrew_update 'update'
        ```


---

## hostname resource

[hostname resource page](hostname/)

Use the **hostname** resource to set the system's hostname, configure hostname and hosts config file, and re-run the Ohai hostname plugin so the hostname will be available in subsequent cookbooks.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/hostname.rb`

### Syntax

The full syntax for all of the properties that are available to the **hostname** resource is:

```ruby
hostname 'name' do
  hostname  # String
  fqdn  # String
  ipaddress  # String  # default: lazy { node["ipaddress"] }
  aliases  # [ Array, nil ]  # default: nil  # override compile_time property to be true by default
  compile_time  # [ TrueClass, FalseClass ]  # default: true
  windows_reboot  # [ TrueClass, FalseClass ]  # default: true
  domain_user  # String
  domain_password  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **hostname** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:set` | Sets the node's hostname. |
| `:nothing` **(default)** |  |
| `:request_reboot` |  |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `hostname` | `String` |  | An optional property to set the hostname if it differs from the resource block's name. |
| `fqdn` | `String` |  | An optional property to set the fqdn if it differs from the resource block's hostname. |
| `ipaddress` | `String` | `lazy { node["ipaddress"] }` | The IP address to use when configuring the hosts file. |
| `aliases` | `[ Array, nil ]` | `nil  # override compile_time property to be true b` | An array of hostname aliases to use when configuring the hosts file. |
| `compile_time` | `[ TrueClass, FalseClass ]` | `true` | Determines whether or not the resource should be run at compile time. |
| `windows_reboot` | `[ TrueClass, FalseClass ]` | `true` | Determines whether or not Windows should be reboot after changing the hostname, as this is required for the change to take effect. |
| `domain_user` | `String` |  | A domain account specified in the form of DOMAIN\\user used when renaming a domain-joined device |
| `domain_password` | `String` |  | The password to accompany the domain_user parameter |

### Agentless Mode

The **hostname** resource has **full** support for Agentless Mode.

Support was added in Chef Infra Client 17.0.

### Examples

The following examples demonstrate various approaches for using the **hostname** resource:

        **Set the hostname using the IP address, as detected by Ohai**:

        ```ruby
        hostname 'example'
        ```

        **Manually specify the hostname and IP address**:

        ```ruby
        hostname 'statically_configured_host' do
          hostname 'example'
          ipaddress '198.51.100.2'
        end
        ```

        **Change the hostname of a Windows, Non-Domain joined node**:

        ```ruby
        hostname 'renaming a workgroup computer' do
          hostname 'Foo'
        end
        ```

        **Change the hostname of a Windows, Domain-joined node (new in 17.2)**:

        ```ruby
        hostname 'renaming a domain-joined computer' do
          hostname 'Foo'
          domain_user "Domain\\Someone"
          domain_password 'SomePassword'
        end
        ```


---

## http_request resource

[http_request resource page](http_request/)

Use the **http_request** resource to send an HTTP request (`GET`, `PUT`, `POST`, `DELETE`, `HEAD`, or `OPTIONS`) with an arbitrary message. This resource is often useful when custom callbacks are necessary.


> Source: `lib/chef/resource/http_request.rb`

### Syntax

The full syntax for all of the properties that are available to the **http_request** resource is:

```ruby
http_request 'name' do
  url  # String
  headers  # Hash  # default: {}
  action  :symbol # defaults to :get if not specified
end
```

### Actions

The **http_request** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:get` **(default)** |  |
| `:patch` |  |
| `:put` |  |
| `:post` |  |
| `:delete` |  |
| `:head` |  |
| `:options` |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `url` | `String` |  | The URL to which an HTTP request is sent. |
| `headers` | `Hash` | `{}` | A Hash of custom headers. |

### Agentless Mode

The **http_request** resource has **full** support for Agentless Mode.


---

## ifconfig resource

[ifconfig resource page](ifconfig/)

Use the **ifconfig** resource to manage interfaces on Unix and Linux systems. Note: This resource requires the ifconfig binary to be present on the system and may require additional packages to be installed first. On Ubuntu 18.04 or later you will need to install the `ifupdown` package, which disables the built in Netplan functionality. Warning: This resource will not work with Fedora release 33 or later.

**New in Chef Infra Client 14.0.** *(catalog version; not declared in local source)*

> Source: `lib/chef/resource/ifconfig.rb`

### Syntax

The full syntax for all of the properties that are available to the **ifconfig** resource is:

```ruby
ifconfig 'name' do
  target  # String
  hwaddr  # String
  mask  # String
  family  # String  # default: "inet"
  inet_addr  # String
  bcast  # String
  mtu  # String
  metric  # String
  device  # String
  onboot  # String
  network  # String
  bootproto  # String
  onparent  # String
  ethtool_opts  # String
  bonding_opts  # String
  master  # String
  slave  # String
  vlan  # String
  gateway  # String
  bridge  # String
  action  :symbol # defaults to :add if not specified
end
```

### Actions

The **ifconfig** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:add` **(default)** |  |
| `:delete` |  |
| `:enable` |  |
| `:disable` |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `target` | `String` |  | The IP address that is to be assigned to the network interface. If not specified we'll use the resource's name. |
| `hwaddr` | `String` |  | The hardware address for the network interface. |
| `mask` | `String` |  | The decimal representation of the network mask. For example: `255.255.255.0`. |
| `family` | `String` | `"inet"` | Networking family option for Debian-based systems; for example: `inet` or `inet6`. |
| `inet_addr` | `String` |  | The Internet host address for the network interface. |
| `bcast` | `String` |  | The broadcast address for a network interface. On some platforms this property is not set using ifconfig, but instead is added to the startup configur |
| `mtu` | `String` |  | The maximum transmission unit (MTU) for the network interface. |
| `metric` | `String` |  | The routing metric for the interface. |
| `device` | `String` |  | The network interface to be configured. |
| `onboot` | `String` |  | Bring up the network interface on boot. |
| `network` | `String` |  | The address for the network interface. |
| `bootproto` | `String` |  | The boot protocol used by a network interface. |
| `onparent` | `String` |  | Bring up the network interface when its parent interface is brought up. |
| `ethtool_opts` | `String` |  | Options to be passed to ethtool(8). For example: `-A eth0 autoneg off rx off tx off`. |
| `bonding_opts` | `String` |  | Bonding options to pass via `BONDING_OPTS` on RHEL and CentOS. For example: `mode=active-backup miimon=100`. |
| `master` | `String` |  | Specifies the channel bonding interface to which the Ethernet interface is linked. |
| `slave` | `String` |  | When set to `yes`, this device is controlled by the channel bonding interface that is specified via the `master` property. |
| `vlan` | `String` |  | The VLAN to assign the interface to. |
| `gateway` | `String` |  | The gateway to use for the interface. |
| `bridge` | `String` |  | The bridge interface this interface is a member of on Red Hat based systems. |

### Agentless Mode

The **ifconfig** resource has **full** support for Agentless Mode.

Support was added in Chef Infra Client 14.0.

### Examples

The following examples demonstrate various approaches for using the **ifconfig** resource:

      **Configure a network interface with a static IP**

      ```ruby
      ifconfig '33.33.33.80' do
        device 'eth1'
      end
      ```

      will create the following interface configuration:

      ```
      iface eth1 inet static
        address 33.33.33.80
      ```

      **Configure an interface to use DHCP**

      ```ruby
      ifconfig 'Set eth1 to DHCP' do
        device 'eth1'
        bootproto 'dhcp'
      end
      ```

      will create the following interface configuration:

      ```
      iface eth1 inet dhcp
      ```

      **Update a static IP address with a boot protocol**

      ```ruby
      ifconfig "33.33.33.80" do
        bootproto "dhcp"
        device "eth1"
      end
      ```

      will update the interface configuration from static to dhcp:

      ```
      iface eth1 inet dhcp
        address 33.33.33.80
      ```


---

## inspec_input resource

[inspec_input resource page](inspec_input/)

Use the **inspec_input** resource to add an input to the Compliance Phase.

**New in Chef Infra Client 17.5.**

> Source: `lib/chef/resource/inspec_input.rb`

### Syntax

The full syntax for all of the properties that are available to the **inspec_input** resource is:

```ruby
inspec_input 'name' do
  name  # [ Hash, String ]
  input  # [ Hash, String ]
  source  # [ Hash, String ]
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **inspec_input** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:add` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `name` | `[ Hash, String ]` |  |  |
| `input` | `[ Hash, String ]` |  |  |
| `source` | `[ Hash, String ]` |  |  |

### Agentless Mode

The **inspec_input** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **inspec_input** resource:


      **Activate the default input in the openssh cookbook's compliance segment**:

      ```ruby
        inspec_input 'openssh' do
          action :add
        end
      ```

      **Activate all inputs in the openssh cookbook's compliance segment**:

      ```ruby
        inspec_input 'openssh::.*' do
          action :add
        end
      ```

      **Add an InSpec input to the Compliance Phase from a hash**:

      ```ruby
        inspec_input { ssh_custom_path: '/whatever2' }
      ```

      **Add an InSpec input to the Compliance Phase using the 'name' property to identify the input**:

      ```ruby
        inspec_input "setting my input" do
          source( { ssh_custom_path: '/whatever2' })
        end
      ```

      **Add an InSpec input to the Compliance Phase using a TOML, JSON, or YAML file**:

      ```ruby
        inspec_input "/path/to/my/input.yml"
      ```

      **Add an InSpec input to the Compliance Phase using a TOML, JSON, or YAML file, using the 'name' property**:

      ```ruby
        inspec_input "setting my input" do
          source "/path/to/my/input.yml"
        end
      ```

      Note that the **inspec_input** resource does not update and will not fire notifications (similar to the log resource). This is done to preserve the ability to use
      the resource while not causing the updated resource count to be larger than zero. Since the resource does not update the state of the managed node, this behavior
      is still consistent with the configuration management model. Instead, you should use events to observe configuration changes for the compliance phase. It is
      possible to use the `notify_group` resource to chain notifications of the two resources, but notifications are the wrong model to use, and you should use pure ruby
      conditionals instead. Compliance configuration should be independent of other resources and should only be conditional based on state/attributes, not other resources.


---

## inspec_waiver resource

[inspec_waiver resource page](inspec_waiver/)

Use the **inspec_waiver** resource to add a waiver to the Compliance Phase.

**New in Chef Infra Client 17.5.**

> Source: `lib/chef/resource/inspec_waiver.rb`

### Syntax

The full syntax for all of the properties that are available to the **inspec_waiver** resource is:

```ruby
inspec_waiver 'name' do
  control  # String
  expiration  # String
  run_test  # [true, false]
  justification  # String
  source  # [ Hash, String ]
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **inspec_waiver** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:add` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `control` | `String` |  | The name of the control being waived |
| `expiration` | `String` |  | The expiration date of the waiver - provided in YYYY-MM-DD format |
| `run_test` | `[true, false]` |  | If present and true, the control will run and be reported, but failures in it won’t make the overall run fail. If absent or false, the control will no |
| `justification` | `String` |  | Can be any text you want and might include a reason for the waiver as well as who signed off on the waiver. |
| `source` | `[ Hash, String ]` |  |  |

### Agentless Mode

The **inspec_waiver** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **inspec_waiver** resource:

      **Activate the default waiver in the openssh cookbook's compliance segment**:

      ```ruby
        inspec_waiver 'openssh' do
          action :add
        end
      ```

      **Activate all waivers in the openssh cookbook's compliance segment**:

      ```ruby
        inspec_waiver 'openssh::.*' do
          action :add
        end
      ```

      **Add an InSpec waiver to the Compliance Phase**:

      ```ruby
        inspec_waiver 'Add waiver entry for control' do
          control 'my_inspec_control_01'
          run_test false
          justification "The subject of this control is not managed by #{ChefUtils::Dist::Infra::PRODUCT} on the systems in policy group \#{node['policy_group']}"
          expiration '2022-01-01'
          action :add
        end
      ```

      **Add an InSpec waiver to the Compliance Phase using the 'name' property to identify the control**:

      ```ruby
        inspec_waiver 'my_inspec_control_01' do
          justification "The subject of this control is not managed by #{ChefUtils::Dist::Infra::PRODUCT} on the systems in policy group \#{node['policy_group']}"
          action :add
        end
      ```

      **Add an InSpec waiver to the Compliance Phase using an arbitrary YAML, JSON, or TOML file**:

      ```ruby
        # files ending in .yml or .yaml that exist are parsed as YAML
        inspec_waiver "/path/to/my/waiver.yml"

        inspec_waiver "my-waiver-name" do
          source "/path/to/my/waiver.yml"
        end

        # files ending in .json that exist are parsed as JSON
        inspec_waiver "/path/to/my/waiver.json"

        inspec_waiver "my-waiver-name" do
          source "/path/to/my/waiver.json"
        end

        # files ending in .toml that exist are parsed as TOML
        inspec_waiver "/path/to/my/waiver.toml"

        inspec_waiver "my-waiver-name" do
          source "/path/to/my/waiver.toml"
        end
      ```

      **Add an InSpec waiver to the Compliance Phase using a hash**:

      ```ruby
        my_hash = { "ssh-01" => {
          "expiration_date" => "2033-07-31",
          "run" => false,
          "justification" => "because"
        } }

        inspec_waiver "my-waiver-name" do
          source my_hash
        end
      ```

      Note that the **inspec_waiver** resource does not update and will not fire notifications (similar to the log resource). This is done to preserve the ability to use
      the resource while not causing the updated resource count to be larger than zero. Since the resource does not update the state of the managed node, this behavior
      is still consistent with the configuration management model. Instead, you should use events to observe configuration changes for the compliance phase. It is
      possible to use the `notify_group` resource to chain notifications of the two resources, but notifications are the wrong model to use, and you should use pure ruby
      conditionals instead. Compliance configuration should be independent of other resources and should only be conditional based on state/attributes, not other resources.


---

## inspec_waiver_file_entry resource

[inspec_waiver_file_entry resource page](inspec_waiver_file_entry/)

Use the **inspec_waiver_file_entry** resource to add or remove entries from an InSpec waiver file. This can be used in conjunction with the Compliance Phase.

**New in Chef Infra Client 17.1.**

> Source: `lib/chef/resource/inspec_waiver_file_entry.rb`

### Syntax

The full syntax for all of the properties that are available to the **inspec_waiver_file_entry** resource is:

```ruby
inspec_waiver_file_entry 'name' do
  control  # String
  file_path  # String  # default: "#{ChefConfig::Config.etc_chef_dir}/inspec_waivers.yml"
  expiration  # String
  run_test  # [true, false]
  justification  # String
  backup  # [false, Integer]  # default: false
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **inspec_waiver_file_entry** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:add` |  |
| `:remove` |  |
| `:create` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `control` | `String` |  | The name of the control being added or removed to the waiver file |
| `file_path` | `String` | `"#{ChefConfig::Config.etc_chef_dir}/inspec_waivers` | The path to the waiver file being modified |
| `expiration` | `String` |  | The expiration date of the given waiver - provided in YYYY-MM-DD format |
| `run_test` | `[true, false]` |  | If present and `true`, the control will run and be reported, but failures in it won’t make the overall run fail. If absent or `false`, the control wil |
| `justification` | `String` |  | Can be any text you want and might include a reason for the waiver as well as who signed off on the waiver. |
| `backup` | `[false, Integer]` | `false` |  |

### Agentless Mode

The **inspec_waiver_file_entry** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **inspec_waiver_file_entry** resource:

      **Add an InSpec waiver entry to a given waiver file**:

      ```ruby
        inspec_waiver_file_entry 'Add waiver entry for control' do
          file_path 'C:\\chef\\inspec_waiver_file.yml'
          control 'my_inspec_control_01'
          run_test false
          justification "The subject of this control is not managed by #{ChefUtils::Dist::Infra::PRODUCT} on the systems in policy group \#{node['policy_group']}"
          expiration '2022-01-01'
          action :add
        end
      ```

      **Add an InSpec waiver entry to a given waiver file using the 'name' property to identify the control**:

      ```ruby
        inspec_waiver_file_entry 'my_inspec_control_01' do
          justification "The subject of this control is not managed by #{ChefUtils::Dist::Infra::PRODUCT} on the systems in policy group \#{node['policy_group']}"
          action :add
        end
      ```

      **Remove an InSpec waiver entry to a given waiver file**:

      ```ruby
        inspec_waiver_file_entry "my_inspec_control_01" do
          action :remove
        end
      ```


---

## ips_package resource

[ips_package resource page](ips_package/)

Use the **ips_package** resource to manage packages (using Image Packaging System (IPS)) on the Solaris 11 platform.


> Source: `lib/chef/resource/ips_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **ips_package** resource is:

```ruby
ips_package 'name' do
  package_name  # String
  version  # String
  accept_license  # [TrueClass, FalseClass]  # default: false
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **ips_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:remove` |  |
| `:upgrade` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `package_name` | `String` |  | An optional property to set the package name if it differs from the resource block's name. |
| `version` | `String` |  | The version of a package to be installed or upgraded. |
| `accept_license` | `[TrueClass, FalseClass]` | `false` | Accept an end-user license agreement, automatically. |

### Agentless Mode

The **ips_package** resource has **full** support for Agentless Mode.


---

## kernel_module resource

[kernel_module resource page](kernel_module/)

Use the **kernel_module** resource to manage kernel modules on Linux systems. This resource can load, unload, blacklist, disable, enable, install, and uninstall modules.

**New in Chef Infra Client 14.3.**

> Source: `lib/chef/resource/kernel_module.rb`

### Syntax

The full syntax for all of the properties that are available to the **kernel_module** resource is:

```ruby
kernel_module 'name' do
  modname  # String
  options  # Array
  load_dir  # String  # default: "/etc/modules-load.d"
  unload_dir  # String  # default: "/etc/modprobe.d"
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **kernel_module** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:load` |  |
| `:uninstall` |  |
| `:unload` |  |
| `:blacklist` |  |
| `:disable` |  |
| `:enable` |  |
| `:install` | Load kernel module, and ensure it loads on reboot. |
| `:nothing` **(default)** |  |
| `:delete` |  |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `modname` | `String` |  | An optional property to set the kernel module name if it differs from the resource block's name. |
| `options` | `Array` |  | An optional property to set options for the kernel module. |
| `load_dir` | `String` | `"/etc/modules-load.d"` | The directory to load modules from. |
| `unload_dir` | `String` | `"/etc/modprobe.d"` | The modprobe.d directory. |

### Agentless Mode

The **kernel_module** resource has **full** support for Agentless Mode.

Support was added in Chef Infra Client 15.4.

### Examples

The following examples demonstrate various approaches for using the **kernel_module** resource:

        Install and load a kernel module, and ensure it loads on reboot.

        ```ruby
        kernel_module 'loop'
        ```

        Install and load a kernel with a specific set of options, and ensure it loads on reboot. Consult kernel module
        documentation for specific options that are supported.

        ```ruby
        kernel_module 'loop' do
          options [
            'max_loop=4',
            'max_part=8',
          ]
        end
        ```

        Load a kernel module.

        ```ruby
        kernel_module 'loop' do
          action :load
        end
        ```

        Unload a kernel module and remove module config, so it doesn't load on reboot.

        ```ruby
        kernel_module 'loop' do
          action :uninstall
        end
        ```

        Unload kernel module.

        ```ruby
        kernel_module 'loop' do
          action :unload
        end
        ```

        Blacklist a module from loading.

        ```ruby
        kernel_module 'loop' do
          action :blacklist
        end
        ```

        Disable a kernel module so that it is not installable.

        ```ruby
        kernel_module 'loop' do
          action :disable
        end
        ```

        Enable a kernel module so that it is can be installed.  Does not load or install.

        ```ruby
        kernel_module 'loop' do
          action :enable
        end
        ```


---

## ksh resource

[ksh resource page](ksh/)

Use the **ksh** resource to execute scripts using the Korn shell (ksh)" \

**New in Chef Infra Client 12.6.**

> Source: `lib/chef/resource/ksh.rb`

### Syntax

The full syntax for all of the properties that are available to the **ksh** resource is:

```ruby
ksh 'name' do
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **ksh** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

No resource-specific properties.

> This resource inherits all properties from the `execute` resource via the `script` base class, including:
> `code` (required), `cwd`, `environment`, `flags`, `group`, `input`, `interpreter`,
> `live_stream`, `login`, `password`, `returns`, `timeout`, `user`, `domain`, `elevated`.

### Agentless Mode

The **ksh** resource has **full** support for Agentless Mode.


---

## launchd resource

[launchd resource page](launchd/)

Use the **launchd** resource to manage system-wide services (daemons) and per-user services (agents) on the macOS platform.

**New in Chef Infra Client 12.8.**

> Source: `lib/chef/resource/launchd.rb`

### Syntax

The full syntax for all of the properties that are available to the **launchd** resource is:

```ruby
launchd 'name' do
  label  # String
  backup  # [Integer, FalseClass]
  cookbook  # String
  group  # [String, Integer]
  plist_hash  # Hash
  mode  # [String, Integer]
  owner  # [String, Integer]
  path  # String
  source  # String
  session_type  # String
  start_calendar_interval  # [Hash, Array]
  type  # String  # default: "daemon"
  abandon_process_group  # [ TrueClass, FalseClass ]
  associated_bundle_identifiers  # Array
  debug  # [ TrueClass, FalseClass ]
  disabled  # [ TrueClass, FalseClass ]  # default: false
  enable_globbing  # [ TrueClass, FalseClass ]
  enable_transactions  # [ TrueClass, FalseClass ]
  environment_variables  # Hash
  exit_timeout  # Integer
  hard_resource_limits  # Hash
  inetd_compatibility  # Hash
  init_groups  # [ TrueClass, FalseClass ]
  keep_alive  # [ TrueClass, FalseClass, Hash ]
  launch_events  # [ Hash ]
  launch_only_once  # [ TrueClass, FalseClass ]
  ld_group  # String
  limit_load_from_hosts  # Array
  limit_load_to_hosts  # Array
  limit_load_to_session_type  # [ Array, String ]
  low_priority_io  # [ TrueClass, FalseClass ]
  mach_services  # Hash
  nice  # Integer
  on_demand  # [ TrueClass, FalseClass ]
  process_type  # String
  program  # String
  program_arguments  # Array
  queue_directories  # Array
  root_directory  # String
  run_at_load  # [ TrueClass, FalseClass ]
  sockets  # Hash
  soft_resource_limits  # Array
  standard_error_path  # String
  standard_in_path  # String
  standard_out_path  # String
  start_interval  # Integer
  start_on_mount  # [ TrueClass, FalseClass ]
  throttle_interval  # Integer
  time_out  # Integer
  username  # String
  wait_for_debugger  # [ TrueClass, FalseClass ]
  watch_paths  # Array
  working_directory  # String
  action  :symbol # defaults to :create if not specified
end
```

### Actions

The **launchd** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` **(default)** |  |
| `:create_if_missing` |  |
| `:delete` |  |
| `:enable` |  |
| `:disable` |  |
| `:restart` |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `label` | `String` |  | The unique identifier for the job. |
| `backup` | `[Integer, FalseClass]` |  | The number of backups to be kept in `/var/chef/backup`. Set to `false` to prevent backups from being kept. |
| `cookbook` | `String` |  | The name of the cookbook in which the source files are located. |
| `group` | `[String, Integer]` |  | When launchd is run as the root user, the group to run the job as. If the username property is specified and this property is not, this value is set t |
| `plist_hash` | `Hash` |  | A Hash of key value pairs used to create the launchd property list. |
| `mode` | `[String, Integer]` |  | A quoted 3-5 character string that defines the octal mode. For example: '755', '0755', or 00755. |
| `owner` | `[String, Integer]` |  |  |
| `path` | `String` |  | The path to the directory. Using a fully qualified path is recommended, but is not always required. |
| `source` | `String` |  | The path to the launchd property list. |
| `session_type` | `String` |  | The type of launchd plist to be created. Possible values: system (default) or user. |
| `start_calendar_interval` | `[Hash, Array]` |  | A Hash (similar to crontab) that defines the calendar frequency at which a job is started or an Array. |
| `type` | `String` | `"daemon"` | The type of resource. Possible values: daemon (default), agent. |
| `abandon_process_group` | `[ TrueClass, FalseClass ]` |  | If a job dies, all remaining processes with the same process ID may be kept running. Set to true to kill all remaining processes. |
| `associated_bundle_identifiers` | `Array` |  | This optional key indicates which bundles the Login Items Added by Apps panel associates with the helper executable. |
| `debug` | `[ TrueClass, FalseClass ]` |  | Sets the log mask to `LOG_DEBUG` for this job. |
| `disabled` | `[ TrueClass, FalseClass ]` | `false` | Hints to `launchctl` to not submit this job to launchd. |
| `enable_globbing` | `[ TrueClass, FalseClass ]` |  | Update program arguments before invocation. |
| `enable_transactions` | `[ TrueClass, FalseClass ]` |  | Track in-progress transactions; if none, then send the `SIGKILL` signal. |
| `environment_variables` | `Hash` |  | Additional environment variables to set before running a job. |
| `exit_timeout` | `Integer` |  | The amount of time (in seconds) launchd waits before sending a `SIGKILL` signal. |
| `hard_resource_limits` | `Hash` |  | A Hash of resource limits to be imposed on a job. |
| `inetd_compatibility` | `Hash` |  |  |
| `init_groups` | `[ TrueClass, FalseClass ]` |  | Specify if `initgroups` is called before running a job. |
| `keep_alive` | `[ TrueClass, FalseClass, Hash ]` |  | Keep a job running continuously (true) or allow demand and conditions on the node to determine if the job keeps running (`false`). |
| `launch_events` | `[ Hash ]` |  | Specify higher-level event types to be used as launch-on-demand event sources. |
| `launch_only_once` | `[ TrueClass, FalseClass ]` |  | Specify if a job can be run only one time. Set this value to true if a job cannot be restarted without a full machine reboot. |
| `ld_group` | `String` |  | The group name. |
| `limit_load_from_hosts` | `Array` |  | An array of hosts to which this configuration file does not apply, i.e. 'apply this configuration file to all hosts not specified in this array'. |
| `limit_load_to_hosts` | `Array` |  | An array of hosts to which this configuration file applies. |
| `limit_load_to_session_type` | `[ Array, String ]` |  | The session type(s) to which this configuration file applies. |
| `low_priority_io` | `[ TrueClass, FalseClass ]` |  | Specify if the kernel on the node should consider this daemon to be low priority during file system I/O. |
| `mach_services` | `Hash` |  | Specify services to be registered with the bootstrap subsystem. |
| `nice` | `Integer` |  | The program scheduling priority value in the range -20 to 19. |
| `on_demand` | `[ TrueClass, FalseClass ]` |  | Keep a job alive. Only applies to macOS version 10.4 (and earlier); use `keep_alive` instead for newer versions. |
| `process_type` | `String` |  | The intended purpose of the job: `Adaptive`, `Background`, `Interactive`, or `Standard`. |
| `program` | `String` |  | The first argument of `execvp`, typically the file name associated with the file to be executed. This value must be specified if `program_arguments` i |
| `program_arguments` | `Array` |  | The second argument of `execvp`. If program is not specified, this property must be specified and will be handled as if it were the first argument. |
| `queue_directories` | `Array` |  | An array of non-empty directories which, if any are modified, will cause a job to be started. |
| `root_directory` | `String` |  | `chroot` to this directory, and then run the job. |
| `run_at_load` | `[ TrueClass, FalseClass ]` |  | Launch a job once (at the time it is loaded). |
| `sockets` | `Hash` |  | A Hash of on-demand sockets that notify launchd when a job should be run. |
| `soft_resource_limits` | `Array` |  | A Hash of resource limits to be imposed on a job. |
| `standard_error_path` | `String` |  | The file to which standard error (`stderr`) is sent. |
| `standard_in_path` | `String` |  | The file to which standard input (`stdin`) is sent. |
| `standard_out_path` | `String` |  | The file to which standard output (`stdout`) is sent. |
| `start_interval` | `Integer` |  | The frequency (in seconds) at which a job is started. |
| `start_on_mount` | `[ TrueClass, FalseClass ]` |  | Start a job every time a file system is mounted. |
| `throttle_interval` | `Integer` |  | The frequency (in seconds) at which jobs are allowed to spawn. |
| `time_out` | `Integer` |  | The amount of time (in seconds) a job may be idle before it times out. If no value is specified, the default timeout value for launchd will be used. |
| `username` | `String` |  | When launchd is run as the root user, the user to run the job as. |
| `wait_for_debugger` | `[ TrueClass, FalseClass ]` |  | Specify if launchd has a job wait for a debugger to attach before executing code. |
| `watch_paths` | `Array` |  | An array of paths which, if any are modified, will cause a job to be started. |
| `working_directory` | `String` |  | `chdir` to this directory, and then run the job. |


---

## link resource

[link resource page](link/)

Use the **link** resource to create symbolic or hard links.  " \


> Source: `lib/chef/resource/link.rb`

### Syntax

The full syntax for all of the properties that are available to the **link** resource is:

```ruby
link 'name' do
  target_file  # String
  to  # [String, nil]
  link_type  # [String, Symbol]  # default: :symbolic
  group  # [String, Integer]
  owner  # [String, Integer]
  action  :symbol # defaults to :create if not specified
end
```

### Actions

The **link** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` **(default)** |  |
| `:delete` |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `target_file` | `String` |  | An optional property to set the target file if it differs from the resource block's name. |
| `to` | `[String, nil]` |  | The actual file to which the link is to be created. |
| `link_type` | `[String, Symbol]` | `:symbolic` | The type of link: :symbolic or :hard. |
| `group` | `[String, Integer]` |  | A group name or ID number that identifies the group associated with a symbolic link. |
| `owner` | `[String, Integer]` |  | The owner associated with a symbolic link. |

### Agentless Mode

The **link** resource has **full** support for Agentless Mode.


---

## locale resource

[locale resource page](locale/)

Use the **locale** resource to set the system's locale on Debian and Windows systems. Windows support was added in Chef Infra Client 16.0

**New in Chef Infra Client 14.5.**

> Source: `lib/chef/resource/locale.rb`

### Syntax

The full syntax for all of the properties that are available to the **locale** resource is:

```ruby
locale 'name' do
  lang  # String
  lc_env  # Hash  # default: {}
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **locale** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:update` | Update the system's locale. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `lang` | `String` |  | Sets the default system language. |
| `lc_env` | `Hash` | `{}` | A Hash of LC_* env variables in the form of `({ 'LC_ENV_VARIABLE' => 'VALUE' })`. |

### Agentless Mode

The **locale** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **locale** resource:

      Set the lang to 'en_US.UTF-8'

      ```ruby
        locale 'set system locale' do
          lang 'en_US.UTF-8'
        end
      ```


---

## log resource

[log resource page](log/)

Use the **log** resource to create log entries. The log resource behaves" \

**New in Chef Infra Client 15.1.** *(catalog version; not declared in local source)*

> Source: `lib/chef/resource/log.rb`

### Syntax

The full syntax for all of the properties that are available to the **log** resource is:

```ruby
log 'name' do
  message  # String
  level  # Symbol  # default: :info
  action  :symbol # defaults to :write if not specified
end
```

### Actions

The **log** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:write` **(default)** |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `message` | `String` |  | The message to be added to a log file. If not specified we'll use the resource's name instead. |
| `level` | `Symbol` | `:info` | The logging level to display this message at. |

### Agentless Mode

The **log** resource has **full** support for Agentless Mode.

Support was added in Chef Infra Client 15.1.


---

## macos_pkg resource

[macos_pkg resource page](macos_pkg/)

Use the **macos_pkg** resource to install a macOS `.pkg` file, optionally downloading it from a remote source. A `package_id` property must be provided for idempotency. Either a `file` or `source` property is required.

**New in Chef Infra Client 18.1.**

> Source: `lib/chef/resource/macos_pkg.rb`

### Syntax

The full syntax for all of the properties that are available to the **macos_pkg** resource is:

```ruby
macos_pkg 'name' do
  checksum  # String
  file  # String
  headers  # Hash
  package_id  # String
  source  # String
  target  # String  # default: "/"  load_current_value do |new_resource|
  action  :symbol # defaults to :install if not specified
end
```

### Actions

The **macos_pkg** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` **(default)** |  |
| `:run` |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `checksum` | `String` |  | The sha256 checksum of the `.pkg` file to download. |
| `file` | `String` |  | The absolute path to the `.pkg` file on the local system. |
| `headers` | `Hash` |  | Allows custom HTTP headers (like cookies) to be set on the `remote_file` resource. |
| `package_id` | `String` |  | The package ID registered with `pkgutil` when a `pkg` or `mpkg` is installed. |
| `source` | `String` |  | The remote URL used to download the `.pkg` file. |
| `target` | `String` | `"/"  load_current_value do |new_resource|` | The device to install the package on. |

### Examples

The following examples demonstrate various approaches for using the **macos_pkg** resource:

        **Install osquery**:

        ```ruby
        macos_pkg 'osquery' do
          checksum   '1fea8ac9b603851d2e76c5fc73138a468a3075a3002c8cb1fd7fff53b889c4dd'
          package_id 'io.osquery.agent'
          source     'https://pkg.osquery.io/darwin/osquery-5.8.2.pkg'
          action     :install
        end
        ```


---

## macos_userdefaults resource

[macos_userdefaults resource page](macos_userdefaults/)

Use the **macos_userdefaults** resource to manage the macOS user defaults system. The properties of this resource are passed to the defaults command, and the parameters follow the convention of that command. See the defaults(1) man page for details on how the tool works.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/macos_userdefaults.rb`

### Syntax

The full syntax for all of the properties that are available to the **macos_userdefaults** resource is:

```ruby
macos_userdefaults 'name' do
  domain  # String  # default: "NSGlobalDomain"
  global  # [TrueClass, FalseClass]  # default: false
  key  # String
  host  # [String, Symbol]  # default: :all
  value  # [Integer, Float, String, TrueClass, FalseClass, Hash, Array]
  type  # String
  user  # [String, Symbol]  # default: :current
  sudo  # [TrueClass, FalseClass]  # default: false
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **macos_userdefaults** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:write` | Write the value to the specified domain/key. |
| `:delete` | Delete a key from a domain. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `domain` | `String` | `"NSGlobalDomain"` | The domain that the user defaults belong to. |
| `global` | `[TrueClass, FalseClass]` | `false` | Determines whether or not the domain is global. |
| `key` | `String` |  | The preference key. |
| `host` | `[String, Symbol]` | `:all` | Set either :current, :all or a hostname to set the user default at the host level. |
| `value` | `[Integer, Float, String, TrueClass, FalseClass, Hash, Array]` |  |  |
| `type` | `String` |  | The value type of the preference key. |
| `user` | `[String, Symbol]` | `:current` | The system user that the default will be applied to. Set :current for current user, :all for all users or pass a valid username |
| `sudo` | `[TrueClass, FalseClass]` | `false` |  |

### Examples

The following examples demonstrate various approaches for using the **macos_userdefaults** resource:

        **Specify a global domain value**

        ```ruby
        macos_userdefaults 'Full keyboard access to all controls' do
          key 'AppleKeyboardUIMode'
          value 2
        end
        ```

        **Setting a value on a specific domain**

        ```ruby
        macos_userdefaults 'Enable macOS firewall' do
          domain '/Library/Preferences/com.apple.alf'
          key 'globalstate'
          value 1
        end
        ```

        **Setting a value for specific user and hosts**

        ```ruby
        macos_userdefaults 'Enable macOS firewall' do
          key 'globalstate'
          value 1
          user 'jane'
          host :current
        end
        ```



---

## macosx_service resource

[macosx_service resource page](macosx_service/)

Use the **macosx_service** resource to manage services on the macOS platform.


> Source: `lib/chef/resource/macosx_service.rb`

### Syntax

The full syntax for all of the properties that are available to the **macosx_service** resource is:

```ruby
macosx_service 'name' do
  plist  # String
  session_type
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **macosx_service** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `plist` | `String` |  | A plist to use in the case where the filename and label for the service do not match. |
| `session_type` |  |  |  |


---

## macports_package resource

[macports_package resource page](macports_package/)

Use the **macports_package** resource to manage packages for the macOS platform using the MacPorts package management system.


> Source: `lib/chef/resource/macports_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **macports_package** resource is:

```ruby
macports_package 'name' do
  package_name  # String
  version  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **macports_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:upgrade` |  |
| `:remove` |  |
| `:purge` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `package_name` | `String` |  | An optional property to set the package name if it differs from the resource block's name. |
| `version` | `String` |  | The version of a package to be installed or upgraded. |


---

## mdadm resource

[mdadm resource page](mdadm/)

Use the **mdadm** resource to manage RAID devices in a Linux environment using the mdadm utility. The mdadm resource" \


> Source: `lib/chef/resource/mdadm.rb`

### Syntax

The full syntax for all of the properties that are available to the **mdadm** resource is:

```ruby
mdadm 'name' do
  chunk  # Integer  # default: 16
  devices  # Array  # default: []
  exists  # [ TrueClass, FalseClass ]  # default: false
  level  # Integer  # default: 1
  metadata  # String  # default: "0.90"
  bitmap  # String
  raid_device  # String
  layout  # String
  action  :symbol # defaults to :create if not specified
end
```

### Actions

The **mdadm** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` **(default)** |  |
| `:assemble` |  |
| `:stop` |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `chunk` | `Integer` | `16` | The chunk size. This property should not be used for a RAID 1 mirrored pair (i.e. when the `level` property is set to `1`). |
| `devices` | `Array` | `[]` | The devices to be part of a RAID array. |
| `exists` | `[ TrueClass, FalseClass ]` | `false` |  |
| `level` | `Integer` | `1` | The RAID level. |
| `metadata` | `String` | `"0.90"` | The superblock type for RAID metadata. |
| `bitmap` | `String` |  | The path to a file in which a write-intent bitmap is stored. |
| `raid_device` | `String` |  | An optional property to specify the name of the RAID device if it differs from the resource block's name. |
| `layout` | `String` |  | The RAID5 parity algorithm. Possible values: `left-asymmetric` (or `la`), `left-symmetric` (or ls), `right-asymmetric` (or `ra`), or `right-symmetric` |

### Examples

The following examples demonstrate various approaches for using the **mdadm** resource:

      **Create and assemble a RAID 0 array**

      The mdadm command can be used to create RAID arrays. For example, a RAID 0 array named /dev/md0 with 10 devices would have a command similar to the following:

      ```
      mdadm --create /dev/md0 --level=0 --raid-devices=10 /dev/s01.../dev/s10
      ```

      where /dev/s01 .. /dev/s10 represents 10 devices (01, 02, 03, and so on). This same command, when expressed as a recipe using the mdadm resource, would be similar to:

      ```ruby
      mdadm '/dev/md0' do
        devices [ '/dev/s01', ... '/dev/s10' ]
        level 0
        action :create
      end
      ```

      (again, where /dev/s01 .. /dev/s10 represents devices /dev/s01, /dev/s02, /dev/s03, and so on).

      **Create and assemble a RAID 1 array**

      ```ruby
      mdadm '/dev/md0' do
        devices [ '/dev/sda', '/dev/sdb' ]
        level 1
        action [ :create, :assemble ]
      end
      ```

      **Create and assemble a RAID 5 array**

      The mdadm command can be used to create RAID arrays. For example, a RAID 5 array named /dev/sd0 with 4, and a superblock type of 0.90 would be similar to:

      ```ruby
      mdadm '/dev/sd0' do
        devices [ '/dev/s1', '/dev/s2', '/dev/s3', '/dev/s4' ]
        level 5
        metadata '0.90'
        chunk 32
        action :create
      end
      ```


---

## mount resource

[mount resource page](mount/)

Use the **mount** resource to manage a mounted file system.


> Source: `lib/chef/resource/mount.rb`

### Syntax

The full syntax for all of the properties that are available to the **mount** resource is:

```ruby
mount 'name' do
  supports  # [Array, Hash]  # default: lazy { { remount: false } }
  password  # String
  mount_point  # String
  device  # String
  device_type  # [String, Symbol]  # default: :device
  mounted  # [TrueClass, FalseClass]  # default: false
  fsck_device  # String  # default: "-"
  fstype  # [String, nil]  # default: "auto"
  options  # [Array, String, nil]  # default: %w{defaults}
  dump  # [Integer, FalseClass]  # default: 0
  pass  # [Integer, FalseClass]  # default: 2
  enabled  # [TrueClass, FalseClass]  # default: false
  username  # String
  domain  # String
  action  :symbol # defaults to :mount if not specified
end
```

### Actions

The **mount** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:mount` **(default)** |  |
| `:umount` |  |
| `:unmount` |  |
| `:remount` |  |
| `:enable` |  |
| `:disable` |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `supports` | `[Array, Hash]` | `lazy { { remount: false } }` | Specify a Hash of supported mount features. |
| `password` | `String` |  | Windows only:. Use to specify the password for username. |
| `mount_point` | `String` |  | The directory (or path) in which the device is to be mounted. Defaults to the name of the resource block if not provided. |
| `device` | `String` |  | Required for `:umount` and `:remount` actions (for the purpose of checking the mount command output for presence). The special block device or remote  |
| `device_type` | `[String, Symbol]` | `:device` | The type of device: :device, :label, or :uuid |
| `mounted` | `[TrueClass, FalseClass]` | `false` |  |
| `fsck_device` | `String` | `"-"` | Solaris only: The fsck device. |
| `fstype` | `[String, nil]` | `"auto"` | The file system type (fstype) of the device. |
| `options` | `[Array, String, nil]` | `%w{defaults}` | An array or comma separated list of options for the mount. |
| `dump` | `[Integer, FalseClass]` | `0` | The dump frequency (in days) used while creating a file systems table (fstab) entry. |
| `pass` | `[Integer, FalseClass]` | `2` | The pass number used by the file system check (fsck) command while creating a file systems table (fstab) entry. |
| `enabled` | `[TrueClass, FalseClass]` | `false` | Use to specify if a mounted file system is enabled. |
| `username` | `String` |  | Windows only: Use to specify the user name. |
| `domain` | `String` |  | Windows only: Use to specify the domain in which the `username` and `password` are located. |

### Agentless Mode

The **mount** resource has **full** support for Agentless Mode.


---

## msu_package resource

[msu_package resource page](msu_package/)

Use the **msu_package** resource to install Microsoft Update(MSU) packages on Microsoft Windows machines.

**New in Chef Infra Client 12.17.**

> Source: `lib/chef/resource/msu_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **msu_package** resource is:

```ruby
msu_package 'name' do
  package_name  # String
  version  # [String, Array]
  source  # String
  checksum  # String
  timeout  # [String, Integer]  # default: 3600
  action  :symbol # defaults to :install if not specified
end
```

### Actions

The **msu_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` **(default)** |  |
| `:remove` |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `package_name` | `String` |  | An optional property to set the package name if it differs from the resource block's name. |
| `version` | `[String, Array]` |  | The version of a package to be installed or upgraded. |
| `source` | `String` |  | The local file path or URL for the MSU package. |
| `checksum` | `String` |  | SHA-256 digest used to verify the checksum of the downloaded MSU package. |
| `timeout` | `[String, Integer]` | `3600` | The amount of time (in seconds) to wait before timing out. |


---

## notify_group resource

[notify_group resource page](notify_group/)

The notify_group resource does nothing, and always fires notifications which are set on it.  Use it to DRY blocks of notifications that are common to multiple resources, and provide a single target for other resources to notify.  Unlike most resources, its default action is :nothing.

**New in Chef Infra Client 15.8.**

> Source: `lib/chef/resource/notify_group.rb`

### Syntax

The full syntax for all of the properties that are available to the **notify_group** resource is:

```ruby
notify_group 'name' do
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **notify_group** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:nothing` **(default)** |  |
| `:run` |  |

### Properties

No resource-specific properties.

### Agentless Mode

The **notify_group** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **notify_group** resource:

        Wire up a notification from a service resource to stop and start the service with a 60 second delay.

        ```ruby
        service "crude" do
          action [ :enable, :start ]
        end

        chef_sleep "60" do
          action :nothing
        end

        # Example code for a hypothetical badly behaved service that requires
        # 60 seconds between a stop and start in order to restart the service
        # (due to race conditions, bleeding connections down, resources that only
        # slowly unlock in the background, or other poor software behaviors that
        # are sometimes encountered).
        #
        notify_group "crude_stop_and_start" do
          notifies :stop, "service[crude]", :immediately
          notifies :sleep, "chef_sleep[60]", :immediately
          notifies :start, "service[crude]", :immediately
        end

        template "/etc/crude/crude.conf" do
          source "crude.conf.erb"
          variables node["crude"]
          notifies :run, "notify_group[crude_stop_and_start]", :immediately
        end
        ```


---

## ohai resource

[ohai resource page](ohai/)

Use the **ohai** resource to reload the Ohai configuration on a node. This allows recipes that change system attributes (like a recipe that adds a user) to refer to those attributes later on during the #{ChefUtils::Dist::Infra::PRODUCT} run.


> Source: `lib/chef/resource/ohai.rb`

### Syntax

The full syntax for all of the properties that are available to the **ohai** resource is:

```ruby
ohai 'name' do
  plugin  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **ohai** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:reload` |  |
| `:nothing` **(default)** |  |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `plugin` | `String` |  |  |

### Agentless Mode

The **ohai** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **ohai** resource:

      Reload All Ohai Plugins

      ```ruby
      ohai 'reload' do
        action :reload
      end
      ```

      Reload A Single Ohai Plugin

      ```ruby
      ohai 'reload' do
        plugin 'ipaddress'
        action :reload
      end
      ```

      Reload Ohai after a new user is created

      ```ruby
      ohai 'reload_passwd' do
        action :nothing
        plugin 'etc'
      end

      user 'daemon_user' do
        home '/dev/null'
        shell '/sbin/nologin'
        system true
        notifies :reload, 'ohai[reload_passwd]', :immediately
      end

      ruby_block 'just an example' do
        block do
          # These variables will now have the new values
          puts node['etc']['passwd']['daemon_user']['uid']
          puts node['etc']['passwd']['daemon_user']['gid']
        end
      end
      ```


---

## ohai_hint resource

[ohai_hint resource page](ohai_hint/)

Use the **ohai_hint** resource to aid in configuration detection by passing hint data to Ohai.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/ohai_hint.rb`

### Syntax

The full syntax for all of the properties that are available to the **ohai_hint** resource is:

```ruby
ohai_hint 'name' do
  hint_name  # String
  content  # Hash
  compile_time  # [TrueClass, FalseClass]  # default: true
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **ohai_hint** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:delete` |  |
| `:create` | Create an Ohai hint file. |
| `:nothing` **(default)** |  |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `hint_name` | `String` |  | An optional property to set the hint name if it differs from the resource block's name. |
| `content` | `Hash` |  | Values to include in the hint file. |
| `compile_time` | `[TrueClass, FalseClass]` | `true` | Determines whether or not the resource is executed during the compile time phase. |

### Agentless Mode

The **ohai_hint** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **ohai_hint** resource:

      **Create a hint file**

      ```ruby
      ohai_hint 'example' do
        content a: 'test_content'
      end
      ```

      **Create a hint file with a name that does not match the resource name**

      ```ruby
      ohai_hint 'example' do
        hint_name 'custom'
      end
      ```

      **Create a hint file that is not loaded at compile time**

      ```ruby
      ohai_hint 'example' do
        compile_time false
      end
      ```

      **Delete a hint file**

      ```ruby
      ohai_hint 'example' do
        action :delete
      end
      ```


---

## openbsd_package resource

[openbsd_package resource page](openbsd_package/)

Use the **openbsd_package** resource to manage packages for the OpenBSD platform.

**New in Chef Infra Client 12.1.**

> Source: `lib/chef/resource/openbsd_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **openbsd_package** resource is:

```ruby
openbsd_package 'name' do
  package_name  # String
  version  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **openbsd_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:remove` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `package_name` | `String` |  | An optional property to set the package name if it differs from the resource block's name. |
| `version` | `String` |  | The version of a package to be installed or upgraded. |

### Agentless Mode

The **openbsd_package** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **openbsd_package** resource:

        **Install a package**

        ```ruby
        openbsd_package 'name of package' do
          action :install
        end
        ```

        **Remove a package**

        ```ruby
        openbsd_package 'name of package' do
          action :remove
        end
        ```


---

## openssl_dhparam resource

[openssl_dhparam resource page](openssl_dhparam/)

Use the **openssl_dhparam** resource to generate `dhparam.pem` files. If a valid `dhparam.pem` file is found at the specified location, no new file will be created. If a file is found at the specified location but it is not a valid `dhparam.pem` file, it will be overwritten.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/openssl_dhparam.rb`

### Syntax

The full syntax for all of the properties that are available to the **openssl_dhparam** resource is:

```ruby
openssl_dhparam 'name' do
  path  # String
  key_length  # Integer  # default: 2048
  generator  # Integer  # default: 2
  owner  # [String, Integer]
  group  # [String, Integer]
  mode  # [Integer, String]  # default: "0640"
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **openssl_dhparam** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` | Create the `dhparam.pem` file. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `path` | `String` |  | An optional property for specifying the path to write the file to if it differs from the resource block's name. |
| `key_length` | `Integer` | `2048` | The desired bit length of the generated key. |
| `generator` | `Integer` | `2` | The desired Diffie-Hellmann generator. |
| `owner` | `[String, Integer]` |  | The owner applied to all files created by the resource. |
| `group` | `[String, Integer]` |  | The group ownership applied to all files created by the resource. |
| `mode` | `[Integer, String]` | `"0640"` | The permission mode applied to all files created by the resource. |

### Examples

The following examples demonstrate various approaches for using the **openssl_dhparam** resource:

        **Create a dhparam file**

        ```ruby
        openssl_dhparam '/etc/httpd/ssl/dhparam.pem'
        ```

        **Create a dhparam file with a specific key length**

        ```ruby
        openssl_dhparam '/etc/httpd/ssl/dhparam.pem' do
          key_length 4096
        end
        ```

        **Create a dhparam file with specific user/group ownership**

        ```ruby
        openssl_dhparam '/etc/httpd/ssl/dhparam.pem' do
          owner 'www-data'
          group 'www-data'
        end
        ```

        **Manually specify the dhparam file path**

        ```ruby
        openssl_dhparam 'httpd_dhparam' do
          path '/etc/httpd/ssl/dhparam.pem'
        end
        ```


---

## openssl_ec_private_key resource

[openssl_ec_private_key resource page](openssl_ec_private_key/)

Use the **openssl_ec_private_key** resource to generate an elliptic curve (EC) private key file. If a valid EC key file can be opened at the specified location, no new file will be created. If the EC key file cannot be opened, either because it does not exist or because the password to the EC key file does not match the password in the recipe, then it will be overwritten.

**New in Chef Infra Client 14.4.**

> Source: `lib/chef/resource/openssl_ec_private_key.rb`

### Syntax

The full syntax for all of the properties that are available to the **openssl_ec_private_key** resource is:

```ruby
openssl_ec_private_key 'name' do
  path  # String
  key_curve  # String  # default: "prime256v1"
  key_pass  # String
  key_cipher  # String  # default: lazy { "des3" }
  owner  # [String, Integer]
  group  # [String, Integer]
  mode  # [Integer, String]  # default: "0600"
  force  # [TrueClass, FalseClass]  # default: false
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **openssl_ec_private_key** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `path` | `String` |  | An optional property for specifying the path to write the file to if it differs from the resource block's name. |
| `key_curve` | `String` | `"prime256v1"` | The desired curve of the generated key (if key_type is equal to 'ec'). Run openssl ecparam -list_curves to see available options. |
| `key_pass` | `String` |  | The desired passphrase for the key. |
| `key_cipher` | `String` | `lazy { "des3" }` | The designed cipher to use when generating your key. Run `openssl list-cipher-algorithms` to see available options. |
| `owner` | `[String, Integer]` |  | The owner applied to all files created by the resource. |
| `group` | `[String, Integer]` |  | The group ownership applied to all files created by the resource. |
| `mode` | `[Integer, String]` | `"0600"` | The permission mode applied to all files created by the resource. |
| `force` | `[TrueClass, FalseClass]` | `false` | Force creation of the key even if the same key already exists on the node. |

### Examples

The following examples demonstrate various approaches for using the **openssl_ec_private_key** resource:

        **Generate a new ec privatekey with prime256v1 key curve and default des3 cipher**

        ```ruby
        openssl_ec_private_key '/etc/ssl_files/eckey_prime256v1_des3.pem' do
          key_curve 'prime256v1'
          key_pass 'something'
          action :create
        end
        ```

        **Generate a new ec private key with prime256v1 key curve and aes-128-cbc cipher**

        ```ruby
        openssl_ec_private_key '/etc/ssl_files/eckey_prime256v1_des3.pem' do
          key_curve 'prime256v1'
          key_cipher 'aes-128-cbc'
          key_pass 'something'
          action :create
        end
        ```


---

## openssl_ec_public_key resource

[openssl_ec_public_key resource page](openssl_ec_public_key/)

Use the **openssl_ec_public_key** resource to generate elliptic curve (EC) public key files from a given EC private key.

**New in Chef Infra Client 14.4.**

> Source: `lib/chef/resource/openssl_ec_public_key.rb`

### Syntax

The full syntax for all of the properties that are available to the **openssl_ec_public_key** resource is:

```ruby
openssl_ec_public_key 'name' do
  path  # String
  private_key_path  # String
  private_key_content  # String
  private_key_pass  # String
  owner  # [String, Integer]
  group  # [String, Integer]
  mode  # [Integer, String]  # default: "0640"
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **openssl_ec_public_key** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `path` | `String` |  | An optional property for specifying the path to write the file to if it differs from the resource block's name. |
| `private_key_path` | `String` |  | The path to the private key file. |
| `private_key_content` | `String` |  | The content of the private key including new lines. This property is used in place of private_key_path in instances where you want to avoid having to  |
| `private_key_pass` | `String` |  | The passphrase of the provided private key. |
| `owner` | `[String, Integer]` |  | The owner applied to all files created by the resource. |
| `group` | `[String, Integer]` |  | The group ownership applied to all files created by the resource. |
| `mode` | `[Integer, String]` | `"0640"` | The permission mode applied to all files created by the resource. |

### Examples

The following examples demonstrate various approaches for using the **openssl_ec_public_key** resource:

        **Generate new EC public key from a private key on disk**

        ```ruby
        openssl_ec_public_key '/etc/ssl_files/eckey_prime256v1_des3.pub' do
          private_key_path '/etc/ssl_files/eckey_prime256v1_des3.pem'
          private_key_pass 'something'
          action :create
        end
        ```

        **Generate new EC public key by passing in a private key**

        ```ruby
        openssl_ec_public_key '/etc/ssl_files/eckey_prime256v1_des3_2.pub' do
          private_key_content "-----BEGIN EC PRIVATE KEY-----\nMHcCAQEEII2VAU9re44mAUzYPWCg+qqwdmP8CplsEg0b/DYPXLg2oAoGCCqGSM49\nAwEHoUQDQgAEKkpMCbIQ2C6Qlp/B+Odp1a9Y06Sm8yqPvCVIkWYP7M8PX5+RmoIv\njGBVf/+mVBx77ji3NpTilMUt2KPZ87lZ3w==\n-----END EC PRIVATE KEY-----\n"
          action :create
        end
        ```


---

## openssl_rsa_private_key resource

[openssl_rsa_private_key resource page](openssl_rsa_private_key/)

Use the **openssl_rsa_private_key** resource to generate RSA private key files. If a valid RSA key file can be opened at the specified location, no new file will be created. If the RSA key file cannot be opened, either because it does not exist or because the password to the RSA key file does not match the password in the recipe, it will be overwritten.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/openssl_rsa_private_key.rb`

### Syntax

The full syntax for all of the properties that are available to the **openssl_rsa_private_key** resource is:

```ruby
openssl_rsa_private_key 'name' do
  path  # String
  key_length  # Integer  # default: 2048
  key_pass  # String
  key_cipher  # String  # default: lazy { "des3" }
  owner  # [String, Integer]
  group  # [String, Integer]
  mode  # [Integer, String]  # default: "0600"
  force  # [TrueClass, FalseClass]  # default: false
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **openssl_rsa_private_key** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `path` | `String` |  | An optional property for specifying the path to write the file to if it differs from the resource block's name. |
| `key_length` | `Integer` | `2048` | The desired bit length of the generated key. |
| `key_pass` | `String` |  | The desired passphrase for the key. |
| `key_cipher` | `String` | `lazy { "des3" }` | The designed cipher to use when generating your key. Run `openssl list-cipher-algorithms` to see available options. |
| `owner` | `[String, Integer]` |  | The owner applied to all files created by the resource. |
| `group` | `[String, Integer]` |  | The group ownership applied to all files created by the resource. |
| `mode` | `[Integer, String]` | `"0600"` | The permission mode applied to all files created by the resource. |
| `force` | `[TrueClass, FalseClass]` | `false` | Force creation of the key even if the same key already exists on the node. |

### Examples

The following examples demonstrate various approaches for using the **openssl_rsa_private_key** resource:

        Generate new 2048bit key with the default des3 cipher

        ```ruby
        openssl_rsa_private_key '/etc/ssl_files/rsakey_des3.pem' do
          key_length 2048
          action :create
        end
        ```

        Generate new 1024bit key with the aes-128-cbc cipher

        ```ruby
        openssl_rsa_private_key '/etc/ssl_files/rsakey_aes128cbc.pem' do
          key_length 1024
          key_cipher 'aes-128-cbc'
          action :create
        end
        ```


---

## openssl_rsa_public_key resource

[openssl_rsa_public_key resource page](openssl_rsa_public_key/)

Use the **openssl_rsa_public_key** resource to generate RSA public key files for a given RSA private key.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/openssl_rsa_public_key.rb`

### Syntax

The full syntax for all of the properties that are available to the **openssl_rsa_public_key** resource is:

```ruby
openssl_rsa_public_key 'name' do
  path  # String
  private_key_path  # String
  private_key_content  # String
  private_key_pass  # String
  owner  # [String, Integer]
  group  # [String, Integer]
  mode  # [Integer, String]  # default: "0640"
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **openssl_rsa_public_key** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `path` | `String` |  | An optional property for specifying the path to the public key if it differs from the resource block's name. |
| `private_key_path` | `String` |  | The path to the private key file. |
| `private_key_content` | `String` |  | The content of the private key, including new lines. This property is used in place of private_key_path in instances where you want to avoid having to |
| `private_key_pass` | `String` |  | The passphrase of the provided private key. |
| `owner` | `[String, Integer]` |  | The owner applied to all files created by the resource. |
| `group` | `[String, Integer]` |  | The group ownership applied to all files created by the resource. |
| `mode` | `[Integer, String]` | `"0640"` | The permission mode applied to all files created by the resource. |

### Examples

The following examples demonstrate various approaches for using the **openssl_rsa_public_key** resource:

        Generate new public key from a private key on disk

        ```ruby
        openssl_rsa_public_key '/etc/ssl_files/rsakey_des3.pub' do
          private_key_path '/etc/ssl_files/rsakey_des3.pem'
          private_key_pass 'something'
          action :create
        end
        ```

        Generate new public key by passing in a private key

        ```ruby
        openssl_rsa_public_key '/etc/ssl_files/rsakey_2.pub' do
          private_key_pass 'something'
          private_key_content "-----BEGIN RSA PRIVATE KEY-----\nProc-Type: 4,ENCRYPTED\nDEK-Info: DES-EDE3-CBC,5EE0AE9A5FE3342E\n\nyb930kj5/4/nd738dPx6XdbDrMCvqkldaz0rHNw8xsWvwARrl/QSPwROG3WY7ROl\nEUttVlLaeVaqRPfQbmTUfzGI8kTMmDWKjw52gJUx2YJTYRgMHAB0dzYIRjeZAaeS\nypXnEfouVav+jKTmmehr1WuVKbzRhQDBSalzeUwsPi2+fb3Bfuo1dRW6xt8yFuc4\nAkv1hCglymPzPHE2L0nSGjcgA2DZu+/S8/wZ4E63442NHPzO4VlLvpNvJrYpEWq9\nB5mJzcdXPeOTjqd13olNTlOZMaKxu9QShu50GreCTVsl8VRkK8NtwbWuPGBZlIFa\njzlS/RaLuzNzfajaKMkcIYco9t7gN2DwnsACHKqEYT8248Ii3NQ+9/M5YcmpywQj\nWGr0UFCSAdCky1lRjwT+zGQKohr+dVR1GaLem+rSZH94df4YBxDYw4rjsKoEhvXB\nv2Vlx+G7Vl2NFiZzxUKh3MvQLr/NDElpG1pYWDiE0DIG13UqEG++cS870mcEyfFh\nSF2SXYHLWyAhDK0viRDChJyFMduC4E7a2P9DJhL3ZvM0KZ1SLMwROc1XuZ704GwO\nYUqtCX5OOIsTti1Z74jQm9uWFikhgWByhVtu6sYL1YTqtiPJDMFhA560zp/k/qLO\nFKiM4eUWV8AI8AVwT6A4o45N2Ru8S48NQyvh/ADFNrgJbVSeDoYE23+DYKpzbaW9\n00BD/EmUQqaQMc670vmI+CIdcdE7L1zqD6MZN7wtPaRIjx4FJBGsFoeDShr+LoTD\nrwbadwrbc2Rf4DWlvFwLJ4pvNvdtY3wtBu79UCOol0+t8DVVSPVASsh+tp8XncDE\nKRljj88WwBjX7/YlRWvQpe5y2UrsHI0pNy8TA1Xkf6GPr6aS2TvQD5gOrAVReSse\n/kktCzZQotjmY1odvo90Zi6A9NCzkI4ZLgAuhiKDPhxZg61IeLppnfFw0v3H4331\nV9SMYgr1Ftov0++x7q9hFPIHwZp6NHHOhdHNI80XkHqtY/hEvsh7MhFMYCgSY1pa\nK/gMcZ/5Wdg9LwOK6nYRmtPtg6fuqj+jB3Rue5/p9dt4kfom4etCSeJPdvP1Mx2I\neNmyQ/7JN9N87FsfZsIj5OK9OB0fPdj0N0m1mlHM/mFt5UM5x39u13QkCt7skEF+\nyOptXcL629/xwm8eg4EXnKFk330WcYSw+sYmAQ9ZTsBxpCMkz0K4PBTPWWXx63XS\nc4J0r88kbCkMCNv41of8ceeGzFrC74dG7i3IUqZzMzRP8cFeps8auhweUHD2hULs\nXwwtII0YQ6/Fw4hgGQ5//0ASdvAicvH0l1jOQScHzXC2QWNg3GttueB/kmhMeGGm\nsHOJ1rXQ4oEckFvBHOvzjP3kuRHSWFYDx35RjWLAwLCG9odQUApHjLBgFNg9yOR0\njW9a2SGxRvBAfdjTa9ZBBrbjlaF57hq7mXws90P88RpAL+xxCAZUElqeW2Rb2rQ6\nCbz4/AtPekV1CYVodGkPutOsew2zjNqlNH+M8XzfonA60UAH20TEqAgLKwgfgr+a\nc+rXp1AupBxat4EHYJiwXBB9XcVwyp5Z+/dXsYmLXzoMOnp8OFyQ9H8R7y9Y0PEu\n-----END RSA PRIVATE KEY-----\n"
          action :create
        end
        ```


---

## openssl_x509_certificate resource

[openssl_x509_certificate resource page](openssl_x509_certificate/)

Use the **openssl_x509_certificate** resource to generate signed or self-signed, PEM-formatted x509 certificates. If no existing key is specified, the resource will automatically generate a passwordless key with the certificate. If a CA private key and certificate are provided, the certificate will be signed with them. Note: This resource was renamed from openssl_x509 to openssl_x509_certificate. The legacy name will continue to function, but cookbook code should be updated for the new resource name.

**New in Chef Infra Client 14.4.**

> Source: `lib/chef/resource/openssl_x509_certificate.rb`

### Syntax

The full syntax for all of the properties that are available to the **openssl_x509_certificate** resource is:

```ruby
openssl_x509_certificate 'name' do
  path  # String
  owner  # [String, Integer]
  group  # [String, Integer]
  expire  # Integer  # default: 365
  mode  # [Integer, String]
  country  # String
  state  # String
  city  # String
  org  # String
  org_unit  # String
  common_name  # String
  email  # String
  extensions  # Hash  # default: {}
  subject_alt_name  # Array  # default: []
  key_file  # String
  key_pass  # String
  key_type  # String  # default: "rsa"
  key_length  # Integer  # default: 2048
  key_curve  # String  # default: "prime256v1"
  csr_file  # String
  ca_cert_file  # String
  ca_key_file  # String
  ca_key_pass  # String
  renew_before_expiry  # Integer
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **openssl_x509_certificate** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` | Generate a certificate file. |
| `:create_if_missing` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `path` | `String` |  | An optional property for specifying the path to write the file to if it differs from the resource block's name. |
| `owner` | `[String, Integer]` |  | The owner applied to all files created by the resource. |
| `group` | `[String, Integer]` |  | The group ownership applied to all files created by the resource. |
| `expire` | `Integer` | `365` | Value representing the number of days from now through which the issued certificate cert will remain valid. The certificate will expire after this per |
| `mode` | `[Integer, String]` |  | The permission mode applied to all files created by the resource. |
| `country` | `String` |  | Value for the `C` certificate field. |
| `state` | `String` |  | Value for the `ST` certificate field. |
| `city` | `String` |  | Value for the `L` certificate field. |
| `org` | `String` |  | Value for the `O` certificate field. |
| `org_unit` | `String` |  | Value for the `OU` certificate field. |
| `common_name` | `String` |  | Value for the `CN` certificate field. |
| `email` | `String` |  | Value for the `email` certificate field. |
| `extensions` | `Hash` | `{}` | Hash of X509 Extensions entries, in format `{ 'keyUsage' => { 'values' => %w( keyEncipherment digitalSignature), 'critical' => true } }`. |
| `subject_alt_name` | `Array` | `[]` | Array of Subject Alternative Name entries, in format `DNS:example.com` or `IP:1.2.3.4`. |
| `key_file` | `String` |  |  |
| `key_pass` | `String` |  | The passphrase for an existing key's passphrase. |
| `key_type` | `String` | `"rsa"` | The desired type of the generated key. |
| `key_length` | `Integer` | `2048` | The desired bit length of the generated key (if key_type is equal to 'rsa'). |
| `key_curve` | `String` | `"prime256v1"` | The desired curve of the generated key (if key_type is equal to 'ec'). Run `openssl ecparam -list_curves` to see available options. |
| `csr_file` | `String` |  |  |
| `ca_cert_file` | `String` |  | The path to the CA X509 Certificate on the filesystem. If the `ca_cert_file` property is specified, the `ca_key_file` property must also be specified, |
| `ca_key_file` | `String` |  | The path to the CA private key on the filesystem. If the `ca_key_file` property is specified, the `ca_cert_file` property must also be specified, the  |
| `ca_key_pass` | `String` |  | The passphrase for CA private key's passphrase. |
| `renew_before_expiry` | `Integer` |  | The number of days before the expiry. The certificate will be automatically renewed when the value is reached. |

### Examples

The following examples demonstrate various approaches for using the **openssl_x509_certificate** resource:

        Create a simple self-signed certificate file

        ```ruby
        openssl_x509_certificate '/etc/httpd/ssl/mycert.pem' do
          common_name 'www.f00bar.com'
          org 'Foo Bar'
          org_unit 'Lab'
          country 'US'
        end
        ```

        Create a certificate using additional options

        ```ruby
        openssl_x509_certificate '/etc/ssl_files/my_signed_cert.crt' do
          common_name 'www.f00bar.com'
          ca_key_file '/etc/ssl_files/my_ca.key'
          ca_cert_file '/etc/ssl_files/my_ca.crt'
          expire 365
          extensions(
            'keyUsage' => {
              'values' => %w(
                keyEncipherment
                digitalSignature),
              'critical' => true,
            },
            'extendedKeyUsage' => {
              'values' => %w(serverAuth),
              'critical' => false,
            }
          )
          subject_alt_name ['IP:127.0.0.1', 'DNS:localhost.localdomain']
        end
        ```


---

## openssl_x509_crl resource

[openssl_x509_crl resource page](openssl_x509_crl/)

Use the **openssl_x509_crl** resource to generate PEM-formatted x509 certificate revocation list (CRL) files.

**New in Chef Infra Client 14.4.**

> Source: `lib/chef/resource/openssl_x509_crl.rb`

### Syntax

The full syntax for all of the properties that are available to the **openssl_x509_crl** resource is:

```ruby
openssl_x509_crl 'name' do
  path  # String
  serial_to_revoke  # [Integer, String]
  revocation_reason  # Integer  # default: 0
  expire  # Integer  # default: 8
  renewal_threshold  # Integer  # default: 1
  ca_cert_file  # String
  ca_key_file  # String
  ca_key_pass  # String
  owner  # [String, Integer]
  group  # [String, Integer]
  mode  # [Integer, String]
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **openssl_x509_crl** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` | Create the certificate revocation list (CRL) file. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `path` | `String` |  | An optional property for specifying the path to write the file to if it differs from the resource block's name. |
| `serial_to_revoke` | `[Integer, String]` |  | Serial of the X509 Certificate to revoke. |
| `revocation_reason` | `Integer` | `0` | Reason for the revocation. |
| `expire` | `Integer` | `8` | Value representing the number of days from now through which the issued CRL will remain valid. The CRL will expire after this period. |
| `renewal_threshold` | `Integer` | `1` | Number of days before the expiration. It this threshold is reached, the CRL will be renewed. |
| `ca_cert_file` | `String` |  | The path to the CA X509 Certificate on the filesystem. If the `ca_cert_file` property is specified, the `ca_key_file` property must also be specified, |
| `ca_key_file` | `String` |  | The path to the CA private key on the filesystem. If the `ca_key_file` property is specified, the `ca_cert_file` property must also be specified, the  |
| `ca_key_pass` | `String` |  | The passphrase for CA private key's passphrase. |
| `owner` | `[String, Integer]` |  | The owner permission for the CRL file. |
| `group` | `[String, Integer]` |  | The group permission for the CRL file. |
| `mode` | `[Integer, String]` |  | The permission mode of the CRL file. |

### Examples

The following examples demonstrate various approaches for using the **openssl_x509_crl** resource:

      **Create a certificate revocation file**

      ```ruby
      openssl_x509_crl '/etc/ssl_test/my_ca.crl' do
        ca_cert_file '/etc/ssl_test/my_ca.crt'
        ca_key_file '/etc/ssl_test/my_ca.key'
      end
      ```

      **Create a certificate revocation file for a particular serial**

      ```ruby
      openssl_x509_crl '/etc/ssl_test/my_ca.crl' do
        ca_cert_file '/etc/ssl_test/my_ca.crt'
        ca_key_file '/etc/ssl_test/my_ca.key'
        serial_to_revoke C7BCB6602A2E4251EF4E2827A228CB52BC0CEA2F
      end
      ```


---

## openssl_x509_request resource

[openssl_x509_request resource page](openssl_x509_request/)

Use the **openssl_x509_request** resource to generate PEM-formatted x509 certificates requests. If no existing key is specified, the resource will automatically generate a passwordless key with the certificate.

**New in Chef Infra Client 14.4.**

> Source: `lib/chef/resource/openssl_x509_request.rb`

### Syntax

The full syntax for all of the properties that are available to the **openssl_x509_request** resource is:

```ruby
openssl_x509_request 'name' do
  path  # String
  owner  # [String, Integer]
  group  # [String, Integer]
  mode  # [Integer, String]
  country  # String
  state  # String
  city  # String
  org  # String
  org_unit  # String
  common_name  # String
  email  # String
  key_file  # String
  key_pass  # String
  key_type  # String  # default: "ec"
  key_length  # Integer  # default: 2048
  key_curve  # String  # default: "prime256v1"
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **openssl_x509_request** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` | Generate a certificate request file. |
| `:create_if_missing` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `path` | `String` |  | An optional property for specifying the path to write the file to if it differs from the resource block's name. |
| `owner` | `[String, Integer]` |  | The owner applied to all files created by the resource. |
| `group` | `[String, Integer]` |  | The group ownership applied to all files created by the resource. |
| `mode` | `[Integer, String]` |  | The permission mode applied to all files created by the resource. |
| `country` | `String` |  | Value for the `C` certificate field. |
| `state` | `String` |  | Value for the `ST` certificate field. |
| `city` | `String` |  | Value for the `L` certificate field. |
| `org` | `String` |  | Value for the `O` certificate field. |
| `org_unit` | `String` |  | Value for the `OU` certificate field. |
| `common_name` | `String` |  | Value for the `CN` certificate field. |
| `email` | `String` |  | Value for the `email` certificate field. |
| `key_file` | `String` |  |  |
| `key_pass` | `String` |  | The passphrase for an existing key's passphrase. |
| `key_type` | `String` | `"ec"` | The desired type of the generated key. |
| `key_length` | `Integer` | `2048` | The desired bit length of the generated key (if key_type is equal to `rsa`). |
| `key_curve` | `String` | `"prime256v1"` | The desired curve of the generated key (if key_type is equal to `ec`). Run `openssl ecparam -list_curves` to see available options. |

### Examples

The following examples demonstrate various approaches for using the **openssl_x509_request** resource:

        **Generate new EC key and CSR file**

        ```ruby
        openssl_x509_request '/etc/ssl_files/my_ec_request.csr' do
          common_name 'myecrequest.example.com'
          org 'Test Kitchen Example'
          org_unit 'Kitchens'
          country 'UK'
        end
        ```

        **Generate a new CSR file from an existing EC key**

        ```ruby
        openssl_x509_request '/etc/ssl_files/my_ec_request2.csr' do
          common_name 'myecrequest2.example.com'
          org 'Test Kitchen Example'
          org_unit 'Kitchens'
          country 'UK'
          key_file '/etc/ssl_files/my_ec_request.key'
        end
        ```

        **Generate new RSA key and CSR file**

        ```ruby
        openssl_x509_request '/etc/ssl_files/my_rsa_request.csr' do
          common_name 'myrsarequest.example.com'
          org 'Test Kitchen Example'
          org_unit 'Kitchens'
          country 'UK'
          key_type 'rsa'
        end
        ```


---

## package resource

[package resource page](package/)

Use the **package** resource to manage packages. When the package is" \

**New in Chef Infra Client 19.0.** *(catalog version; not declared in local source)*

> Source: `lib/chef/resource/package.rb`

### Syntax

The full syntax for all of the properties that are available to the **package** resource is:

```ruby
package 'name' do
  package_name  # [ String, Array ]
  version  # [ String, Array ]
  options  # [ String, Array ]
  source  # String
  timeout  # [ String, Integer ]
  environment  # Hash
  action  :symbol # defaults to :install if not specified
end
```

### Actions

The **package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` **(default)** |  |
| `:upgrade` |  |
| `:remove` |  |
| `:purge` |  |
| `:reconfig` |  |
| `:lock` |  |
| `:unlock` |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `package_name` | `[ String, Array ]` |  | An optional property to set the package name if it differs from the resource block's name. |
| `version` | `[ String, Array ]` |  | The version of a package to be installed or upgraded. |
| `options` | `[ String, Array ]` |  | One (or more) additional command options that are passed to the command. |
| `source` | `String` |  | The optional path to a package on the local file system. |
| `timeout` | `[ String, Integer ]` |  | The amount of time (in seconds) to wait before timing out. |
| `environment` | `Hash` |  | A Hash of environment variables in the form of {'ENV_VARIABLE' => 'VALUE'} to be set before running the command. |

### Agentless Mode

The **package** resource has **full** support for Agentless Mode.

Support was added in Chef Infra Client 19.0.


---

## pacman_package resource

[pacman_package resource page](pacman_package/)

Use the **pacman_package** resource to manage packages (using pacman) on the Arch Linux platform.


> Source: `lib/chef/resource/pacman_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **pacman_package** resource is:

```ruby
pacman_package 'name' do
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **pacman_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:upgrade` |  |
| `:remove` |  |
| `:purge` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

No resource-specific properties.

### Agentless Mode

The **pacman_package** resource has **full** support for Agentless Mode.


---

## paludis_package resource

[paludis_package resource page](paludis_package/)

Use the **paludis_package** resource to manage packages for the Paludis platform.

**New in Chef Infra Client 12.1.**

> Source: `lib/chef/resource/paludis_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **paludis_package** resource is:

```ruby
paludis_package 'name' do
  package_name  # String
  version  # String
  timeout  # [String, Integer]  # default: 3600
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **paludis_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:remove` |  |
| `:upgrade` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `package_name` | `String` |  | An optional property to set the package name if it differs from the resource block's name. |
| `version` | `String` |  | The version of a package to be installed or upgraded. |
| `timeout` | `[String, Integer]` | `3600` | The amount of time (in seconds) to wait before timing out. |

### Agentless Mode

The **paludis_package** resource has **full** support for Agentless Mode.


---

## perl resource

[perl resource page](perl/)

Use the **perl** resource to execute scripts using the Perl interpreter." \


> Source: `lib/chef/resource/perl.rb`

### Syntax

The full syntax for all of the properties that are available to the **perl** resource is:

```ruby
perl 'name' do
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **perl** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

No resource-specific properties.

> This resource inherits all properties from the `execute` resource via the `script` base class, including:
> `code` (required), `cwd`, `environment`, `flags`, `group`, `input`, `interpreter`,
> `live_stream`, `login`, `password`, `returns`, `timeout`, `user`, `domain`, `elevated`.

### Agentless Mode

The **perl** resource has **full** support for Agentless Mode.


---

## plist resource

[plist resource page](plist/)

Use the **plist** resource to set config values in plist files on macOS systems.

**New in Chef Infra Client 16.0.**

> Source: `lib/chef/resource/plist.rb`

### Syntax

The full syntax for all of the properties that are available to the **plist** resource is:

```ruby
plist 'name' do
  path  # String
  entry
  value  # [TrueClass, FalseClass, String, Integer, Float, Hash]
  encoding  # String  # default: "binary"
  owner  # String  # default: "root"
  group  # String  # default: "wheel"
  mode  # [String, Integer]
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **plist** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:set` | Set a value in a plist file. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `path` | `String` |  | The path on disk to the plist file. |
| `entry` |  |  |  |
| `value` | `[TrueClass, FalseClass, String, Integer, Float, Hash]` |  |  |
| `encoding` | `String` | `"binary"` |  |
| `owner` | `String` | `"root"` | The owner of the plist file. |
| `group` | `String` | `"wheel"` | The group of the plist file. |
| `mode` | `[String, Integer]` |  | The file mode of the plist file. Ex: '644' |

### Examples

The following examples demonstrate various approaches for using the **plist** resource:

        **Show hidden files in finder**:

        ```ruby
        plist 'show hidden files' do
          path '/Users/vagrant/Library/Preferences/com.apple.finder.plist'
          entry 'AppleShowAllFiles'
          value true
        end
        ```


---

## portage_package resource

[portage_package resource page](portage_package/)

Use the **portage_package** resource to manage packages for the Gentoo platform.


> Source: `lib/chef/resource/portage_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **portage_package** resource is:

```ruby
portage_package 'name' do
  package_name  # String
  version  # String
  timeout  # [String, Integer]  # default: 3600
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **portage_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:upgrade` |  |
| `:remove` |  |
| `:purge` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `package_name` | `String` |  | An optional property to set the package name if it differs from the resource block's name. |
| `version` | `String` |  | The version of a package to be installed or upgraded. |
| `timeout` | `[String, Integer]` | `3600` | The amount of time (in seconds) to wait before timing out. |

### Agentless Mode

The **portage_package** resource has **full** support for Agentless Mode.


---

## powershell_package resource

[powershell_package resource page](powershell_package/)

Use the **powershell_package** resource to install and manage packages via the PowerShell Package Manager for the Microsoft Windows platform. The powershell_package resource requires administrative access, and a source must be configured in the PowerShell Package Manager via the powershell_package_source resource.

**New in Chef Infra Client 12.16.**

> Source: `lib/chef/resource/powershell_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **powershell_package** resource is:

```ruby
powershell_package 'name' do
  package_name  # [String, Array]
  version  # [String, Array]
  source  # String
  skip_publisher_check  # [true, false]  # default: false
  allow_clobber  # [TrueClass, FalseClass]  # default: false
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **powershell_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:remove` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `package_name` | `[String, Array]` |  | The name of the package. Default value: the name of the resource block. |
| `version` | `[String, Array]` |  | The version of a package to be installed or upgraded. |
| `source` | `String` |  | Specify the source of the package. |
| `skip_publisher_check` | `[true, false]` | `false` | Skip validating module author. |
| `allow_clobber` | `[TrueClass, FalseClass]` | `false` | Overrides warning messages about installation conflicts about existing commands on a computer. |


---

## powershell_package_source resource

[powershell_package_source resource page](powershell_package_source/)

Use the **powershell_package_source** resource to register a PowerShell package source and a Powershell package provider. There are two distinct objects we care about here. The first is a package source like a PowerShell repository or a NuGet Source. The second object is a provider that PowerShell uses to get to that source with, like PowerShellGet, NuGet, Chocolatey, etc.

**New in Chef Infra Client 14.3.**

> Source: `lib/chef/resource/powershell_package_source.rb`

### Syntax

The full syntax for all of the properties that are available to the **powershell_package_source** resource is:

```ruby
powershell_package_source 'name' do
  source_name  # String
  new_name  # String
  source_location  # String
  publish_location  # String
  script_source_location  # String
  script_publish_location  # String
  trusted  # [TrueClass, FalseClass]  # default: false
  user  # String
  password  # String
  provider_name  # String  # default: "NuGet"
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **powershell_package_source** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:register` |  |
| `:set` |  |
| `:unregister` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `source_name` | `String` |  | A label that names your package source. |
| `new_name` | `String` |  | Used to change the name of a standard package source. |
| `source_location` | `String` |  | The URL to the location to retrieve modules from. |
| `publish_location` | `String` |  | The URL where modules will be published to. Only valid if the provider is `PowerShellGet`. |
| `script_source_location` | `String` |  | The URL where scripts are located for this source. Only valid if the provider is `PowerShellGet`. |
| `script_publish_location` | `String` |  | The location where scripts will be published to for this source. Only valid if the provider is `PowerShellGet`. |
| `trusted` | `[TrueClass, FalseClass]` | `false` | Whether or not to trust packages from this source. Used when creating a non-PowerShell repository package source. |
| `user` | `String` |  | A username that, as part of a credential object, is used to register a repository or other package source with. |
| `password` | `String` |  | A password that, as part of a credential object, is used to register a repository or other package source with. |
| `provider_name` | `String` | `"NuGet"` | The package management provider for the package source. The default is `PowerShellGet`. Only change this option in specific use cases. |

### Examples

The following examples demonstrate various approaches for using the **powershell_package_source** resource:

        **Add a new PowerShell repository that is not trusted and which requires credentials to connect to**:

        ```ruby
        powershell_package_source 'PowerShellModules' do
          source_name                  "PowerShellModules"
          source_location              "https://pkgs.dev.azure.com/some-org/some-project/_packaging/some_feed/nuget/v2"
          publish_location             "https://pkgs.dev.azure.com/some-org/some-project/_packaging/some_feed/nuget/v2"
          trusted                      false
          user                         "someuser@somelocation.io"
          password                     "my_password"
          provider_name                "PSRepository"
          action                       :register
        end
        ```

        **Add a new package source that uses Chocolatey as the package provider**:

        ```ruby
        powershell_package_source 'PowerShellModules' do
          source_name                  "PowerShellModules"
          source_location              "https://pkgs.dev.azure.com/some-org/some-project/_packaging/some_feed/nuget/v2"
          publish_location             "https://pkgs.dev.azure.com/some-org/some-project/_packaging/some_feed/nuget/v2"
          trusted                      true
          provider_name                "chocolatey"
          action                       :register
        end
        ```

        **Add a new PowerShell script source that is trusted**:

        ```ruby
        powershell_package_source 'MyDodgyScript' do
          source_name                  "MyDodgyScript"
          script_source_location       "https://pkgs.dev.azure.com/some-org/some-project/_packaging/some_feed/nuget/v2"
          script_publish_location      "https://pkgs.dev.azure.com/some-org/some-project/_packaging/some_feed/nuget/v2"
          trusted                      true
          action                       :register
        end
        ```

        **Update an existing PowerShell repository to make it trusted**:

        ```ruby
        powershell_package_source 'MyPSModule' do
          source_name                  "MyPSModule"
          trusted                      true
          action                       :set
        end
        ```

        **Update a Nuget package source with a new name and make it trusted**:

        ```ruby
        powershell_package_source 'PowerShellModules -> GoldFishBowl' do
          source_name                  "PowerShellModules"
          new_name                     "GoldFishBowl"
          provider_name                "Nuget"
          trusted                      true
          action                       :set
        end
        ```

        **Update a Nuget package source with a new name when the source is secured with a username and password**:

        ```ruby
        powershell_package_source 'PowerShellModules -> GoldFishBowl' do
          source_name                  "PowerShellModules"
          new_name                     "GoldFishBowl"
          trusted                      true
          user                         "user@domain.io"
          password                     "some_secret_password"
          action                       :set
        end
        ```

        **Unregister a package source**:

        ```ruby
        powershell_package_source 'PowerShellModules' do
          source_name                  "PowerShellModules"
          action                       :unregister
        end
        ```


---

## powershell_script resource

[powershell_script resource page](powershell_script/)

Use the **powershell_script** resource to execute a script using the Windows PowerShell interpreter, much like how the script and script-based resources **bash**, **csh**, **perl**, **python**, and **ruby** are used. The **powershell_script** resource is specific to the Microsoft Windows platform, but may use both the Windows PowerShell interpreter or the PowerShell Core (pwsh) interpreter as of Chef Infra Client 16.6 and later. The **powershell_script** resource creates and executes a temporary file rather than running the command inline. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use `not_if` and `only_if` conditionals to guard this resource for idempotence.


> Source: `lib/chef/resource/powershell_script.rb`

### Syntax

The full syntax for all of the properties that are available to the **powershell_script** resource is:

```ruby
powershell_script 'name' do
  flags  # String
  interpreter  # String  # default: "powershell"
  use_inline_powershell  # [true, false]  # default: false
  convert_boolean_return  # [true, false]  # default: false
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **powershell_script** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `flags` | `String` |  | A string that is passed to the Windows PowerShell command |
| `interpreter` | `String` | `"powershell"` | The interpreter type, `powershell` or `pwsh` (PowerShell Core) |
| `use_inline_powershell` | `[true, false]` | `false` |  |
| `convert_boolean_return` | `[true, false]` | `false` |  |


---

## python resource

[python resource page](python/)

Use the **python** resource to execute scripts using the Python interpreter." \


> Source: `lib/chef/resource/python.rb`

### Syntax

The full syntax for all of the properties that are available to the **python** resource is:

```ruby
python 'name' do
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **python** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

No resource-specific properties.

> This resource inherits all properties from the `execute` resource via the `script` base class, including:
> `code` (required), `cwd`, `environment`, `flags`, `group`, `input`, `interpreter`,
> `live_stream`, `login`, `password`, `returns`, `timeout`, `user`, `domain`, `elevated`.

### Agentless Mode

The **python** resource has **full** support for Agentless Mode.


---

## reboot resource

[reboot resource page](reboot/)

Use the **reboot** resource to reboot a node, a necessary step with some" \

**New in Chef Infra Client 12.0.**

> Source: `lib/chef/resource/reboot.rb`

### Syntax

The full syntax for all of the properties that are available to the **reboot** resource is:

```ruby
reboot 'name' do
  reason  # String  # default: "Reboot by #{ChefUtils::Dist::Infra::PRODUCT}"
  delay_mins  # Integer  # default: 0
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **reboot** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:nothing` **(default)** |  |
| `:request_reboot` |  |
| `:cancel` |  |
| `:reboot_now` | Reboot a node so that the #{ChefUtils::Dist::Infra::PRODUCT} may continue the installation process. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `reason` | `String` | `"Reboot by #{ChefUtils::Dist::Infra::PRODUCT}"` | A string that describes the reboot action. |
| `delay_mins` | `Integer` | `0` | The amount of time (in minutes) to delay a reboot request. |

### Agentless Mode

The **reboot** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **reboot** resource:

        **Reboot a node immediately**

        ```ruby
        reboot 'now' do
          action :nothing
          reason 'Cannot continue Chef run without a reboot.'
          delay_mins 2
        end

        execute 'foo' do
          command '...'
          notifies :reboot_now, 'reboot[now]', :immediately
        end
        ```

        **Reboot a node at the end of a Chef Infra Client run**

        ```ruby
        reboot 'app_requires_reboot' do
          action :request_reboot
          reason 'Need to reboot when the run completes successfully.'
          delay_mins 5
        end
        ```

        **Cancel a reboot**

        ```ruby
        reboot 'cancel_reboot_request' do
          action :cancel
          reason 'Cancel a previous end-of-run reboot request.'
        end
        ```


---

## registry_key resource

[registry_key resource page](registry_key/)

Use the **registry_key** resource to create and delete registry keys in Microsoft Windows. Note: 64-bit versions of Microsoft Windows have a 32-bit compatibility layer in the registry that reflects and redirects certain keys (and their values) into specific locations (or logical views) of the registry hive.  #{ChefUtils::Dist::Infra::PRODUCT} can access any reflected or redirected registry key. The machine architecture of the system on which #{ChefUtils::Dist::Infra::PRODUCT} is running is used as the default (non-redirected) location. Access to the SysWow64 location is redirected must be specified. Typically, this is only necessary to ensure compatibility with 32-bit applications that are running on a 64-bit operating system.  For more information, see: [Registry Reflection](https://docs.microsoft.com/en-us/windows/win32/winprog64/registry-reflection).


> Source: `lib/chef/resource/registry_key.rb`

### Syntax

The full syntax for all of the properties that are available to the **registry_key** resource is:

```ruby
registry_key 'name' do
  key  # String
  values  # [Hash, Array]  # default: []
  recursive  # [TrueClass, FalseClass]  # default: false
  architecture  # Symbol  # default: :machine
  action  :symbol # defaults to :create if not specified
end
```

### Actions

The **registry_key** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` **(default)** |  |
| `:delete` |  |
| `:delete_key` |  |
| `:create_if_missing` |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `key` | `String` |  |  |
| `values` | `[Hash, Array]` | `[]` |  |
| `recursive` | `[TrueClass, FalseClass]` | `false` |  |
| `architecture` | `Symbol` | `:machine` |  |

### Examples

The following examples demonstrate various approaches for using the **registry_key** resource:

      **Create a registry key**

      ```ruby
      registry_key 'HKEY_LOCAL_MACHINE\\path-to-key\\Policies\\System' do
        values [{
          name: 'EnableLUA',
          type: :dword,
          data: 0
        }]
        action :create
      end
      ```

      **Create a registry key with binary data: "\x01\x02\x03"**:

      ```ruby
      registry_key 'HKEY_CURRENT_USER\ChefTest' do
        values [{
          :name => "test",
          :type => :binary,
          :data => [0, 1, 2].map(&:chr).join
        }]

        action :create
      end
      ```

      **Create 32-bit key in redirected wow6432 tree**

      In 64-bit versions of Microsoft Windows, HKEY_LOCAL_MACHINE\SOFTWARE\Example is a re-directed key. In the following examples, because HKEY_LOCAL_MACHINE\SOFTWARE\Example is a 32-bit key, the output will be “Found 32-bit key” if they are run on a version of Microsoft Windows that is 64-bit:

      ```ruby
      registry_key 'HKEY_LOCAL_MACHINE\SOFTWARE\Example' do
        architecture :i386
        recursive true
        action :create
      end
      ```

      **Set proxy settings to be the same as those used by #{ChefUtils::Dist::Infra::PRODUCT}**

      ```ruby
      proxy = URI.parse(Chef::Config[:http_proxy])
      registry_key 'HKCU\Software\Microsoft\path\to\key\Internet Settings' do
        values [{name: 'ProxyEnable', type: :reg_dword, data: 1},
                {name: 'ProxyServer', data: "#{proxy.host}:#{proxy.port}"},
                {name: 'ProxyOverride', type: :reg_string, data: <local>},
               ]
        action :create
      end
      ```

      **Set the name of a registry key to "(Default)"**

      ```ruby
      registry_key 'Set (Default) value' do
        key 'HKLM\Software\Test\Key\Path'
        values [
          {name: '', type: :string, data: 'test'},
        ]
        action :create
      end
      ```

      **Delete a registry key value**

      ```ruby
      registry_key 'HKEY_LOCAL_MACHINE\SOFTWARE\path\to\key\AU' do
        values [{
          name: 'NoAutoRebootWithLoggedOnUsers',
          type: :dword,
          data: ''
          }]
        action :delete
      end
      ```

      Note: If data: is not specified, you get an error: Missing data key in RegistryKey values hash

      **Delete a registry key and its subkeys, recursively**

      ```ruby
      registry_key 'HKCU\SOFTWARE\Policies\path\to\key\Themes' do
        recursive true
        action :delete_key
      end
      ```

      Note: Be careful when using the :delete_key action with the recursive attribute. This will delete the registry key, all of its values and all of the names, types, and data associated with them. This cannot be undone by #{ChefUtils::Dist::Infra::PRODUCT}.


---

## remote_directory resource

[remote_directory resource page](remote_directory/)

Use the **remote_directory** resource to incrementally transfer a directory from a cookbook to a node. The directory that is copied from the cookbook should be located under `COOKBOOK_NAME/files/default/REMOTE_DIRECTORY`. The `remote_directory` resource will obey file specificity.


> Source: `lib/chef/resource/remote_directory.rb`

### Syntax

The full syntax for all of the properties that are available to the **remote_directory** resource is:

```ruby
remote_directory 'name' do
  recursive  # [ TrueClass, FalseClass ]  # default: true
  source  # String  # default: lazy { ::File.basename(path) }
  files_backup  # [ Integer, FalseClass ]  # default: 5
  purge  # [ TrueClass, FalseClass ]  # default: false
  overwrite  # [ TrueClass, FalseClass ]  # default: true
  cookbook  # String
  files_group  # [String, Integer]
  files_mode  # [String, Integer, nil]  # default: lazy { 0644 unless Chef::Platform.windows? }
  files_owner  # [String, Integer]
  action  :symbol # defaults to :create if not specified
end
```

### Actions

The **remote_directory** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` **(default)** |  |
| `:create_if_missing` |  |
| `:delete` |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `recursive` | `[ TrueClass, FalseClass ]` | `true` | Create or delete parent directories recursively. For the owner, group, and mode properties, the value of this attribute applies only to the leaf direc |
| `source` | `String` | `lazy { ::File.basename(path) }` | The base name of the source file (and inferred from the path property). |
| `files_backup` | `[ Integer, FalseClass ]` | `5` | The number of backup copies to keep for files in the directory. |
| `purge` | `[ TrueClass, FalseClass ]` | `false` | Purge extra files found in the target directory. |
| `overwrite` | `[ TrueClass, FalseClass ]` | `true` | Overwrite a file when it is different. |
| `cookbook` | `String` |  | The cookbook in which a file is located (if it is not located in the current cookbook). The default value is the current cookbook. |
| `files_group` | `[String, Integer]` |  |  |
| `files_mode` | `[String, Integer, nil]` | `lazy { 0644 unless Chef::Platform.windows? }` | 0644 on *nix systems |
| `files_owner` | `[String, Integer]` |  |  |

### Agentless Mode

The **remote_directory** resource has **full** support for Agentless Mode.


---

## remote_file resource

[remote_file resource page](remote_file/)

Use the **remote_file** resource to transfer a file from a remote location using file specificity. This resource is similar to the **file** resource. Note: Fetching files from the `files/` directory in a cookbook should be done with the **cookbook_file** resource.

**New in Chef Infra Client 16.2.** *(catalog version; not declared in local source)*

> Source: `lib/chef/resource/remote_file.rb`

### Syntax

The full syntax for all of the properties that are available to the **remote_file** resource is:

```ruby
remote_file 'name' do
  checksum  # String
  use_etag  # [ TrueClass, FalseClass ]  # default: true
  use_last_modified  # [ TrueClass, FalseClass ]  # default: true
  ftp_active_mode  # [ TrueClass, FalseClass ]  # default: false
  headers  # Hash  # default: {}
  show_progress  # [ TrueClass, FalseClass ]  # default: false
  ssl_verify_mode  # Symbol
  remote_user  # String
  remote_domain  # String
  remote_password  # String
  authentication  # Symbol  # default: :remote
  http_options  # Hash  # default: {}
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **remote_file** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create_if_missing` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `checksum` | `String` |  |  |
| `use_etag` | `[ TrueClass, FalseClass ]` | `true` | Enable ETag headers. Set to `false` to disable ETag headers. To use this setting, `use_conditional_get` must also be set to true. |
| `use_last_modified` | `[ TrueClass, FalseClass ]` | `true` | Enable `If-Modified-Since` headers. Set to `false` to disable `If-Modified-Since` headers. To use this setting, `use_conditional_get` must also be set |
| `ftp_active_mode` | `[ TrueClass, FalseClass ]` | `false` | Whether #{ChefUtils::Dist::Infra::PRODUCT} uses active or passive FTP. Set to `true` to use active FTP. |
| `headers` | `Hash` | `{}` |  |
| `show_progress` | `[ TrueClass, FalseClass ]` | `false` | Displays the progress of the file download. |
| `ssl_verify_mode` | `Symbol` |  | Optional property to override SSL policy. If not specified, uses the SSL policy from `config.rb`. |
| `remote_user` | `String` |  |  |
| `remote_domain` | `String` |  |  |
| `remote_password` | `String` |  |  |
| `authentication` | `Symbol` | `:remote` |  |
| `http_options` | `Hash` | `{}` | A Hash of custom HTTP options. For example: `http_options({ http_retry_count: 0, http_retry_delay: 2 })` |

### Agentless Mode

The **remote_file** resource has **full** support for Agentless Mode.

Support was added in Chef Infra Client 16.2.

### Examples

The following examples demonstrate various approaches for using the **remote_file** resource:

      **Download a file without checking the checksum**:

      ```ruby
        remote_file '/tmp/remote.txt' do
          source 'https://example.org/remote.txt'
        end
      ```

      **Download a file with a checksum to validate**:

      ```ruby
        remote_file '/tmp/test_file' do
          source 'http://www.example.com/tempfiles/test_file'
          mode '0755'
          checksum '3a7dac00b1' # A SHA256 (or portion thereof) of the file.
        end
      ```

      **Download a file only if it's not already present**:

      ```ruby
        remote_file '/tmp/remote.txt' do
          source 'https://example.org/remote.txt'
          checksum '3a7dac00b1' # A SHA256 (or portion thereof) of the file.
          action :create_if_missing
        end
      ```

      **Using HTTP Basic Authentication in Headers**:

      ```ruby
        remote_file '/tmp/remote.txt' do
          source 'https://example.org/remote.txt'
          headers('Authorization' => "Basic #{Base64.encode64("USERNAME_VALUE:PASSWORD_VALUE").delete("\n")}")
          checksum '3a7dac00b1' # A SHA256 (or portion thereof) of the file.
          action :create_if_missing
        end
      ```

      **Downloading a file to the Chef file cache dir for execution**:

      ```ruby
        remote_file '#{Chef::Config['file_cache_path']}/install.sh' do
          source 'https://example.org/install.sh'
          action :create_if_missing
        end

        execute '#{Chef::Config['file_cache_path']}/install.sh'
      ```

      **Specify advanced HTTP connection options including Net::HTTP (nethttp) options:**

      ```ruby
        remote_file '/tmp/remote.txt' do
          source 'https://example.org/remote.txt'
          http_options({
            http_retry_delay: 0,
            http_retry_count: 0,
            keepalives: false,
            nethttp: {
              continue_timeout: 5,
              max_retries: 5,
              read_timeout: 5,
              write_timeout: 5,
              ssl_timeout: 5,
            },
          })
        end
      ```


---

## rhsm_errata resource

[rhsm_errata resource page](rhsm_errata/)

Use the **rhsm_errata** resource to install packages associated with a given Red Hat Subscription Manager Errata ID. This is helpful if packages to mitigate a single vulnerability must be installed on your hosts.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/rhsm_errata.rb`

### Syntax

The full syntax for all of the properties that are available to the **rhsm_errata** resource is:

```ruby
rhsm_errata 'name' do
  errata_id  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **rhsm_errata** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` | Install a package for a specific errata ID. |
| `:run` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `errata_id` | `String` |  | An optional property for specifying the errata ID if it differs from the resource block's name. |

### Agentless Mode

The **rhsm_errata** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **rhsm_errata** resource:

        **Install a package from an Errata ID**

        ```ruby
        rhsm_errata 'RHSA:2018-1234'
        ```

        **Specify an Errata ID that differs from the resource name**

        ```ruby
        rhsm_errata 'errata-install'
          errata_id 'RHSA:2018-1234'
        end
        ```


---

## rhsm_errata_level resource

[rhsm_errata_level resource page](rhsm_errata_level/)

Use the **rhsm_errata_level** resource to install all packages of a specified errata level from the Red Hat Subscription Manager. For example, you can ensure that all packages associated with errata marked at a 'Critical' security level are installed.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/rhsm_errata_level.rb`

### Syntax

The full syntax for all of the properties that are available to the **rhsm_errata_level** resource is:

```ruby
rhsm_errata_level 'name' do
  errata_level  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **rhsm_errata_level** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` | Install all packages of the specified errata level. |
| `:run` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `errata_level` | `String` |  | An optional property for specifying the errata level of packages to install if it differs from the resource block's name. |

### Agentless Mode

The **rhsm_errata_level** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **rhsm_errata_level** resource:

        **Specify an errata level that differs from the resource name**

        ```ruby
        rhsm_errata_level 'example_install_moderate' do
          errata_level 'moderate'
        end
        ```


---

## rhsm_register resource

[rhsm_register resource page](rhsm_register/)

Use the **rhsm_register** resource to register a node with the Red Hat Subscription Manager or a local Red Hat Satellite server.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/rhsm_register.rb`

### Syntax

The full syntax for all of the properties that are available to the **rhsm_register** resource is:

```ruby
rhsm_register 'name' do
  activation_key  # [String, Array]
  satellite_host  # String
  organization  # String
  environment  # String
  username  # String
  password  # String
  system_name  # String
  auto_attach  # [TrueClass, FalseClass]  # default: false
  install_katello_agent  # [TrueClass, FalseClass]  # default: true
  force  # [TrueClass, FalseClass]  # default: false
  https_for_ca_consumer  # [TrueClass, FalseClass]  # default: false
  server_url  # String
  base_url  # String
  service_level  # String
  release  # [Float, String]
  not_registered_strings  # [String, Array]
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **rhsm_register** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:register` | Register the node with RHSM. |
| `:nothing` **(default)** |  |
| `:create` |  |
| `:delete` |  |
| `:run` |  |
| `:unregister` | Unregister the node from RHSM. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `activation_key` | `[String, Array]` |  | A string or array of activation keys to use when registering; you must also specify the 'organization' property when using this property. |
| `satellite_host` | `String` |  | The FQDN of the Satellite host to register with. If this property is not specified, the host will register with Red Hat's public RHSM service. |
| `organization` | `String` |  | The organization to use when registering; required when using the 'activation_key' property. |
| `environment` | `String` |  | The environment to use when registering; required when using the username and password properties. |
| `username` | `String` |  | The username to use when registering. This property is not applicable if using an activation key. If specified, password and environment properties ar |
| `password` | `String` |  | The password to use when registering. This property is not applicable if using an activation key. If specified, username and environment are also requ |
| `system_name` | `String` |  | The name of the system to register, defaults to the hostname. |
| `auto_attach` | `[TrueClass, FalseClass]` | `false` | If true, RHSM will attempt to automatically attach the host to applicable subscriptions. It is generally better to use an activation key with the subs |
| `install_katello_agent` | `[TrueClass, FalseClass]` | `true` | If true, the 'katello-agent' RPM will be installed. |
| `force` | `[TrueClass, FalseClass]` | `false` | If true, the system will be registered even if it is already registered. Normally, any register operations will fail if the machine has already been r |
| `https_for_ca_consumer` | `[TrueClass, FalseClass]` | `false` | If true, #{ChefUtils::Dist::Infra::PRODUCT} will fetch the katello-ca-consumer-latest.noarch.rpm from the satellite_host using HTTPS. |
| `server_url` | `String` |  |  |
| `base_url` | `String` |  |  |
| `service_level` | `String` |  | Sets the service level to use for subscriptions on the registering machine. This is only used with the `auto_attach` option. |
| `release` | `[Float, String]` |  |  |
| `not_registered_strings` | `[String, Array]` |  | The string value(s) that when present in the output of the `subscription-manager status` command indicate that the system is not registered. |

### Agentless Mode

The **rhsm_register** resource has **full** support for Agentless Mode.

Support was added in Chef Infra Client 16.5.

### Examples

The following examples demonstrate various approaches for using the **rhsm_register** resource:

        **Register a node with RHSM*

        ```ruby
        rhsm_register 'my-host' do
          activation_key 'ABCD1234'
          organization 'my_org'
        end
        ```


---

## rhsm_repo resource

[rhsm_repo resource page](rhsm_repo/)

Use the **rhsm_repo** resource to enable or disable Red Hat Subscription Manager repositories that are made available via attached subscriptions.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/rhsm_repo.rb`

### Syntax

The full syntax for all of the properties that are available to the **rhsm_repo** resource is:

```ruby
rhsm_repo 'name' do
  repo_name  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **rhsm_repo** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:disable` |  |
| `:enable` | Enable a RHSM repository. |
| `:run` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `repo_name` | `String` |  | An optional property for specifying the repository name if it differs from the resource block's name. |

### Agentless Mode

The **rhsm_repo** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **rhsm_repo** resource:

        **Enable an RHSM repository**

        ```ruby
        rhsm_repo 'rhel-7-server-extras-rpms'
        ```

        **Disable an RHSM repository**

        ```ruby
        rhsm_repo 'rhel-7-server-extras-rpms' do
          action :disable
        end
        ```


---

## rhsm_subscription resource

[rhsm_subscription resource page](rhsm_subscription/)

Use the **rhsm_subscription** resource to add or remove Red Hat Subscription Manager subscriptions from your host. This can be used when a host's activation_key does not attach all necessary subscriptions to your host.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/rhsm_subscription.rb`

### Syntax

The full syntax for all of the properties that are available to the **rhsm_subscription** resource is:

```ruby
rhsm_subscription 'name' do
  pool_id  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **rhsm_subscription** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:attach` | Attach the node to a subscription pool. |
| `:remove` | Remove the node from a subscription pool. |
| `:run` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `pool_id` | `String` |  | An optional property for specifying the Pool ID if it differs from the resource block's name. |

### Agentless Mode

The **rhsm_subscription** resource has **full** support for Agentless Mode.


---

## route resource

[route resource page](route/)

Use the **route** resource to manage the system routing table in a Linux environment.

**New in Chef Infra Client 14.0.** *(catalog version; not declared in local source)*

> Source: `lib/chef/resource/route.rb`

### Syntax

The full syntax for all of the properties that are available to the **route** resource is:

```ruby
route 'name' do
  target  # String
  comment  # [String, nil]
  metric  # [Integer, nil]
  netmask  # [String, nil]
  gateway  # [String, nil]
  device  # [String, nil]
  route_type  # [Symbol, String]  # default: :host
  action  :symbol # defaults to :add if not specified
end
```

### Actions

The **route** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:add` **(default)** |  |
| `:delete` |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `target` | `String` |  | The IP address of the target route. |
| `comment` | `[String, nil]` |  | Add a comment for the route. |
| `metric` | `[Integer, nil]` |  | The route metric value. |
| `netmask` | `[String, nil]` |  | The decimal representation of the network mask. For example: `255.255.255.0`. |
| `gateway` | `[String, nil]` |  | The gateway for the route. |
| `device` | `[String, nil]` |  | The network interface to which the route applies. |
| `route_type` | `[Symbol, String]` | `:host` |  |

### Agentless Mode

The **route** resource has **full** support for Agentless Mode.

Support was added in Chef Infra Client 14.0.


---

## rpm_package resource

[rpm_package resource page](rpm_package/)

Use the **rpm_package** resource to manage packages using the RPM Package Manager.

**New in Chef Infra Client 19.0.** *(catalog version; not declared in local source)*

> Source: `lib/chef/resource/rpm_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **rpm_package** resource is:

```ruby
rpm_package 'name' do
  allow_downgrade  # [ TrueClass, FalseClass ]  # default: true
  package_name  # String
  version  # String
  environment  # Hash  # default: {}
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **rpm_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:upgrade` |  |
| `:remove` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `allow_downgrade` | `[ TrueClass, FalseClass ]` | `true` | Allow downgrading a package to satisfy requested version requirements. |
| `package_name` | `String` |  | An optional property to set the package name if it differs from the resource block's name. |
| `version` | `String` |  | The version of a package to be installed or upgraded. |
| `environment` | `Hash` | `{}` | A Hash of environment variables in the form of {'ENV_VARIABLE' => 'VALUE'} to be set before running the command. |

### Agentless Mode

The **rpm_package** resource has **full** support for Agentless Mode.

Support was added in Chef Infra Client 19.0.


---

## ruby resource

[ruby resource page](ruby/)

Use the **ruby** resource to execute scripts using the Ruby interpreter. This resource may also use any of the actions and properties that are available to the **execute** resource. Commands that are executed with this resource are (by their nature) not idempotent, as they are typically unique to the environment in which they are run. Use `not_if` and `only_if` to guard this resource for idempotence.


> Source: `lib/chef/resource/ruby.rb`

### Syntax

The full syntax for all of the properties that are available to the **ruby** resource is:

```ruby
ruby 'name' do
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **ruby** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

No resource-specific properties.

> This resource inherits all properties from the `execute` resource via the `script` base class, including:
> `code` (required), `cwd`, `environment`, `flags`, `group`, `input`, `interpreter`,
> `live_stream`, `login`, `password`, `returns`, `timeout`, `user`, `domain`, `elevated`.

### Agentless Mode

The **ruby** resource has **full** support for Agentless Mode.


---

## ruby_block resource

[ruby_block resource page](ruby_block/)

Use the **ruby_block** resource to execute Ruby code during a #{ChefUtils::Dist::Infra::PRODUCT} run. Ruby code in the `ruby_block` resource is evaluated with other resources during convergence, whereas Ruby code outside of a `ruby_block` resource is evaluated before other resources, as the recipe is compiled.


> Source: `lib/chef/resource/ruby_block.rb`

### Syntax

The full syntax for all of the properties that are available to the **ruby_block** resource is:

```ruby
ruby_block 'name' do
  block_name  # String
  action  :symbol # defaults to :run if not specified
end
```

### Actions

The **ruby_block** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:run` **(default)** |  |
| `:nothing` |  |
| `:create` |  |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `block_name` | `String` |  |  |

### Agentless Mode

The **ruby_block** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **ruby_block** resource:

        **Reload Chef Infra Client configuration data**

        ```ruby
        ruby_block 'reload_client_config' do
          block do
            Chef::Config.from_file('/etc/chef/client.rb')
          end
          action :run
        end
        ```

        **Run a block on a particular platform**

        The following example shows how an if statement can be used with the `windows?` method in the Chef Infra Language to run code specific to Microsoft Windows. The code is defined using the ruby_block resource:

        ```ruby
        if windows?
          ruby_block 'copy libmysql.dll into ruby path' do
            block do
              require 'fileutils'
              FileUtils.cp "#{node['mysql']['client']['lib_dir']}\\libmysql.dll",
                node['mysql']['client']['ruby_dir']
            end
            not_if { ::File.exist?("#{node['mysql']['client']['ruby_dir']}\\libmysql.dll") }
          end
        end
        ```

        **Stash a file in a data bag**

        The following example shows how to use the ruby_block resource to stash a BitTorrent file in a data bag so that it can be distributed to nodes in the organization.

        ```ruby
        ruby_block 'share the torrent file' do
          block do
            f = File.open(node['bittorrent']['torrent'],'rb')
            #read the .torrent file and base64 encode it
            enc = Base64.encode64(f.read)
            data = {
              'id'=>bittorrent_item_id(node['bittorrent']['file']),
              'seed'=>node.ipaddress,
              'torrent'=>enc
            }
            item = Chef::DataBagItem.new
            item.data_bag('bittorrent')
            item.raw_data = data
            item.save
          end
          action :nothing
          subscribes :create, "bittorrent_torrent[#{node['bittorrent']['torrent']}]", :immediately
        end
        ```

        **Update the /etc/hosts file**

        The following example shows how the ruby_block resource can be used to update the /etc/hosts file:

        ```ruby
        ruby_block 'edit etc hosts' do
          block do
            rc = Chef::Util::FileEdit.new('/etc/hosts')
            rc.search_file_replace_line(/^127\.0\.0\.1 localhost$/,
              '127.0.0.1 #{new_fqdn} #{new_hostname} localhost')
            rc.write_file
          end
        end
        ```

        **Set environment variables**

        The following example shows how to use variables within a Ruby block to set environment variables using rbenv.

        ```ruby
        node.override[:rbenv][:root] = rbenv_root
        node.override[:ruby_build][:bin_path] = rbenv_binary_path

        ruby_block 'initialize' do
          block do
            ENV['RBENV_ROOT'] = node[:rbenv][:root]
            ENV['PATH'] = "#{node[:rbenv][:root]}/bin:#{node[:ruby_build][:bin_path]}:#{ENV['PATH']}"
          end
        end
        ```

        **Call methods in a gem**

        The following example shows how to call methods in gems not shipped in Chef Infra Client

        ```ruby
        chef_gem 'mongodb'

        ruby_block 'config_replicaset' do
          block do
            MongoDB.configure_replicaset(node, replicaset_name, rs_nodes)
          end
          action :run
        end
        ```


---

## selinux_boolean resource

[selinux_boolean resource page](selinux_boolean/)

Use **selinux_boolean** resource to set SELinux boolean values.

**New in Chef Infra Client 18.0.**

> Source: `lib/chef/resource/selinux_boolean.rb`

### Syntax

The full syntax for all of the properties that are available to the **selinux_boolean** resource is:

```ruby
selinux_boolean 'name' do
  boolean  # String
  value  # [Integer, String, true, false]
  persistent  # [true, false]  # default: true
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **selinux_boolean** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:set` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `boolean` | `String` |  | SELinux boolean to set. |
| `value` | `[Integer, String, true, false]` |  | SELinux boolean value. |
| `persistent` | `[true, false]` | `true` | Set to true for value setting to survive reboot. |

### Agentless Mode

The **selinux_boolean** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **selinux_boolean** resource:

      **Set ssh_keysign to true**:

      ```ruby
      selinux_boolean 'ssh_keysign' do
        value true
      end
      ```

      **Set ssh_sysadm_login to 'on'**:

      ```ruby
      selinux_boolean 'ssh_sysadm_login' do
        value 'on'
      end
      ```


---

## selinux_fcontext resource

[selinux_fcontext resource page](selinux_fcontext/)

Use the **selinux_fcontext** resource to set the SELinux context of files using the `semanage fcontext` command.

**New in Chef Infra Client 18.0.**

> Source: `lib/chef/resource/selinux_fcontext.rb`

### Syntax

The full syntax for all of the properties that are available to the **selinux_fcontext** resource is:

```ruby
selinux_fcontext 'name' do
  file_spec  # String
  secontext  # String
  file_type  # String  # default: "a"
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **selinux_fcontext** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:manage` | Assign the file to the right context regardless of previous state. |
| `:addormodify` | Assign the file context if not set. Update the file context if previously set. |
| `:add` | Assign the file context if not set. |
| `:modify` | Update the file context if previously set. |
| `:delete` | Removes the file context if set.  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `file_spec` | `String` |  | Path to or regex matching the files or directories to label. |
| `secontext` | `String` |  | SELinux context to assign. |
| `file_type` | `String` | `"a"` | The type of the file being labeled. |

### Agentless Mode

The **selinux_fcontext** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **selinux_fcontext** resource:

      **Allow http servers (e.g. nginx/apache) to modify moodle files**:

      ```ruby
      selinux_fcontext '/var/www/moodle(/.*)?' do
        secontext 'httpd_sys_rw_content_t'
      end
      ```

      **Adapt a symbolic link**:

      ```ruby
      selinux_fcontext '/var/www/symlink_to_webroot' do
        secontext 'httpd_sys_rw_content_t'
        file_type 'l'
      end
      ```


---

## selinux_install resource

[selinux_install resource page](selinux_install/)

Use **selinux_install** resource to encapsulates the set of selinux packages to install in order to manage selinux. It also ensures the directory `/etc/selinux` is created.

**New in Chef Infra Client 18.0.**

> Source: `lib/chef/resource/selinux_install.rb`

### Syntax

The full syntax for all of the properties that are available to the **selinux_install** resource is:

```ruby
selinux_install 'name' do
  packages  # [String, Array]  # default: lazy { default_install_packages }
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **selinux_install** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:remove` |  |
| `:install` | Install required packages. |
| `:create` |  |
| `:upgrade` | Upgrade required packages. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `packages` | `[String, Array]` | `lazy { default_install_packages }` | SELinux packages for system. |

### Agentless Mode

The **selinux_install** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **selinux_install** resource:

      **Default installation**:

      ```ruby
      selinux_install 'example'
      ```

      **Install with custom packages**:

      ```ruby
      selinux_install 'example' do
        packages %w(policycoreutils selinux-policy selinux-policy-targeted)
      end
      ```

      **Uninstall**
      ```ruby
      selinux_install 'example' do
        action :remove
      end
      ```


---

## selinux_login resource

[selinux_login resource page](selinux_login/)

Use the **selinux_login** resource to add, update, or remove SELinux user to OS login mappings.

**New in Chef Infra Client 18.1.**

> Source: `lib/chef/resource/selinux_login.rb`

### Syntax

The full syntax for all of the properties that are available to the **selinux_login** resource is:

```ruby
selinux_login 'name' do
  login  # String
  user  # String
  range  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **selinux_login** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:manage` | Sets the SELinux login mapping to the desired settings regardless of previous state. |
| `:add` | Creates the SELinux login mapping if not previously created. |
| `:modify` | Updates the SELinux login mapping if previously created. |
| `:delete` | Removes the SELinux login mapping if previously created. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `login` | `String` |  | An optional property to set the OS user login value if it differs from the resource block's name. |
| `user` | `String` |  | SELinux user to be mapped. |
| `range` | `String` |  | MLS/MCS security range for the SELinux user. |

### Agentless Mode

The **selinux_login** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **selinux_login** resource:

      **Manage test OS user mapping with a range of s0 and associated SELinux user test_u**:

      ```ruby
      selinux_login 'test' do
        user 'test_u'
        range 's0'
      end
      ```


---

## selinux_module resource

[selinux_module resource page](selinux_module/)

Use **selinux_module** module resource to create an SELinux policy module from a cookbook file or content provided as a string.

**New in Chef Infra Client 18.0.**

> Source: `lib/chef/resource/selinux_module.rb`

### Syntax

The full syntax for all of the properties that are available to the **selinux_module** resource is:

```ruby
selinux_module 'name' do
  module_name  # String
  source  # String
  content  # String
  cookbook  # String
  base_dir  # String  # default: "/etc/selinux/local"
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **selinux_module** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` |  |
| `:nothing` **(default)** |  |
| `:delete` | Remove module source files from `/etc/selinux/local`. |
| `:install` | Install a compiled module into the system. |
| `:remove` | Remove a module from the system. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `module_name` | `String` |  | Override the module name. |
| `source` | `String` |  | Module source file name. |
| `content` | `String` |  | Module source as String. |
| `cookbook` | `String` |  | Cookbook to source from module source file from(if it is not located in the current cookbook). The default value is the current cookbook. |
| `base_dir` | `String` | `"/etc/selinux/local"` | Directory to create module source file in. |

### Agentless Mode

The **selinux_module** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **selinux_module** resource:

      **Creating SElinux module from .te file located at `files` directory of your cookbook.**:

      ```ruby
      selinux_module 'my_policy_module' do
        source 'my_policy_module.te'
        action :create
      end
      ```


---

## selinux_permissive resource

[selinux_permissive resource page](selinux_permissive/)

Use the **selinux_permissive** resource to allow some domains to misbehave without stopping them. This is not as good as setting specific policies, but better than disabling SELinux entirely.

**New in Chef Infra Client 18.0.**

> Source: `lib/chef/resource/selinux_permissive.rb`

### Syntax

The full syntax for all of the properties that are available to the **selinux_permissive** resource is:

```ruby
selinux_permissive 'name' do
  context  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **selinux_permissive** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:add` | Add a permissive, unless already set. |
| `:delete` | Remove a permissive, if set. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `context` | `String` |  | The SELinux context to permit. |

### Agentless Mode

The **selinux_permissive** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **selinux_permissive** resource:

      **Disable enforcement on Apache**:

      ```ruby
      selinux_permissive 'httpd_t' do
        notifies :restart, 'service[httpd]'
      end
      ```


---

## selinux_port resource

[selinux_port resource page](selinux_port/)

Use the **selinux_port** resource to assign a network port to a specific SELinux context. For example, running a web server on a non-standard port.

**New in Chef Infra Client 18.0.**

> Source: `lib/chef/resource/selinux_port.rb`

### Syntax

The full syntax for all of the properties that are available to the **selinux_port** resource is:

```ruby
selinux_port 'name' do
  port  # [Integer, String]
  protocol  # String
  secontext  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **selinux_port** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:manage` | Assign the port to the right context regardless of previous state. |
| `:addormodify` | Assigns the port context if not set. Updates the port context if previously set. |
| `:add` | Assign the port context if not set. |
| `:modify` | Update the port context if previously set. |
| `:delete` | Removes the port context if set. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `port` | `[Integer, String]` |  | Port to modify. |
| `protocol` | `String` |  | Protocol to modify. |
| `secontext` | `String` |  | SELinux context to assign to the port. |

### Agentless Mode

The **selinux_port** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **selinux_port** resource:

      **Allow nginx/apache to bind to port 5678 by giving it the http_port_t context**:

      ```ruby
      selinux_port '5678' do
       protocol 'tcp'
       secontext 'http_port_t'
      end
      ```


---

## selinux_state resource

[selinux_state resource page](selinux_state/)

Use **selinux_state** resource to manages the SELinux state on the system. It does this by using the `setenforce` command and rendering the `/etc/selinux/config` file from a template.

**New in Chef Infra Client 18.0.**

> Source: `lib/chef/resource/selinux_state.rb`

### Syntax

The full syntax for all of the properties that are available to the **selinux_state** resource is:

```ruby
selinux_state 'name' do
  config_file  # String  # default: "/etc/selinux/config"
  persistent  # [true, false]  # default: true
  policy  # String  # default: lazy { default_policy_platform }
  automatic_reboot  # [true, false, Symbol]  # default: false
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **selinux_state** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:permissive` |  |
| `:enforcing` |  |
| `:disabled` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `config_file` | `String` | `"/etc/selinux/config"` | Path to SELinux config file on disk. |
| `persistent` | `[true, false]` | `true` | Set the status update in the SELinux configuration file. |
| `policy` | `String` | `lazy { default_policy_platform }` | SELinux policy type. |
| `automatic_reboot` | `[true, false, Symbol]` | `false` | Perform an automatic node reboot if required for state change. |

### Agentless Mode

The **selinux_state** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **selinux_state** resource:

      **Set SELinux state to permissive**:

      ```ruby
      selinux_state 'permissive' do
        action :permissive
      end
      ```

      **Set SELinux state to enforcing**:

      ```ruby
      selinux_state 'enforcing' do
        action :enforcing
      end
      ```

      **Set SELinux state to disabled**:
      ```ruby
      selinux_state 'disabled' do
        action :disabled
      end
      ```


---

## selinux_user resource

[selinux_user resource page](selinux_user/)

Use the **selinux_user** resource to add, update, or remove SELinux users.

**New in Chef Infra Client 18.1.**

> Source: `lib/chef/resource/selinux_user.rb`

### Syntax

The full syntax for all of the properties that are available to the **selinux_user** resource is:

```ruby
selinux_user 'name' do
  user  # String
  level  # String
  range  # String
  roles  # Array
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **selinux_user** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:manage` | Sets the SELinux user to the desired settings regardless of previous state. |
| `:add` | Creates the SELinux user if not previously created. |
| `:modify` | Updates the SELinux user if previously created. |
| `:delete` | Removes the SELinux user if previously created. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `user` | `String` |  | An optional property to set the SELinux user value if it differs from the resource block's name. |
| `level` | `String` |  | MLS/MCS security level for the SELinux user. |
| `range` | `String` |  | MLS/MCS security range for the SELinux user. |
| `roles` | `Array` |  | Associated SELinux roles for the user. |

### Agentless Mode

The **selinux_user** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **selinux_user** resource:

      **Manage test_u SELinux user with a level and range of s0 and roles sysadm_r and staff_r**:

      ```ruby
      selinux_user 'test_u' do
        level 's0'
        range 's0'
        roles %w(sysadm_r staff_r)
      end
      ```


---

## service resource

[service resource page](service/)

Use the **service** resource to manage a service.

**New in Chef Infra Client 15.1.** *(catalog version; not declared in local source)*

> Source: `lib/chef/resource/service.rb`

### Syntax

The full syntax for all of the properties that are available to the **service** resource is:

```ruby
service 'name' do
  supports  # Hash  # default: { restart: nil
  service_name  # String
  pattern  # String  # default: lazy { service_name }
  start_command  # [ String, nil, FalseClass ]
  stop_command  # [ String, nil, FalseClass ]
  status_command  # [ String, nil, FalseClass ]
  restart_command  # [ String, nil, FalseClass ]
  reload_command  # [ String, nil, FalseClass ]
  init_command  # String
  enabled  # [ TrueClass, FalseClass ]
  running  # [ TrueClass, FalseClass ]
  masked  # [ TrueClass, FalseClass ]
  static  # [ TrueClass, FalseClass ]
  indirect  # [ TrueClass, FalseClass ]
  options  # [ Array, String ]
  priority  # [ Integer, String, Hash ]
  timeout  # Integer  # default: 900
  parameters  # Hash
  run_levels  # Array
  user  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **service** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:enable` |  |
| `:disable` |  |
| `:start` |  |
| `:stop` |  |
| `:restart` |  |
| `:reload` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `supports` | `Hash` | `{ restart: nil` |  |
| `service_name` | `String` |  | An optional property to set the service name if it differs from the resource block's name. |
| `pattern` | `String` | `lazy { service_name }` | The pattern to look for in the process table. |
| `start_command` | `[ String, nil, FalseClass ]` |  | The command used to start a service. |
| `stop_command` | `[ String, nil, FalseClass ]` |  | The command used to stop a service. |
| `status_command` | `[ String, nil, FalseClass ]` |  | The command used to check the run status for a service. |
| `restart_command` | `[ String, nil, FalseClass ]` |  | The command used to restart a service. |
| `reload_command` | `[ String, nil, FalseClass ]` |  | The command used to tell a service to reload its configuration. |
| `init_command` | `String` |  |  |
| `enabled` | `[ TrueClass, FalseClass ]` |  |  |
| `running` | `[ TrueClass, FalseClass ]` |  |  |
| `masked` | `[ TrueClass, FalseClass ]` |  |  |
| `static` | `[ TrueClass, FalseClass ]` |  |  |
| `indirect` | `[ TrueClass, FalseClass ]` |  |  |
| `options` | `[ Array, String ]` |  | Solaris platform only. Options to pass to the service command. See the svcadm manual for details of possible options. |
| `priority` | `[ Integer, String, Hash ]` |  |  |
| `timeout` | `Integer` | `900` | The amount of time (in seconds) to wait before timing out. |
| `parameters` | `Hash` |  | Upstart only: A hash of parameters to pass to the service command for use in the service definition. |
| `run_levels` | `Array` |  | RHEL platforms only: Specific run_levels the service will run under. |
| `user` | `String` |  | systemd only: A username to run the service under. |

### Agentless Mode

The **service** resource has **full** support for Agentless Mode.

Support was added in Chef Infra Client 15.1.


---

## smartos_package resource

[smartos_package resource page](smartos_package/)

Use the **smartos_package** resource to manage packages for the SmartOS platform.


> Source: `lib/chef/resource/smartos_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **smartos_package** resource is:

```ruby
smartos_package 'name' do
  package_name  # String
  version  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **smartos_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:upgrade` |  |
| `:remove` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `package_name` | `String` |  | An optional property to set the package name if it differs from the resource block's name. |
| `version` | `String` |  | The version of a package to be installed or upgraded. |

### Agentless Mode

The **smartos_package** resource has **full** support for Agentless Mode.


---

## snap_package resource

[snap_package resource page](snap_package/)

Use the **snap_package** resource to manage snap packages on supported Linux distributions.

**New in Chef Infra Client 15.0.**

> Source: `lib/chef/resource/snap_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **snap_package** resource is:

```ruby
snap_package 'name' do
  channel  # [String, nil]  # default: "latest/stable"
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **snap_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:upgrade` |  |
| `:install` |  |
| `:remove` |  |
| `:purge` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `channel` | `[String, nil]` | `"latest/stable"` | The desired channel. For example: `latest/stable`. `latest/beta/fix-test-062`, or `0.x/edge`. If nil, the resource will install the snap's default ver |

### Agentless Mode

The **snap_package** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **snap_package** resource:

      **Install a package**

      ```ruby
      snap_package 'hello'
      ```

      **Upgrade a package**

      ```ruby
      snap_package 'hello' do
        action :upgrade
      end
      ```

      **Install a package from a specific channel track**

      ```ruby
      snap_package 'firefox' do
        channel 'esr/stable'
        action :upgrade
      end
      ```

      **Install a package with classic confinement**

      ```ruby
      snap_package 'hello' do
        options 'classic'
      end
      ```


---

## solaris_package resource

[solaris_package resource page](solaris_package/)

Use the **solaris_package** resource to manage packages on the Solaris platform.


> Source: `lib/chef/resource/solaris_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **solaris_package** resource is:

```ruby
solaris_package 'name' do
  package_name  # String
  version  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **solaris_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:upgrade` |  |
| `:remove` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `package_name` | `String` |  | An optional property to set the package name if it differs from the resource block's name. |
| `version` | `String` |  | The version of a package to be installed or upgraded. |

### Agentless Mode

The **solaris_package** resource has **full** support for Agentless Mode.


---

## ssh_known_hosts_entry resource

[ssh_known_hosts_entry resource page](ssh_known_hosts_entry/)

Use the **ssh_known_hosts_entry** resource to add an entry for the specified host in /etc/ssh/ssh_known_hosts or a user's known hosts file if specified.

**New in Chef Infra Client 14.3.**

> Source: `lib/chef/resource/ssh_known_hosts_entry.rb`

### Syntax

The full syntax for all of the properties that are available to the **ssh_known_hosts_entry** resource is:

```ruby
ssh_known_hosts_entry 'name' do
  host  # String
  key  # String
  key_type  # String  # default: "rsa"
  port  # Integer  # default: 22
  timeout  # Integer  # default: 30
  mode  # String  # default: "0644"
  owner  # [String, Integer]  # default: "root"
  group  # [String, Integer]  # default: lazy { node["root_group"] }
  hash_entries  # [TrueClass, FalseClass]  # default: false
  file_location  # String  # default: "/etc/ssh/ssh_known_hosts"
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **ssh_known_hosts_entry** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` | Create an entry in the ssh_known_hosts file. |
| `:nothing` **(default)** |  |
| `:flush` | Immediately flush the entries to the config file. Without this the actual writing of the file is delayed in the #{ChefUtils::Dist::Infra::PRODUCT} run so all entries can be accumulated before writing the file out. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `host` | `String` |  | The host to add to the known hosts file. |
| `key` | `String` |  | An optional key for the host. If not provided this will be automatically determined. |
| `key_type` | `String` | `"rsa"` | The type of key to store. |
| `port` | `Integer` | `22` | The server port that the ssh-keyscan command will use to gather the public key. |
| `timeout` | `Integer` | `30` | The timeout in seconds for ssh-keyscan. |
| `mode` | `String` | `"0644"` | The file mode for the ssh_known_hosts file. |
| `owner` | `[String, Integer]` | `"root"` | The file owner for the ssh_known_hosts file. |
| `group` | `[String, Integer]` | `lazy { node["root_group"] }` | The file group for the ssh_known_hosts file. |
| `hash_entries` | `[TrueClass, FalseClass]` | `false` | Hash the hostname and addresses in the ssh_known_hosts file for privacy. |
| `file_location` | `String` | `"/etc/ssh/ssh_known_hosts"` | The location of the ssh known hosts file. Change this to set a known host file for a particular user. |

### Agentless Mode

The **ssh_known_hosts_entry** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **ssh_known_hosts_entry** resource:

      **Add a single entry for github.com with the key auto detected**

      ```ruby
      ssh_known_hosts_entry 'github.com'
      ```

      **Add a single entry with your own provided key**

      ```ruby
      ssh_known_hosts_entry 'github.com' do
        key 'node.example.com ssh-rsa ...'
      end
      ```


---

## subversion resource

Use the **subversion** resource to manage source control resources that exist in a Subversion repository. Warning: The subversion resource has known bugs and may not work as expected. For more information see Chef GitHub issues, particularly [#4050](https://github.com/chef/chef/issues/4050) and [#4257](https://github.com/chef/chef/issues/4257).


> Source: `lib/chef/resource/scm\subversion.rb`

### Syntax

The full syntax for all of the properties that are available to the **subversion** resource is:

```ruby
subversion 'name' do
  svn_arguments  # [String, nil, FalseClass]  # default: "--no-auth-cache"
  svn_info_args  # [String, nil, FalseClass]  # default: "--no-auth-cache"
  svn_binary  # String
  svn_username  # String
  svn_password  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **subversion** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:sync` |  |
| `:force_export` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `svn_arguments` | `[String, nil, FalseClass]` | `"--no-auth-cache"` | The extra arguments that are passed to the Subversion command. |
| `svn_info_args` | `[String, nil, FalseClass]` | `"--no-auth-cache"` | Use when the `svn info` command is used by #{ChefUtils::Dist::Infra::PRODUCT} and arguments need to be passed. The `svn_arguments` command does not wo |
| `svn_binary` | `String` |  | The location of the svn binary. |
| `svn_username` | `String` |  | The user name for a user that has access to the Subversion repository. |
| `svn_password` | `String` |  | The password for a user that has access to the Subversion repository. |

### Agentless Mode

The **subversion** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **subversion** resource:

      **Get the latest version of an application**

      ```ruby
      subversion 'CouchDB Edge' do
        repository 'http://svn.apache.org/repos/asf/couchdb/trunk'
        revision 'HEAD'
        destination '/opt/my_sources/couch'
        action :sync
      end
      ```


---

## sudo resource

[sudo resource page](sudo/)

Use the **sudo** resource to add or remove individual sudo entries using sudoers.d files." \

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/sudo.rb`

### Syntax

The full syntax for all of the properties that are available to the **sudo** resource is:

```ruby
sudo 'name' do
  filename  # String
  users  # [String, Array]  # default: []
  groups  # [String, Array]  # default: []
  commands  # Array  # default: ["ALL"]
  host  # String  # default: "ALL"
  runas  # String  # default: "ALL"
  nopasswd  # [TrueClass, FalseClass]  # default: false
  noexec  # [TrueClass, FalseClass]  # default: false
  template  # String
  variables  # [Hash, nil]  # default: nil
  defaults  # Array  # default: []
  command_aliases  # Array  # default: []
  setenv  # [TrueClass, FalseClass]  # default: false
  env_keep_add  # Array  # default: []
  env_keep_subtract  # Array  # default: []
  visudo_path  # String
  visudo_binary  # String  # default: "/usr/sbin/visudo"
  config_prefix  # String  # default: lazy { platform_config_prefix }
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **sudo** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` | Create a single sudoers configuration file in the `sudoers.d` directory. |
| `:install` |  |
| `:remove` |  |
| `:delete` | Remove a sudoers configuration file from the `sudoers.d` directory. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `filename` | `String` |  | The name of the sudoers.d file if it differs from the name of the resource block |
| `users` | `[String, Array]` | `[]` | User(s) to provide sudo privileges to. This property accepts either an array or a comma separated list. |
| `groups` | `[String, Array]` | `[]` | Group(s) to provide sudo privileges to. This property accepts either an array or a comma separated list. Leading % on group names is optional. |
| `commands` | `Array` | `["ALL"]` | An array of full paths to commands and/or command aliases this sudoer can execute. |
| `host` | `String` | `"ALL"` | The host to set in the sudo configuration. |
| `runas` | `String` | `"ALL"` | User that the command(s) can be run as. |
| `nopasswd` | `[TrueClass, FalseClass]` | `false` | Allow sudo to be run without specifying a password. |
| `noexec` | `[TrueClass, FalseClass]` | `false` | Prevent commands from shelling out. |
| `template` | `String` |  | The name of the erb template in your cookbook, if you wish to supply your own template. |
| `variables` | `[Hash, nil]` | `nil` | The variables to pass to the custom template. This property is ignored if not using a custom template. |
| `defaults` | `Array` | `[]` | An array of defaults for the user/group. |
| `command_aliases` | `Array` | `[]` |  |
| `setenv` | `[TrueClass, FalseClass]` | `false` | Determines whether or not to permit preservation of the environment with `sudo -E`. |
| `env_keep_add` | `Array` | `[]` | An array of strings to add to `env_keep`. |
| `env_keep_subtract` | `Array` | `[]` | An array of strings to remove from `env_keep`. |
| `visudo_path` | `String` |  |  |
| `visudo_binary` | `String` | `"/usr/sbin/visudo"` | The path to visudo for configuration verification. |
| `config_prefix` | `String` | `lazy { platform_config_prefix }` | The directory that contains the sudoers configuration file. |

### Agentless Mode

The **sudo** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **sudo** resource:

      **Grant a user sudo privileges for any command**

      ```ruby
      sudo 'admin' do
        user 'admin'
      end
      ```

      **Grant a user and groups sudo privileges for any command**

      ```ruby
      sudo 'admins' do
        users 'bob'
        groups 'sysadmins, superusers'
      end
      ```

      **Grant passwordless sudo privileges for specific commands**

      ```ruby
      sudo 'passwordless-access' do
        commands ['/bin/systemctl restart httpd', '/bin/systemctl restart mysql']
        nopasswd true
      end
      ```

      **Create command aliases and assign them to a group**

      ```ruby
      sudo 'webteam' do
        command_aliases [
          {
            'name': 'WEBTEAM_SYSTEMD_JBOSS',
            'command_list': [
              '/usr/bin/systemctl start eap7-standalone.service',
              '/usr/bin/systemctl start jbcs-httpd24-httpd.service', \
              '/usr/bin/systemctl stop eap7-standalone.service', \
              '/usr/bin/systemctl stop jbcs-httpd24-httpd.service', \
              '/usr/bin/systemctl restart eap7-standalone.service', \
              '/usr/bin/systemctl restart jbcs-httpd24-httpd.service', \
              '/usr/bin/systemctl --full edit eap7-standalone.service', \
              '/usr/bin/systemctl --full edit jbcs-httpd24-httpd.service', \
              '/usr/bin/systemctl daemon-reload',
            ]
          },
          {
            'name': 'GENERIC_SYSTEMD',
            'command_list': [
              '/usr/sbin/systemctl list-unit-files',
              '/usr/sbin/systemctl list-timers', \
              '/usr/sbin/systemctl is-active *', \
              '/usr/sbin/systemctl is-enabled *',
              ]
          }
        ]
        nopasswd true
        users '%webteam'
        commands [ 'WEBTEAM_SYSTEMD_JBOSS', 'GENERIC_SYSTEMD' ]
      end
      ```


---

## swap_file resource

[swap_file resource page](swap_file/)

Use the **swap_file** resource to create or delete swap files on Linux systems, and optionally to manage the swappiness configuration for a host.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/swap_file.rb`

### Syntax

The full syntax for all of the properties that are available to the **swap_file** resource is:

```ruby
swap_file 'name' do
  path  # String
  size  # Integer
  persist  # [TrueClass, FalseClass]  # default: false
  timeout  # Integer  # default: 600
  swappiness  # Integer
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **swap_file** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:remove` |  |
| `:create` | Create a swapfile. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `path` | `String` |  | The path where the swap file will be created on the system if it differs from the resource block's name. |
| `size` | `Integer` |  | The size (in MBs) of the swap file. |
| `persist` | `[TrueClass, FalseClass]` | `false` | Persist the swapon. |
| `timeout` | `Integer` | `600` | Timeout for `dd` / `fallocate` commands. |
| `swappiness` | `Integer` |  | The swappiness value to set on the system. |

### Agentless Mode

The **swap_file** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **swap_file** resource:

      **Create a swap file**

      ```ruby
      swap_file '/dev/sda1' do
        size 1024
      end
      ```

      **Remove a swap file**

      ```ruby
      swap_file '/dev/sda1' do
        action :remove
      end
      ```


---

## sysctl resource

[sysctl resource page](sysctl/)

Use the **sysctl** resource to set or remove kernel parameters using the `sysctl` command line tool and configuration files in the system's `sysctl.d` directory. Configuration files managed by this resource are named `99-chef-KEYNAME.conf`.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/sysctl.rb`

### Syntax

The full syntax for all of the properties that are available to the **sysctl** resource is:

```ruby
sysctl 'name' do
  key  # String
  ignore_error  # [TrueClass, FalseClass]  # default: false
  value  # [Array, String, Integer, Float]
  comment  # [Array, String]  # default: []
  conf_dir  # String  # default: "/etc/sysctl.d"
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **sysctl** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:remove` |  |
| `:apply` | Set the kernel parameter and update the `sysctl` settings. |
| `:run` |  |
| `:delete` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `key` | `String` |  | The kernel parameter key in dotted format if it differs from the resource block's name. |
| `ignore_error` | `[TrueClass, FalseClass]` | `false` | Ignore any errors when setting the value on the command line. |
| `value` | `[Array, String, Integer, Float]` |  | The value to set. |
| `comment` | `[Array, String]` | `[]` | Comments, placed above the resource setting in the generated file. For multi-line comments, use an array of strings, one per line. |
| `conf_dir` | `String` | `"/etc/sysctl.d"` | The configuration directory to write the config to. |

### Agentless Mode

The **sysctl** resource has **full** support for Agentless Mode.

Support was added in Chef Infra Client 15.8.

### Examples

The following examples demonstrate various approaches for using the **sysctl** resource:

      **Set vm.swappiness**:

      ```ruby
      sysctl 'vm.swappiness' do
        value 19
      end
      ```

      **Remove kernel.msgmax**:

      **Note**: This only removes the sysctl.d config for kernel.msgmax. The value will be set back to the kernel default value.

      ```ruby
      sysctl 'kernel.msgmax' do
        action :remove
      end
      ```

      **Adding Comments to sysctl configuration files**:

      ```ruby
      sysctl 'vm.swappiness' do
        value 19
        comment "define how aggressively the kernel will swap memory pages."
      end
      ```

      This produces /etc/sysctl.d/99-chef-vm.swappiness.conf as follows:

      ```
      # define how aggressively the kernel will swap memory pages.
      vm.swappiness = 1
      ```

      **Converting sysctl settings from shell scripts**:

      Example of existing settings:

      ```bash
      fs.aio-max-nr = 1048576 net.ipv4.ip_local_port_range = 9000 65500 kernel.sem = 250 32000 100 128
      ```

      Converted to sysctl resources:

      ```ruby
      sysctl 'fs.aio-max-nr' do
        value '1048576'
      end

      sysctl 'net.ipv4.ip_local_port_range' do
        value '9000 65500'
      end

      sysctl 'kernel.sem' do
        value '250 32000 100 128'
      end
      ```


---

## systemd_unit resource

[systemd_unit resource page](systemd_unit/)

Use the **systemd_unit** resource to create, manage, and run [systemd units](https://www.freedesktop.org/software/systemd/man/systemd.html#Concepts).

**New in Chef Infra Client 12.11.**

> Source: `lib/chef/resource/systemd_unit.rb`

### Syntax

The full syntax for all of the properties that are available to the **systemd_unit** resource is:

```ruby
systemd_unit 'name' do
  enabled  # [TrueClass, FalseClass]
  active  # [TrueClass, FalseClass]
  masked  # [TrueClass, FalseClass]
  static  # [TrueClass, FalseClass]
  indirect  # [TrueClass, FalseClass]
  user  # String
  content  # [String, Hash]
  triggers_reload  # [TrueClass, FalseClass]  # default: true
  verify  # [TrueClass, FalseClass]  # default: true
  unit_name  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **systemd_unit** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` |  |
| `:delete` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `enabled` | `[TrueClass, FalseClass]` |  |  |
| `active` | `[TrueClass, FalseClass]` |  |  |
| `masked` | `[TrueClass, FalseClass]` |  |  |
| `static` | `[TrueClass, FalseClass]` |  |  |
| `indirect` | `[TrueClass, FalseClass]` |  |  |
| `user` | `String` |  |  |
| `content` | `[String, Hash]` |  |  |
| `triggers_reload` | `[TrueClass, FalseClass]` | `true` | Specifies whether to trigger a daemon reload when creating or deleting a unit. |
| `verify` | `[TrueClass, FalseClass]` | `true` | Specifies if the unit will be verified before installation. Systemd can be overly strict when verifying units, so in certain cases it is preferable no |
| `unit_name` | `String` |  | The name of the unit file if it differs from the resource block's name. |

### Agentless Mode

The **systemd_unit** resource has **full** support for Agentless Mode.

Support was added in Chef Infra Client 15.1.

### Examples

The following examples demonstrate various approaches for using the **systemd_unit** resource:

      **Create systemd service unit file from a Hash**

      ```ruby
      systemd_unit 'etcd.service' do
        content({ Unit: {
                  Description: 'Etcd',
                  Documentation: ['https://coreos.com/etcd', 'man:etcd(1)'],
                  After: 'network.target',
                },
                Service: {
                  Type: 'notify',
                  ExecStart: '/usr/local/etcd',
                  Restart: 'always',
                },
                Install: {
                  WantedBy: 'multi-user.target',
                } })
        action [:create, :enable]
      end
      ```

      **Create systemd service unit file from a String**

      ```ruby
      systemd_unit 'sysstat-collect.timer' do
        content <<~EOU
        [Unit]
        Description=Run system activity accounting tool every 10 minutes

        [Timer]
        OnCalendar=*:00/10

        [Install]
        WantedBy=sysstat.service
        EOU

        action [:create, :enable]
      end
      ```


---

## template resource

[template resource page](template/)

The **template** resource.


> Source: `lib/chef/resource/template.rb`

### Syntax

The full syntax for all of the properties that are available to the **template** resource is:

```ruby
template 'name' do
  variables  # Hash  # default: {}
  cookbook  # String
  local  # [ TrueClass, FalseClass ]  # default: false
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **template** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `variables` | `Hash` | `{}` | The variables property of the template resource can be used to reference a partial template file by using a Hash. |
| `cookbook` | `String` |  | The cookbook in which a file is located (if it is not located in the current cookbook). The default value is the current cookbook. |
| `local` | `[ TrueClass, FalseClass ]` | `false` |  |

### Agentless Mode

The **template** resource has **full** support for Agentless Mode.


---

## timezone resource

[timezone resource page](timezone/)

Use the **timezone** resource to change the system timezone on Windows, Linux, and macOS hosts. Timezones are specified in tz database format, with a complete list of available TZ values for Linux and macOS here: <https://en.wikipedia.org/wiki/List_of_tz_database_time_zones>. On Windows systems run `tzutil /l` for a complete list of valid timezones.

**New in Chef Infra Client 14.6.**

> Source: `lib/chef/resource/timezone.rb`

### Syntax

The full syntax for all of the properties that are available to the **timezone** resource is:

```ruby
timezone 'name' do
  timezone  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **timezone** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:set` | Set the system timezone. |
| `:create` |  |
| `:nothing` **(default)** |  |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `timezone` | `String` |  | An optional property to set the timezone value if it differs from the resource block's name. |

### Agentless Mode

The **timezone** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **timezone** resource:

      **Set the timezone to UTC**

      ```ruby
      timezone 'UTC'
      ```

      **Set the timezone to America/Los_Angeles with a friendly resource name on Linux/macOS**

      ```ruby
      timezone "Set the host's timezone to America/Los_Angeles" do
        timezone 'America/Los_Angeles'
      end
      ```

      **Set the timezone to PST with a friendly resource name on Windows**

      ```ruby
      timezone "Set the host's timezone to PST" do
        timezone 'Pacific Standard time'
      end
      ```


---

## user resource

[user resource page](user/)

Use the **user** resource to add users, update existing users, remove users, and to lock/unlock user passwords.

**New in Chef Infra Client 18.0.** *(catalog version; not declared in local source)*

> Source: `lib/chef/resource/user.rb`

### Syntax

The full syntax for all of the properties that are available to the **user** resource is:

```ruby
user 'name' do
  username  # String
  comment  # String
  home  # String
  salt  # String
  shell  # String
  password  # String
  non_unique  # [ TrueClass, FalseClass ]  # default: false
  manage_home  # [ TrueClass, FalseClass ]  # default: false
  force  # [ TrueClass, FalseClass ]  # default: false
  system  # [ TrueClass, FalseClass ]  # default: false
  uid  # [ String, Integer, NilClass ]
  gid  # [ String, Integer, NilClass ]
  expire_date  # [ String, NilClass ]
  inactive  # [ String, Integer, NilClass ]
  action  :symbol # defaults to :create if not specified
end
```

### Actions

The **user** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` **(default)** |  |
| `:remove` |  |
| `:modify` |  |
| `:manage` |  |
| `:lock` |  |
| `:unlock` |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `username` | `String` |  | An optional property to set the username value if it differs from the resource block's name. |
| `comment` | `String` |  | The contents of the user comments field. |
| `home` | `String` |  | The location of the home directory. |
| `salt` | `String` |  | A SALTED-SHA512-PBKDF2 hash. |
| `shell` | `String` |  | The login shell. |
| `password` | `String` |  | The password shadow hash |
| `non_unique` | `[ TrueClass, FalseClass ]` | `false` | Create a duplicate (non-unique) user account. |
| `manage_home` | `[ TrueClass, FalseClass ]` | `false` |  |
| `force` | `[ TrueClass, FalseClass ]` | `false` | Force the removal of a user. May be used only with the :remove action. |
| `system` | `[ TrueClass, FalseClass ]` | `false` | Create a system user. This property may be used with useradd as the provider to create a system user which passes the -r flag to useradd. |
| `uid` | `[ String, Integer, NilClass ]` |  | The numeric user identifier. |
| `gid` | `[ String, Integer, NilClass ]` |  | The numeric group identifier. |
| `expire_date` | `[ String, NilClass ]` |  | (Linux) The date on which the user account will be disabled. The date is specified in YYYY-MM-DD format. |
| `inactive` | `[ String, Integer, NilClass ]` |  |  |

### Agentless Mode

The **user** resource has **full** support for Agentless Mode.

Support was added in Chef Infra Client 18.0.


---

## user_ulimit resource

[user_ulimit resource page](user_ulimit/)

Use the **user_ulimit** resource to create individual ulimit files that are installed into the `/etc/security/limits.d/` directory.

**New in Chef Infra Client 16.0.**

> Source: `lib/chef/resource/user_ulimit.rb`

### Syntax

The full syntax for all of the properties that are available to the **user_ulimit** resource is:

```ruby
user_ulimit 'name' do
  username  # String
  as_limit  # [String, Integer]
  as_soft_limit  # [String, Integer]
  as_hard_limit  # [String, Integer]
  filehandle_limit  # [String, Integer]
  filehandle_soft_limit  # [String, Integer]
  filehandle_hard_limit  # [String, Integer]
  process_limit  # [String, Integer]
  process_soft_limit  # [String, Integer]
  process_hard_limit  # [String, Integer]
  locks_limit  # [String, Integer]
  memory_limit  # [String, Integer]
  maxlogins_limit  # [String, Integer]
  maxlogins_soft_limit  # [String, Integer]
  maxlogins_hard_limit  # [String, Integer]
  msgqueue_limit  # [String, Integer]
  msgqueue_soft_limit  # [String, Integer]
  msgqueue_hard_limit  # [String, Integer]
  core_limit  # [String, Integer]
  core_soft_limit  # [String, Integer]
  core_hard_limit  # [String, Integer]
  cpu_limit  # [String, Integer]
  cpu_soft_limit  # [String, Integer]
  cpu_hard_limit  # [String, Integer]
  sigpending_limit  # [String, Integer]
  sigpending_soft_limit  # [String, Integer]
  sigpending_hard_limit  # [String, Integer]
  stack_limit  # [String, Integer]
  stack_soft_limit  # [String, Integer]
  stack_hard_limit  # [String, Integer]
  rss_limit  # [String, Integer]
  rss_soft_limit  # [String, Integer]
  rss_hard_limit  # [String, Integer]
  rtprio_limit  # [String, Integer]
  rtprio_soft_limit  # [String, Integer]
  rtprio_hard_limit  # [String, Integer]
  virt_limit  # [String, Integer]
  filename  # String  # default: lazy { |r| r.username == "*" ? "00_all_limits.conf" : "#{r.username}_limits.conf" }
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **user_ulimit** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` | Create a ulimit configuration file. |
| `:delete` | Delete an existing ulimit configuration file. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `username` | `String` |  |  |
| `as_limit` | `[String, Integer]` |  |  |
| `as_soft_limit` | `[String, Integer]` |  |  |
| `as_hard_limit` | `[String, Integer]` |  |  |
| `filehandle_limit` | `[String, Integer]` |  |  |
| `filehandle_soft_limit` | `[String, Integer]` |  |  |
| `filehandle_hard_limit` | `[String, Integer]` |  |  |
| `process_limit` | `[String, Integer]` |  |  |
| `process_soft_limit` | `[String, Integer]` |  |  |
| `process_hard_limit` | `[String, Integer]` |  |  |
| `locks_limit` | `[String, Integer]` |  |  |
| `memory_limit` | `[String, Integer]` |  |  |
| `maxlogins_limit` | `[String, Integer]` |  |  |
| `maxlogins_soft_limit` | `[String, Integer]` |  |  |
| `maxlogins_hard_limit` | `[String, Integer]` |  |  |
| `msgqueue_limit` | `[String, Integer]` |  |  |
| `msgqueue_soft_limit` | `[String, Integer]` |  |  |
| `msgqueue_hard_limit` | `[String, Integer]` |  |  |
| `core_limit` | `[String, Integer]` |  |  |
| `core_soft_limit` | `[String, Integer]` |  |  |
| `core_hard_limit` | `[String, Integer]` |  |  |
| `cpu_limit` | `[String, Integer]` |  |  |
| `cpu_soft_limit` | `[String, Integer]` |  |  |
| `cpu_hard_limit` | `[String, Integer]` |  |  |
| `sigpending_limit` | `[String, Integer]` |  |  |
| `sigpending_soft_limit` | `[String, Integer]` |  |  |
| `sigpending_hard_limit` | `[String, Integer]` |  |  |
| `stack_limit` | `[String, Integer]` |  |  |
| `stack_soft_limit` | `[String, Integer]` |  |  |
| `stack_hard_limit` | `[String, Integer]` |  |  |
| `rss_limit` | `[String, Integer]` |  |  |
| `rss_soft_limit` | `[String, Integer]` |  |  |
| `rss_hard_limit` | `[String, Integer]` |  |  |
| `rtprio_limit` | `[String, Integer]` |  |  |
| `rtprio_soft_limit` | `[String, Integer]` |  |  |
| `rtprio_hard_limit` | `[String, Integer]` |  |  |
| `virt_limit` | `[String, Integer]` |  |  |
| `filename` | `String` | `lazy { |r| r.username == "*" ? "00_all_limits.conf` |  |

### Agentless Mode

The **user_ulimit** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **user_ulimit** resource:

      **Set filehandle limit for the tomcat user**:

      ```ruby
      user_ulimit 'tomcat' do
        filehandle_limit 8192
      end
      ```

      **Specify a username that differs from the name given to the resource block**:

      ```ruby
      user_ulimit 'Bump filehandle limits for tomcat user' do
        username 'tomcat'
        filehandle_limit 8192
      end
      ```

      **Set filehandle limit for the tomcat user with a non-default filename**:

      ```ruby
      user_ulimit 'tomcat' do
        filehandle_limit 8192
        filename 'tomcat_filehandle_limits.conf'
      end
      ```


---

## windows_ad_join resource

[windows_ad_join resource page](windows_ad_join/)

Use the **windows_ad_join** resource to join a Windows Active Directory domain.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/windows_ad_join.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_ad_join** resource is:

```ruby
windows_ad_join 'name' do
  domain_name  # String
  domain_user  # String
  domain_password  # String
  ou_path  # String
  reboot  # Symbol  # default: :immediate
  reboot_delay  # Integer  # default: 0
  new_hostname  # String
  workgroup_name  # String
  sensitive  # [TrueClass, FalseClass]  # default: true
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_ad_join** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:leave` |  |
| `:join` | Join the Active Directory domain. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `domain_name` | `String` |  | An optional property to set the FQDN of the Active Directory domain to join if it differs from the resource block's name. |
| `domain_user` | `String` |  | The domain user that will be used to join the domain. |
| `domain_password` | `String` |  | The password for the domain user. Note that this resource is set to hide sensitive information by default.  |
| `ou_path` | `String` |  | The path to the Organizational Unit where the host will be placed. |
| `reboot` | `Symbol` | `:immediate` |  |
| `reboot_delay` | `Integer` | `0` | The amount of time (in minutes) to delay a reboot request. |
| `new_hostname` | `String` |  | Specifies a new hostname for the computer in the new domain. |
| `workgroup_name` | `String` |  | Specifies the name of a workgroup to which the computer is added to when it is removed from the domain. The default value is WORKGROUP. This property  |
| `sensitive` | `[TrueClass, FalseClass]` | `true` |  |

### Examples

The following examples demonstrate various approaches for using the **windows_ad_join** resource:

      **Join a domain**

      ```ruby
      windows_ad_join 'ad.example.org' do
        domain_user 'nick'
        domain_password 'p@ssw0rd1'
      end
      ```

      **Join a domain, as `win-workstation`**

      ```ruby
      windows_ad_join 'ad.example.org' do
        domain_user 'nick'
        domain_password 'p@ssw0rd1'
        new_hostname 'win-workstation'
      end
      ```

      **Leave the current domain and re-join the `local` workgroup**

      ```ruby
      windows_ad_join 'Leave domain' do
        action :leave
        workgroup 'local'
      end
      ```


---

## windows_audit_policy resource

[windows_audit_policy resource page](windows_audit_policy/)

Use the **windows_audit_policy** resource to configure system level and per-user Windows advanced audit policy settings.

**New in Chef Infra Client 16.2.**

> Source: `lib/chef/resource/windows_audit_policy.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_audit_policy** resource is:

```ruby
windows_audit_policy 'name' do
  subcategory  # [String, Array]
  success  # [true, false]
  failure  # [true, false]
  include_user  # String
  exclude_user  # String
  crash_on_audit_fail  # [true, false]
  full_privilege_auditing  # [true, false]
  audit_base_objects  # [true, false]
  audit_base_directories  # [true, false]
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_audit_policy** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:set` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `subcategory` | `[String, Array]` |  | The audit policy subcategory, specified by GUID or name. Applied system-wide if no user is specified. |
| `success` | `[true, false]` |  |  |
| `failure` | `[true, false]` |  |  |
| `include_user` | `String` |  | The audit policy specified by the category or subcategory is applied per-user if specified. When a user is specified, include user. Include and exclud |
| `exclude_user` | `String` |  | The audit policy specified by the category or subcategory is applied per-user if specified. When a user is specified, exclude user. Include and exclud |
| `crash_on_audit_fail` | `[true, false]` |  | Setting this audit policy option to true will cause the system to crash if the auditing system is unable to log events. |
| `full_privilege_auditing` | `[true, false]` |  | Setting this audit policy option to true will force the audit of all privilege changes except SeAuditPrivilege. Setting this property may cause the lo |
| `audit_base_objects` | `[true, false]` |  | Setting this audit policy option to true will force the system to assign a System Access Control List to named objects to enable auditing of base obje |
| `audit_base_directories` | `[true, false]` |  | Setting this audit policy option to true will force the system to assign a System Access Control List to named objects to enable auditing of container |

### Examples

The following examples demonstrate various approaches for using the **windows_audit_policy** resource:

      **Set Logon and Logoff policy to "Success and Failure"**:

      ```ruby
      windows_audit_policy "Set Audit Policy for 'Logon and Logoff' actions to 'Success and Failure'" do
        subcategory %w(Logon Logoff)
        success true
        failure true
        action :set
      end
      ```

      **Set Credential Validation policy to "Success"**:

      ```ruby
      windows_audit_policy "Set Audit Policy for 'Credential Validation' actions to 'Success'" do
        subcategory 'Credential Validation'
        success true
        failure false
        action :set
      end
      ```

      **Enable CrashOnAuditFail option**:

      ```ruby
      windows_audit_policy 'Enable CrashOnAuditFail option' do
        crash_on_audit_fail true
        action :set
      end
      ```


---

## windows_auto_run resource

[windows_auto_run resource page](windows_auto_run/)

Use the **windows_auto_run** resource to set applications to run at login.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/windows_auto_run.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_auto_run** resource is:

```ruby
windows_auto_run 'name' do
  program_name  # String
  path  # String
  args  # String
  root  # Symbol  # default: :machine
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_auto_run** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` |  |
| `:remove` | Remove an item that was previously configured to run at login. |
| `:delete` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `program_name` | `String` |  | The name of the program to run at login if it differs from the resource block's name. |
| `path` | `String` |  | The path to the program that will run at login. |
| `args` | `String` |  | Any arguments to be used with the program. |
| `root` | `Symbol` | `:machine` | The registry root key to put the entry under. |

### Examples

The following examples demonstrate various approaches for using the **windows_auto_run** resource:

      **Run BGInfo at login**

      ```ruby
      windows_auto_run 'BGINFO' do
        program 'C:/Sysinternals/bginfo.exe'
        args    "'C:/Sysinternals/Config.bgi' /NOLICPROMPT /TIMER:0"
        action  :create
      end
      ```


---

## windows_certificate resource

[windows_certificate resource page](windows_certificate/)

Use the **windows_certificate** resource to install a certificate into the Windows certificate store from a file. The resource grants read-only access to the private key for designated accounts. Due to current limitations in WinRM, installing certificates remotely may not work if the operation requires a user profile. Operations on the local machine store should still work.

**New in Chef Infra Client 14.7.**

> Source: `lib/chef/resource/windows_certificate.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_certificate** resource is:

```ruby
windows_certificate 'name' do
  source  # String
  pfx_password  # String
  private_key_acl  # Array
  store_name  # String  # default: "MY"
  user_store  # [TrueClass, FalseClass]
  sensitive  # [TrueClass, FalseClass]  # default: lazy { pfx_password ? true : false }
  exportable  # [TrueClass, FalseClass]  # default: false
  output_path  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_certificate** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:delete` |  |
| `:create` | Creates or updates a certificate. |
| `:acl_add` | Adds read-only entries to a certificate's private key ACL. |
| `:fetch` | Fetches a certificate. |
| `:verify` | Verifies a certificate and logs the result. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `source` | `String` |  | The source file (for `create` and `acl_add`), thumbprint (for `delete`, `export`, and `acl_add`), or subject (for `delete` or `export`) if it differs  |
| `pfx_password` | `String` |  | The password to access the object with if it is a PFX file. |
| `private_key_acl` | `Array` |  | An array of 'domain\\account' entries to be granted read-only access to the certificate's private key. Not idempotent. |
| `store_name` | `String` | `"MY"` | The certificate store to manipulate. |
| `user_store` | `[TrueClass, FalseClass]` |  | Use the `CurrentUser` store instead of the default `LocalMachine` store. Note: Prior to #{ChefUtils::Dist::Infra::CLIENT}. 16.10 this property was ign |
| `sensitive` | `[TrueClass, FalseClass]` | `lazy { pfx_password ? true : false }` | Ensure that sensitive resource data is not logged by the #{ChefUtils::Dist::Infra::CLIENT}. |
| `exportable` | `[TrueClass, FalseClass]` | `false` | Ensure that imported pfx certificate is exportable. Please provide 'true' if you want the certificate to be exportable. |
| `output_path` | `String` |  | A path on the node where a certificate object (PFX, PEM, CER, KEY, etc) can be exported to. |

### Examples

The following examples demonstrate various approaches for using the **windows_certificate** resource:

      **Add PFX cert to local machine personal store and grant accounts read-only access to private key**

      ```ruby
      windows_certificate 'c:/test/mycert.pfx' do
        pfx_password 'password'
        private_key_acl ["acme\\fred", "pc\\jane"]
      end
      ```

      **Add cert to trusted intermediate store**

      ```ruby
      windows_certificate 'c:/test/mycert.cer' do
        store_name 'CA'
      end
      ```

      **Remove all certificates matching the subject**

      ```ruby
      windows_certificate 'me.acme.com' do
        action :delete
      end
      ```


---

## windows_defender resource

[windows_defender resource page](windows_defender/)

Use the **windows_defender** resource to enable or disable the Microsoft Windows Defender service.

**New in Chef Infra Client 17.3.**

> Source: `lib/chef/resource/windows_defender.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_defender** resource is:

```ruby
windows_defender 'name' do
  realtime_protection  # [true, false]  # default: true
  intrusion_protection_system  # [true, false]  # default: true
  lock_ui  # [true, false]  # default: false  # DisableArchiveScanning
  scan_archives  # [true, false]  # default: true
  scan_scripts  # [true, false]  # default: false
  scan_email  # [true, false]  # default: false
  scan_removable_drives  # [true, false]  # default: false
  scan_network_files  # [true, false]  # default: false
  scan_mapped_drives  # [true, false]  # default: true
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_defender** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:enable` |  |
| `:disable` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `realtime_protection` | `[true, false]` | `true` | Enable realtime scanning of downloaded files and attachments. |
| `intrusion_protection_system` | `[true, false]` | `true` | Enable network protection against exploitation of known vulnerabilities. |
| `lock_ui` | `[true, false]` | `false  # DisableArchiveScanning` | Lock the UI to prevent users from changing Windows Defender settings. |
| `scan_archives` | `[true, false]` | `true` | Scan file archives such as .zip or .gz archives. |
| `scan_scripts` | `[true, false]` | `false` | Scan scripts in malware scans. |
| `scan_email` | `[true, false]` | `false` | Scan e-mails for malware. |
| `scan_removable_drives` | `[true, false]` | `false` | Scan content of removable drives. |
| `scan_network_files` | `[true, false]` | `false` | Scan files on a network. |
| `scan_mapped_drives` | `[true, false]` | `true` | Scan files on mapped network drives. |

### Examples

The following examples demonstrate various approaches for using the **windows_defender** resource:

      **Configure Windows Defender AV settings**:

      ```ruby
      windows_defender 'Configure Defender' do
        realtime_protection true
        intrusion_protection_system true
        lock_ui true
        scan_archives true
        scan_scripts true
        scan_email true
        scan_removable_drives true
        scan_network_files false
        scan_mapped_drives false
        action :enable
      end
      ```

      **Disable Windows Defender AV**:

      ```ruby
      windows_defender 'Disable Defender' do
        action :disable
      end
      ```


---

## windows_defender_exclusion resource

[windows_defender_exclusion resource page](windows_defender_exclusion/)

Use the **windows_defender_exclusion** resource to exclude paths, processes, or file types from Windows Defender realtime protection scanning.

**New in Chef Infra Client 17.3.**

> Source: `lib/chef/resource/windows_defender_exclusion.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_defender_exclusion** resource is:

```ruby
windows_defender_exclusion 'name' do
  paths  # [String, Array]  # default: []
  extensions  # [String, Array]  # default: []
  process_paths  # [String, Array]  # default: []
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_defender_exclusion** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:add` |  |
| `:remove` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `paths` | `[String, Array]` | `[]` | File or directory paths to exclude from scanning. |
| `extensions` | `[String, Array]` | `[]` | File extensions to exclude from scanning. |
| `process_paths` | `[String, Array]` | `[]` | Paths to executables to exclude from scanning. |

### Examples

The following examples demonstrate various approaches for using the **windows_defender_exclusion** resource:

      **Add excluded items to Windows Defender scans**:

      ```ruby
      windows_defender_exclusion 'Add to things to be excluded from scanning' do
        paths 'c:\\foo\\bar, d:\\bar\\baz'
        extensions 'png, foo, ppt, doc'
        process_paths 'c:\\windows\\system32'
        action :add
      end
      ```

      **Remove excluded items from Windows Defender scans**:

      ```ruby
      windows_defender_exclusion 'Remove things from the list to be excluded' do
        process_paths 'c:\\windows\\system32'
        action :remove
      end
      ```


---

## windows_dfs_folder resource

[windows_dfs_folder resource page](windows_dfs_folder/)

Use the **windows_dfs_folder** resource to creates a folder within DFS as many levels deep as required.

**New in Chef Infra Client 15.0.**

> Source: `lib/chef/resource/windows_dfs_folder.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_dfs_folder** resource is:

```ruby
windows_dfs_folder 'name' do
  folder_path  # String
  namespace_name  # String
  target_path  # String
  description  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_dfs_folder** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` | Creates the folder in dfs namespace. |
| `:delete` | Deletes the folder in the dfs namespace. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `folder_path` | `String` |  | An optional property to set the path of the dfs folder if it differs from the resource block's name. |
| `namespace_name` | `String` |  | The namespace this should be created within. |
| `target_path` | `String` |  | The target that this path will connect you to. |
| `description` | `String` |  | Description for the share. |


---

## windows_dfs_namespace resource

[windows_dfs_namespace resource page](windows_dfs_namespace/)

Use the **windows_dfs_namespace** resource to creates a share and DFS namespace on a Windows server.

**New in Chef Infra Client 15.0.**

> Source: `lib/chef/resource/windows_dfs_namespace.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_dfs_namespace** resource is:

```ruby
windows_dfs_namespace 'name' do
  namespace_name  # String
  description  # String
  full_users  # Array  # default: ["BUILTIN\\administrators"]
  change_users  # Array  # default: []
  read_users  # Array  # default: []
  root  # String  # default: "C:\\DFSRoots"
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_dfs_namespace** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` | Creates the dfs namespace on the server. |
| `:delete` | Deletes a DFS Namespace including the directory on disk. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `namespace_name` | `String` |  | An optional property to set the dfs namespace if it differs from the resource block's name. |
| `description` | `String` |  | Description of the share. |
| `full_users` | `Array` | `["BUILTIN\\administrators"]` | Determines which users should have full access to the share. |
| `change_users` | `Array` | `[]` | Determines which users should have change access to the share. |
| `read_users` | `Array` | `[]` | Determines which users should have read access to the share. |
| `root` | `String` | `"C:\\DFSRoots"` | The root from which to create the DFS tree. Defaults to C:\\DFSRoots. |


---

## windows_dfs_server resource

[windows_dfs_server resource page](windows_dfs_server/)

Use the **windows_dfs_server** resource to set system-wide DFS settings.

**New in Chef Infra Client 15.0.**

> Source: `lib/chef/resource/windows_dfs_server.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_dfs_server** resource is:

```ruby
windows_dfs_server 'name' do
  use_fqdn  # [TrueClass, FalseClass]  # default: false
  ldap_timeout_secs  # Integer  # default: 30
  prefer_login_dc  # [TrueClass, FalseClass]  # default: false
  enable_site_costed_referrals  # [TrueClass, FalseClass]  # default: false
  sync_interval_secs  # Integer  # default: 3600  load_current_value do
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_dfs_server** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:configure` | Configure DFS settings |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `use_fqdn` | `[TrueClass, FalseClass]` | `false` |  |
| `ldap_timeout_secs` | `Integer` | `30` |  |
| `prefer_login_dc` | `[TrueClass, FalseClass]` | `false` |  |
| `enable_site_costed_referrals` | `[TrueClass, FalseClass]` | `false` |  |
| `sync_interval_secs` | `Integer` | `3600  load_current_value do` |  |


---

## windows_dns_record resource

[windows_dns_record resource page](windows_dns_record/)

The windows_dns_record resource creates a DNS record for the given domain.

**New in Chef Infra Client 15.0.**

> Source: `lib/chef/resource/windows_dns_record.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_dns_record** resource is:

```ruby
windows_dns_record 'name' do
  record_name  # String
  zone  # String
  target  # String
  record_type  # String  # default: "ARecord"
  dns_server  # String  # default: "localhost"
  Ensure
  Name
  Zone
  Type
  Target
  DnsServer
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_dns_record** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` | Creates and updates the DNS entry. |
| `:delete` | Deletes a DNS entry. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `record_name` | `String` |  | An optional property to set the dns record name if it differs from the resource block's name. |
| `zone` | `String` |  | The zone to create the record in. |
| `target` | `String` |  | The target for the record. |
| `record_type` | `String` | `"ARecord"` | The type of record to create, can be either ARecord, CNAME or PTR. |
| `dns_server` | `String` | `"localhost"` | The name of the DNS server on which to create the record. |
| `Ensure` |  |  |  |
| `Name` |  |  |  |
| `Zone` |  |  |  |
| `Type` |  |  |  |
| `Target` |  |  |  |
| `DnsServer` |  |  |  |


---

## windows_dns_zone resource

[windows_dns_zone resource page](windows_dns_zone/)

The windows_dns_zone resource creates an Active Directory Integrated DNS Zone on the local server.

**New in Chef Infra Client 15.0.**

> Source: `lib/chef/resource/windows_dns_zone.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_dns_zone** resource is:

```ruby
windows_dns_zone 'name' do
  zone_name  # String
  replication_scope  # String  # default: "Domain"
  server_type  # String  # default: "Domain"
  Ensure
  Name
  ReplicationScope
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_dns_zone** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` | Creates and updates a DNS Zone. |
| `:delete` | Deletes a DNS Zone. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `zone_name` | `String` |  | An optional property to set the dns zone name if it differs from the resource block's name. |
| `replication_scope` | `String` | `"Domain"` | The replication scope for the zone, required if server_type set to 'Domain'. |
| `server_type` | `String` | `"Domain"` | The type of DNS server, Domain or Standalone. |
| `Ensure` |  |  |  |
| `Name` |  |  |  |
| `ReplicationScope` |  |  |  |


---

## windows_env resource

[windows_env resource page](windows_env/)

Use the **windows_env** resource to manage environment keys in Microsoft Windows. After an environment key is set, Microsoft Windows must be restarted before the environment key will be available to the Task Scheduler.  This resource was previously called the **env** resource; its name was updated in #{ChefUtils::Dist::Infra::PRODUCT} 14.0 to reflect the fact that only Windows is supported. Existing cookbooks using `env` will continue to function, but should be updated to use the new name. Note: On UNIX-based systems, the best way to manipulate environment keys is with the `ENV` variable in Ruby; however, this approach does not have the same permanent effect as using the windows_env resource.


> Source: `lib/chef/resource/windows_env.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_env** resource is:

```ruby
windows_env 'name' do
  key_name  # String
  value  # String
  delim  # [ String, nil, false ]
  user  # String  # default: "<System>"  action_class do include Chef::Mixin::WindowsEnvHelper
  action  :symbol # defaults to :create if not specified
end
```

### Actions

The **windows_env** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` **(default)** |  |
| `:delete` |  |
| `:modify` |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `key_name` | `String` |  | An optional property to set the name of the key that is to be created, deleted, or modified if it differs from the resource block's name. |
| `value` | `String` |  | The value of the environmental variable to set. |
| `delim` | `[ String, nil, false ]` |  | The delimiter that is used to separate multiple values for a single key. |
| `user` | `String` | `"<System>"  action_class do include Chef::Mixin::W` |  |

### Examples

The following examples demonstrate various approaches for using the **windows_env** resource:

      **Set an environment variable**:

      ```ruby
      windows_env 'ComSpec' do
        value 'C:\\Windows\\system32\\cmd.exe'
      end
      ```


---

## windows_feature resource

[windows_feature resource page](windows_feature/)

Use the **windows_feature** resource to add, remove or entirely delete Windows features and roles. This resource calls the 'windows_feature_dism' or 'windows_feature_powershell' resources depending on the specified installation method, and defaults to DISM, which is available on both Workstation and Server editions of Windows.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/windows_feature.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_feature** resource is:

```ruby
windows_feature 'name' do
  feature_name  # [Array, String]
  source  # String
  all  # [TrueClass, FalseClass]  # default: false
  management_tools  # [TrueClass, FalseClass]  # default: false
  install_method  # Symbol  # default: :windows_feature_dism
  timeout  # Integer  # default: 600
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_feature** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:remove` |  |
| `:delete` | Remove a Windows role or feature from the image. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `feature_name` | `[Array, String]` |  |  |
| `source` | `String` |  | Specify a local repository for the feature install. |
| `all` | `[TrueClass, FalseClass]` | `false` | Install all sub-features. |
| `management_tools` | `[TrueClass, FalseClass]` | `false` | Install all applicable management tools for the roles, role services, or features (PowerShell-only). |
| `install_method` | `Symbol` | `:windows_feature_dism` | The underlying installation method to use for feature installation. Specify `:windows_feature_dism` for DISM or `:windows_feature_powershell` for Powe |
| `timeout` | `Integer` | `600` | Specifies a timeout (in seconds) for the feature installation. |

### Examples

The following examples demonstrate various approaches for using the **windows_feature** resource:

      **Install the DHCP Server feature**:

      ```ruby
      windows_feature 'DHCPServer' do
        action :install
      end
      ```

      **Install the .Net 3.5.1 feature using repository files on DVD**:

      ```ruby
      windows_feature "NetFx3" do
        action :install
        source 'd:\\sources\\sxs'
      end
      ```

      **Remove Telnet Server and Client features**:

      ```ruby
      windows_feature %w(TelnetServer TelnetClient) do
        action :remove
      end
      ```

      **Add the SMTP Server feature using the PowerShell provider**:

      ```ruby
      windows_feature 'smtp-server' do
        action :install
        all true
        install_method :windows_feature_powershell
      end
      ```

      **Install multiple features using one resource with the PowerShell provider**:

      ```ruby
      windows_feature %w(Web-Asp-Net45 Web-Net-Ext45) do
        action :install
        install_method :windows_feature_powershell
      end
      ```

      **Install the Network Policy and Access Service feature, including the management tools**:

      ```ruby
      windows_feature 'NPAS' do
        action :install
        management_tools true
        install_method :windows_feature_powershell
      end
      ```


---

## windows_feature_dism resource

[windows_feature_dism resource page](windows_feature_dism/)

Use the **windows_feature_dism** resource to add, remove, or entirely delete Windows features and roles using DISM.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/windows_feature_dism.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_feature_dism** resource is:

```ruby
windows_feature_dism 'name' do
  feature_name  # [Array, String]
  source  # String
  all  # [TrueClass, FalseClass]  # default: false
  timeout  # Integer  # default: 600
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_feature_dism** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` | Install a Windows role/feature using DISM. |
| `:remove` | Remove a Windows role or feature using DISM. |
| `:delete` | Remove a Windows role or feature from the image using DISM. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `feature_name` | `[Array, String]` |  | The name of the feature(s) or role(s) to install if they differ from the resource name. |
| `source` | `String` |  | Specify a local repository for the feature install. |
| `all` | `[TrueClass, FalseClass]` | `false` | Install all sub-features. When set to `true`, this is the equivalent of specifying the `/All` switch to `dism.exe` |
| `timeout` | `Integer` | `600` | Specifies a timeout (in seconds) for the feature installation. |

### Examples

The following examples demonstrate various approaches for using the **windows_feature_dism** resource:

      **Installing the TelnetClient service**:

      ```ruby
      windows_feature_dism "TelnetClient"
      ```

      **Installing two features by using an array**:

      ```ruby
      windows_feature_dism %w(TelnetClient TFTP)
      ```


---

## windows_feature_powershell resource

[windows_feature_powershell resource page](windows_feature_powershell/)

Use the **windows_feature_powershell** resource to add, remove, or entirely delete Windows features and roles using PowerShell. This resource offers significant speed benefits over the windows_feature_dism resource, but requires installation of the Remote Server Administration Tools on non-server releases of Windows.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/windows_feature_powershell.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_feature_powershell** resource is:

```ruby
windows_feature_powershell 'name' do
  feature_name  # [Array, String]
  source  # String
  all  # [TrueClass, FalseClass]  # default: false
  timeout  # Integer  # default: 600
  management_tools  # [TrueClass, FalseClass]  # default: false  # Converts strings of features into an Array. Array objects are lowercased
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_feature_powershell** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:remove` | Remove a Windows role or feature using PowerShell. |
| `:delete` | Delete a Windows role or feature from the image using PowerShell. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `feature_name` | `[Array, String]` |  | The name of the feature(s) or role(s) to install if they differ from the resource block's name. |
| `source` | `String` |  | Specify a local repository for the feature install. |
| `all` | `[TrueClass, FalseClass]` | `false` | Install all subfeatures. When set to `true`, this is the equivalent of specifying the `-InstallAllSubFeatures` switch with `Add-WindowsFeature`. |
| `timeout` | `Integer` | `600` | Specifies a timeout (in seconds) for the feature installation. |
| `management_tools` | `[TrueClass, FalseClass]` | `false  # Converts strings of features into an Arra` | Install all applicable management tools for the roles, role services, or features. |

### Examples

The following examples demonstrate various approaches for using the **windows_feature_powershell** resource:

      **Add the SMTP Server feature**:

      ```ruby
      windows_feature_powershell "smtp-server" do
        action :install
        all true
      end
      ```

      **Install multiple features using one resource**:

      ```ruby
      windows_feature_powershell ['Web-Asp-Net45', 'Web-Net-Ext45'] do
        action :install
      end
      ```

      **Install the Network Policy and Access Service feature**:

      ```ruby
      windows_feature_powershell 'NPAS' do
        action :install
        management_tools true
      end
      ```


---

## windows_firewall_profile resource

[windows_firewall_profile resource page](windows_firewall_profile/)

Use the **windows_firewall_profile** resource to enable, disable, and configure the Windows firewall.

**New in Chef Infra Client 16.3.**

> Source: `lib/chef/resource/windows_firewall_profile.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_firewall_profile** resource is:

```ruby
windows_firewall_profile 'name' do
  profile  # String
  default_inbound_action  # [String, nil]
  default_outbound_action  # [String, nil]
  allow_inbound_rules  # [true, false, String]
  allow_local_firewall_rules  # [true, false, String]
  allow_local_ipsec_rules  # [true, false, String]
  allow_user_apps  # [true, false, String]
  allow_user_ports  # [true, false, String]
  allow_unicast_response  # [true, false, String]
  display_notification  # [true, false, String]
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_firewall_profile** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:enable` |  |
| `:disable` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `profile` | `String` |  | Set the Windows Profile being configured |
| `default_inbound_action` | `[String, nil]` |  | Set the default policy for inbound network traffic |
| `default_outbound_action` | `[String, nil]` |  | Set the default policy for outbound network traffic |
| `allow_inbound_rules` | `[true, false, String]` |  | Allow users to set inbound firewall rules |
| `allow_local_firewall_rules` | `[true, false, String]` |  | Merges inbound firewall rules into the policy |
| `allow_local_ipsec_rules` | `[true, false, String]` |  | Allow users to manage local connection security rules |
| `allow_user_apps` | `[true, false, String]` |  | Allow user applications to manage firewall |
| `allow_user_ports` | `[true, false, String]` |  | Allow users to manage firewall port rules |
| `allow_unicast_response` | `[true, false, String]` |  | Allow unicast responses to multicast and broadcast messages |
| `display_notification` | `[true, false, String]` |  | Display a notification when firewall blocks certain activity |

### Examples

The following examples demonstrate various approaches for using the **windows_firewall_profile** resource:

      **Enable and Configure the Private Profile of the Windows Profile**:

      ```ruby
      windows_firewall_profile 'Private' do
        default_inbound_action 'Block'
        default_outbound_action 'Allow'
        allow_inbound_rules true
        display_notification false
        action :enable
      end
      ```

      **Enable and Configure the Public Profile of the Windows Firewall**:

      ```ruby
      windows_firewall_profile 'Public' do
        default_inbound_action 'Block'
        default_outbound_action 'Allow'
        allow_inbound_rules false
        display_notification false
        action :enable
      end
      ```

      **Disable the Domain Profile of the Windows Firewall**:

      ```ruby
      windows_firewall_profile 'Disable the Domain Profile of the Windows Firewall' do
        profile 'Domain'
        action :disable
      end
      ```


---

## windows_firewall_rule resource

[windows_firewall_rule resource page](windows_firewall_rule/)

Use the **windows_firewall_rule** resource to create, change or remove Windows firewall rules.

**New in Chef Infra Client 14.7.**

> Source: `lib/chef/resource/windows_firewall_rule.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_firewall_rule** resource is:

```ruby
windows_firewall_rule 'name' do
  rule_name  # String
  description  # String
  displayname  # String  # default: lazy { rule_name }
  group  # String
  local_address  # String
  local_port  # [String, Integer, Array]
  remote_address  # [String, Array]
  remote_port  # [String, Integer, Array]
  direction  # [Symbol, String]  # default: :inbound
  protocol  # String  # default: "TCP"
  icmp_type  # [String, Integer]  # default: "Any"
  firewall_action  # [Symbol, String]  # default: :allow
  profile  # [Symbol, String, Array]  # default: :any
  program  # String
  service  # String
  interface_type  # [Symbol, String]  # default: :any
  enabled  # [TrueClass, FalseClass]  # default: true
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_firewall_rule** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` |  |
| `:delete` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `rule_name` | `String` |  | An optional property to set the name of the firewall rule to assign if it differs from the resource block's name. |
| `description` | `String` |  | The description to assign to the firewall rule. |
| `displayname` | `String` | `lazy { rule_name }` | The displayname to assign to the firewall rule. |
| `group` | `String` |  | Specifies that only matching firewall rules of the indicated group association are copied. |
| `local_address` | `String` |  | The local address the firewall rule applies to. |
| `local_port` | `[String, Integer, Array]` |  | The local port the firewall rule applies to. |
| `remote_address` | `[String, Array]` |  | The remote address(es) the firewall rule applies to. |
| `remote_port` | `[String, Integer, Array]` |  | The remote port the firewall rule applies to. |
| `direction` | `[Symbol, String]` | `:inbound` | The direction of the firewall rule. Direction means either inbound or outbound traffic. |
| `protocol` | `String` | `"TCP"` | The protocol the firewall rule applies to. |
| `icmp_type` | `[String, Integer]` | `"Any"` | Specifies the ICMP Type parameter for using a protocol starting with ICMP |
| `firewall_action` | `[Symbol, String]` | `:allow` | The action of the firewall rule. |
| `profile` | `[Symbol, String, Array]` | `:any` | The profile the firewall rule applies to. |
| `program` | `String` |  | The program the firewall rule applies to. |
| `service` | `String` |  | The service the firewall rule applies to. |
| `interface_type` | `[Symbol, String]` | `:any` | The interface type the firewall rule applies to. |
| `enabled` | `[TrueClass, FalseClass]` | `true` | Whether or not to enable the firewall rule. |

### Examples

The following examples demonstrate various approaches for using the **windows_firewall_rule** resource:

      **Allowing port 80 access**:

      ```ruby
      windows_firewall_rule 'IIS' do
        local_port '80'
        protocol 'TCP'
        firewall_action :allow
      end
      ```

      **Configuring multiple remote-address ports on a rule**:

      ```ruby
      windows_firewall_rule 'MyRule' do
        description          'Testing out remote address arrays'
        enabled              false
        local_port           1434
        remote_address       %w(10.17.3.101 172.7.7.53)
        protocol             'TCP'
        action               :create
      end
      ```

      **Allow protocol ICMPv6 with ICMP Type**:

      ```ruby
      windows_firewall_rule 'CoreNet-Rule' do
        rule_name 'CoreNet-ICMP6-LR2-In'
        display_name 'Core Networking - Multicast Listener Report v2 (ICMPv6-In)'
        local_port 'RPC'
        protocol 'ICMPv6'
        icmp_type '8'
      end
      ```

      **Blocking WinRM over HTTP on a particular IP**:

      ```ruby
      windows_firewall_rule 'Disable WinRM over HTTP' do
        local_port '5985'
        protocol 'TCP'
        firewall_action :block
        local_address '192.168.1.1'
      end
      ```

      **Deleting an existing rule**

      ```ruby
      windows_firewall_rule 'Remove the SSH rule' do
        rule_name 'ssh'
        action :delete
      end
      ```


---

## windows_font resource

[windows_font resource page](windows_font/)

Use the **windows_font** resource to install font files on Windows. By default, the font is sourced from the cookbook using the resource, but a URI source can be specified as well.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/windows_font.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_font** resource is:

```ruby
windows_font 'name' do
  font_name  # String
  source  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_font** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` | Install a font to the system fonts directory. |
| `:nothing` **(default)** |  |
| `:delete` |  |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `font_name` | `String` |  | An optional property to set the name of the font to install if it differs from the resource block's name. |
| `source` | `String` |  | A local filesystem path or URI that is used to source the font file. |

### Examples

The following examples demonstrate various approaches for using the **windows_font** resource:

      **Install a font from a https source**:

      ```ruby
      windows_font 'Custom.otf' do
        source 'https://example.com/Custom.otf'
      end
      ```


---

## windows_package resource

[windows_package resource page](windows_package/)

Use the **windows_package** resource to manage packages on the Microsoft Windows platform. The **windows_package** resource supports these installer formats: * Microsoft Installer Package (MSI) * Nullsoft Scriptable Install System (NSIS) * Inno Setup (inno) * Wise * InstallShield * Custom installers such as installing a non-.msi file that embeds an .msi-based installer To enable idempotence of the `:install` action or to enable the `:remove` action with no source property specified, `package_name` MUST be an exact match of the name used by the package installer. The names of installed packages Windows knows about can be found in **Add/Remove programs**, in the output of `ohai packages`, or in the `DisplayName` property in one of the following in the Windows registry: * `HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall` * `HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall` * `HKEY_LOCAL_MACHINE\\Software\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall` Note: If there are multiple versions of a package installed with the same display name, all of those packages will be removed unless a version is provided in the **version** property or unless it can be discovered in the installer file specified by the **source** property.

**New in Chef Infra Client 11.12.**

> Source: `lib/chef/resource/windows_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_package** resource is:

```ruby
windows_package 'name' do
  package_name  # String
  options  # String
  installer_type  # Symbol
  timeout  # [ String, Integer ]  # default: 600
  returns  # [ String, Integer, Array ]
  source  # String
  checksum  # String
  remote_file_attributes  # Hash
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:remove` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `package_name` | `String` |  | An optional property to set the package name if it differs from the resource block's name. |
| `options` | `String` |  | One (or more) additional options that are passed to the command. |
| `installer_type` | `Symbol` |  |  |
| `timeout` | `[ String, Integer ]` | `600` | 600 (seconds) |
| `returns` | `[ String, Integer, Array ]` |  | A comma-delimited list of return codes that indicate the success or failure of the package command that was run. |
| `source` | `String` |  |  |
| `checksum` | `String` |  |  |
| `remote_file_attributes` | `Hash` |  |  |

### Examples

The following examples demonstrate various approaches for using the **windows_package** resource:

      **Install a package**:

      ```ruby
      windows_package '7zip' do
        action :install
        source 'C:\\7z920.msi'
      end
      ```

      **Specify a URL for the source attribute**:

      ```ruby
      windows_package '7zip' do
        source 'http://www.7-zip.org/a/7z938-x64.msi'
      end
      ```

      **Specify path and checksum**:

      ```ruby
      windows_package '7zip' do
        source 'http://www.7-zip.org/a/7z938-x64.msi'
        checksum '7c8e873991c82ad9cfcdbdf45254ea6101e9a645e12977dcd518979e50fdedf3'
      end
      ```

      **Modify remote_file resource attributes**:

      The windows_package resource may specify a package at a remote location using the remote_file_attributes property. This uses the remote_file resource to download the contents at the specified URL and passes in a Hash that modifies the properties of the remote_file resource.

      ```ruby
      windows_package '7zip' do
        source 'http://www.7-zip.org/a/7z938-x64.msi'
        remote_file_attributes ({
          :path => 'C:\\7zip.msi',
          :checksum => '7c8e873991c82ad9cfcdbdf45254ea6101e9a645e12977dcd518979e50fdedf3'
        })
      end
      ```

      **Download a nsis (Nullsoft) package resource**:

      ```ruby
      windows_package 'Mercurial 3.6.1 (64-bit)' do
        source 'https://www.mercurial-scm.org/release/windows/Mercurial-3.6.1-x64.exe'
        checksum 'febd29578cb6736163d232708b834a2ddd119aa40abc536b2c313fc5e1b5831d'
      end
      ```

      **Download a custom package**:

      ```ruby
      windows_package 'Microsoft Visual C++ 2005 Redistributable' do
        source 'https://download.microsoft.com/download/6/B/B/6BB661D6-A8AE-4819-B79F-236472F6070C/vcredist_x86.exe'
        installer_type :custom
        options '/Q'
      end
      ```


---

## windows_pagefile resource

[windows_pagefile resource page](windows_pagefile/)

Use the **windows_pagefile** resource to configure pagefile settings on Windows.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/windows_pagefile.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_pagefile** resource is:

```ruby
windows_pagefile 'name' do
  path  # String
  system_managed  # [TrueClass, FalseClass]
  automatic_managed  # [TrueClass, FalseClass]
  initial_size  # Integer
  maximum_size  # Integer
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_pagefile** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:delete` |  |
| `:set` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `path` | `String` |  | An optional property to set the pagefile name if it differs from the resource block's name. |
| `system_managed` | `[TrueClass, FalseClass]` |  | Configures whether the system manages the pagefile size. |
| `automatic_managed` | `[TrueClass, FalseClass]` |  | Enable automatic management of pagefile initial and maximum size. Setting this to true ignores `initial_size` and `maximum_size` properties. |
| `initial_size` | `Integer` |  | Initial size of the pagefile in megabytes. |
| `maximum_size` | `Integer` |  | Maximum size of the pagefile in megabytes. |

### Examples

The following examples demonstrate various approaches for using the **windows_pagefile** resource:

      **Set the system to manage pagefiles**:

      ```ruby
      windows_pagefile 'Enable automatic management of pagefiles' do
        automatic_managed true
      end
      ```

      **Delete a pagefile**:

      ```ruby
      windows_pagefile 'Delete the pagefile' do
        path 'C'
        action :delete
      end
      ```

      **Switch to system managed pagefiles**:

      ```ruby
      windows_pagefile 'Change the pagefile to System Managed' do
        path 'E:\\'
        system_managed true
        action :set
      end
      ```

      **Create a pagefile with an initial and maximum size**:

      ```ruby
      windows_pagefile 'create the pagefile with these sizes' do
        path 'f:\\'
        initial_size 100
        maximum_size 200
      end
      ```


---

## windows_path resource

[windows_path resource page](windows_path/)

Use the **windows_path** resource to manage the path environment variable on Microsoft Windows.

**New in Chef Infra Client 13.4.**

> Source: `lib/chef/resource/windows_path.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_path** resource is:

```ruby
windows_path 'name' do
  path  # String
  action  :symbol # defaults to :add if not specified
end
```

### Actions

The **windows_path** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:add` **(default)** |  |
| `:remove` |  |
| `:modify` |  |
| `:delete` |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `path` | `String` |  | An optional property to set the path value if it differs from the resource block's name. |

### Examples

The following examples demonstrate various approaches for using the **windows_path** resource:

      **Add Sysinternals to the system path**:

      ```ruby
      windows_path 'C:\\Sysinternals' do
        action :add
      end
      ```

      **Remove 7-Zip from the system path**:

      ```ruby
      windows_path 'C:\\7-Zip' do
        action :remove
      end
      ```


---

## windows_printer resource

[windows_printer resource page](windows_printer/)

Use the **windows_printer** resource to setup Windows printers. This resource will automatically install the driver specified in the `driver_name` property and will automatically create a printer port using either the `ipv4_address` property or the `port_name` property.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/windows_printer.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_printer** resource is:

```ruby
windows_printer 'name' do
  device_id  # String
  comment  # String
  default  # [TrueClass, FalseClass]  # default: false
  driver_name  # String
  location  # String
  shared  # [TrueClass, FalseClass]  # default: false
  share_name  # String
  ipv4_address  # String
  create_port  # [TrueClass, FalseClass]  # default: true
  port_name  # String  # default: lazy { |x| "IP_#{x.ipv4_address}" }
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_printer** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:delete` |  |
| `:create` | Create a new printer and printer port, if one doesn't already. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `device_id` | `String` |  | An optional property to set the printer queue name if it differs from the resource block's name. Example: `HP LJ 5200 in fifth floor copy room`. |
| `comment` | `String` |  | Optional descriptor for the printer queue. |
| `default` | `[TrueClass, FalseClass]` | `false` | Determines whether or not this should be the system's default printer. |
| `driver_name` | `String` |  | The exact name of printer driver installed on the system. |
| `location` | `String` |  | Printer location, such as `Fifth floor copy room`. |
| `shared` | `[TrueClass, FalseClass]` | `false` | Determines whether or not the printer is shared. |
| `share_name` | `String` |  | The name used to identify the shared printer. |
| `ipv4_address` | `String` |  | The IPv4 address of the printer, such as `10.4.64.23` |
| `create_port` | `[TrueClass, FalseClass]` | `true` | Create a printer port for the printer. Set this to false and specify the `port_name` property if using the `windows_printer_port` resource to create t |
| `port_name` | `String` | `lazy { |x| "IP_#{x.ipv4_address}" }` | The port name. |

### Examples

The following examples demonstrate various approaches for using the **windows_printer** resource:

      **Create a printer**:

      ```ruby
      windows_printer 'HP LaserJet 5th Floor' do
        driver_name 'HP LaserJet 4100 Series PCL6'
        ipv4_address '10.4.64.38'
      end
      ```

      **Delete a printer**:

      Note: this doesn't delete the associated printer port. See windows_printer_port above for how to delete the port.

      ```ruby
      windows_printer 'HP LaserJet 5th Floor' do
        action :delete
      end
      ```

      **Create a printer port and a printer that uses that port (new in 17.3)**

      ```ruby
      windows_printer_port '10.4.64.39' do
        port_name 'My awesome printer port'
        snmp_enabled true
        port_protocol 2
      end

      windows_printer 'HP LaserJet 5th Floor' do
        driver_name 'HP LaserJet 4100 Series PCL6'
        port_name 'My awesome printer port'
        ipv4_address '10.4.64.38'
        create_port false
      end
      ```


---

## windows_printer_port resource

[windows_printer_port resource page](windows_printer_port/)

Use the **windows_printer_port** resource to create and delete TCP/IPv4 printer ports on Windows.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/windows_printer_port.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_printer_port** resource is:

```ruby
windows_printer_port 'name' do
  ipv4_address  # String
  port_name  # String  # default: lazy { |x| "IP_#{x.ipv4_address}" }
  port_number  # Integer  # default: 9100
  port_description  # String
  snmp_enabled  # [TrueClass, FalseClass]  # default: false
  port_protocol  # Integer  # default: 1
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_printer_port** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:delete` |  |
| `:create` | Create or update the printer port. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `ipv4_address` | `String` |  | An optional property for the IPv4 address of the printer if it differs from the resource block's name. |
| `port_name` | `String` | `lazy { |x| "IP_#{x.ipv4_address}" }` | The port name. |
| `port_number` | `Integer` | `9100` | The TCP port number. |
| `port_description` | `String` |  |  |
| `snmp_enabled` | `[TrueClass, FalseClass]` | `false` | Determines if SNMP is enabled on the port. |
| `port_protocol` | `Integer` | `1` | The printer port protocol: 1 (RAW) or 2 (LPR). |

### Examples

The following examples demonstrate various approaches for using the **windows_printer_port** resource:

      **Delete a printer port**

      ```ruby
      windows_printer_port '10.4.64.37' do
        action :delete
      end
      ```

      **Delete a port with a custom port_name**

      ```ruby
      windows_printer_port '10.4.64.38' do
        port_name 'My awesome port'
        action :delete
      end
      ```

      **Create a port with more options**

      ```ruby
      windows_printer_port '10.4.64.39' do
        port_name 'My awesome port'
        snmp_enabled true
        port_protocol 2
      end
      ```


---

## windows_security_policy resource

[windows_security_policy resource page](windows_security_policy/)

Use the **windows_security_policy** resource to set a security policy on the Microsoft Windows platform.

**New in Chef Infra Client 16.0.**

> Source: `lib/chef/resource/windows_security_policy.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_security_policy** resource is:

```ruby
windows_security_policy 'name' do
  secoption  # String
  secvalue  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_security_policy** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:set` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `secoption` | `String` |  | The name of the policy to be set on windows platform to maintain its security. |
| `secvalue` | `String` |  | Policy value to be set for policy name. |

### Examples

The following examples demonstrate various approaches for using the **windows_security_policy** resource:

      **Set Administrator Account to Enabled**:

      ```ruby
      windows_security_policy 'EnableAdminAccount' do
        secvalue       '1'
        action         :set
      end
      ```

      **Rename Administrator Account**:

      ```ruby
      windows_security_policy 'NewAdministratorName' do
        secvalue       'AwesomeChefGuy'
        action         :set
      end
      ```

      **Set Guest Account to Disabled**:

      ```ruby
      windows_security_policy 'EnableGuestAccount' do
        secvalue       '0'
        action         :set
      end
      ```


---

## windows_service resource

[windows_service resource page](windows_service/)

Chef client as service

**New in Chef Infra Client 12.0.**

> Source: `lib/chef/resource/windows_service.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_service** resource is:

```ruby
windows_service 'name' do
  timeout  # Integer  # default: 60
  display_name  # String
  desired_access  # Integer  # default: SERVICE_ALL_ACCESS
  service_type  # Integer  # default: SERVICE_WIN32_OWN_PROCESS
  startup_type  # [Symbol]  # default: :automatic
  delayed_start  # [TrueClass, FalseClass]  # default: false
  error_control  # Integer  # default: SERVICE_ERROR_NORMAL
  binary_path_name  # String
  load_order_group  # String
  dependencies  # [String, Array]
  description  # String
  run_as_user  # String  # default: "localsystem"
  run_as_password  # String  # default: "" end end
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_service** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:configure_startup` |  |
| `:create` |  |
| `:delete` |  |
| `:configure` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `timeout` | `Integer` | `60` | The amount of time (in seconds) to wait before timing out. |
| `display_name` | `String` |  | The display name to be used by user interface programs to identify the service. This string has a maximum length of 256 characters. |
| `desired_access` | `Integer` | `SERVICE_ALL_ACCESS` |  |
| `service_type` | `Integer` | `SERVICE_WIN32_OWN_PROCESS` |  |
| `startup_type` | `[Symbol]` | `:automatic` | Use to specify the startup type of the service. |
| `delayed_start` | `[TrueClass, FalseClass]` | `false` | Set the startup type to delayed start. This only applies if `startup_type` is `:automatic` |
| `error_control` | `Integer` | `SERVICE_ERROR_NORMAL` |  |
| `binary_path_name` | `String` |  | The fully qualified path to the service binary file. The path can also include arguments for an auto-start service. This is required for `:create` and |
| `load_order_group` | `String` |  | The name of the service's load ordering group(s). |
| `dependencies` | `[String, Array]` |  |  |
| `description` | `String` |  | Description of the service. |
| `run_as_user` | `String` | `"localsystem"` | The user under which a Microsoft Windows service runs. |
| `run_as_password` | `String` | `"" end end` | The password for the user specified by `run_as_user`. |

### Examples

The following examples demonstrate various approaches for using the **windows_service** resource:

      **Starting Services**

      Start a service with a `manual` startup type:

      ```ruby
      windows_service 'BITS' do
        action :configure_startup
        startup_type :manual
      end
      ```

      **Creating Services**

      Create a service named chef-client:

      ```ruby
      windows_service 'chef-client' do
        action :create
        binary_path_name "C:\\opscode\\chef\\bin"
      end
      ```

      Create a service with `service_name` and `display_name`:

      ```ruby
      windows_service 'Setup chef-client as a service' do
        action :create
        display_name 'CHEF-CLIENT'
        service_name 'chef-client'
        binary_path_name "C:\\opscode\\chef\\bin"
      end
      ```

      Create a service with the `manual` startup type:

      ```ruby
      windows_service 'chef-client' do
        action :create
        binary_path_name "C:\\opscode\\chef\\bin"
        startup_type :manual
      end
      ```

      Create a service with the `disabled` startup type:

      ```ruby
      windows_service 'chef-client' do
        action :create
        binary_path_name "C:\\opscode\\chef\\bin"
        startup_type :disabled
      end
      ```

      Create a service with the `automatic` startup type and delayed start enabled:

      ```ruby
      windows_service 'chef-client' do
        action :create
        binary_path_name "C:\\opscode\\chef\\bin"
        startup_type :automatic
        delayed_start true
      end
      ```

      Create a service with a description:

      ```ruby
      windows_service 'chef-client' do
        action :create
        binary_path_name "C:\\opscode\\chef\\bin"
        startup_type :automatic
        description "Chef client as service"
      end
      ```

      **Deleting Services**

      Delete a service named chef-client:

      ```ruby
      windows_service 'chef-client' do
        action :delete
      end
      ```

      Delete a service with the `service_name` property:

      ```ruby
      windows_service 'Delete chef client' do
        action :delete
        service_name 'chef-client'
      end
      ```

      **Configuring Services**

      Change an existing service from automatic to manual startup:

      ```ruby
      windows_service 'chef-client' do
        action :configure
        binary_path_name "C:\\opscode\\chef\\bin"
        startup_type :manual
      end
      ```


---

## windows_share resource

[windows_share resource page](windows_share/)

Use the **windows_share** resource to create, modify and remove Windows shares.

**New in Chef Infra Client 14.7.**

> Source: `lib/chef/resource/windows_share.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_share** resource is:

```ruby
windows_share 'name' do
  share_name  # String
  path  # String
  description  # String
  full_users  # Array  # default: []
  change_users  # Array  # default: []
  read_users  # Array  # default: []
  temporary  # [TrueClass, FalseClass]  # default: false  # Specifies the scope name of the share.
  scope_name  # String  # default: "*"  # Specifies the continuous availability time-out for the share.
  ca_timeout  # Integer  # default: 0  # Indicates that the share is continuously available.
  continuously_available  # [TrueClass, FalseClass]  # default: false  # Specifies the caching mode of the offline files for the SMB share.
  concurrent_user_limit  # Integer  # default: 0  # Indicates that the share is encrypted.
  encrypt_data  # [TrueClass, FalseClass]
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_share** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` |  |
| `:delete` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `share_name` | `String` |  | An optional property to set the share name if it differs from the resource block's name. |
| `path` | `String` |  | The path of the folder to share. Required when creating. If the share already exists on a different path then it is deleted and re-created. |
| `description` | `String` |  | The description to be applied to the share. |
| `full_users` | `Array` | `[]` | The users that should have 'Full control' permissions on the share in domain\\username format. |
| `change_users` | `Array` | `[]` | The users that should have 'modify' permission on the share in domain\\username format. |
| `read_users` | `Array` | `[]` | The users that should have 'read' permission on the share in domain\\username format. |
| `temporary` | `[TrueClass, FalseClass]` | `false  # Specifies the scope name of the share.` | The lifetime of the new SMB share. A temporary share does not persist beyond the next restart of the computer. |
| `scope_name` | `String` | `"*"  # Specifies the continuous availability time-` | The scope name of the share. |
| `ca_timeout` | `Integer` | `0  # Indicates that the share is continuously avai` | The continuous availability time-out for the share. |
| `continuously_available` | `[TrueClass, FalseClass]` | `false  # Specifies the caching mode of the offline` | Indicates that the share is continuously available. |
| `concurrent_user_limit` | `Integer` | `0  # Indicates that the share is encrypted.` | The maximum number of concurrently connected users the share can accommodate. |
| `encrypt_data` | `[TrueClass, FalseClass]` |  | Indicates that the share is encrypted. |

### Examples

The following examples demonstrate various approaches for using the **windows_share** resource:

      **Create a share**:

      ```ruby
      windows_share 'foo' do
        action :create
        path 'C:\\foo'
        full_users ['DOMAIN_A\\some_user', 'DOMAIN_B\\some_other_user']
        read_users ['DOMAIN_C\\Domain users']
      end
      ```

      **Delete a share**:

      ```ruby
      windows_share 'foo' do
        action :delete
      end
      ```


---

## windows_shortcut resource

[windows_shortcut resource page](windows_shortcut/)

Use the **windows_shortcut** resource to create shortcut files on Windows.

**New in Chef Infra Client 14.0.**

> Source: `lib/chef/resource/windows_shortcut.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_shortcut** resource is:

```ruby
windows_shortcut 'name' do
  shortcut_name  # String
  target  # String
  arguments  # String
  description  # String
  cwd  # String
  iconlocation  # String
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_shortcut** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` | Create or modify a Windows shortcut. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `shortcut_name` | `String` |  | An optional property to set the shortcut name if it differs from the resource block's name. |
| `target` | `String` |  | The destination that the shortcut links to. |
| `arguments` | `String` |  | Arguments to pass to the target when the shortcut is executed. |
| `description` | `String` |  | The description of the shortcut |
| `cwd` | `String` |  | Working directory to use when the target is executed. |
| `iconlocation` | `String` |  |  |

### Examples

The following examples demonstrate various approaches for using the **windows_shortcut** resource:

      **Create a shortcut with a description**:

      ```ruby
      windows_shortcut 'C:\\shortcut_dir.lnk' do
        target 'C:\\original_dir'
        description 'Make a shortcut to C:\\original_dir'
      end
      ```


---

## windows_task resource

[windows_task resource page](windows_task/)

Use the **windows_task** resource to create, delete or run a Windows scheduled task.

**New in Chef Infra Client 13.0.**

> Source: `lib/chef/resource/windows_task.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_task** resource is:

```ruby
windows_task 'name' do
  task_name  # String
  command  # String
  cwd  # String
  user  # String  # default: lazy { Chef::ReservedNames::Win32::Security::SID.LocalSystem.account_simple_name if ChefUtils.windows_ruby? }
  password  # String
  run_level  # Symbol  # default: :limited
  force  # [TrueClass, FalseClass]  # default: false
  interactive_enabled  # [TrueClass, FalseClass]  # default: false
  frequency_modifier  # [Integer, String]  # default: 1
  frequency  # Symbol
  start_day  # String
  start_time  # String
  day  # [String, Integer]
  months  # String
  idle_time  # Integer
  random_delay  # [String, Integer]
  execution_time_limit  # [String, Integer]  # default: "PT72H"
  minutes_duration  # [String, Integer]
  minutes_interval  # [String, Integer]
  priority  # Integer  # default: 7
  disallow_start_if_on_batteries  # [TrueClass, FalseClass]  # default: false
  stop_if_going_on_batteries  # [TrueClass, FalseClass]  # default: false
  description  # String
  start_when_available  # [TrueClass, FalseClass]  # default: false
  backup  # [Integer, FalseClass]  # default: 5
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_task** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:delete` |  |
| `:enable` |  |
| `:disable` |  |
| `:create` |  |
| `:run` |  |
| `:end` |  |
| `:change` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `task_name` | `String` |  | An optional property to set the task name if it differs from the resource block's name. Example: `Task Name` or `/Task Name` |
| `command` | `String` |  | The command to be executed by the windows scheduled task. |
| `cwd` | `String` |  | The directory the task will be run from. |
| `user` | `String` | `lazy { Chef::ReservedNames::Win32::Security::SID.L` | The user to run the task as. |
| `password` | `String` |  | The user's password. The user property must be set if using this property. |
| `run_level` | `Symbol` | `:limited` | Run with `:limited` or `:highest` privileges. |
| `force` | `[TrueClass, FalseClass]` | `false` | When used with create, will update the task. |
| `interactive_enabled` | `[TrueClass, FalseClass]` | `false` | Allow task to run interactively or non-interactively. Requires user and password to also be set. |
| `frequency_modifier` | `[Integer, String]` | `1` |  |
| `frequency` | `Symbol` |  | The frequency with which to run the task. Note: This property is required in Chef Infra Client 14.1 or later. Note: The `:once` value requires the `st |
| `start_day` | `String` |  | Specifies the first date on which the task runs in **MM/DD/YYYY** format. |
| `start_time` | `String` |  | Specifies the start time to run the task, in **HH:mm** format. |
| `day` | `[String, Integer]` |  |  |
| `months` | `String` |  | The Months of the year on which the task runs, such as: `JAN, FEB` or `*`. Multiple months should be comma delimited. e.g. `Jan, Feb, Mar, Dec`. |
| `idle_time` | `Integer` |  | For `:on_idle` frequency, the time (in minutes) without user activity that must pass to trigger the task, from `1` - `999`. |
| `random_delay` | `[String, Integer]` |  | Delays the task up to a given time (in seconds). |
| `execution_time_limit` | `[String, Integer]` | `"PT72H"` | The maximum time the task will run. This field accepts either seconds or an ISO8601 duration value. |
| `minutes_duration` | `[String, Integer]` |  |  |
| `minutes_interval` | `[String, Integer]` |  |  |
| `priority` | `Integer` | `7` | Use to set Priority Levels range from 0 to 10. |
| `disallow_start_if_on_batteries` | `[TrueClass, FalseClass]` | `false` | Disallow start of the task if the system is running on battery power. |
| `stop_if_going_on_batteries` | `[TrueClass, FalseClass]` | `false` | Scheduled task option when system is switching on battery. |
| `description` | `String` |  | The task description. |
| `start_when_available` | `[TrueClass, FalseClass]` | `false` | To start the task at any time after its scheduled time has passed. |
| `backup` | `[Integer, FalseClass]` | `5` | Number of backups to keep of the task when modified/deleted. Set to false to disable backups. |

### Examples

The following examples demonstrate various approaches for using the **windows_task** resource:

      **Create a scheduled task to run every 15 minutes as the Administrator user**:

      ```ruby
      windows_task 'chef-client' do
        user 'Administrator'
        password 'password'
        command 'chef-client'
        run_level :highest
        frequency :minute
        frequency_modifier 15
      end
      ```

      **Create a scheduled task to run every 2 days**:

      ```ruby
      windows_task 'chef-client' do
        command 'chef-client'
        run_level :highest
        frequency :daily
        frequency_modifier 2
      end
      ```

      **Create a scheduled task to run on specific days of the week**:

      ```ruby
      windows_task 'chef-client' do
        command 'chef-client'
        run_level :highest
        frequency :weekly
        day 'Mon, Thu'
      end
      ```

      **Create a scheduled task to run only once**:

      ```ruby
      windows_task 'chef-client' do
        command 'chef-client'
        run_level :highest
        frequency :once
        start_time '16:10'
      end
      ```

      **Create a scheduled task to run on current day every 3 weeks and delay upto 1 min**:

      ```ruby
      windows_task 'chef-client' do
        command 'chef-client'
        run_level :highest
        frequency :weekly
        frequency_modifier 3
        random_delay '60'
      end
      ```

      **Create a scheduled task to run weekly starting on Dec 28th 2018**:

      ```ruby
      windows_task 'chef-client 8' do
        command 'chef-client'
        run_level :highest
        frequency :weekly
        start_day '12/28/2018'
      end
      ```

      **Create a scheduled task to run every Monday, Friday every 2 weeks**:

      ```ruby
      windows_task 'chef-client' do
        command 'chef-client'
        run_level :highest
        frequency :weekly
        frequency_modifier 2
        day 'Mon, Fri'
      end
      ```

      **Create a scheduled task to run when computer is idle with idle duration 20 min**:

      ```ruby
      windows_task 'chef-client' do
        command 'chef-client'
        run_level :highest
        frequency :on_idle
        idle_time 20
      end
      ```

      **Delete a task named "old task"**:
      ```ruby
      windows_task 'old task' do
        action :delete
      end
      ```

      **Enable a task named "chef-client"**:
      ```ruby
      windows_task 'chef-client' do
        action :enable
      end
      ```

      **Disable a task named "ProgramDataUpdater" with TaskPath "\\Microsoft\\Windows\\Application Experience\\ProgramDataUpdater"**
      ```ruby
      windows_task '\\Microsoft\\Windows\\Application Experience\\ProgramDataUpdater' do
        action :disable
      end
      ```


---

## windows_uac resource

[windows_uac resource page](windows_uac/)

The **windows_uac** resource.

**New in Chef Infra Client 15.0.**

> Source: `lib/chef/resource/windows_uac.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_uac** resource is:

```ruby
windows_uac 'name' do
  enable_uac  # [TrueClass, FalseClass]  # default: true # EnableLUA
  require_signed_binaries  # [TrueClass, FalseClass]  # default: false
  prompt_on_secure_desktop  # [TrueClass, FalseClass]  # default: true
  detect_installers  # [TrueClass, FalseClass]
  consent_behavior_admins  # Symbol  # default: :prompt_for_consent_non_windows_binaries
  consent_behavior_users  # Symbol  # default: :prompt_for_creds
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_uac** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:configure` | Configures UAC by setting registry keys at `HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System`. |
| `:create` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `enable_uac` | `[TrueClass, FalseClass]` | `true # EnableLUA` |  |
| `require_signed_binaries` | `[TrueClass, FalseClass]` | `false` |  |
| `prompt_on_secure_desktop` | `[TrueClass, FalseClass]` | `true` |  |
| `detect_installers` | `[TrueClass, FalseClass]` |  |  |
| `consent_behavior_admins` | `Symbol` | `:prompt_for_consent_non_windows_binaries` |  |
| `consent_behavior_users` | `Symbol` | `:prompt_for_creds` |  |

### Examples

The following examples demonstrate various approaches for using the **windows_uac** resource:

      **Disable UAC prompts for the admin**:

      ```ruby
      windows_uac 'Disable UAC prompts for the admin' do
        enable_uac true
        prompt_on_secure_desktop false
        consent_behavior_admins :no_prompt
      end
      ```

      **Disable UAC entirely**:

      ```ruby
      windows_uac 'Disable UAC entirely' do
        enable_uac false
      end
      ```


---

## windows_update_settings resource

[windows_update_settings resource page](windows_update_settings/)

Use the **windows_update_settings** resource to manage the various Windows Update patching options.

**New in Chef Infra Client 17.3.**

> Source: `lib/chef/resource/windows_update_settings.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_update_settings** resource is:

```ruby
windows_update_settings 'name' do
  disable_os_upgrades  # [true, false]  # default: false
  elevate_non_admins  # [true, false]  # default: true
  add_to_target_wsus_group  # [true, false]
  target_wsus_group_name  # String
  wsus_server_url  # String
  wsus_status_server_url  # String
  block_windows_update_website  # [true, false]  # default: false
  automatic_update_option  # [Integer, Symbol]  # default: :download_and_schedule
  automatically_install_minor_updates  # [true, false]  # default: false
  enable_detection_frequency  # [true, false]  # default: false
  custom_detection_frequency  # Integer  # default: 22
  no_reboot_with_users_logged_on  # [true, false]  # default: true
  disable_automatic_updates  # [true, false]  # default: false
  scheduled_install_day  # String  # default: DAYS.first
  scheduled_install_hour  # Integer
  update_other_ms_products  # [true, false]  # default: true
  custom_wsus_server  # [true, false]
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_update_settings** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:enable` |  |
| `:set` |  |
| `:create` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `disable_os_upgrades` | `[true, false]` | `false` | Disable OS upgrades. |
| `elevate_non_admins` | `[true, false]` | `true` | Allow normal user accounts to temporarily be elevated to install patches. |
| `add_to_target_wsus_group` | `[true, false]` |  |  |
| `target_wsus_group_name` | `String` |  | Add the node to a WSUS Target Group. |
| `wsus_server_url` | `String` |  | The URL of your WSUS server if you use one. |
| `wsus_status_server_url` | `String` |  |  |
| `block_windows_update_website` | `[true, false]` | `false` | Block accessing the Windows Update website. |
| `automatic_update_option` | `[Integer, Symbol]` | `:download_and_schedule` |  |
| `automatically_install_minor_updates` | `[true, false]` | `false` | Automatically install minor updates. |
| `enable_detection_frequency` | `[true, false]` | `false` | Used to override the OS default of how often to check for updates |
| `custom_detection_frequency` | `Integer` | `22` | If you decided to override the OS default detection frequency, specify your choice here. Valid choices are 0 - 22 |
| `no_reboot_with_users_logged_on` | `[true, false]` | `true` | Prevents the OS from rebooting while someone is on the console. |
| `disable_automatic_updates` | `[true, false]` | `false` | Disable Windows Update. |
| `scheduled_install_day` | `String` | `DAYS.first` | A day of the week to tell Windows when to install updates. |
| `scheduled_install_hour` | `Integer` |  | If you chose a scheduled day to install, then choose an hour on that day for you installation |
| `update_other_ms_products` | `[true, false]` | `true` | Allows for other Microsoft products to get updates too |
| `custom_wsus_server` | `[true, false]` |  |  |

### Examples

The following examples demonstrate various approaches for using the **windows_update_settings** resource:

      **Set Windows Update settings**:

      ```ruby
      windows_update_settings 'Settings to Configure Windows Nodes to automatically receive updates' do
        disable_os_upgrades true
        elevate_non_admins true
        block_windows_update_website true
        automatically_install_minor_updates true
        scheduled_install_day 'Friday'
        scheduled_install_hour 18
        update_other_ms_products true
        action :enable
      end
      ```


---

## windows_user_privilege resource

[windows_user_privilege resource page](windows_user_privilege/)

Use the **windows_user_privilege** resource to set privileges for a principal, user, or group.  See [Microsoft's user rights assignment documentation](https://learn.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/user-rights-assignment) for more information.

**New in Chef Infra Client 16.0.**

> Source: `lib/chef/resource/windows_user_privilege.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_user_privilege** resource is:

```ruby
windows_user_privilege 'name' do
  principal  # String
  users  # [Array, String]
  privilege  # [Array, String]
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_user_privilege** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:set` |  |
| `:add` |  |
| `:remove` |  |
| `:clear` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `principal` | `String` |  |  |
| `users` | `[Array, String]` |  | An optional property to set the privilege for the specified users. Use only with `:set` action |
| `privilege` | `[Array, String]` |  |  |

### Examples

The following examples demonstrate various approaches for using the **windows_user_privilege** resource:

      **Set the SeNetworkLogonRight privilege for the Builtin Administrators and Authenticated Users groups**:

      The `:set` action will add this privilege for these two groups and remove this privilege from all other groups or users.

      ```ruby
      windows_user_privilege 'Network Logon Rights' do
        privilege      'SeNetworkLogonRight'
        users          ['BUILTIN\\Administrators', 'NT AUTHORITY\\Authenticated Users']
        action         :set
      end
      ```

      **Set the SeCreatePagefilePrivilege privilege for the Builtin Guests and Administrator groups**:

      The `:set` action will add this privilege for these two groups and remove this privilege from all other groups or users.

      ```ruby
      windows_user_privilege 'Create Pagefile' do
        privilege      'SeCreatePagefilePrivilege'
        users          ['BUILTIN\\Guests', 'BUILTIN\\Administrators']
        action         :set
      end
      ```

      **Add the SeDenyRemoteInteractiveLogonRight privilege to the 'Remote interactive logon' principal**:

      ```ruby
      windows_user_privilege 'Remote interactive logon' do
        privilege      'SeDenyRemoteInteractiveLogonRight'
        action         :add
      end
      ```

      **Add the SeCreatePageFilePrivilege privilege to the Builtin Guests group**:

      ```ruby
      windows_user_privilege 'Guests add Create Pagefile' do
        principal      'BUILTIN\\Guests'
        privilege      'SeCreatePagefilePrivilege'
        action         :add
      end
      ```

      **Remove the SeCreatePageFilePrivilege privilege from the Builtin Guests group**:

      ```ruby
      windows_user_privilege 'Create Pagefile' do
        privilege      'SeCreatePagefilePrivilege'
        principal      'BUILTIN\\Guests'
        action         :remove
      end
      ```

      **Clear the SeDenyNetworkLogonRight privilege from all users**:

      ```ruby
      windows_user_privilege 'Allow any user the Network Logon right' do
        privilege      'SeDenyNetworkLogonRight'
        action         :clear
      end
      ```


---

## windows_workgroup resource

[windows_workgroup resource page](windows_workgroup/)

Use the **windows_workgroup** resource to join or change the workgroup of a Windows host.

**New in Chef Infra Client 14.5.**

> Source: `lib/chef/resource/windows_workgroup.rb`

### Syntax

The full syntax for all of the properties that are available to the **windows_workgroup** resource is:

```ruby
windows_workgroup 'name' do
  workgroup_name  # String
  user  # String
  password  # String
  reboot  # Symbol
  sensitive  # [TrueClass, FalseClass]  # default: true
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **windows_workgroup** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:join` | Update the workgroup. |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `workgroup_name` | `String` |  | An optional property to set the workgroup name if it differs from the resource block's name. |
| `user` | `String` |  | The local administrator user to use to change the workgroup. Required if using the `password` property. |
| `password` | `String` |  | The password for the local administrator user. Required if using the `user` property. |
| `reboot` | `Symbol` |  |  |
| `sensitive` | `[TrueClass, FalseClass]` | `true` |  |

### Examples

The following examples demonstrate various approaches for using the **windows_workgroup** resource:

      **Join a workgroup**:

      ```ruby
      windows_workgroup 'myworkgroup'
      ```

      **Join a workgroup using a specific user**:

      ```ruby
      windows_workgroup 'myworkgroup' do
        user 'Administrator'
        password 'passw0rd'
      end
      ```


---

## yum_package resource

[yum_package resource page](yum_package/)

Use the **yum_package** resource to install, upgrade, and remove packages with Yum for the Red Hat and CentOS platforms. The yum_package resource is able to resolve `provides` data for packages much like Yum can do when it is run from the command line. This allows a variety of options for installing packages, like minimum versions, virtual provides, and library names. Note: Support for using file names to install packages (as in `yum_package '/bin/sh'`) is not available because the volume of data required to parse for this is excessive.

**New in Chef Infra Client 19.0.** *(catalog version; not declared in local source)*

> Source: `lib/chef/resource/yum_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **yum_package** resource is:

```ruby
yum_package 'name' do
  package_name  # [ String, Array ]
  version  # [ String, Array ]
  arch  # [ String, Array ]
  flush_cache  # Hash  # default: { before: false
  allow_downgrade  # [ TrueClass, FalseClass ]  # default: true
  yum_binary  # String
  environment  # Hash  # default: {}
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **yum_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:upgrade` |  |
| `:remove` |  |
| `:purge` |  |
| `:lock` |  |
| `:unlock` |  |
| `:flush_cache` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `package_name` | `[ String, Array ]` |  | One of the following: the name of a package, the name of a package and its architecture, the name of a dependency. |
| `version` | `[ String, Array ]` |  | The version of a package to be installed or upgraded. This property is ignored when using the `:upgrade` action. |
| `arch` | `[ String, Array ]` |  | The architecture of the package to be installed or upgraded. This value can also be passed as part of the package name. |
| `flush_cache` | `Hash` | `{ before: false` |  |
| `allow_downgrade` | `[ TrueClass, FalseClass ]` | `true` | Allow downgrading a package to satisfy requested version requirements. |
| `yum_binary` | `String` |  | The path to the yum binary. |
| `environment` | `Hash` | `{}` | A Hash of environment variables in the form of {'ENV_VARIABLE' => 'VALUE'} to be set before running the command. |

### Agentless Mode

The **yum_package** resource has **full** support for Agentless Mode.

Support was added in Chef Infra Client 19.0.

### Examples

The following examples demonstrate various approaches for using the **yum_package** resource:

        **Install an exact version**:

        ```ruby
        yum_package 'netpbm = 10.35.58-8.el8'
        ```

        **Install a minimum version**:

        ```ruby
        yum_package 'netpbm >= 10.35.58-8.el8'
        ```

        **Install a minimum version using the default action**:

        ```ruby
        yum_package 'netpbm'
        ```

        **Install a version without worrying about the exact release**:

        ```ruby
        yum_package 'netpbm-10.35*'
        ```


        **To install a package**:

        ```ruby
        yum_package 'netpbm' do
          action :install
        end
        ```

        **To install a partial minimum version**:

        ```ruby
        yum_package 'netpbm >= 10'
        ```

        **To install a specific architecture**:

        ```ruby
        yum_package 'netpbm' do
          arch 'i386'
        end
        ```

        or:

        ```ruby
        yum_package 'netpbm.x86_64'
        ```

        **To install a specific version-release**

        ```ruby
        yum_package 'netpbm' do
          version '10.35.58-8.el8'
        end
        ```

        **Handle cookbook_file and yum_package resources in the same recipe**:

        When a **cookbook_file** resource and a **yum_package** resource are
        both called from within the same recipe, use the `flush_cache` attribute
        to dump the in-memory Yum cache, and then use the repository immediately
        to ensure that the correct package is installed:

        ```ruby
        cookbook_file '/etc/yum.repos.d/custom.repo' do
          source 'custom'
          mode '0755'
        end

        yum_package 'pkg-that-is-only-in-custom-repo' do
          action :install
          flush_cache [ :before ]
        end
        ```


---

## yum_repository resource

[yum_repository resource page](yum_repository/)

Use the **yum_repository** resource to manage a Yum repository configuration file located at `/etc/yum.repos.d/repositoryid.repo` on the local machine. This configuration file specifies which repositories to reference, how to handle cached data, etc.

**New in Chef Infra Client 12.14.**

> Source: `lib/chef/resource/yum_repository.rb`

### Syntax

The full syntax for all of the properties that are available to the **yum_repository** resource is:

```ruby
yum_repository 'name' do
  reposdir  # String  # default: "/etc/yum.repos.d/"
  baseurl  # [String, Array]
  clean_headers  # [TrueClass, FalseClass]  # default: false
  clean_metadata  # [TrueClass, FalseClass]  # default: true
  cost  # String
  description  # String  # default: "Yum Repository"
  enabled  # [TrueClass, FalseClass]  # default: true
  enablegroups  # [TrueClass, FalseClass]
  exclude  # String
  failovermethod  # String
  fastestmirror_enabled  # [TrueClass, FalseClass]
  gpgcheck  # [TrueClass, FalseClass]  # default: true
  gpgkey  # [String, Array]
  http_caching  # String
  include_config  # String
  includepkgs  # String
  keepalive  # [TrueClass, FalseClass]
  make_cache  # [TrueClass, FalseClass]  # default: true
  makecache_fast  # [TrueClass, FalseClass]  # default: false
  max_retries  # [String, Integer]
  metadata_expire  # String
  metalink  # String
  mirror_expire  # String
  mirrorlist_expire  # String
  mirrorlist  # String
  mode  # [String, Integer]  # default: "0644"
  options  # Hash
  password  # String
  priority  # String
  proxy_password  # String
  proxy_username  # String
  proxy  # String
  repo_gpgcheck  # [TrueClass, FalseClass]
  report_instanceid  # [TrueClass, FalseClass]
  repositoryid  # String
  skip_if_unavailable  # [TrueClass, FalseClass]
  source  # String
  sslcacert  # String
  sslclientcert  # String
  sslclientkey  # String
  sslverify  # [TrueClass, FalseClass]
  throttle  # [String, Integer]
  timeout  # String
  username  # String
  action  :symbol # defaults to :create if not specified
end
```

### Actions

The **yum_repository** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:create` **(default)** |  |
| `:delete` |  |
| `:remove` |  |
| `:makecache` |  |
| `:add` |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `reposdir` | `String` | `"/etc/yum.repos.d/"` | The directory where the Yum repository files should be stored |
| `baseurl` | `[String, Array]` |  | URL to the directory where the Yum repository's `repodata` directory lives. Can be an `http://`, `https://` or a `ftp://` URLs. You can specify multip |
| `clean_headers` | `[TrueClass, FalseClass]` | `false` | Specifies whether you want to purge the package data files that are downloaded from a Yum repository and held in a cache directory. |
| `clean_metadata` | `[TrueClass, FalseClass]` | `true` | Specifies whether you want to purge all of the packages downloaded from a Yum repository and held in a cache directory. |
| `cost` | `String` |  | Relative cost of accessing this repository. Useful for weighing one repo's packages as greater/less than any other. |
| `description` | `String` | `"Yum Repository"` | Descriptive name for the repository channel and maps to the 'name' parameter in a repository .conf. |
| `enabled` | `[TrueClass, FalseClass]` | `true` | Specifies whether or not Yum should use this repository. |
| `enablegroups` | `[TrueClass, FalseClass]` |  | Specifies whether Yum will allow the use of package groups for this repository. |
| `exclude` | `String` |  | List of packages to exclude from updates or installs. This should be a space separated list. Shell globs using wildcards (eg. * and ?) are allowed. |
| `failovermethod` | `String` |  |  |
| `fastestmirror_enabled` | `[TrueClass, FalseClass]` |  | Specifies whether to use the fastest mirror from a repository configuration when more than one mirror is listed in that configuration. |
| `gpgcheck` | `[TrueClass, FalseClass]` | `true` | Specifies whether or not Yum should perform a GPG signature check on the packages received from a repository. |
| `gpgkey` | `[String, Array]` |  |  |
| `http_caching` | `String` |  |  |
| `include_config` | `String` |  | An external configuration file using the format `url://to/some/location`. |
| `includepkgs` | `String` |  | Inverse of exclude property. This is a list of packages you want to use from a repository. If this option lists only one package then that is all Yum  |
| `keepalive` | `[TrueClass, FalseClass]` |  | Determines whether or not HTTP/1.1 `keep-alive` should be used with this repository. |
| `make_cache` | `[TrueClass, FalseClass]` | `true` | Determines whether package files downloaded by Yum stay in cache directories. By using cached data, you can carry out certain operations without a net |
| `makecache_fast` | `[TrueClass, FalseClass]` | `false` | if make_cache is true, uses `yum makecache fast`, which downloads only the minimum amount of data required. Useful over slower connections and when di |
| `max_retries` | `[String, Integer]` |  | Number of times any attempt to retrieve a file should retry before returning an error. Setting this to `0` makes Yum try forever. |
| `metadata_expire` | `String` |  |  |
| `metalink` | `String` |  | Specifies a URL to a metalink file for the repomd.xml, a list of mirrors for the entire repository are generated by converting the mirrors for the rep |
| `mirror_expire` | `String` |  |  |
| `mirrorlist_expire` | `String` |  |  |
| `mirrorlist` | `String` |  | URL to a file containing a list of baseurls. This can be used instead of or with the baseurl option. Substitution variables, described below, can be u |
| `mode` | `[String, Integer]` | `"0644"` | Permissions mode of .repo file on disk. This is useful for scenarios where secrets are in the repo file. If this value is set to `600`, normal users w |
| `options` | `Hash` |  | Specifies the repository options. |
| `password` | `String` |  | Password to use with the username for basic authentication. |
| `priority` | `String` |  |  |
| `proxy_password` | `String` |  | Password for this proxy. |
| `proxy_username` | `String` |  | Username to use for proxy. |
| `proxy` | `String` |  | URL to the proxy server that Yum should use. |
| `repo_gpgcheck` | `[TrueClass, FalseClass]` |  | Determines whether or not Yum should perform a GPG signature check on the repodata from this repository. |
| `report_instanceid` | `[TrueClass, FalseClass]` |  | Determines whether to report the instance ID when using Amazon Linux AMIs and repositories. |
| `repositoryid` | `String` |  | An optional property to set the repository name if it differs from the resource block's name. |
| `skip_if_unavailable` | `[TrueClass, FalseClass]` |  | Allow yum to continue if this repository cannot be contacted for any reason. |
| `source` | `String` |  | Use a custom template source instead of the default one. |
| `sslcacert` | `String` |  | Path to the directory containing the databases of the certificate authorities Yum should use to verify SSL certificates. |
| `sslclientcert` | `String` |  | Path to the SSL client certificate Yum should use to connect to repos/remote sites. |
| `sslclientkey` | `String` |  | Path to the SSL client key Yum should use to connect to repos/remote sites. |
| `sslverify` | `[TrueClass, FalseClass]` |  | Determines whether Yum will verify SSL certificates/hosts. |
| `throttle` | `[String, Integer]` |  | Enable bandwidth throttling for downloads. |
| `timeout` | `String` |  | Number of seconds to wait for a connection before timing out. Defaults to 30 seconds. This may be too short of a time for extremely overloaded sites. |
| `username` | `String` |  | Username to use for basic authentication to a repository. |

### Agentless Mode

The **yum_repository** resource has **full** support for Agentless Mode.

Support was added in Chef Infra Client 16.9.

### Examples

The following examples demonstrate various approaches for using the **yum_repository** resource:

      **Add an internal company repository**:

      ```ruby
      yum_repository 'OurCo' do
        description 'OurCo yum repository'
        mirrorlist 'http://artifacts.ourco.org/mirrorlist?repo=ourco-8&arch=$basearch'
        gpgkey 'http://artifacts.ourco.org/pub/yum/RPM-GPG-KEY-OURCO-8'
        action :create
      end
      ```

      **Delete a repository**:

      ```ruby
      yum_repository 'CentOS-Media' do
        action :delete
      end
      ```


---

## zypper_package resource

[zypper_package resource page](zypper_package/)

Use the **zypper_package** resource to install, upgrade, and remove packages with Zypper for the SUSE Enterprise and openSUSE platforms.

**New in Chef Infra Client 13.6.** *(catalog version; not declared in local source)*

> Source: `lib/chef/resource/zypper_package.rb`

### Syntax

The full syntax for all of the properties that are available to the **zypper_package** resource is:

```ruby
zypper_package 'name' do
  gpg_check  # [ TrueClass, FalseClass ]  # default: lazy { Chef::Config[:zypper_check_gpg] }
  allow_downgrade  # [ TrueClass, FalseClass ]  # default: true
  global_options  # [ String, Array ]
  action  :symbol # defaults to :nothing unless notified
end
```

### Actions

The **zypper_package** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:install` |  |
| `:upgrade` |  |
| `:remove` |  |
| `:purge` |  |
| `:lock` |  |
| `:unlock` |  |
| `:nothing` **(default)** | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `gpg_check` | `[ TrueClass, FalseClass ]` | `lazy { Chef::Config[:zypper_check_gpg] }` | Verify the package's GPG signature. Can also be controlled site-wide using the `zypper_check_gpg` config option. |
| `allow_downgrade` | `[ TrueClass, FalseClass ]` | `true` | Allow downgrading a package to satisfy requested version requirements. |
| `global_options` | `[ String, Array ]` |  |  |

### Agentless Mode

The **zypper_package** resource has **full** support for Agentless Mode.

Support was added in Chef Infra Client 13.6.

### Examples

The following examples demonstrate various approaches for using the **zypper_package** resource:

        **Install a package using package manager:**

        ```ruby
        zypper_package 'name of package' do
          action :install
        end
        ```

        **Install a package using local file:**

        ```ruby
        zypper_package 'jwhois' do
          action :install
          source '/path/to/jwhois.rpm'
        end
        ```

        **Install without using recommend packages as a dependency:**

        ```ruby
        package 'apache2' do
          options '--no-recommends'
        end
        ```


---

## zypper_repository resource

[zypper_repository resource page](zypper_repository/)

Use the **zypper_repository** resource to create Zypper package repositories on SUSE Enterprise Linux and openSUSE systems. This resource maintains full compatibility with the **zypper_repository** resource in the existing **zypper** cookbook.

**New in Chef Infra Client 13.3.**

> Source: `lib/chef/resource/zypper_repository.rb`

### Syntax

The full syntax for all of the properties that are available to the **zypper_repository** resource is:

```ruby
zypper_repository 'name' do
  repo_name  # String
  description  # String
  type  # String  # default: "NONE"
  enabled  # [TrueClass, FalseClass]  # default: true
  autorefresh  # [TrueClass, FalseClass]  # default: true
  gpgcheck  # [TrueClass, FalseClass]  # default: true
  gpgkey  # [String, Array]  # default: []
  baseurl  # String
  mirrorlist  # String
  path  # String
  priority  # Integer  # default: 99
  keeppackages  # [TrueClass, FalseClass]  # default: false
  mode  # [String, Integer]  # default: "0644"
  refresh_cache  # [TrueClass, FalseClass]  # default: true
  source  # String
  cookbook  # String  # default: lazy { cookbook_name }
  gpgautoimportkeys  # [TrueClass, FalseClass]  # default: true  default_action :create
  action  :symbol # defaults to :create if not specified
end
```

### Actions

The **zypper_repository** resource has the following actions:

| Action | Description |
|--------|-------------|
| `:delete` |  |
| `:refresh` |  |
| `:create` **(default)** |  |
| `:remove` |  |
| `:add` |  |
| `:nothing` | This resource block doesn't act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run. |

### Properties

| Property | Ruby Type | Default | Description |
|----------|-----------|---------|-------------|
| `repo_name` | `String` |  | An optional property to set the repository name if it differs from the resource block's name. |
| `description` | `String` |  | The description of the repository that will be shown by the `zypper repos` command. |
| `type` | `String` | `"NONE"` | Specifies the repository type. |
| `enabled` | `[TrueClass, FalseClass]` | `true` | Determines whether or not the repository should be enabled. |
| `autorefresh` | `[TrueClass, FalseClass]` | `true` | Determines whether or not the repository should be refreshed automatically. |
| `gpgcheck` | `[TrueClass, FalseClass]` | `true` | Determines whether or not to perform a GPG signature check on the repository. |
| `gpgkey` | `[String, Array]` | `[]` | The location of the repository key(s) to be imported. |
| `baseurl` | `String` |  | The base URL for the Zypper repository, such as `http://download.opensuse.org`. |
| `mirrorlist` | `String` |  | The URL of the mirror list that will be used. |
| `path` | `String` |  | The relative path from the repository's base URL. |
| `priority` | `Integer` | `99` | Determines the priority of the Zypper repository. |
| `keeppackages` | `[TrueClass, FalseClass]` | `false` | Determines whether or not packages should be saved. |
| `mode` | `[String, Integer]` | `"0644"` | The file mode of the repository file. |
| `refresh_cache` | `[TrueClass, FalseClass]` | `true` | Determines whether or not the package cache should be refreshed. |
| `source` | `String` |  | The name of the template for the repository file. Only necessary if you're using a custom template for the repository file. |
| `cookbook` | `String` | `lazy { cookbook_name }` | The cookbook to source the repository template file from. Only necessary if you're using a custom template for the repository file. |
| `gpgautoimportkeys` | `[TrueClass, FalseClass]` | `true  default_action :create` | Automatically import the specified key when setting up the repository. |

### Agentless Mode

The **zypper_repository** resource has **full** support for Agentless Mode.

### Examples

The following examples demonstrate various approaches for using the **zypper_repository** resource:

        **Add the Apache repo on openSUSE Leap 15**:

        ```ruby
        zypper_repository 'apache' do
          baseurl 'http://download.opensuse.org/repositories/Apache'
          path '/openSUSE_Leap_15.2'
          type 'rpm-md'
          priority '100'
        end
        ```

        **Remove the repo named 'apache'**:

        ```ruby
        zypper_repository 'apache' do
          action :delete
        end
        ```

        **Refresh the repo named 'apache'**:

        ```ruby
        zypper_repository 'apache' do
          action :refresh
        end
        ```


