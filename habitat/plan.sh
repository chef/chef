export HAB_BLDR_CHANNEL="base-2025"
SRC_PATH="$(dirname "$PLAN_CONTEXT")"
_chef_client_ruby="core/ruby3_4/3.4.8"
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
  core/glibc
  core/make
  core/gcc
  core/git
  core/which
)

pkg_bin_dirs=(bin)
pkg_include_dirs=(include)
pkg_lib_dirs=(lib64)
pkg_pconfig_dirs=(lib64/pkgconfig)

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
  build_line "Setting up the safe directory for the build"
  git config --global --add safe.directory /src
  build_line "Locally creating archive of latest repository commit at ${HAB_CACHE_SRC_PATH}/${pkg_filename}"
  # source is in this repo, so we're going to create an archive from the
  # appropriate path within the repo and place the generated tarball in the
  # location expected by do_unpack
  ( cd "${SRC_PATH}" || exit_with "unable to enter hab-src directory" 1
    git archive --format=tar.gz --prefix="${pkg_name}-${pkg_version}/" --output="${HAB_CACHE_SRC_PATH}/${pkg_filename}" HEAD
  )
}

do_verify() {
  build_line "Skipping checksum verification on the archive we just created."
  return 0
}

do_setup_environment() {
  push_runtime_env GEM_PATH "${pkg_prefix}/vendor"

  set_runtime_env APPBUNDLER_ALLOW_RVM "true" # prevent appbundler from clearing out the carefully constructed runtime GEM_PATH
  set_runtime_env -f SSL_CERT_FILE "$(pkg_path_for cacerts)/ssl/cert.pem"
  set_runtime_env LANG "en_US.UTF-8"
  set_runtime_env LC_CTYPE "en_US.UTF-8"
}

do_prepare() {
  export GEM_HOME="${pkg_prefix}/vendor"
  export OPENSSL_DIR="$(pkg_path_for openssl)"
  export OPENSSL_INCLUDE_DIR="$(pkg_path_for openssl)/include"
  export SSL_CERT_FILE="$(pkg_path_for cacerts)/ssl/cert.pem"
  export CPPFLAGS="${CPPFLAGS} ${CFLAGS} -I$(pkg_path_for core/glibc)/include"
  export CFLAGS="${CPPFLAGS}"
  export LDFLAGS="${LDFLAGS} -L$(pkg_path_for core/glibc)/lib"
  export HAB_BLDR_CHANNEL="base-2025"
  export HAB_STUDIO_SECRET_NODE_OPTIONS="--dns-result-order=ipv4first"
  export HAB_STUDIO_SECRET_HAB_BLDR_CHANNEL="base-2025"
  export HAB_STUDIO_SECRET_HAB_FALLBACK_CHANNEL="base-2025"
  build_line " ** Securing the /src directory"
  git config --global --add safe.directory /src

  ( cd "$CACHE_PATH"
    bundle config --local build.nokogiri "--use-system-libraries \
        --with-zlib-dir=$(pkg_path_for zlib) \
        --with-xslt-dir=$(pkg_path_for libxslt) \
        --with-xml2-include=$(pkg_path_for libxml2)/include/libxml2 \
        --with-xml2-lib=$(pkg_path_for libxml2)/lib"
    bundle config --local build.ffi "-Wl,-rpath,'${LD_RUN_PATH}'"
    bundle config --local jobs "$(nproc)"
    bundle config --local without server docgen maintenance pry travis integration ci
    bundle config --local shebang "$(pkg_path_for "$_chef_client_ruby")/bin/ruby"
    bundle config --local retry 5
    bundle config --local silence_root_warning 1
  )

  # Needed for appbundler-updater to work properly
  build_line "Extracting bundler version from Gemfile.lock"
  BUNDLER_VERSION=$(grep -A 1 "BUNDLED WITH" "$CACHE_PATH/Gemfile.lock" | tail -n 1 | tr -d '[:space:]')
  if [ -z "$BUNDLER_VERSION" ]; then
    exit_with "Failed to extract bundler version from Gemfile.lock" 1
  fi
  build_line "Installing bundler version $BUNDLER_VERSION"
  gem install bundler --version "$BUNDLER_VERSION" --no-document

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

    ruby ./scripts/cleanup_lint_roller.rb

    build_line "Installing this project's gems ..."
    bundle exec rake install:local
  )
}

do_install() {

  # Copy NOTICE to the package directory
  if [[ -f "$PLAN_CONTEXT/../NOTICE" ]]; then
    build_line "Copying NOTICE to package directory"
    cp "$PLAN_CONTEXT/../NOTICE" "$pkg_prefix/"
  else
    build_line "Warning: NOTICE not found at $PLAN_CONTEXT/../NOTICE"
  fi

  ( cd "$pkg_prefix" || exit_with "unable to enter pkg prefix directory" 1
    export BUNDLE_GEMFILE="${CACHE_PATH}/Gemfile"
    # Test if artifactory-internal.ps.chef.co is reachable
    build_line "Testing connectivity to artifactory-internal.ps.chef.co..."
    artifactory_url="https://artifactory-internal.ps.chef.co/artifactory/omnibus-gems-local/"

    if wget --spider --timeout=30 --tries=1 --quiet "$artifactory_url" > /dev/null 2>&1; then
      build_line "Artifactory is reachable, proceeding with chef-official-distribution installation"

      echo "***************** INSTALLING  chef-official-distribution *****************"
      gem sources --add "$artifactory_url"
      gem install chef-official-distribution
      gem sources --remove "$artifactory_url"

      # verify installation
      echo "***************** VERIFYING  chef-official-distribution *****************"
      gem list chef-official-distribution

      if [ $? -ne 0 ]; then
        exit 1
      fi
    else
      build_line "WARNING: Artifactory is not reachable, skipping chef-official-distribution installation"
    fi

    build_line "** fixing binstub shebangs"
    fix_interpreter "${pkg_prefix}/vendor/bin/*" "$_chef_client_ruby" bin/ruby

    for gem in chef-bin chef inspec-core-bin ohai; do
      build_line "** generating binstubs for $gem with precise version pins"
      "${pkg_prefix}/vendor/bin/appbundler" $CACHE_PATH $pkg_prefix/bin $gem
    done

    build_line "** patching binstubs to allow running directly"
    for binstub in ${pkg_prefix}/bin/*; do
      build_line "Before patching $(basename $binstub):"
      head -n 20 "$binstub"
      sed -i "/require \"rubygems\"/r ${PLAN_CONTEXT}/binstub_patch.rb" "$binstub"
      build_line "After patching $(basename $binstub):"
      head -n 20 "$binstub"
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

  # we need the built gems outside of the studio
  build_line "Copying gems to ${SRC_PATH}"
  mkdir -p "${SRC_PATH}/pkg" "${SRC_PATH}/chef-bin/pkg" "${SRC_PATH}/chef-config/pkg" "${SRC_PATH}/chef-utils/pkg"
  cp "${CACHE_PATH}/pkg/chef-${pkg_version}.gem" "${SRC_PATH}/pkg"
  cp "${CACHE_PATH}/chef-bin/pkg/chef-bin-${pkg_version}.gem" "${SRC_PATH}/chef-bin/pkg"
  cp "${CACHE_PATH}/chef-config/pkg/chef-config-${pkg_version}.gem" "${SRC_PATH}/chef-config/pkg"
  cp "${CACHE_PATH}/chef-utils/pkg/chef-utils-${pkg_version}.gem" "${SRC_PATH}/chef-utils/pkg"
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
