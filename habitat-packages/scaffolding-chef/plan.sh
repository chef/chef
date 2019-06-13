pkg_name=scaffolding-chef
pkg_description="Scaffolding for Chef Policyfiles"
pkg_origin=chef
pkg_version="0.5.0"
pkg_maintainer="The Habitat Maintainers <humans@habitat.sh>"
pkg_license=('Apache-2.0')
pkg_source=nope
pkg_upstream_url="https://www.chef.sh"

do_download() {
  return 0
}

do_verify() {
  return 0
}

do_unpack() {
  return 0
}

do_build() {
  return 0
}

do_install() {
  install -D -m 0644 "$PLAN_CONTEXT/lib/scaffolding.sh" "$pkg_prefix/lib/scaffolding.sh"
}
