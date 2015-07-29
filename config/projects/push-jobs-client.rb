#
# Copyright 2012-2014 Chef Software, Inc.
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

name          "push-jobs-client"
friendly_name "Push Jobs Client"
maintainer    "Chef Software, Inc. <maintainers@chef.io>"
homepage      "https://www.chef.io"

# Ensure we install over the top of the previous package name
replace  "opscode-push-jobs-client"
conflict "opscode-push-jobs-client"

build_iteration 1
build_version "2.0.0-alpha.1"

if windows?
  # NOTE: Ruby DevKit fundamentally CANNOT be installed into "Program Files"
  #       Native gems will use gcc which will barf on files with spaces,
  #       which is only fixable if everyone in the world fixes their Makefiles
  install_dir  "#{default_root}/opscode/#{name}"
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

override :bundler,        version: "1.7.12"
# Uncomment to pin the chef version
#override :chef,           version: "12.2.1"
override :ruby,           version: "2.1.6"
######
# Ruby 2.1/2.2 has an error on Windows - HTTPS gem downloads aren't working
# https://bugs.ruby-lang.org/issues/11033
# Going to leave 2.1.5 for now since there is a workaround
override :'ruby-windows', version: "2.1.5"
override :'ruby-windows-devkit', version: "4.7.2-20130224-1151"
#override :'ruby-windows', version: "2.0.0-p451"
######

# Short term fix to keep from breaking old client build process
override :libzmq, version: "4.0.5"

######
# rubygems 2.4.5 is not working on windows.
# See https://github.com/rubygems/rubygems/issues/1120
# Once this is fixed, we can bump the version
override :rubygems,       version: "2.4.4"
######

dependency "preparation"
dependency "opscode-pushy-client"
dependency "version-manifest"

package :rpm do
  signing_passphrase ENV['OMNIBUS_RPM_SIGNING_PASSPHRASE']
end

package :pkg do
  identifier "com.getchef.pkg.push-jobs-client"
  signing_identity "Developer ID Installer: Chef Software, Inc. (EU3VF8YLX2)"
end
compress :dmg

package :msi do
  # Upgrade code for Chef MSI
  upgrade_code "D607A85C-BDFA-4F08-83ED-2ECB4DCD6BC5"
  signing_identity "F74E1A68005E8A9C465C3D2FF7B41F3988F0EA09", machine_store: true

  #######################################################################
  # Locate the Chef gem's path relative to the installation directory
  #######################################################################
  install_path = Pathname.new(install_dir)

  # Find path in which the Chef gem is installed
  search_pattern = "#{install_path}/**/gems/opscode-pushy-client-[0-9]*"
  gem_path  = Pathname.glob(search_pattern).find { |path| path.directory? }

  if gem_path.nil?
    raise "Could not find a gem in `#{search_pattern}'!"
  else
    relative_path = gem_path.relative_path_from(install_path)
  end

  parameters(
    # We are going to use this path in the startup command of chef
    # service. So we need to change file seperators to make windows
    # happy.
    'PushJobsGemPath' => windows_safe_path(relative_path.to_s),
  )
end
