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

### Parallelize cookbook synchronization

You can now synchronize your cookbooks faster by parallelizing the process. You can specify the number of helper threads in your config file with `cookbook_sync_threads NUM_THREADS`. The default is 10. Increasing `NUM_THREADS` can result in gateway errors from the chef server (namely 503 and 504). If you are experiencing these often, consider decreasing `NUM_THREADS` to fewer than default.
