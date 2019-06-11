# Releasing Chef Infra

## Steps to validate that we are ready to ship

  1. Has the version number been bumped for releasing? This can be done by merging in a PR that has the "Expeditor: Bump Version Minor" label applied.
  2. Are there any outstanding community PRs that should be merged? Ideally we don't make a community member wait multiple months for a code contribution to ship. Merge anything that's been reviewed.
  3. Are new resource "introduced" fields using the correct version? From time to time, we incorrectly merge a PR that has the wrong "introduced" version in a new resource or new resource property. If we added new resources or properties, make sure these fields match the version we are about to ship.
  4. Have any changes in Ohai been shipped to rubygems?
  5. Do we have a build in the `current` channel? If not, you might wanna fix that.

## Prepare the Release

### Write the release notes

The importance of our release notes cannot be understated. As developers, we understand changes between releases and we are accustomed to reading git history. Users are not, and if we don't call out new functionality, they will not find it on their own. We need to take the time and effort to write quality release notes that give a compelling reason to upgrade and also properly warn of any potential breaking changes. Make sure to involve the docs team so we can make sure our English is legible.

#### Overall Release Notes Structure

1. `New Resources`: If we ship new resources, we want to make sure to brag about those resources. Use this section to give the elevator pitch for the new resource, including an example of how it might be used if available.
2. `Updated Resources`: It's important to let users know about new functionality in resources they may already be using. Cover any important bug fixes or new properties/actions here.
3. `Major new features`: Document new features with a high level bullet. This is a great opportunity to show off our work and sell users on new workflows.
4. `Updated InSpec Releases`: We should always call out the updated Chef InSpec release and include a description of new functionality.
5. `Security Updates`: Call out any updated components we are shipping and include links to the CVEs if available.

### Update the Docs Site

If there are any new or updated resources, the docs site will need to be updated. This is a `partially` automated process. If you are making a single resource update or changing wording, it may just be easier to do it by hand.

#### Resource Documentation Automation

1. Checkout the `doc_generator` branch in `chef/chef`
2. Rebase the branch against master
3. Run `bundle install`
4. Run `bundle exec ./docs.rb`, which generates resource_FOO.rst files in the root of the git repo.
5. Compare the relevant generated files with the docs site content in the `chef_master/source` directory. The generated files are missing some content, such as action descriptions, and don't have perfect formatting, so this is a bit of an art form.

## Release Chef Infra Client

### Promote the build

Chef employees can promote a build to stable from Slack. This is done with expeditor using a chatops command in the following format:

`/expeditor promote chef/chef:master 15.1.9`

or for a previous release branch:

`/expeditor promote chef/chef:chef-14 14.13.9`

### Announce the Build

We want to make sure to announce the build on Discourse. It is helpful that these announcements come from real people because people like people and not machines. You can copy a previous release announcement, and change the version numbers and release notes content.

Also, make sure to announce the build on any social media platforms that you occupy if you feel comfortable doing so. It's great to make an announcement in `#sous-chefs` and `#general` in Community Slack, as well as on Twitter, where we tend to get a good response.

### Update homebrew Content

Many of our users consume Chef via Homebrew using our casks. Make sure to update those here: https://github.com/chef/homebrew-chef

### Update Chocolatey Packages

Many Windows users consume our packages via Chocolatey. Make sure to update the various version strings and sha checksums here: https://github.com/chef/chocolatey-packages

Once this is updated, you'll need to build / push the artifact to the Chocolatey site from a Windows host:
  1. `choco pack .\chef-client\chef-client.nuspec`
  2. `choco push .\chef-client.15.1.9.nupkg --key API_KEY_HERE`

Note: In order to push the artifact, you will need to be added as a maintainer on [Chocolatey.org](https://chocolatey.org/).

### Relax

You're done. You have a month to relax.
