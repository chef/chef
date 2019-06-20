$pkg_name="scaffolding-chef"
$pkg_description="Scaffolding for Chef Policyfiles"
$pkg_origin="chef"
$pkg_version="0.6.0"
$pkg_maintainer="The Habitat Maintainers <humans@habitat.sh>"
$pkg_license=("Apache-2.0")
$pkg_upstream_url="https://www.chef.sh"
$pkg_build_deps=@(
    "core/chefdk"
    "core/git"
  )
function Invoke-Install {
  New-Item -ItemType directory -Path "${pkg_prefix}/lib"
  Copy-Item -Path "$PLAN_CONTEXT/lib/scaffolding.ps1" -Destination "$pkg_prefix/lib/scaffolding.ps1"
}
