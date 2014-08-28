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

#
# This is a clone of chef that we can install on build and test machines
# without interfering with the regular build/test.
#

name "angrychef"
friendly_name "Angry Chef Client"
maintainer "Chef Software, Inc."
homepage "https://www.getchef.com"

build_iteration 1
build_version do
  # Use chef to determine the build version
  source :git, from_dependency: 'chef'

  # Output a SemVer compliant version string
  output_format :semver
end

install_dir "/opt/angrychef"

resources_path File.join(files_path, "chef")
mac_pkg_identifier "com.getchef.pkg.angrychef"

dependency "preparation"
dependency "chef"
dependency "version-manifest"
