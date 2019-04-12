# Chef Release Cadence

Chef follows [Semantic Versioning](https://semver.org/) for releases. Major versions (eg. 11.x -> 12.x) will include backwards-incompatible changes. Minor versions (eg 12.1 -> 12.2) will include new features and bug fixes, but will be backwards-compatible to the best of our ability. Patch releases will contain bug and security fixes only.

Chef feature releases are promoted to the stable channel once per month. It is expected that this occur during the second week of the month unless circumstances intervene. Additional patch releases for a given feature release may be promoted if critical issues are found.

ChefDK is released once per month. It is expected that this occur during the fourth week of the month unless circumstances intervene.

Both Chef and ChefDK will prepare a release candidate before the target release date, usually in the week before but at least three business days before release.

The Chef release in April of each year is a major version release, which will contain backwards-incompatible changes. A reminder notice will be sent via Discourse and Slack in March that will summarize the changes slated for the release.

## Rationale

Monthly releases help ensure we get new features and minor bug fixes out to Chef users in a timely fashion while not overloading the maintainer teams. Similarly, offsetting the Chef and ChefDK releases allows the full attention of the Chef development team on each of those releases, and leaves time for any potential hot fixes or follow-up.

Major releases in April avoids releasing during winter holidays, summer vacations, ChefConf, and Chef Summits.
