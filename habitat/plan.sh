pkg_name=chef-client
pkg_origin=chef
pkg_maintainer="The Chef Maintainers <humans@chef.io>"
pkg_description="The Chef Client"
pkg_version=$(cat ../VERSION)
pkg_source=nosuchfile.tar.gz
pkg_filename=${pkg_dirname}.tar.gz
pkg_license=('Apache-2.0')
pkg_bin_dirs=(bin)
pkg_build_deps=(core/make core/gcc core/coreutils core/git)
pkg_deps=(core/glibc core/ruby core/libxml2 core/libxslt core/libiconv core/xz core/zlib core/bundler core/openssl core/cacerts core/libffi)
pkg_svc_user=root

do_download() {
  build_line "Fake download! Creating archive of latest repository commit."
  # source is in this repo, so we're going to create an archive from the
  # appropriate path within the repo and place the generated tarball in the
  # location expected by do_unpack
  cd $PLAN_CONTEXT/../
  git archive --prefix=${pkg_name}-${pkg_version}/ --output=$HAB_CACHE_SRC_PATH/${pkg_filename} HEAD
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

  export GEM_HOME=${pkg_prefix}
  export GEM_PATH=${_bundler_dir}:${GEM_HOME}

  export NOKOGIRI_CONFIG="--use-system-libraries --with-zlib-dir=${_zlib_dir} --with-xslt-dir=${_libxslt_dir} --with-xml2-include=${_libxml2_dir}/include/libxml2 --with-xml2-lib=${_libxml2_dir}/lib"
  bundle config --local build.nokogiri '${NOKOGIRI_CONFIG}'

  bundle config --local silence_root_warning 1

  # We need to add tzinfo-data to the Gemfile since we're not in an
  # environment that has this from the OS
  if [[ -z "`grep 'gem .*tzinfo-data.*' Gemfile`" ]]; then
    echo 'gem "tzinfo-data"' >> Gemfile
  fi

  bundle install --no-deployment --jobs 2 --retry 5 --path $pkg_prefix

  bundle exec 'cd ./chef-config && rake package'
  bundle exec 'rake package'
  mkdir -p gems-suck/gems
  cp pkg/chef-$pkg_version.gem gems-suck/gems
  cp chef-config/pkg/chef-config-$pkg_version.gem gems-suck/gems
  bundle exec gem generate_index -d gems-suck

  sed -e "s#gem \"chef\".*#gem \"chef\", source: \"file://$HAB_CACHE_SRC_PATH/$pkg_dirname/gems-suck\"#" -i Gemfile
  sed -e "s#gem \"chef-config\".*#gem \"chef-config\", source: \"file://$HAB_CACHE_SRC_PATH/$pkg_dirname/gems-suck\"#" -i Gemfile
  #bundle config --local local.chef $HAB_CACHE_SRC_PATH/$pkg_dirname/gems-suck
  #bundle config --local local.chef-config $HAB_CACHE_SRC_PATH/$pkg_dirname/gems-suck

  bundle install --no-deployment --jobs 2 --retry 5 --path $pkg_prefix

}

do_install() {

  mkdir -p $pkg_prefix/bin

  bundle exec appbundler $HAB_CACHE_SRC_PATH/$pkg_dirname $pkg_prefix/bin chef
  bundle exec appbundler $HAB_CACHE_SRC_PATH/$pkg_dirname $pkg_prefix/bin ohai

  for binstub in ${pkg_prefix}/bin/*; do
    build_line "Setting shebang for ${binstub} to 'ruby'"
    [[ -f $binstub ]] && sed -e "s#/usr/bin/env ruby#$(pkg_path_for ruby)/bin/ruby#" -i $binstub
  done

  if [[ `readlink /usr/bin/env` = "$(pkg_path_for coreutils)/bin/env" ]]; then
    build_line "Removing the symlink we created for '/usr/bin/env'"
    rm /usr/bin/env
  fi
}

# Stubs
do_strip() {
  return 0
}
