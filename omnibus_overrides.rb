# THIS IS NOW HAND MANAGED, JUST EDIT THE THING
# .travis.yml and appveyor.yml consume this,
# try to keep it machine-parsable.
#
# NOTE: You MUST update omnibus-software when adding new versions of
# software here: bundle exec rake dependencies:update_omnibus_gemfile_lock
override :rubygems, version: "2.7.6"
override :bundler, version: "1.16.1"
override "nokogiri", version: "1.8.5"
override "libffi", version: "3.2.1"
override "libiconv", version: "1.15"
override "liblzma", version: "5.2.4"
override "libtool", version: "2.4.2"
override "libxml2", version: "2.9.7"
override "libxslt", version: "1.1.30"
override "libyaml", version: "0.1.7"
override "makedepend", version: "1.0.5"
override "ncurses", version: "5.9"
override "pkg-config-lite", version: "0.28-1"
override "ruby", version: "2.5.3"
override "ruby-windows-devkit-bash", version: "3.1.23-4-msys-1.0.18"
override "util-macros", version: "1.19.0"
override "xproto", version: "7.0.28"
override "zlib", version: "1.2.11"
override "openssl", version: "1.0.2p"
