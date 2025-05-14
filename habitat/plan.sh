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
  core/make
  core/gcc
  core/git
  core/which
  core/bundler
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
  export CPPFLAGS="${CPPFLAGS} ${CFLAGS}"
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
    bundle config --local jobs "$(nproc)"
    bundle config --local without server docgen maintenance pry travis integration ci
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
    # we're on new-enough bundler, we need at least rubygems 3.4.14 to get the
    # spec.ignored? method, except you cannot change the habitat read-only
    # ruby install. So as a temporary workaround, we provide that method
    # as a monkeypatch that will be required at runtime

    build_line "Creating monkey_patch_ignored.rb"
    cat <<'EOF' > monkey_patch_ignored.rb
class Gem::Specification
  def ignored?
    false
  end unless method_defined?(:ignored?)
end
EOF

    build_line "Installing gem dependencies ..."
    RUBYOPT="-r${CACHE_PATH}/monkey_patch_ignored.rb" \
      ruby -S bundle install --jobs=3 --retry=3

    build_line "Installing gems from git repos properly ..."
    RUBYOPT="-r${CACHE_PATH}/monkey_patch_ignored.rb" \
      ruby ./post-bundle-install.rb

    build_line "Installing this project's gems ..."
    RUBYOPT="-r${CACHE_PATH}/monkey_patch_ignored.rb" \
      bundle exec rake install:local
  )
}

do_install() {
  ( cd "$pkg_prefix" || exit_with "unable to enter pkg prefix directory" 1
    export BUNDLE_GEMFILE="${CACHE_PATH}/Gemfile"

    build_line "** fixing binstub shebangs"
    fix_interpreter "${pkg_prefix}/vendor/bin/*" "$_chef_client_ruby" bin/ruby

    for gem in chef-bin chef inspec-core-bin ohai; do
      build_line "** generating binstubs for $gem with precise version pins"
      "${pkg_prefix}/vendor/bin/appbundler" $CACHE_PATH $pkg_prefix/bin $gem
    done

    build_line "** copying monkey_patch_ignored.rb into package"
    cp "${CACHE_PATH}/monkey_patch_ignored.rb" "$pkg_prefix/vendor/"

    build_line "** configuring bundle to load monkey_patch"
    mkdir -p "$pkg_prefix/vendor/bundler/setup"
    cat <<'EOF' > "$pkg_prefix/vendor/bundler/setup.rb"
# preload monkeypatch and continue loading bundler
require_relative '../monkey_patch_ignored'
require 'bundler/setup'
EOF

    cat <<EOF > "$pkg_prefix/bin/bundler"
#!/bin/sh
RUBYLIB="$pkg_prefix/vendor" exec ruby -r"bundler/setup" "$(hab pkg path core/bundler)/bin/bundler" "\$@"
EOF
    chmod +x "$pkg_prefix/bin/bundler"

    # but all that doesn't seem to work for rspec, I think because the hab
    # tests don't use 'bundle exec', so...
    # monkeypatch rspec to require monkey_patch_ignored.rb before anything else
    build_line "** patching rspec binstub to preload monkey_patch"
    # Rename original binstub
    mv "$pkg_prefix/vendor/bin/rspec" "$pkg_prefix/vendor/bin/rspec.real"

    # Write a new wrapper
    cat <<EOF > "$pkg_prefix/vendor/bin/rspec"
#!/bin/sh
RUBYLIB="$pkg_prefix/vendor" exec ruby -r"monkey_patch_ignored.rb" "\$0".real "\$@"
EOF

    chmod +x "$pkg_prefix/vendor/bin/rspec"
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
