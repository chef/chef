# End-To-End Testing for Chef Client

Here we seek to provide end-to-end testing of Chef Client through cookbooks which exercise many of the available resources, providers, and common patterns. The cookbooks here are designed to ensure certain capabilities remain functional with updates to the client code base.

## Getting started

These tests run in Docker containers, so make sure to install Docker on your workstation. Once Docker is installed, all the gems needed to run these tests can be installed with Bundler.

```shell
chef/kitchen-tests$ bundle install
```

To ensure everything is working properly, and to see which platforms can have tests executed on them, run

```shell
chef/kitchen-tests$ bundle exec kitchen list
```

You should see output similar to

```shell
Instance                  Driver  Provisioner  Verifier  Transport  Last Action    Last Error
end-to-end-amazonlinux    Dokken  Dokken       Inspec    Dokken     <Not Created>  <None>
```

## Testing

We use Test Kitchen to build instances, test client code, and destroy instances. If you are unfamiliar with Test Kitchen, we recommend checking out the [tutorial](http://kitchen.ci/) along with the `kitchen-dokken` [driver documentation](https://github.com/someara/kitchen-dokken). Test Kitchen is configured to manipulate instances using [Docker](https://www.docker.com/) when testing locally, and when testing, pull requests on [Travis CI](https://travis-ci.com/).

### Commands

Kitchen instances are led through a series of states. The instance states, and the actions taken to transition into each state, are in order:

- `destroy`: Delete all information for and terminate one or more instances.
	- This is equivalent to running `vagrant destroy` to stop and delete a Vagrant machine.
- `create`: Start one or more instances.
	- This is equivalent to running `vagrant up --no-provision` to start a Vagrant instance.
- `converge`: Use a provisioner to configure one or more instances.
  - By default, Test Kitchen is configured to use the `ChefSolo` provisioner which:
    - Prepares local files for transfer,
    - Installs the latest release of Chef Omnibus,
    - Downloads Chef Client source code from the prescribed GitHub repository and reference,
    - Builds and installs a `chef` gem from the downloaded source,
    - Runs `chef-client`.
- `setup`: Prepare the instance to run automated tests.
- `verify`: Run automated tests on one or more instances.

When transitioning between states, actions for any and all intermediate states will performed. Executing the `create` then the `verify` commands is equivalent to executing `create`, `converge`, `setup`, and `verify` one-by-one and in order. The only exception is `destroy`, which will immediately transfer that machine's state to destroyed.

The `test` command takes one or more instances through all the states, in order: `destroy`, `create`, `converge`, `setup`, `verify`, `destroy`.

To see a list of available commands, type `bundle exec kitchen help`. To see more information about a particular command, type `bundle exec kitchen help <command>`.

### Configuring your tests

Test Kitchen is configured in the `kitchen.yml` file, which resides in this directory. You will need to configure the provisioner before running the tests.

The provisioner can be configured to pull client source code from a GitHub repository using any valid Git reference. You are encouraged to modify any of these settings, but please return them to their original values before submitting a pull request for review (unless, of course, your changes are enhancements to the default provisioner settings).

By default, the provisioner is configured to pull your most recent commit to `chef/chef`. You can change this by modifying the `github` and `branch` provisioner options:

- `github`: Set this to `"<your_username>/<your_chef_repo>"`. The default is `"chef/chef"`.
- `branch`: This can be any valid git reference (e.g., branch name, tag, or commit SHA). If omitted, it defaults to `master`.

The branch you choose must be accessible on GitHub. You cannot use a local commit at this time.

### Testing pull requests

These end-to-end tests are also configured to run on Travis-CI with Docker containers when you submit a pull request to `chef/chef`. Kitchen is configured to pull chef client source code from the branch it is testing. There is no need to modify `kitchen.yml` unless you are contributing tests.

## Contributing

We would love to fill out our end-to-end testing coverage! If you have cookbooks and tests that you would like to see become a part of client testing, we encourage you to submit a pull request with your additions. We request that you do not add platforms to `kitchen.yml`. Please file a request to add a platform under [Issues](https://github.com/chef/chef/issues).
