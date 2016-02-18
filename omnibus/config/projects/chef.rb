#
# Copyright 2012-2016, Chef Software, Inc.
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
maintainer "Chef Software, Inc. <maintainers@chef.io>"
homepage "https://www.chef.io"

build_iteration 1
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

if windows?
  #override :'ruby-windows', version: "2.0.0-p645"
  ## Leave dev-kit pinned to 4.5 because 4.7 is 20MB larger and we don't want
  ## to unnecessarily make the client any fatter.
  #if windows_arch_i386?
    #override :'ruby-windows-devkit', version: "4.5.2-20111229-1559"
  #end
  override :ruby, version: "2.0.0-p645"
  # Leave dev-kit pinned to 4.5 because 4.7 is 20MB larger and we don't want
  # to unnecessarily make the client any fatter.
  if windows_arch_i386?
    override :'ruby-windows-devkit', version: "4.5.2-20111229-1559"
  end
else
  override :ruby, version: "2.1.6"
end

override :bundler,      version: "1.11.2"
override :rubygems,     version: "2.5.2"

# Chef Release version pinning
override :chef, version: "local_source"
override :ohai, version: "master"
override :"rb-readline", version: "v0.5.3"

# Global FIPS override flag.
override :fips, enabled: true

dependency "preparation"
dependency "chef"
dependency "pry"
dependency "nokogiri"
dependency "shebang-cleanup"
dependency "version-manifest"
dependency "openssl-customization"
dependency "rb-readline"
dependency "ruby-windows-devkit"
dependency "ruby-windows-devkit-bash"

package :rpm do
  signing_passphrase ENV["OMNIBUS_RPM_SIGNING_PASSPHRASE"]
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
  signing_identity "F74E1A68005E8A9C465C3D2FF7B41F3988F0EA09", machine_store: true
  parameters ChefLogDllPath: windows_safe_path(gem_path("chef-[0-9]*-mingw32/ext/win32-eventlog/chef-log.dll")),
             ProjectLocationDir: project_location_dir
end
