# Chef Client Release Notes 11.14.0:

### CHEF-5223 OS X Service provider regression.

This commit: https://github.com/opscode/chef/commit/024b1e3e4de523d3c1ebbb42883a2bef3f9f415c
introduced a requirement that a service have a plist file for any
action, but a service that is being created will not have a plist file
yet. Chef now only requires that a service have a plist for the enable
and disable actions.

### Signal Regression Fix

CHEF-1761 introduced a regression for signal handling when not in daemon mode
(see CHEF-5172). Chef will now, once again, exit immediately on SIGTERM if it
is not in daemon mode, otherwise it will complete it's current run before
existing.

### Ubuntu 13.10+ uses Upstart service provider.

The "compatibility interface" for /etc/init.d/ is no longer used at least as of
13.10 (per the Ubuntu wiki page). The default service provider in Chef for Ubuntu
is C:\:\P::S::Debian, which uses /etc/init.d/service_name with the start, stop,
etc commands to manage the script. If you are able to use the init provider just
fine, you will need to manually override the provider back to Debian.


### New knife command: knife serve
You can now run a persistent chef-zero against your local repository:

```
knife serve
```

knife serve takes --chef-zero-host=HOST, --chef-zero-port=PORT and --chef-repo-path=PATH variables. By default, it will do exactly the same thing as the local mode argument to knife and chef-client (-z), locating your chef-repo-path automatically and binding to port 8900.  It will print the URL it is bound to so that you can add it to your knife.rb files.

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

### New knife command: knife node environment set
You can now easily set the environment for an existing node without editing the node object:

```
knife node environment set NODE ENVIRONMENT
```
### New configurable knife bootstrap options for chef-full template
You can now modify the chef-full template with the following options in `knife bootstrap`:

* `--bootstrap-install-sh URL` fetches and executes an installation bash script from the provided URL.
* `--bootstrap-wget-options OPTIONS` and `--bootstrap-curl-options OPTIONS` allow arbitrary options to be added to wget and curl.
* `--bootstrap-install-command COMMAND` can be used to execute a custom chef-client installation command sequence. Take note that this cannot be used in conjunction with the above options.

### Parallelize cookbook synchronization

You can now synchronize your cookbooks faster by parallelizing the process. You can specify the number of helper threads in your config file with `cookbook_sync_threads NUM_THREADS`. The default is 10. Increasing `NUM_THREADS` can result in gateway errors from the chef server (namely 503 and 504). If you are experiencing these often, consider decreasing `NUM_THREADS` to fewer than default.

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
  },
  "network" => {
    "interfaces" => {
      "eth0" => {...},
      "eth1" => {...},
    }
  }
}
````
and your config file looks like
````
automatic_attribute_whitelist = ["network/interfaces/eth0"]
````
then the entire `filesystem` and `eth1` subtrees will not be saved by the node. To save the `/dev/disk0s2` subtree, you must write `automatic_attribute_whitelist = [ ["filesystem", "/dev/disk0s2"] ]`.

If your config file looks like `automatic_attribute_whitelist = []`, then none of your automatic attribute data will be saved by the node.

The default behavior is for the node to save all the attribute data. This can be ensured by setting your whitelist filter to `nil`.

We recommend only using `automatic_attribute_whitelist` to reduce the size of the system data being stored for nodes, and discourage the use of the other attribute whitelists except by advanced users.

### Set proxy environment variables if present in your config file.

If `:http_proxy`, `:https_proxy`, `:ftp_proxy`, or `:no_proxy` is found in your config file, we will configure your environment variables according to the variable form and configuration info given. If your config file looks like

````
http_proxy "http://proxy.example.org:8080"
http_proxy_user "myself"
http_proxy_pass "Password1"
````

then Chef will set `ENV['http_proxy'] = "http://myself:Password1@proxy.example.org:8080"`

### -E is not respected by knife ssh [search]
knife now includes a warning in the -E/--environment option that this setting is ignored by knife searches.

### New configurable option :yum-lock-timeout
You can now set the timeout for receiving the yum lock in `config.rb` by adding `yum-lock-timeout SECONDS` (default is 30 seconds).
