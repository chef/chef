_chef_client_ruby="core/ruby30"
pkg_name="chef-infra-client"
pkg_origin="chef"
pkg_maintainer="The Chef Maintainers <humans@chef.io>"
pkg_description="The Chef Infra Client"
pkg_license=('Apache-2.0')
pkg_bin_dirs=(
  bin
  vendor/bin
)
pkg_build_deps=(
  core/make
  core/gcc
  core/git
)
pkg_deps=(
  core/glibc
  $_chef_client_ruby
  core/libxml2
  core/libxslt
  core/libiconv
  core/xz
  core/zlib
  core/openssl
  core/cacerts
  core/libffi
  core/coreutils
  core/libarchive
)
pkg_svc_user=root

pkg_version() {
  cat "${SRC_PATH}/VERSION"
}

do_before() {
  do_default_before
  update_pkg_version
  # We must wait until we update the pkg_version to use the pkg_version
  pkg_filename="${pkg_name}-${pkg_version}.tar.gz"
}

do_download() {
  build_line "Locally creating archive of latest repository commit at ${HAB_CACHE_SRC_PATH}/${pkg_filename}"
  # source is in this repo, so we're going to create an archive from the
  # appropriate path within the repo and place the generated tarball in the
  # location expected by do_unpack
  ( cd "${SRC_PATH}" || exit_with "unable to enter hab-src directory" 1
    git archive --prefix="${pkg_name}-${pkg_version}/" --output="${HAB_CACHE_SRC_PATH}/${pkg_filename}" HEAD
  )
}

do_verify() {
  build_line "Skipping checksum verification on the archive we just created."
  return 0
}

do_setup_environment() {
  push_runtime_env GEM_PATH "${pkg_prefix}/vendor"

  set_runtime_env APPBUNDLER_ALLOW_RVM "true" # prevent appbundler from clearing out the carefully constructed runtime GEM_PATH
  set_runtime_env SSL_CERT_FILE "$(pkg_path_for cacerts)/ssl/cert.pem"
  set_runtime_env LANG "en_US.UTF-8"
  set_runtime_env LC_CTYPE "en_US.UTF-8"
}

do_prepare() {
  export GEM_HOME="${pkg_prefix}/vendor"
  export OPENSSL_LIB_DIR="$(pkg_path_for openssl)/lib"
  export OPENSSL_INCLUDE_DIR="$(pkg_path_for openssl)/include"
  export SSL_CERT_FILE="$(pkg_path_for cacerts)/ssl/cert.pem"
  export CPPFLAGS="${CPPFLAGS} ${CFLAGS}"

  ( cd "$CACHE_PATH"
    bundle config --local build.nokogiri "--use-system-libraries \
        --with-zlib-dir=$(pkg_path_for zlib) \
        --with-xslt-dir=$(pkg_path_for libxslt) \
        --with-xml2-include=$(pkg_path_for libxml2)/include/libxml2 \
        --with-xml2-lib=$(pkg_path_for libxml2)/lib"
    bundle config --local jobs "$(nproc)"
    bundle config --local without server docgen maintenance pry travis integration ci chefstyle
    bundle config --local shebang "$(pkg_path_for "$_chef_client_ruby")/bin/ruby"
    bundle config --local retry 5
    bundle config --local silence_root_warning 1
  )

  build_line "Setting link for /usr/bin/env to 'coreutils'"
  if [ ! -f /usr/bin/env ]; then
    ln -s "$(pkg_interpreter_for core/coreutils bin/env)" /usr/bin/env
  fi
}

do_build() {
  ( cd "$CACHE_PATH" || exit_with "unable to enter hab-cache directory" 1
    build_line "Installing gem dependencies ..."
    bundle install --jobs=3 --retry=3
    build_line "Installing gems from git repos properly ..."
    ruby ./post-bundle-install.rb
    build_line "Installing this project's gems ..."
    bundle exec rake install
  )
}

do_install() {
  ( cd "$pkg_prefix" || exit_with "unable to enter pkg prefix directory" 1
    export BUNDLE_GEMFILE="${CACHE_PATH}/Gemfile"
    build_line "** fixing binstub shebangs"
    fix_interpreter "${pkg_prefix}/vendor/bin/*" "$_chef_client_ruby" bin/ruby
    export BUNDLE_GEMFILE="${CACHE_PATH}/Gemfile"
    for gem in chef-bin chef inspec-core-bin ohai; do
      build_line "** generating binstubs for $gem with precise version pins"
      appbundler $CACHE_PATH $pkg_prefix/bin $gem
    done
  )
}

do_after() {
  build_line "Trimming the fat ..."

  # We don't need the cache of downloaded .gem files ...
  rm -r "$pkg_prefix/vendor/cache"
  # ... or bundler's cache of git-ref'd gems
  rm -r "$pkg_prefix/vendor/bundler"
  # We don't need the gem docs.
  rm -r "$pkg_prefix/vendor/doc"
  # We don't need to ship the test suites for every gem dependency,
  # only Chef's for package verification.
  find "$pkg_prefix/vendor/gems" -name spec -type d | grep -v "chef-${pkg_version}" \
      | while read spec_dir; do rm -r "$spec_dir"; done
}

do_end() {
  if [ "$(readlink /usr/bin/env)" = "$(pkg_interpreter_for core/coreutils bin/env)" ]; then
    build_line "Removing the symlink we created for '/usr/bin/env'"
    rm /usr/bin/env
  fi
}

do_strip() {
  return 0
}
