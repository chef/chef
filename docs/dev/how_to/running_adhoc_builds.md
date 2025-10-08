# Running Buildkite Ad Hoc Builds

Buildkite ad hoc builds are a great way to ensure that complex changes or changes that impact package creation will build across all supported platforms.

## What's wrong with just PR testing

The testing of Chef Infra Client occurs at the PR level and the build level, each incrementally improving developer confidence in the safety of a change.

Pull Request testing in GitHub is our first layer of defense but is far from perfect. It's optimized for speed and to work within the constraints of GitHub and public CI instances. This means this testing occurs against Ruby containers and no builds are created. Any change to build dependencies or configuration untested at the PR level.

Build testing occurs post-merge and involves the creation of packages for the platforms we support and the execution of RSpec tests using those packages. Since these RSpec tests are performed within the packages, we test against the dependencies we ship to the customer.

When making changes that impact the package you always want to validate the build process by running an ad hoc Buildkite build. Ad hoc builds take the same path as merged changes but without the need to merge code.

## Starting the Build

Ad hoc Buildkite builds can be created against any branch in the `chef/chef` GitHub repository by Chef employees with access to the private Buildkite account. If you don't have access to this account or the ability to push branches to `chef/chef` ask in `#releng-support`.

Buildkite pipelines for running ad hoc builds are automatically created for each branch configured in the Expeditor `config.yml` file. They follow a standard naming system:

### Master

https://buildkite.com/chef/chef-chef-master-omnibus-adhoc/

### Chef 16

https://buildkite.com/chef/chef-chef-chef-16-omnibus-adhoc/

Once in the ad hoc pipeline page, select "New Build" in the upper right hand corner. Then provide a message to display in the Buildkite UI, the commit, and branch name.

## Downloading the Build

Once your build completes you can download it from either Artifactory or via mixlib-install.

### Artifactory

Builds are available in Artifactory at http://artifactory.chef.co/ui/builds/chef

### mixlib-install

Successful ad hoc builds are promoted to the unstable channel and can be downloaded using mixlib-install (part of Chef Workstation)

`mixlib-install download chef -c unstable`

Keep in mind this just downloads the last build so you may end up the wrong build if the ad hoc isn't the last build to promote to unstable.
