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

name "chef11-windows"
friendly_name "Chef Client"
maintainer "Chef Software, Inc."
homepage "https://www.getchef.com"

# NOTE: Ruby DevKit fundamentally CANNOT be installed into "Program Files"
#       Native gems will use gcc which will barf on files with spaces,
#       which is only fixable if everyone in the world fixes their Makefiles
install_dir    "#{default_root}/chef"

build_iteration 1
build_version do
  # Use chef to determine the build version
  source :git, from_dependency: 'chef-windows'

  # Output a SemVer compliant version string
  output_format :semver
end

package_name    "chef-client"

override :chef,     version: "11-stable"
override :bundler,  version: "1.5.2"
override :ruby,     version: "1.9.3-p547"
override :rubygems, version: "1.8.29"

dependency "preparation"
dependency "chef-windows"

resources_path File.join(files_path, "chef")

msi_parameters do
  # Find path in which chef gem is installed to.
  # Note that install_dir is something like: c:/opscode/chef
  search_pattern = "#{install_dir}/**/gems/chef-[0-9]*"
  chef_gem_path  = Dir.glob(search_pattern).find do |path|
    File.directory?(path)
  end

  if chef_gem_path.nil?
    raise "Could not find a chef gem in `#{search_pattern}'!"
  end

  # Convert the chef gem path to a relative path based on install_dir
  relative_path = Pathname.new(chef_gem_path)
    .relative_path_from(Pathname.new(install_dir))
    .to_s

  # Return the result as a hash
  {
    # We are going to use this path in the startup command of chef
    # service. So we need to change file seperators to make windows
    # happy.
    chef_gem_path: relative_path.gsub(File::SEPARATOR, File::ALT_SEPARATOR),
    upgrade_code:  'D607A85C-BDFA-4F08-83ED-2ECB4DCD6BC5',
  }
end
