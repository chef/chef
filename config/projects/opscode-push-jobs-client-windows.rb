#
# Copyright:: Copyright (c) 2012-2014 Chef, Inc.
# License:: Apache License, Version 2.0
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

name       "opscode-push-jobs-client-windows"
maintainer "CHEF, Inc."
homepage   "http://www.getchef.com"

package_name    "opscode-push-jobs-client"
install_path    "c:\\opscode_pushy_build"
build_version   Omnibus::BuildVersion.new.semver
build_iteration 1

dependency "preparation"
dependency "ruby-windows"
dependency "ruby-windows-devkit"
dependency "chef-gem-windows"
dependency "bundler"
dependency "libzmq-windows"
dependency "opscode-pushy-client-windows"
dependency "version-manifest"

exclude '\.git*'
exclude 'bundler\/git'


resources_path File.join(files_path, "push-jobs-client")

msi_parameters do
  msi_parameters = { }

  # build_version looks something like this:
  # dev builds => 11.14.0-alpha.1+20140501194641.git.94.561b564
  # rel builds => 11.14.0.alpha.1 || 11.14.0
  versions = build_version.split("-").first.split(".")
  msi_parameters[:major_version] = versions[0]
  msi_parameters[:minor_version] = versions[1]
  msi_parameters[:micro_version] = versions[2]
  msi_parameters[:build_version] = build_iteration

  # Find path in which chef gem is installed to.
  # Note that install_dir is something like: c:\\opscode\\chef
  push_path_regex = "#{install_path.gsub(File::ALT_SEPARATOR, File::SEPARATOR)}/**/gems/opscode-pushy-client-[0-9]*"
  push_gem_paths = Dir[push_path_regex].select{ |path| File.directory?(path) }
  unless push_gem_paths.length == 1
    raise "Expected one but found #{push_gem_paths.length} installation directories \
      for chef gem using: #{push_path_regex}. Found paths: #{push_gem_paths.inspect}."
  end
  push_gem_path = push_gem_paths.first
  # Convert the chef gem path to a relative path based on install_dir
  # We are going to use this path in the startup command of chef
  # service. So we need to change file seperators to make windows
  # happy.
  push_gem_path.gsub!(File::SEPARATOR, File::ALT_SEPARATOR)
  push_gem_path.slice!(install_path.gsub(File::SEPARATOR, File::ALT_SEPARATOR) + File::ALT_SEPARATOR)
  msi_parameters[:push_gem_path] = push_gem_path

  # Upgrade code for Chef MSI
  msi_parameters[:upgrade_code] = "D607A85C-BDFA-4F08-83ED-2ECB4DCD6BC5"

  msi_parameters
end
