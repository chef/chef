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

## Pre-requisites / One time set up

### Set up for local VM (Vagrant)

If you intend to run the acceptance tests on a local VM, the supported solution is to use Vagrant.
Ensure that Vagrant is installed on the machine that tests will run from, along with a
virtualization driver (E.g.: VirtualBox).

Set up the KITCHEN_DRIVER environment variable appropriately (value should be "vagrant").  E.g.:
```
export KITCHEN_DRIVER=vagrant
```
Add this to your shell profile or startup script as needed.

### Set up for cloud VM (EC2)

If you intend to run the acceptance tests on a cloud VM, the supported solution is to use EC2.

The steps you will need to do are:

1. Add your AWS credentials to the machine - e.g., to the ~/.aws/credentials directory.
2. Create or import a SSH key to AWS. Make sure the key name is the same as the username.
3. Copy or move the private key file (USERNAME.pem) to the SSH folder (e.g. `~/.ssh/`. Change the mode so that the file is only read-able by root (E.g.: chmod 0400 USERNAME.pem)

4. Set up the KITCHEN_DRIVER environment variable appropriately (value should be "ec2").  E.g.:
```
export KITCHEN_DRIVER=ec2
```
Add this to your shell profile or startup script as needed.

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

If KITCHEN_INSTANCES is not specified, the default instances are default-ubuntu-1404 and default-windows-windows-2012r2.
