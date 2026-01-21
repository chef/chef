# Releasing Chef Infra

## Steps to validate that we are ready to ship

  1. Has the version number been bumped for releasing? This can be done by merging in a PR that has the "Expeditor: Bump Version Minor" label applied.
  2. Are there any outstanding community PRs that should be merged? Ideally we don't make a community member wait multiple months for a code contribution to ship. Merge anything that's been reviewed.
  3. Are new resource "introduced" fields using the correct version? From time to time, we incorrectly merge a PR that has the wrong "introduced" version in a new resource or new resource property. If we added new resources or properties, make sure these fields match the version we are about to ship.
  4. Have any changes in Ohai been shipped to rubygems?

        **NOTE:** Keep in mind that if you are releasing a new version (chef 18 over chef 17, for example) you will need to ship updated\ versions of Ohai, Chef-Utils, Chef-Config and Knife to Rubygems.org BEFORE you ship Chef
  5. Do we have a build in the `current` channel? If not, you might wanna fix that.

## Prepare the Release

### Let the Docs Team Know

The docs team needs to know about our upcoming release at least 48 hours ahead of time. This ensures that when we release our docs are immediately available to users. Accommodations can be made for emergency releases. Contact the team directly in those instances. Do this for a normal release:

Open 2 tickets on the [Chef-Infra board](https://chefio.atlassian.net/jira/software/c/projects/CHEF/boards/492)
    1. Assign the first one to yourself to write documentation for your upcoming release.
    2. Create the second one, assign it to the `BL-DOCS team`, tag it as 'Documentation', and mark it as blocked by the first ticket you created.
    3. Inform the docs team either via `#docs-support` in Slack or directly and let them know about the ticket.
    4. Finish the documents following the steps below and update your tickets when you're done.

### Write the release notes

Release notes are published from the [chef/chef-web-docs repository](https://github.com/chef/chef-web-docs/blob/main/content/release_notes/client.md).

The importance of our release notes cannot be understated. As developers, we understand changes between releases and we are accustomed to reading git history. Users are not, and if we don't call out new functionality, they will not find it on their own. We need to take the time and effort to write quality release notes that give a compelling reason to upgrade and also properly warn of any potential breaking changes. Make sure to involve the docs team so we can make sure our English is legible.

#### Overall Release Notes Structure

1. `New features`: Document *important* / *major* new features. This is a great opportunity to show off our work and sell users on new workflows.
2. `Compliance Phase Improvements`: We should always call out the updated Chef InSpec release and include a description of new functionality. If we've improved how compliance phase operates overall also call that out.
3. `New Resources`: If we ship new resources, we want to make sure to brag about those resources. Use this section to give the elevator pitch for the new resource, including an example of how it might be used if available.
4. `Updated Resources`: It's important to let users know about new functionality in resources they may already be using. Cover any important bug fixes or new properties/actions here.
5. `Security Updates`: Call out any updated components we are shipping and include links to the CVEs if available.

### Update the Docs Site

If there are any new or updated resources, the docs site will need to be updated. This is a `partially` automated process. If you are making a single resource update or changing wording, it may just be easier to do it by hand.

`publish-release-notes.sh` pushes to S3 and then Netlify site needs to be rebuilt, so the Docs Site may not immediately reflect the Release notes related updates. The way to rebuild Netlify is manually or by merging a PR in chef-web-docs repository. Reach out to the Docs team to trigger an update.

#### Resource Documentation Automation

1. Run `rake docs_site:resources` to generate content to a `docs_site` directory
   1. WARNING: Any resource that inherits it's basic structure from a parent resource is likely to commingle settings from both when you run that command. For example, there are 17-20 resources that consume the basic package.rb resource file. As a consequence, ALL of the children will most likely have pulled in properties and actions that do not apply to them. You have to be careful here.

2. Compare the relevant generated files to the content in the `content/resources` directory within the [chef-web-docs repo](https://github.com/chef/chef-web-docs/). The generated files are missing some content, such as action descriptions, and don't have perfect formatting, so this is a bit of an art form.
   1. This will take time - expect to use 2-4 days of going through the new docs to ensure you aren't accidentally overwriting things or ignoring important updates.
   2. One tool you can use to help yourself is Beyond Compare. If you have to buy it, it's like $20
   3. You'll end up using a combo of the old docs, the new docs, what Beyond Compare shows you and your intuition.

## Release Chef Infra Client

The docs are the most time-consuming aspect of the release.

### Promote the build

:warning: Be sure to update the appropriate version of Pending Release Notes in the [wiki](https://github.com/chef/chef/wiki)! Failure to do so will cause the `git commit` step in [`publish-release-notes.sh`](https://github.com/chef/chef/blob/main/.expeditor/publish-release-notes.sh#L30) to fail.

Chef employees can promote a build to stable from Slack. This is done with expeditor using a chatops command in the following format:

`/expeditor promote chef/chef:main 17.1.9`

or for a previous release branch:

`/expeditor promote chef/chef:chef-16 16.13.9`

:warning: Do not `gem push` the ruby gem manually... this will prevent promotion of habitat packages to stable and will block notifications to chef.io slack channels.

:information_source: the promotion of habitat packages can also be blocked if the Linux and Linux2 packages somehow have the same timestamp.

### Announce the Build

Also, make sure to announce the build on any social media platforms that you occupy if you feel comfortable doing so. It's great to make an announcement in `#sous-chefs` and `#general` in Community Slack, where we tend to get a good response.

### Update homebrew Content

Many of our users consume Chef via Homebrew using our casks. Expeditor will create a pull request to update the Chef Homebrew cask, which will need to be merged here: https://github.com/chef/homebrew-chef

### Update Chocolatey Packages

Many Windows users consume our packages via Chocolatey. Here's how you get a new build out for them

From a Windows host:

  1. Clone this repo locally : https://github.com/chef/chocolatey-packages
  2. There is no separate branch being maintained for each version of chef. Make your PR for `main` branch only.
  3. Getting the SHA256 checksum for windows artifact:
      There are three ways we can do this:
      * Easiest: https://omnitruck.chef.io/current/chef/packages?v=18.4.2 - obviously replace the version then hit that url, scroll down to windows and get the SHA.
      * Still Easy: Since we have already promoted latest version of chef, the artifacts will be available on download site.
        Visit https://www.chef.io/downloads/tools/infra-client?os=windows, select the intended Infra Client version and grab the SHA256 checksum for `Windows 2012r2` OS.
        In case this url changes or not accessible, use below method:
      * Less Easy: Go to the buildkite release pipeline which you are promoting to stable.
        * Go to the `windows-2012r2-x86_64` builder and download the artifact
          (NOTE: On a mac system, if the `msi` file gets downloaded as an `exe`, do this from a windows machine, since they are different files and not the intended file for which we are creating the chocolatey package.)
        * Run `shasum -a 256 {path_to_your_downloaded_artifact}`
        * This will output the SHA256 checksum for the file
  4. Update the version strings and sha checksums in the chef.nuspec and chocolateyinstall.ps1 files and create the PR.
  5. Contact the Build Systems team to get the password for the choco account if you don't have it already. The user is 'chef-ci'.
  6. Logon to the chocolatey and go to the account page
  7. Grab the API key from there.
  8. Run `choco pack .\chef\chef.nuspec`
    **Note**: If your nupkg file looks like this: `chef-client:15.1.9.nupkg` (note the colon), change the colon to a period. Choco push will fail on the colon

  9. Then run `choco push .\chef-client.15.1.9.nupkg --key API_KEY_HERE`. You might get an error using just that command. This will solve that:
      `choco push .\chef-client.18.4.12.nupkg --api-key '<your key goes here>' --source=https://push.chocolatey.org/`

  10. Once the nupkg file is pushed to Chocolatey, then merge your PR (e.g PR [here](https://github.com/chef/chocolatey-packages/pull/29))

Note: You may need to be added as a maintainer on [Chocolatey.org](https://chocolatey.org/).

### Cookstyle Verification

Please make sure cookstyle is working properly & auto correcting detected offenses for any of the cookbooks you are trying to test against the newer version of Chef Infra Client
Reference doc - https://github.com/chef/cookstyle#usage

### Relax

You're done. You have a month to relax.
