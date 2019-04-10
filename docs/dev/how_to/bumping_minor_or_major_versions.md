# How To Bump Minor / Major Versions

## When to Bump Versions


After performing the monthly minor release of Chef, we should wait several days, and then bump the version for the next month's release. Why wait? We don't want to bump the version until we are sure we do not need to perform an emergency release for a regression. Once we're fairly confident we won't be performing a regression release, we want all new builds for the current channel to have the next month's version. This makes it very clear what version of Chef users are testing within the current channel.

Bumping for the yearly major release is a bit different. We can bump for the new major release once we create a stable branch for the current major version number. Once this branch and version bump occurs, all development on master will be for the upcoming major release, and anything going into the stable release will need to be backported. See [Branching and Backporting](branching_and_backporting.md) for more information on how we branch and backport to stable.

### How to Bump

Chef's Expeditor tool includes functionality to bump the minor or major version of the product. By using Expeditor to bump versions, we can perform a bump without directly editing the version files. A version bump is performed when a PR is merged with either of these two labels applied:
 - Expeditor: Bump Version Minor
 - Expeditor: Bump Version Major

