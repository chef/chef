# Chef Client Release Notes 11.16.0:

## Known Issues

### Some Ubuntu 13.10+ services will require a provider

The Upstart "compatibility interface" for /etc/init.d/ is no longer used as of
Ubuntu 13.10 (Saucy). The default service provider in Chef for Ubuntu uses the sysvinit
scripts located in /etc/init.d, but some of these init scripts will now exit with a failure when
sent a start command and exit with success but do nothing for a stop command.

The "ssh" and "rsyslog" services are currently known to exhibit this behavior. A Chef service resource
that manages these services, on these versions of Ubuntu, must be passed the provider attribute
to manually specify the Upstart provider, e.g.:

```
service "ssh" do
  provider Chef::Provider::Service::Upstart if platform?("ubuntu") && node["platform_version"].to_f >= 13.10
  action :start
end
```

Fix status: [Github Issue #1587](https://github.com/opscode/chef/issues/1587)
Original bug: [JIRA CHEF-5276](https://tickets.opscode.com/browse/CHEF-5276)

## Bug Fixes and New Features

### New dsc\_script resource for PowerShell DSC on Windows
The `dsc_script` resource is new in Chef with this release. `dsc_script`
allows the invocation of
[PowerShell Desired State Configuration]((http://technet.microsoft.com/en-us/library/dn249912.aspx) (DSC) scripts
from Chef recipes. The `dsc_script` resource is only available for systems
running the Windows operating systtem with **PowerShell version 4.0 or later** installed. Windows systems may be
updated to PowerShell version 4.0 or later using the [PowerShell cookbook](https://supermarket.getchef.com/cookbooks/powershell)
available at [Chef Supermarket](http://supermarket.getchef.com). 

The **WinRM** service required by PowerShell DSC must be enabled on the system as well in order to use
the `dsc_script` resource -- this can be accomplished using the Windows OS `winrm quickconfig` command.

