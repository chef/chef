<!---
This file is reset every time a new release is done. The contents of this file are for the currently unreleased version.

Example Note:

## Example Heading
Details about the thing that changed that needs to get included in the Release Notes in markdown.
-->
# Chef Client Release Notes:

#### Chef Solo Missing Dependency Improvments ([CHEF-4367](https://tickets.opscode.com/browse/CHEF-4367))

Chef 11.0 introduced ordered evaluation of non-recipe files in
cookbooks, based on the dependencies specified in your cookbooks'
metadata. This was a huge improvement on the previous behavior for all
chef users, but it also introduced a problem for chef-solo users:
because of the way chef-solo works, it was possible to use
`include_recipe` to load a recipe from a cookbook without specifying the
dependency in the metadata. This would load the recipe without having
evaluated the associated attributes, libraries, LWRPs, etc. in that
recipe's cookbook, and the recipe would fail to load with errors that
did not suggest the actual cause of the failure.

We've added a check to `include_recipe` so that attempting to include a
recipe which is not a dependency of any cookbook specified in the run
list will now raise an error with a message describing the problem and
solution.

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
