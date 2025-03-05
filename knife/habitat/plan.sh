# Package metadata
export HAB_BLDR_CHANNEL="LTS-2024"
pkg_name=knife
# _chef_client_ruby="core/ruby3_1"
ruby_pkg="core/ruby3_1"
pkg_origin=core
pkg_description="knife is a command-line tool that provides an interface between a local chef-repo and the Chef Infra Server."
pkg_upstream_url=https://www.chef.io/
pkg_maintainer="The Habitat Maintainers <humans@habitat.sh>"
pkg_license=('Apache-2.0')

# Package dependencies
pkg_deps=(
  ${ruby_pkg}
  core/coreutils
  core/git
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
pkg_svc_user=root

# Setup environment variables required for building the package

do_setup_environment() {
  build_line 'Setting GEM_HOME="$pkg_prefix/vendor"'
  export GEM_HOME="$pkg_prefix/vendor"

  build_line "Setting GEM_PATH=$GEM_HOME"
  export GEM_PATH="$GEM_HOME"
}

# Unpack the source code into the Habitat cache path
do_unpack() {
  mkdir -pv "$HAB_CACHE_SRC_PATH/$pkg_dirname"
  cp -RT "$PLAN_CONTEXT"/../.. "$HAB_CACHE_SRC_PATH/$pkg_dirname/"
}

# do_prepare() {
#   export GEM_HOME="${pkg_prefix}/vendor"
#   export OPENSSL_DIR="$(pkg_path_for openssl)"
#   export OPENSSL_INCLUDE_DIR="$(pkg_path_for openssl)/include"
#   export SSL_CERT_FILE="$(pkg_path_for cacerts)/ssl/cert.pem"
#   export CPPFLAGS="${CPPFLAGS} ${CFLAGS}"
#   export HAB_BLDR_CHANNEL="LTS-2024"
#   export HAB_STUDIO_SECRET_NODE_OPTIONS="--dns-result-order=ipv4first"
#   export HAB_STUDIO_SECRET_HAB_BLDR_CHANNEL="LTS-2024"
#   export HAB_STUDIO_SECRET_HAB_FALLBACK_CHANNEL="LTS-2024"
#   build_line " ** Securing the /src directory"
#   git config --global --add safe.directory /src

#   (
#     # cd "$CACHE_PATH"
#     # bundle config --local build.nokogiri "--use-system-libraries \
#     #     --with-zlib-dir=$(pkg_path_for zlib) \
#     #     --with-xslt-dir=$(pkg_path_for libxslt) \
#     #     --with-xml2-include=$(pkg_path_for libxml2)/include/libxml2 \
#     #     --with-xml2-lib=$(pkg_path_for libxml2)/lib"
#     # bundle config --local jobs "$(nproc)"
#     # bundle config --local without server docgen maintenance pry travis integration ci chefstyle
#     # bundle config --local shebang "$(pkg_path_for "$_chef_client_ruby")/bin/ruby"
#     # bundle config --local retry 5
#     # bundle config --local silence_root_warning 1
#   )

#   # build_line "Setting link for /usr/bin/env to 'coreutils'"
#   # if [ ! -f /usr/bin/env ]; then
#   #   ln -s "$(pkg_interpreter_for core/coreutils bin/env)" /usr/bin/env
#   # fi
# }

# Build the Knife gem from its specification file
do_build() {
  export GEM_HOME="$pkg_prefix/vendor"
  build_line "Setting GEM_PATH=$GEM_HOME"
  export GEM_PATH="$GEM_HOME"
  build_line "Building the Knife gem from the gemspec"

  pushd "$HAB_CACHE_SRC_PATH/$pkg_dirname/knife"
    bundle install --jobs=3 --retry=3
    gem build knife.gemspec
    build_line "Installing gems from git repos properly ..."

    ruby ./../post-bundle-install.rb
    build_line "Installing this project's gems ..."
    # bundle exec rake install:local

  popd
}

# Install the built gem into the package directory
do_install() {
  # fix_interpreter "${pkg_prefix}/vendor/bin/*" "$_chef_client_ruby" bin/ruby
   build_line "Installing the Knife gem"
  pushd "$HAB_CACHE_SRC_PATH/$pkg_dirname/knife"
    gem install knife-*.gem --no-document

    build_line "** Installing knife driver"
    # gem install knife-vcenter
    # gem install knife-vrealize
    # gem install knife-vsphere
    # gem install knife-azure
    # gem install knife-ec2
    # gem install knife-google
    # gem install knife-windows
  popd

  # Wrap the Knife binary to ensure correct environment paths
  # wrap_knife_bin
  wrap_ruby_knife
  set_runtime_env "GEM_PATH" "${pkg_prefix}/vendor"
}

# # Wrap the Knife binary to ensure paths are set correctly for execution
# wrap_knife_bin() {

#   build_line "core ruby path $(pkg_path_for core/ruby31)/bin:$PATH"
#   local bin="$pkg_prefix/bin/$pkg_name"
#   local real_bin="$GEM_HOME/gems/knife-${pkg_version}/bin/knife"
#   build_line "Adding wrapper $bin to $real_bin"
#   cat <<EOF > "$bin"
# #!$(pkg_path_for core/bash)/bin/bash
# set -e

# # Set binary path that allows Knife to use non-Hab pkg binaries
# export PATH="/sbin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:\$PATH"

# # Set Ruby paths defined from 'do_setup_environment()'
# export GEM_HOME="$GEM_HOME"
# export GEM_PATH="$GEM_PATH"

# exec $(pkg_path_for core/ruby31)/bin/ruby $real_bin \$@
# EOF
#   chmod -v 755 "$bin"
# }

# do_strip() {
#   return 0
# }



wrap_ruby_knife() {
  local bin="$pkg_prefix/bin/$pkg_name"
  local real_bin="$GEM_HOME/gems/knife-${pkg_version}/bin/knife"
  wrap_bin_with_ruby "$bin" "$real_bin"
}

wrap_bin_with_ruby() {
  local bin="$1"
  local real_bin="$2"
  build_line "Adding wrapper $bin to $real_bin"
  cat <<EOF > "$bin"
#!$(pkg_path_for core/bash)/bin/bash
set -e
# Set binary path that allows cookstyle to use non-Hab pkg binaries
export PATH="/sbin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:\$PATH"
# Set Ruby paths defined from 'do_setup_environment()'
export GEM_HOME="$pkg_prefix/vendor"
export GEM_PATH="$GEM_PATH"
exec $(pkg_path_for ${ruby_pkg})/bin/ruby $real_bin \$@
EOF
  chmod -v 755 "$bin"
}

do_strip() {
  return 0
}