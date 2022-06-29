# THIS IS NOW HAND MANAGED, JUST EDIT THE THING
# keep it machine-parsable since CI uses it
#
# NOTE: You MUST update omnibus-software when adding new versions of
# software here: bundle exec rake dependencies:update_omnibus_gemfile_lock
override "libffi", version: "3.4.2"
override "libiconv", version: "1.16"
override "liblzma", version: "5.2.5"
override "libtool", version: "2.4.2"

# libxslt 1.1.35 does not build successfully with libxml2 2.9.13 on Windows so we will pin
# windows builds to libxslt 1.1.34 and libxml2 2.9.10 for now and followup later with the
# work to fix that issue in IPACK-145.
override "libxml2", version: windows? ? "2.9.10" : "2.9.13"
override "libxslt", version: windows? ? "1.1.34" : "1.1.35"

override "libyaml", version: "0.1.7"
override "makedepend", version: "1.0.5"
override "ncurses", version: "6.3"
override "nokogiri", version: "1.13.1"
override "openssl", version: mac_os_x? ? "1.1.1m" : "1.0.2zb"
override "pkg-config-lite", version: "0.28-1"
override :ruby, version: aix? ? "3.0.3" : "3.1.2"
override "ruby-windows-devkit-bash", version: "3.1.23-4-msys-1.0.18"
override "util-macros", version: "1.19.0"
override "xproto", version: "7.0.28"
override "zlib", version: "1.2.11"
