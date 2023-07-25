docker run -i --rm --volume c:/projects/chef:C:/workdir --workdir C:\\workdir --env BUILDKITE_ORGANIZATION_SLUG="chef-oss" chefes/omnibus-toolchain-windows-2019:3.0.0 powershell -Command ./.github/kitchen_things.ps1

