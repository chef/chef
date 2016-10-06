# Acceptance Testing for Chef Client

This folder contains acceptance tests that are required for Chef client release readiness.

## Getting started

The tests use the _chef-acceptance_ gem as the high level framework. All the gems needed to run these tests can be installed with Bundler from this directory.

### Important Note!

Before running chef-acceptance, you _MUST_ do the following on your current session:

```shell
export APPBUNDLER_ALLOW_RVM=true
```

## Pre-requisites / One time set up

### Set up for local VM (Vagrant)

If you intend to run the acceptance tests on a local VM, the supported solution is to use Vagrant. Ensure that Vagrant is installed on the machine that tests will run from, along with a virtualization driver (E.g.: VirtualBox).

Set up the KITCHEN_DRIVER environment variable appropriately (value should be "vagrant"). E.g.:

```shell
export KITCHEN_DRIVER=vagrant
```

Add this to your shell profile or startup script as needed.

### Set up for cloud VM (EC2)

If you intend to run the acceptance tests on a cloud VM, the supported solution is to use EC2.

The steps you will need to do are:

1. Add your AWS credentials to the machine - e.g., to the ~/.aws/credentials directory.

  - The easiest way to do this is to download the aws command line (`brew install awscli` on OS/X) and run `aws configure`.

2. Create or import a SSH key to AWS. (If you already have one, you can skip the import/create)

  - In the AWS console, click Key Pairs, then Create Key Pair or Import Key Pair.

3. Copy or move the private key file (USERNAME.pem) to the SSH folder (e.g. `~/.ssh/USERNAME.pem`).

  - If you Created a key pair in step 2, download the private key and move it to `~/.ssh`.
  - If you Importd a key pair in step 2, just ensure your private key is in `~/.ssh` and has the same name as the key pair (`~/.ssh/USERNAME` or `~/.ssh/USERNAME.pem`).

4. Set AWS_SSH_KEY_ID to the SSH key name.

  - This is **optional** if your AWS SSH key name is your local username.
  - You may want to set this in your shell `.profile`.

    ```shell
    export AWS_SSH_KEY_ID=name-of-private-key
    ```

5. Set the private key to only be readable by root

  ```shell
  chmod 0400 ~/.ssh/USERNAME.pem
  ```

6. Set up the KITCHEN_DRIVER environment variable appropriately (value should be "ec2"). (This is optional, as ec2 is the default.) E.g.:

  ```shell
  export KITCHEN_DRIVER=ec2
  ```

  Add this to your shell profile or startup script as needed.

7. **Connect to Chef VPN**. The instances you create will not have public IPs!

## Setting up and running a test suite

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

If KITCHEN_INSTANCES is not specified, the default instances are default-ubuntu-1404 and default-windows-windows-2012r2\. All selected instances will be run in _parallel_ if the driver supports it (ec2 does, vagrant doesn't).

## Optional Settings

In addition to the environment settings above, there are a number of key values that are available to set for changing the way the acceptance tests are run.

### KITCHEN_CHEF_CHANNEL

Use this setting to specify which channel we will pull the chef build from. The default is to use the "current" channel, unless the ARTIFACTORY_USERNAME is set (which normally happens when running under Jenkins), in which case the default is changed to "unstable".

```shell
export KITCHEN_CHEF_CHANNEL=name-of-channel
```

### KITCHEN_CHEF_VERSION

Use this setting to override the version of the Chef client that is installed. The default is to get the latest version in the desired channel.

```shell
export KITCHEN_CHEF_VERSION=version-of-chef-client
```

### ARTIFACTORY_USERNAME / ARTIFACTORY_PASSWORD

If the desired channel to get the Chef client from is "unstable", the following settings need to be exported:

```shell
export ARTIFACTORY_USERNAME=username
export ARTIFACTORY_PASSWORD=password
```

## Future Work

Currently, there is no simple mechanism for chef-acceptance to build an Omnibus package of the developers local chef instance and run acceptance tests on it - the only packages that can be exercised are ones that come from one of the pipeline channels (unstable, current or stable).

This is not an issue when adding acceptance tests for pre-existing functionality (as that functionality is presumed to already be in a build in one of the pipeline channels).
