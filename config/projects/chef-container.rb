#
# Copyright:: Copyright (c) 2012-2014 Chef Software, Inc.
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

name "chef-container"
maintainer "Chef Software, Inc"
homepage "http://www.getchef.com"

install_path     "/opt/chef"
build_version do
  # Use chef to determine the build version
  source :git, from_dependency: 'chef'

  # Set a Rubygems style version
  output_format :git_describe
end
build_iteration  1
package_name     "chef-container"

override :chef, version: "11.12.4"
override :runit, version: "2.1.1"

dependency "preparation"
dependency "chef"
dependency "chef-container"
dependency "version-manifest"
