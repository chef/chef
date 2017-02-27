# gem installs this gem from the version specified in chef's Gemfile.lock
# so we can take advantage of omnibus's caching. Just duplicate this file and
# add the new software def to chef software def if you want to separate
# another gem's installation.
require_relative "../../files/chef-gem/build-chef-gem/gem-install-software-def"
BuildChefGem::GemInstallSoftwareDef.define(self, __FILE__)

license "BSD-3-Clause"
license_file "https://github.com/ffi/ffi/blob/master/LICENSE"
license_file "https://github.com/ffi/ffi/blob/master/COPYING"
license_file "https://github.com/ffi/ffi/blob/master/LICENSE.SPECS"
skip_transitive_dependency_licensing true
