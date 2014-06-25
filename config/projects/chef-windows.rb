#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

name "chef-windows"
friendly_name "Chef Client"
maintainer "Chef Software, Inc."
homepage "http://www.getchef.com"

# NOTE: Ruby DevKit fundamentally CANNOT be installed into "Program Files"
#       Native gems will use gcc which will barf on files with spaces,
#       which is only fixable if everyone in the world fixes their Makefiles
install_path    "c:\\opscode\\chef"

build_iteration 1
build_version do
  # Use chef to determine the build version
  source :git, from_dependency: 'chef-windows'

  # Set a Rubygems style version
  output_format :git_describe
end

package_name    "chef-client"

override :rubygems, version: "1.8.29"

dependency "preparation"
dependency "chef-windows"

resources_path File.join(files_path, "chef")

msi_parameters do
  msi_parameters = { }

  # Find path in which chef gem is installed to.
  # Note that install_dir is something like: c:\\opscode\\chef
  chef_path_regex = "#{install_path.gsub(File::ALT_SEPARATOR, File::SEPARATOR)}/**/gems/chef-[0-9]*"
  chef_gem_paths = Dir[chef_path_regex].select{ |path| File.directory?(path) }
  unless chef_gem_paths.length == 1
    raise "Expected one but found #{chef_gem_paths.length} installation directories \
      for chef gem using: #{chef_path_regex}. Found paths: #{chef_gem_paths.inspect}."
  end
  chef_gem_path = chef_gem_paths.first
  # Convert the chef gem path to a relative path based on install_dir
  # We are going to use this path in the startup command of chef
  # service. So we need to change file seperators to make windows
  # happy.
  chef_gem_path.gsub!(File::SEPARATOR, File::ALT_SEPARATOR)
  chef_gem_path.slice!(install_path.gsub(File::SEPARATOR, File::ALT_SEPARATOR) + File::ALT_SEPARATOR)
  msi_parameters[:chef_gem_path] = chef_gem_path

  # Upgrade code for Chef MSI
  msi_parameters[:upgrade_code] = "D607A85C-BDFA-4F08-83ED-2ECB4DCD6BC5"

  msi_parameters
end
