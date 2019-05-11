#
# Copyright 2012-2018, Chef Software Inc.
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
friendly_name "Chef Infra Client"
maintainer "Chef Software, Inc. <maintainers@chef.io>"
homepage "https://www.chef.io"
license "Chef EULA"
license_file "CHEF-EULA.md"

build_iteration 1
# Do not use __FILE__ after this point, use current_file. If you use __FILE__
# after this point, any dependent defs (ex: angrychef) that use instance_eval
# will fail to work correctly.
current_file ||= __FILE__
version_file = File.expand_path("../../../../VERSION", current_file)
build_version IO.read(version_file).strip

if windows?
  # NOTE: Ruby DevKit fundamentally CANNOT be installed into "Program Files"
  #       Native gems will use gcc which will barf on files with spaces,
  #       which is only fixable if everyone in the world fixes their Makefiles
  install_dir  "#{default_root}/opscode/#{name}"
  package_name "chef-client"
else
  install_dir "#{default_root}/#{name}"
end

override :chef, version: "local_source"

# Load dynamically updated overrides
overrides_path = File.expand_path("../../../../omnibus_overrides.rb", current_file)
instance_eval(IO.read(overrides_path), overrides_path)

dependency "preparation"

dependency "chef"

#
# addons which require omnibus software defns (not direct deps of chef itself - RFC-063)
#
dependency "nokogiri" # (nokogiri cannot go in the Gemfile, see wall of text in the software defn)

# FIXME?: might make sense to move dependencies below into the omnibus-software chef
#  definition or into a chef-complete definition added to omnibus-software.
dependency "gem-permissions"
dependency "shebang-cleanup"
dependency "version-manifest"
dependency "openssl-customization"

# devkit needs to come dead last these days so we do not use it to compile any gems
if windows?
  override :"ruby-windows-devkit", version: "4.5.2-20111229-1559" if windows_arch_i386?
  dependency "ruby-windows-devkit"
  dependency "ruby-windows-devkit-bash"
end

dependency "ruby-cleanup"

package :rpm do
  signing_passphrase ENV["OMNIBUS_RPM_SIGNING_PASSPHRASE"]
  compression_level 1
  compression_type :xz
end

package :deb do
  compression_level 1
  compression_type :xz
end

proj_to_work_around_cleanroom = self
package :pkg do
  identifier "com.getchef.pkg.#{proj_to_work_around_cleanroom.name}"
  signing_identity "Developer ID Installer: Chef Software, Inc. (EU3VF8YLX2)"
end
compress :dmg

msi_upgrade_code = "D607A85C-BDFA-4F08-83ED-2ECB4DCD6BC5"
project_location_dir = name
package :msi do
  fast_msi true
  upgrade_code msi_upgrade_code
  wix_candle_extension "WixUtilExtension"
  wix_light_extension "WixUtilExtension"
  signing_identity "E05FF095D07F233B78EB322132BFF0F035E11B5B", machine_store: true
  parameters ChefLogDllPath: windows_safe_path(gem_path("chef-[0-9]*-mingw32/ext/win32-eventlog/chef-log.dll")),
             ProjectLocationDir: project_location_dir
end

package :appx do
  signing_identity "E05FF095D07F233B78EB322132BFF0F035E11B5B", machine_store: true
end
