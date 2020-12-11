# THIS IS NOW HAND MANAGED, JUST EDIT THE THING
# keep it machine-parsable since CI uses it
#
# NOTE: You MUST update omnibus-software when adding new versions of
# software here: bundle exec rake dependencies:update_omnibus_gemfile_lock
override :rubygems, version: "3.1.4" # pin to what ships in the ruby version
override :bundler, version: "2.1.4" # pin to what ships in the ruby version
override "libarchive", version: "3.5.0"
override "libffi", version: "3.3"
override "libiconv", version: "1.16"
override "liblzma", version: "5.2.5"
override "libtool", version: "2.4.2"
override "libxml2", version: "2.9.10"
override "libxslt", version: "1.1.34"
override "libyaml", version: "0.1.7"
override "makedepend", version: "1.0.5"
override "ncurses", version: "5.9"
override "nokogiri", version: "1.10.10"
override "openssl", version: "1.0.2w"
override "pkg-config-lite", version: "0.28-1"
override "ruby", version: "2.7.2"
override "ruby-windows-devkit-bash", version: "3.1.23-4-msys-1.0.18"
override "util-macros", version: "1.19.0"
override "xproto", version: "7.0.28"
override "zlib", version: "1.2.11"

# We build both chef and ohai omnibus-software definitions which creates the
# chef-client and ohai binstubs. Out of the box the ohai definition uses whatever
# is in master, which won't match what's in the Gemfile.lock and used by the chef
# definition. This pin will ensure that ohai and chef-client commands use the
# same (released) version of ohai.
gemfile_lock = File.join(File.expand_path(__dir__), "Gemfile.lock")
override "ohai", version: "#{::File.readlines(gemfile_lock).find { |l| l =~ /^\s+ohai \((\d+\.\d+\.\d+)\)/ }; "v" + $1}" # rubocop: disable Layout/SpaceInsideStringInterpolation
