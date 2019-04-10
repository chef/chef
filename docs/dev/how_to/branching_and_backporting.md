# Branching and Backporting

## Branch Structure

We develop and ship the current release of Chef off the master branch of this repository. Our goal is that `master` should always be in a shipable state. Previous stable releases of Chef are developed on their own branches named by the major version (ex: chef-14 or chef-13). We do not perform direct development on these stable branches, except to resolve build failures. Instead, we backport fixes from our master branch to these stable branches. Stable branches receive critical bugfixes and security releases, and stable Chef releases are made as necessary for security purposes.

## Backporting Fixes to Stable Releases

If there is a critical fix that you believe should be backported from master to a stable branch, please follow these steps to backport your change:

1. Ask in the #chef-dev channel on [Chef Community Slack](https://community-slack.chef.io/) if this is an appropriate change to backport.
3. Inspect the Git history and find the `SHA`(s) associated with the fix.
4. Backport the fix to a branch via cherry-pick:
    1. Check out the stable release branch: `git checkout chef-14`
    2. Create a branch for your backport: `git checkout -b my_great_bug_packport`
    3. Cherry Pick the SHA with the fix: `git cherry-pick SHA`
    4. Address any conflicts (if necessary)
    5. Push the new branch to your origin: `git push origin`
5. Open a PR for your backport
    1. The PR title should be `Backport: ORIGINAL_PR_TEXT`
    2. The description should link to the original PR and include a description of why it needs to be backported