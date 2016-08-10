# gem installs this gem from the version specified in chef's Gemfile.lock
# so we can take advantage of omnibus's caching. Just duplicate this file and
# add the new software def to chef software def if you want to separate
# another gem's installation.
require_relative "../../files/chef-gem/build-chef-gem/gem-install-software-def"
BuildChefGem::GemInstallSoftwareDef.define(self, __FILE__)

license "Ruby"
license_file "https://github.com/flori/json/blob/master/README.md"
license_file "https://www.ruby-lang.org/en/about/license.txt"
skip_transitive_dependency_licensing true
