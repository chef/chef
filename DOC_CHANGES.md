<!---
This file is reset every time a new release is done. This file describes changes that have not yet been released.

Example Doc Change:
### Headline for the required change
Description of the required change.
-->

### --run-lock-timeout for chef-client and chef-solo
You can now add a timeout for the maximum time a client run waits on another client run to finish.
The default is to wait indefinitely.
Setting the run lock timeout to 0 causes the second client run to exit immediately.

This can be configured in your config file:
```
run_lock_timeout SECONDS
```

Or via the command line:
```
chef-client --run-lock-timeout SECONDS
```

#### New knife command: knife node environment set
You can now easily set the environment for an existing node without editing the node object:

```
knife node environment set NODE ENVIRONMENT
```
### New configurable knife bootstrap options for chef-full template
You can now modify the chef-full template with the following options in `knife bootstrap`:

* `--bootstrap-install-sh URL` fetches and executes an installation bash script from the provided URL.
* `--bootstrap-wget-options OPTIONS` and `--bootstrap-curl-options OPTIONS` allow arbitrary options to be added to wget and curl.
* `--bootstrap-install-command COMMAND` can be used to execute a custom chef-client installation command sequence. Take note that this cannot be used in conjunction with the above options.

### New chef config options: Whitelisting for the attributes saved by the node

You can now whitelist attributes that will be saved by the node by providing a hash with the keys you want to include. Whitelist filters are described for each attribute level: `automatic_attribute_whitelist`, `default_attribute_whitelist`, `normal_attribute_whitelist`, and `override_attribute_whitelist`.

If your automatic attribute data looks like
````
{
  "filesystem" => {
    "/dev/disk0s2" => {
      "size" => "10mb"
    },
    "map - autohome" => {
      "size" => "10mb"
    }
  }
}
````
and your config file looks like
````
automatic_attribute_whitelist =
  {
    "filesystem" => {
      "/dev/disk0s2" => true
    }
  }
````
then the entire `map - autohome` subtree will not be saved by the node.

If your config file looks like `automatic_attribute_whitelist = {}`, then none of your automatic attribute data will be saved by the node.

The default behavior is for the node to save all the attribute data. This can be ensured by setting your whitelist filter to `nil`.

Note that only the keys in this has will be used. If the values are anything other than a hash, they are ignored. You cannot magically morph these config options into a blacklist by putting `false` as a value in the whitelist.
