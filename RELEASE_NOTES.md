<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->
# Chef Client Release Notes:

#### reboot_pending?  

We have added a ```reboot_pending?``` method to the recipe DSL. This method returns true or false if the operating system
has a rebooting pending due to updates and a reboot being necessary to complete the installation. It does not report if a reboot has been requested, e.g. if someone has scheduled a restart using shutdown. It currently supports Windows and Ubuntu Linux.

```
Chef::Log.warn "There is a pending reboot, which will affect this Chef run" if reboot_pending?

execute "Install Application" do
  command 'C:\application\setup.exe'
  not_if { reboot_pending? }
end
```

#### OHAI 7

After spending 3 months in the RC stage, OHAI 7 is now included in Chef Client 11.10.0. Note that Chef Client 10.32.0 still includes OHAI 6.

For more information about the changes in OHAI 7 please see our previous blog post [here](http://www.getchef.com/blog/2014/01/20/ohai-7-0-release-candidate/).

# Chef Client Breaking Changes:

None.
