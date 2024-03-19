# THIS IS NOW HAND MANAGED, JUST EDIT THE THING
# keep it machine-parsable since CI uses it
#
# NOTE: You MUST update omnibus-software when adding new versions of
# software here: bundle exec rake dependencies:update_omnibus_gemfile_lock
override "libffi", version: "3.4.2"
override "libiconv", version: "1.16"
override "liblzma", version: "5.2.5"
override "libtool", version: "2.4.2"
override "libxml2", version: "2.9.10" if windows?
override "libxslt", version: "1.1.34" if windows?
override "libyaml", version: "0.1.7"
override "makedepend", version: "1.0.5"
override "ncurses", version: "6.3"
override "nokogiri", version: "1.13.1"
override "openssl", version: "3.0.9"
override "pkg-config-lite", version: "0.28-1"
override "ruby", version: "3.0.3", openssl_gem: "3.0.0"
override "ruby-windows-devkit-bash", version: "3.1.23-4-msys-1.0.18"
override "util-macros", version: "1.19.0"
override "xproto", version: "7.0.28"
override "zlib", version: "1.2.11"
