# Package metadata
pkg_name=knife
pkg_origin=core
pkg_description="knife is a command-line tool that provides an interface between a local chef-repo and the Chef Infra Server."
pkg_upstream_url=https://www.chef.io/
pkg_maintainer="The Habitat Maintainers <humans@habitat.sh>"
pkg_license=('Apache-2.0')

# Package dependencies
pkg_deps=(
  core/coreutils
  core/git
  core/ruby31
  core/bash
)

# Build dependencies
pkg_build_deps=(
  core/gcc
  core/make
)

pkg_version() {
  cat "../../VERSION"
}

do_before() {
  update_pkg_version
}

# Directories that contain executable binaries
pkg_bin_dirs=(bin)

# Setup environment variables required for building the package
do_setup_environment() {

  build_line "Setting GEM_HOME=$pkg_prefix/lib"
  export GEM_HOME="$pkg_prefix/lib"

  build_line "Setting GEM_PATH=$GEM_HOME"
  export GEM_PATH="$GEM_HOME"

  build_line "pkg_prefix is set to: $pkg_prefix"
  build_line "GEM_HOME is set to: $GEM_HOME"
  build_line "GEM_PATH is set to: $GEM_PATH"
}

# Unpack the source code into the Habitat cache path
do_unpack() {
  mkdir -pv "$HAB_CACHE_SRC_PATH/$pkg_dirname"
  cp -RT "$PLAN_CONTEXT"/../.. "$HAB_CACHE_SRC_PATH/$pkg_dirname/"
}

# Build the Knife gem from its specification file
do_build() {
  build_line "Building the Knife gem from the gemspec"

  pushd "$HAB_CACHE_SRC_PATH/$pkg_dirname/knife"
    gem build knife.gemspec
  popd
}

# Install the built gem into the package directory
do_install() {
   build_line "Installing the Knife gem"
  pushd "$HAB_CACHE_SRC_PATH/$pkg_dirname/knife"
    gem install knife-*.gem --no-document

    build_line "** Installing knife driver"
    gem install knife-vcenter
    gem install knife-vrealize
    gem install knife-vsphere
    gem install knife-azure
    gem install knife-ec2
    gem install knife-google
    gem install knife-windows
  popd

  # Wrap the Knife binary to ensure correct environment paths
  wrap_knife_bin
}

# Wrap the Knife binary to ensure paths are set correctly for execution
wrap_knife_bin() {

  build_line "core ruby path $(pkg_path_for core/ruby31)/bin:$PATH"
  local bin="$pkg_prefix/bin/$pkg_name"
  local real_bin="$GEM_HOME/gems/knife-${pkg_version}/bin/knife"
  build_line "Adding wrapper $bin to $real_bin"
  cat <<EOF > "$bin"
#!$(pkg_path_for core/bash)/bin/bash
set -e

# Set binary path that allows Knife to use non-Hab pkg binaries
export PATH="/sbin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:\$PATH"

# Set Ruby paths defined from 'do_setup_environment()'
export GEM_HOME="$GEM_HOME"
export GEM_PATH="$GEM_PATH"

exec $(pkg_path_for core/ruby31)/bin/ruby $real_bin \$@
EOF
  chmod -v 755 "$bin"
}

do_strip() {
  return 0
}