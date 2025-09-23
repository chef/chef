export HAB_BLDR_CHANNEL="LTS-2024"
SRC_PATH="$(dirname "$PLAN_CONTEXT")"
_chef_client_ruby="core/ruby3_1"
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
  export HAB_BLDR_CHANNEL="LTS-2024"
  export HAB_STUDIO_SECRET_NODE_OPTIONS="--dns-result-order=ipv4first"
  export HAB_STUDIO_SECRET_HAB_BLDR_CHANNEL="LTS-2024"
  export HAB_STUDIO_SECRET_HAB_FALLBACK_CHANNEL="LTS-2024"
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

    build_line "=== DEBUGGING GEMFILE LOCATION AND CONTENT ==="
    build_line "Current working directory: $(pwd)"
    build_line "CACHE_PATH: $CACHE_PATH"
    build_line "Contents of current directory:"
    ls -la

    build_line "Checking if Gemfile exists and showing path:"
    if [ -f Gemfile ]; then
      build_line "Gemfile found at: $(pwd)/Gemfile"
    else
      build_line "Gemfile NOT found in current directory!"
      exit_with "Gemfile not found in CACHE_PATH" 1
    fi

    build_line "=== GEMFILE CONTENT VERIFICATION ==="
    build_line "Searching for InSpec in Gemfile..."
    grep -n "inspec" Gemfile || build_line "No InSpec references found in Gemfile!"

    build_line "Full InSpec-related lines in Gemfile:"
    grep -n -A1 -B1 "inspec" Gemfile || build_line "No InSpec context found!"

    build_line "Verifying custom InSpec branch specifically..."
    if grep -q "inspec.*git.*CHEF-23547" Gemfile; then
      build_line "Custom InSpec branch found in Gemfile!"
    else
      build_line "WARNING: Custom InSpec branch NOT found in Gemfile!"
      build_line "Let's check what InSpec entries exist:"
      grep "inspec" Gemfile || build_line "No InSpec entries found at all!"
    fi

    build_line "=== BUNDLE ENVIRONMENT ==="
    build_line "Bundle version: $(bundle --version)"
    build_line "Ruby version: $(ruby --version)"
    build_line "Gem environment:"
    gem env | grep -E "RUBY EXECUTABLE|INSTALLATION DIRECTORY|GEM PATH"

    build_line "Installing gem dependencies ..."
    bundle install --jobs=3 --retry=3

    build_line "Installing gems from git repos properly ..."
    ruby ./post-bundle-install.rb

    build_line "Installing this project's gems ..."
    bundle exec rake install:local

    build_line "Final verification of InSpec installation..."
    gem list inspec
  )
}

do_install() {
  # workaround to load custom chef-licensing branch
  git clone --depth 1 --branch nm/introducing-optional-mode https://github.com/chef/chef-licensing.git /tmp/chef-licensing
  pushd /tmp/chef-licensing/components/ruby
  gem build chef-licensing.gemspec
  gem install chef-licensing-*.gem --no-document
  popd
  rm -rf /tmp/chef-licensing

  gem source --add "https://artifactory-internal.ps.chef.co/artifactory/omnibus-gems-local/"
  gem install chef-official-distribution
  gem sources -r "https://artifactory-internal.ps.chef.co/artifactory/omnibus-gems-local/"

  # Verify chef-licensing and chef-official-distribution installation
  build_line "** Verifying custom gem installations"
  gem list chef-licensing
  gem list chef-official-distribution

  ( cd "$pkg_prefix" || exit_with "unable to enter pkg prefix directory" 1
    export BUNDLE_GEMFILE="${CACHE_PATH}/Gemfile"

    build_line "** Verifying InSpec versions before binstub generation"
    cd "${CACHE_PATH}" && bundle list | grep inspec

    build_line "** fixing binstub shebangs"
    fix_interpreter "${pkg_prefix}/vendor/bin/*" "$_chef_client_ruby" bin/ruby

    for gem in chef-bin chef inspec-core-bin ohai; do
      build_line "** generating binstubs for $gem with precise version pins"
      "${pkg_prefix}/vendor/bin/appbundler" $CACHE_PATH $pkg_prefix/bin $gem
    done

    # Final verification of installed gems in the package
    build_line "** Final verification of packaged gems"
    ls -la "${pkg_prefix}/vendor/gems/" | grep inspec || build_line "WARNING: InSpec gems not found in vendor/gems!"
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
