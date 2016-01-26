# Acceptance Testing for Chef Client
This folder contains acceptance tests that are required for Chef client
release readiness.

## Getting started
The tests use the _chef-acceptance_ gem as the high level framework.
All the gems needed to run these tests can be installed with Bundler.

### Important Note!
Before running chef-acceptance, you *MUST* do the following on your current session:

```
export APPBUNDLER_ALLOW_RVM=true
```

### Setting up and running a test suite
To get started, do a bundle install from the acceptance directory:
```shell
chef/acceptance$ bundle install --binstubs
```

To get some basic info and ensure chef-acceptance can be run, do:
```shell
chef/acceptance$ bin/chef-acceptance info
```

To run a particular test suite, do the following:
```shell
chef/acceptance$ bin/chef-acceptance test TEST_SUITE
```

To restrict which OS's will run, use the KITCHEN_INSTANCES environment variable:

```shell
chef/acceptance$ export KITCHEN_INSTANCES=*-ubuntu-1404
chef/acceptance$ bin/chef-acceptance test cookbook-git
```
