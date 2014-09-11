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

name "chef"
friendly_name "Chef Client"
maintainer "Chef Software, Inc."
homepage "https://www.getchef.com"

build_iteration 1
build_version do
  # Use chef to determine the build version
  source :git, from_dependency: 'chef'

  # Output a SemVer compliant version string
  output_format :semver
end

if windows?
  # NOTE: Ruby DevKit fundamentally CANNOT be installed into "Program Files"
  #       Native gems will use gcc which will barf on files with spaces,
  #       which is only fixable if everyone in the world fixes their Makefiles
  install_dir  "#{default_root}/opscode/#{name}"
  package_name "chef-client"
else
  install_dir "#{default_root}/#{name}"
end

override :bundler,        version: "1.7.2"
# TODO: bump this to 2.1.2 when we can sort out the Solaris compile issues
override :ruby,           version: "1.9.3-p547"
override :'ruby-windows', version: "2.0.0-p451"
override :rubygems,       version: "2.4.1"

dependency "preparation"
dependency "chef"
dependency "version-manifest"

package :rpm do
  signing_passphrase ENV['OMNIBUS_RPM_SIGNING_PASSPHRASE']
end

package :pkg do
  identifier "com.getchef.pkg.chef"
  signing_identity "Developer ID Installer: Opscode Inc. (9NBR9JL2R2)"
end
compress :dmg

package :msi do
  upgrade_code "D607A85C-BDFA-4F08-83ED-2ECB4DCD6BC5"

  #######################################################################
  # Locate the Chef gem's path relative to the installation directory
  #######################################################################
  install_path = Pathname.new(install_dir)

  # Find path in which the Chef gem is installed
  search_pattern = "#{install_path}/**/gems/chef-[0-9]*"
  chef_gem_path  = Pathname.glob(search_pattern).find { |path| path.directory? }

  if chef_gem_path.nil?
    raise "Could not find a chef gem in `#{search_pattern}'!"
  else
    relative_path = chef_gem_path.relative_path_from(install_path)
  end

  parameters(
    # We are going to use this path in the startup command of chef
    # service. So we need to change file seperators to make windows
    # happy.
    'ChefGemPath' => windows_safe_path(relative_path.to_s),
  )
end
