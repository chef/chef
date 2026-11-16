# Running Buildkite Ad Hoc Builds

Buildkite ad hoc builds are a great way to ensure that complex changes or changes that impact package creation will build across all supported platforms.

## What's wrong with just PR testing

The testing of Chef Infra Client occurs at the PR level and the build level, each incrementally improving developer confidence in the safety of a change.

Pull Request testing in GitHub is our first layer of defense. It's optimized for speed and to work within the constraints of GitHub and public CI instances.

Build testing occurs post-merge and involves the creation of packages for the platforms we support and the execution of RSpec tests using those packages. Since these RSpec tests are performed within the packages, we test against the dependencies we ship to the customer.

When making changes that impact the package you always want to validate the build process by running an ad hoc Buildkite build. Ad hoc builds take the same path as merged changes but without the need to merge code.

## Starting the Build

Ad hoc Buildkite builds can be created against any branch in the `chef/chef` GitHub repository by Chef employees with access to the private Buildkite account.

Buildkite pipelines for running ad hoc builds are automatically created for each branch configured in the Expeditor `config.yml` file. They follow a standard naming system:

### Main

https://buildkite.com/chef/chef-chef-main-validate-adhoc

### Chef 16

https://buildkite.com/chef/chef-chef-chef-16-omnibus-adhoc/

Once in the ad hoc pipeline page, select "New Build" in the upper right hand corner. Then provide a message to display in the Buildkite UI, the commit, and branch name.

## Downloading the Build

Once your build completes you can download it.
