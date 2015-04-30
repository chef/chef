#
# Copyright 2014 Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

name "chefdk"
friendly_name "Chef Development Kit"
maintainer "Chef Software, Inc. <maintainers@chef.io>"
homepage "https://www.getchef.com"

build_iteration 1
build_version do
  source :git, from_dependency: 'chefdk'
  output_format :semver
end

if windows?
  # NOTE: Ruby DevKit fundamentally CANNOT be installed into "Program Files"
  #       Native gems will use gcc which will barf on files with spaces,
  #       which is only fixable if everyone in the world fixes their Makefiles
  install_dir "#{default_root}/opscode/#{name}"
else
  install_dir "#{default_root}/#{name}"
end

# As of 27 October 2014, the newest CA cert bundle does not work with AWS's
# root cert. See:
# * https://github.com/opscode/chef-dk/issues/199
# * https://blog.mozilla.org/security/2014/09/08/phasing-out-certificates-with-1024-bit-rsa-keys/
# * https://forums.aws.amazon.com/thread.jspa?threadID=164095
# * https://github.com/opscode/omnibus-supermarket/commit/89197026af2931de82cfdc13d92ca2230cced3b6
#
# For now we resolve it by using an older version of the cert. This only works
# if you have this version of the CA bundle stored via S3 caching (which Chef
# Software does).
override :cacerts, version: '2014.08.20'

override :berkshelf,      version: "v3.2.3"
override :bundler,        version: "1.7.12"
override :chef,           version: "12.2.1"
override :'chef-vault',   version: "v2.4.0"

# TODO: Can we bump default versions in omnibus-software?
override :libedit,        version: "20130712-3.1"
override :libtool,        version: "2.4.2"
override :libxml2,        version: "2.9.1"
override :libxslt,        version: "1.1.28"

override :ruby,           version: "2.1.5"
######
# Ruby 2.1/2.2 has an error on Windows - HTTPS gem downloads aren't working
# https://bugs.ruby-lang.org/issues/11033
# Going to leave 2.1.5 for now since there is a workaround
override :'ruby-windows', version: "2.1.5"
override :'ruby-windows-devkit', version: "4.7.2-20130224-1151"
#override :'ruby-windows', version: "2.0.0-p451"
######

######
# rubygems 2.4.5 is not working on windows.
# See https://github.com/rubygems/rubygems/issues/1120
# Once this is fixed, we can bump the version
override :rubygems,       version: "2.4.4"
######

override :'test-kitchen', version: "v1.4.0"
override :'kitchen-vagrant', version: "v0.17.0"
override :yajl,           version: "1.2.1"
override :zlib,           version: "1.2.8"

override :'chef-provisioning', version: "v1.1.1"
override :'chef-provisioning-fog', version: "v0.13.2"
override :'chef-provisioning-vagrant', version: "v0.8.3"
override :'chef-provisioning-azure', version: "v0.3.2"
override :'chef-provisioning-aws', version: "v1.1.1"

dependency "preparation"
dependency "chefdk"
dependency "chef-provisioning"
dependency "chef-provisioning-fog"
dependency "chef-provisioning-vagrant"
dependency "chef-provisioning-azure"
dependency "chef-provisioning-aws"
dependency "rubygems-customization"
dependency "shebang-cleanup"
dependency "version-manifest"
dependency "openssl-customization"

package :rpm do
  signing_passphrase ENV['OMNIBUS_RPM_SIGNING_PASSPHRASE']
end

package :pkg do
  identifier "com.getchef.pkg.chefdk"
  signing_identity "Developer ID Installer: Chef Software, Inc. (EU3VF8YLX2)"
end

package :msi do
  upgrade_code "AB1D6FBD-F9DC-4395-BDAD-26C4541168E7"
end

compress :dmg
