pkg_name=chef-client
pkg_origin=chef
pkg_maintainer="The Chef Maintainers <humans@chef.io>"
pkg_description="The Chef Client"
pkg_license=('Apache-2.0')
pkg_filename="${pkg_name}-${pkg_version}.tar.gz"
pkg_bin_dirs=(bin)
pkg_build_deps=(
  core/make
  core/gcc
  core/git
)
pkg_deps=(
  core/glibc
  core/ruby26
  core/libxml2
  core/libxslt
  core/libiconv
  core/xz
  core/zlib
  core/bundler
  core/openssl
  core/cacerts
  core/libffi
  core/coreutils
  core/libarchive
)
pkg_svc_user=root

pkg_version() {
  cat "${SRC_PATH}/../../VERSION"
}

do_before() {
  do_default_before
  update_pkg_version
}

do_download() {
  build_line "Locally creating archive of latest repository commit."
  # source is in this repo, so we're going to create an archive from the
  # appropriate path within the repo and place the generated tarball in the
  # location expected by do_unpack
  cd ${PLAN_CONTEXT}/../../
  git archive --prefix=${pkg_name}-${pkg_version}/ --output=${HAB_CACHE_SRC_PATH}/${pkg_filename} HEAD
}

do_verify() {
  build_line "Skipping checksum verification on the archive we just created."
  return 0
}

do_prepare() {
  export OPENSSL_LIB_DIR=$(pkg_path_for openssl)/lib
  export OPENSSL_INCLUDE_DIR=$(pkg_path_for openssl)/include
  export SSL_CERT_FILE=$(pkg_path_for cacerts)/ssl/cert.pem

  build_line "Setting link for /usr/bin/env to 'coreutils'"
  [[ ! -f /usr/bin/env ]] && ln -s $(pkg_path_for coreutils)/bin/env /usr/bin/env

  return 0
}

do_build() {
  export CPPFLAGS="${CPPFLAGS} ${CFLAGS}"

  local _bundler_dir=$(pkg_path_for bundler)
  local _libxml2_dir=$(pkg_path_for libxml2)
  local _libxslt_dir=$(pkg_path_for libxslt)
  local _zlib_dir=$(pkg_path_for zlib)

  export GEM_HOME=${pkg_prefix}/bundle
  export GEM_PATH=${_bundler_dir}:${GEM_HOME}

  export NOKOGIRI_CONFIG="--use-system-libraries --with-zlib-dir=${_zlib_dir} --with-xslt-dir=${_libxslt_dir} --with-xml2-include=${_libxml2_dir}/include/libxml2 --with-xml2-lib=${_libxml2_dir}/lib"
  bundle config --local build.nokogiri '${NOKOGIRI_CONFIG}'

  bundle config --local silence_root_warning 1

  pushd ${HAB_CACHE_SRC_PATH}/${pkg_name}-${pkg_version}/chef-config > /dev/null
  _bundle_install "${pkg_prefix}/bundle"
  popd > /dev/null

  _bundle_install "${pkg_prefix}/bundle"
}

do_install() {
  mkdir -p "${pkg_prefix}/chef"
  for dir in bin chef-bin chef-config lib chef.gemspec Gemfile Gemfile.lock; do
    cp -rv "${PLAN_CONTEXT}/../../${dir}" "${pkg_prefix}/chef/"
  done

  # This is just generating binstubs with the correct path.
  # If we generated them on install, bundler thinks our source is in $HAB_CACHE_SOURCE_PATH
  pushd "$pkg_prefix/chef" > /dev/null
  _bundle_install \
    "${pkg_prefix}/bundle" \
    --local \
    --quiet \
    --binstubs "${pkg_prefix}/bin"
  popd > /dev/null

  fix_interpreter "${pkg_prefix}/bin/*" core/coreutils bin/env
  fix_interpreter "${pkg_prefix}/bin/*" core/ruby26 bin/ruby
}

do_end() {
  if [[ `readlink /usr/bin/env` = "$(pkg_path_for coreutils)/bin/env" ]]; then
    build_line "Removing the symlink we created for '/usr/bin/env'"
    rm /usr/bin/env
  fi
}

do_strip() {
  return 0
}

# Helper function to wrap up some repetitive bundle install flags
_bundle_install() {
  local path
  path="$1"
  shift

  bundle install ${*:-} \
    --jobs "$(nproc)" \
    --without development:test \
    --path "$path" \
    --shebang="$(pkg_path_for "core/ruby26")/bin/ruby" \
    --no-clean \
    --retry 5 \
    --standalone
}
