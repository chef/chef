# Chef Infra Client Release Cadence

Chef Infra Client follows [Semantic Versioning](https://semver.org/) for releases. Major versions (eg. 16.x -> 17.x) will include backwards-incompatible changes. Minor versions (eg 16.7 -> 16.8) will include new features and bug fixes, but will be backwards-compatible to the best of our ability. Patch releases will contain bug and security fixes only.

Chef Infra Client feature releases are promoted to the stable channel once per month. It is expected that this occur during the second week of the month unless circumstances intervene. Additional patch releases for a given feature release may be promoted if critical issues are found.

Chef Workstation is released once per month in order to pull in the latest Chef Infra Client. It is expected that this occur during the fourth week of the month unless circumstances intervene.

The Chef release in April of each year is a major version release, which will contain backwards-incompatible changes. A reminder notice will be sent via Discourse and Slack in March that will summarize the changes slated for the release.

## Rationale

Monthly releases help ensure we get new features and minor bug fixes out to Chef Infra users in a timely fashion while not overloading the maintainer teams. Similarly, offsetting the Chef Infra Client and Chef Workstation releases allows Workstation to ship with current Chef Infra Client releases.

Major releases in April avoids releasing during winter holidays, summer vacations, ChefConf, and Chef Summits.
