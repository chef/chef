# End-To-End Testing for Chef Client

The goal is to provide end-to-end testing of `chef-client` and tools which ship
with it. To accomplish this, we use Test Kitchen with the `chef-solo` provisioner
to download Chef source code from GitHub, locally create and install the chef
gem from the source code, and run functional tests. Currently, these tests can
be run locally on your machine, or on Travis when you submit a pull request.

## Testing
### On your local machine
By default, Test Kitchen uses the [kitchen-vagrant](https://github.com/test-kitchen/kitchen-vagrant)
driver plugin to create local kitchen instances and installs Chef based on your
latest commit to `github.com/opscode/chef`. Currently, for this to work you'll
need to ensure that your latest commit has been pushed to GitHub. If you want to
download Chef from a different commit, modify the `branch` line under
`provisioner` to have that commit's SHA. For example, it may look something like this:

```(yaml)
# spec/e2e/.kitchen.yml
---
provisioner:
  name: chef_solo
  branch: c8a54df7ca24f1482a701d5f39879cdc6c836f8a
  github: "github.com/opscode/chef"
  require_chef_omnibus: true

platforms:
  - name: ubuntu-12.04
    driver_plugin: vagrant
```
`branch` accepts any valid git reference.

When you're ready to test, execute the following lines (this assumes your current
working directory is the head of the chef source code, e.g. mine is`~/oc/chef/`):

```
$ pwd
~/oc/chef
$ cd spec/e2e
$ bundle install
$ bundle exec kitchen test
```
To change what Test Kitchen runs, modify your `spec/e2e/.kitchen.yml`.

### On Travis
By default, Test Kitchen uses the [kitchen-ec2](https://github.com/test-kitchen/kitchen-ec2)
driver plugin to create kitchen instances on EC2 and installs Chef based on the
latest pushed commit to your pull request on `github.com/opscode/chef`. That is,
Travis installs Chef from the branch and commit it's testing. Travis runs automatically
every time you publish your commits to a pull request, so please disable Test Kitchen
in Travis (by commenting out the appropriate lines in your `.travis.yml`) or push
new commits to your PR infrequently.

To change what Test Kitchen runs, modify your `spec/e2e/.kitchen.travis.yml`.

**IMPORTANT: Do not modify any of the values in the matrix under `env`!** These are carefully
configured so that Travis can use EC2 and Test Kitchen.
