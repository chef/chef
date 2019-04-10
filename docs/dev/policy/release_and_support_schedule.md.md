# Chef Infra Release and Support Schedule

## Versioning Scheme

Chef Infra releases follow a `MAJOR.MINOR.PATCH` versioning scheme based on [Semantic Versioning](https://semver.org).

Given a version number `MAJOR.MINOR.PATCH`:

  * **MAJOR** version releases (e.g. 1.x -> 2.x) will include breaking or backwards-incompatible changes.
    * _Example: When changing the load order of any cookbook segments_
  * **MINOR** version releases (e.g. 1.1 -> 1.2) will include new features, bug fixes, and will be backwards-compatible to the best of the maintainers' abilities.
    * _Example: When adding support to the mount provider for special filesystem types that were previously unsupported._
    * _Example: Major version bump of a software dependency._
  * **PATCH** version releases (e.g. 1.1.1 -> 1.1.2) will include backwards-compatible bug fixes.
    * _Example: Minor version bump of a software dependency._

When incrementing a version, the following conditions will apply:

  * When **MAJOR** increases, **MINOR** and **PATCH** will be reset to zero (e.g. 11.X.X -> 12.0.0)
    * _Note: New features that did not exist in version 1.1.0 may be released in 2.0.0 without any intermediary releases._
  * When **MINOR** increases, **PATCH** will be reset to zero (e.g. 11.3.x -> 11.4.0)

When contextually appropriate, a version may be referred to by only the **MAJOR** or **MAJOR.MINOR** versions. For example:

  * a breaking change: "This behavior will change in Chef 16" would refer to the first release in the `16.MINOR.PATCH` series.
  * a future feature release:: "We expect to release Chef Workstation 2.2 this month" would refer to the `2.2.PATCH` build that was selected as the stable release.

### Auto-bumping PATCH versions

Chef projects are managed by our Expeditor release tooling application. This application is executed each time a pull request is merged and incrementwss the patch version of the software before running the change through our internal CI/CD pipeline. As not all builds will make it successfully through the CI/CD pipeline, the versions available for public consumption might have gaps (e.g. 1.2.1, 1.2.10, 1.2.11, 1.2.12, 1.2.20), but all verisons have been built and tested.

## Support Schedule

Chef currently supports the current major version release as well as the previous major version release. These releases each fall into one of three distinct lifecycle stages:

  - Generally Available
  - Deprecated
  - End of Life (EOL)

### Generally Available (GA)

This stage indicates that the release version is in active development.

  - Releases occur per our regular release schedule
  - New features as well as bug fixes ship in each new release
  - When a new major version release of Chef Infra ships it becomes the new GA release and the previous release moves to the Deprecated stage

### Deprecated

This stage indicates that a release version is no longer in active development and will eventually move to end of life status.

  - Releases do not follow our regular release schedule, but instead only occur as necessary for critical bugs or security vulnerabilities.
  - After a year releases transition from Deprecated to End of Life status when a new major release is made.

### End of Life (EOL)

This stage indicates a previously deprecated release version, which is no longer supported
  - No additional releases will be made
  - Documentation will be archived
  - Cookbooks and other community tooling may no longer function using this version of Chef Infra

## Release Schedule

The current Generally Availble (stable) release of Chef Infra is released on a regular cadence with a new **minor release shipping every month** during the 2nd week of the month. A new **major release ships every April**, at which time the previous GA release will become deprecated with further releases only for critical bugs or security issues.

Each release will be announced to the "chef-release" [Chef Mailing List](https://discourse.chef.io) category, notifying users of the new stable release.

### Example Release / Support Cycle

April 2019: Chef 15.0 released as GA
April 2020: Chef 15 becomes Deprecated when Chef 16 ships
April 2021: Chef 15 becomes End of Life when Chef 17 ships
