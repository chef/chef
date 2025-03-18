# Bumping Major Version Number

This document outlines the process for bumping the major version of Chef Infra Client for the yearly release.

## Preparing Ohai

Chef consumes Ohai from GitHub as both a runtime dependency and a testing dependency for Test Kitchen validations in Buildkite. Ohai's version is tightly coupled to that of Chef Infra Client so the first step in bumping the major release in the chef/chef repo is to bump the major version of Ohai.

### Create a new stable branch of Ohai

1. Edit the Expeditor config for the new branch, which you'll create shortly:

    - Example config change commit: https://github.com/chef/ohai/commit/1ad8c5946606a7f08ffb841e3682ae2d4991077f

2. Edit all the GitHub action workflows in .github/workflows/ to point to your new stable branch

3. On your local machine fork the current main branch to a new stable branch. For example: `git checkout -b 16-stable`.

4. Push the branch `git push --set-upstream origin 16-stable`

### Bump Ohai main to the new major version

Starting from the main branch create a PR which:

- Edits the `VERSION` file in the root of the repository to the new major release
- Updates the `chef-config` and `chef-utils` dependencies to allow for the new major release of Chef Infra in `ohai.gemspec`

## Update chef/chef

### Step 1.  Prep main branch for forking ###
- Please note these steps must be completed in sequence.

- [In ./expeditor/config.yml add the version_constraint for the new branch, update the version_constraint for main to match the new planned major version and add a constraint for the new stable version / branch.](https://expeditor.chef.io/docs/patterns/version-management/#release-branches)
- In .github/dependabot.yml add an entry for your new stable branch

### Step 2. Create the new release branch off of main.

Before bumping the major version of Chef Infra we want to fork off the current main to a new stable branch, which will be used to build hotfix releases. We support the N-1 version of Chef Infra Client for a year after the release of a new major version. For example Chef Infra Client 17 was released in April 2021, at which point Chef Infra Client 16 became the N-1 release. Chef Infra Client 16 will then be maintained with critical bug and security fixes until April 2022.

After defining the release branch in your .expeditor/config.yml and merging the pull request to main, you can now create the branch in git.

```
git checkout main
git pull
git branch *new_release_branch_name* # e.g. chef-18
git push origin *new_release_branch_name* # e.g. chef-18
```

### Step 3. Update your new release branch to fixup your new stable branch for release

Once you've forked to a new stable branch such as `chef-17` you'll want to create a new branch so you can build a PR, which will get this branch ready for release:

- In ./expeditor/config.yml remove the update_dep.sh subscriptions which don't work against stable branches such as chefstyle and ohai.
- In readme.md update the buildkite badge to point to the new stable branch image and link instead of pointing to main.
- In kitchen-tests/Gemfile update the Ohai branch to point to the new Ohai stable
- In kitchen-tests/kitchen.yml update chef_version to be your new stable version and not current. Ex: 15
- In tasks/bin/run_external_test update the ohai branch to point to your new stable ohai branch
- In Gemfile set ohai to pull from the ohai stable branch
- In Gemfile set cheffish to match the stable release of chef
- In knife/Gemfile set ohai to pull from the ohai stable branch
- In tasks/bin/run_external_test set ohai to pull from the ohai stable branch
- Update .github/dependabot.yml with the new branch
- Update .github/workflows/*.yml with the new branch on the new branch (optionally can add all such to `main` as well)
```yml
  pull_request:
   push:
     branches:
       - chef-18
```
- Create a new release notes wiki page for the stable version. See https://github.com/chef/chef/wiki/Pending-Release-Notes-17
- Update release notes publishing script to us the new stable branch. See branch names here: https://github.com/chef/chef/blob/e0ccaa0f5c7fc05f8ad8ce05295f48e5c48a6695/.expeditor/publish-release-notes.sh
- Run `rake dependencies:update` to generate a new gemfile.lock

Example PR for Chef 15: https://github.com/chef/chef/pull/9236

Note: Make sure you're making this PR against the **new stable** branch and not **main!**

### Step 4. Bump main for the new major release

Create a PR that performs the following:

- Update the version in the VERSION file
- Update `chef.gemspec` and `knife.gemspec` to point to the new ohai major release
- run `rake dependencies:update`

### Step 5. Update Ohai stable for the Chef stable branch

- In the ohai repo checkout the stable branch
- Update the `chef-config` and `chef-utils` deps in the Gemfile to point to the chef-XYZ stable branch in the `chef/chef` repo.

### Step 6. Have a github admin update the branch protections for the new release branch. 

