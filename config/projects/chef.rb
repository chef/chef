#
# Copyright:: Copyright (c) 2012 Chef Software, Inc.
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

name "chef"
friendly_name "Chef Client"
maintainer "Chef Software, Inc."
homepage "http://www.getchef.com"

build_iteration 1
build_version do
  # Use chef to determine the build version
  source :git, from_dependency: 'chef'

  # Output a SemVer compliant version string
  output_format :semver
end

install_dir    "/opt/chef"

resources_path File.join(files_path, "chef")
mac_pkg_identifier "com.getchef.pkg.chef"

override :bundler,  version: "1.7.0"
override :ruby,     version: "2.1.2"
override :rubygems, version: "2.2.1"

dependency "preparation"
dependency "chef"
dependency "version-manifest"
